
# SAGE (11)

Instructions to install and work with [Sage](https://github.com/roots/sage?tab=readme-ov-file).

[![version](https://img.shields.io/badge/version-11-blue.svg)](https://semver.org)

If you need information about earlier versions of Sage, check [SAGE_10.md](SAGE_10.md).

> **All Composer, Node and WP-CLI commands run through Docker.** You don't need them installed locally. The services are defined in `docker-compose.yml`:
>
> | Service | Profile | Used for | Runs in |
> |---|---|---|---|
> | `composer` | `tools` | `composer …` | the theme folder (`wp-content/themes/${WORDPRESS_THEMENAME}`) |
> | `node` | `dev` | `npm …` / Vite | the theme folder |
> | `wpcli` | — | `wp …` (and `wp acorn …`) | the WordPress root |

---

## Installation

The theme is based on Sage 11, a WordPress starter theme that uses Laravel Blade for templates, Vite for assets and Tailwind CSS 4 for styles.

> `new-wp-sage.sh` runs these steps for you when it creates a new project. Use this section to run them by hand.

### Create the theme with Composer

`composer create-project` installs the latest **stable** Sage release, including `vendor/`. The theme folder must not exist or must be empty.

```bash
cd ~/Dockers/<project>

docker compose --profile tools run --rm --user "$(id -u):$(id -g)" \
  -e COMPOSER_HOME=/tmp/composer \
  -w /var/www/html/wp-content/themes \
  composer create-project --no-interaction roots/sage codigo
```

```
  Creating a "roots/sage" project at "./codigo"
  Installing roots/sage (11.0.4)
    - Downloading roots/sage (11.0.4)
    - Installing roots/sage (11.0.4): Extracting archive
  Created project in ./codigo
```

To pin a version, add a constraint at the end, e.g. `... roots/sage codigo "11.*"`.

Then remove the Sage developer files, if they're there:

```bash
cd wordpress/wp-content/themes/codigo
rm -rf .git .github .editorconfig .gitattributes .gitignore
```

### Install the JS libraries and build

```bash
docker compose run --rm node sh -lc "rm -rf node_modules package-lock.json && npm i"
docker compose run --rm node sh -lc "npm run build"
```

```
  > build
  > vite build

  vite v8.0.16 building client environment for production...
  ✓ 5 modules transformed.
  computing gzip size...
  public/build/assets/editor.deps-DxpY22xl.json   0.02 kB │ gzip: 0.04 kB
  public/build/manifest.json                      0.79 kB │ gzip: 0.25 kB
  public/build/assets/theme.json                 41.08 kB │ gzip: 5.35 kB
  public/build/assets/editor-meoVWcpj.css         5.51 kB │ gzip: 1.83 kB
  public/build/assets/app-CBz_0vPW.css           21.14 kB │ gzip: 6.13 kB
  public/build/assets/app-BvRk9kiK.js             0.00 kB │ gzip: 0.02 kB
  public/build/assets/editor-Dqo-zVGR.js          0.02 kB │ gzip: 0.04 kB

  ✓ built in 3.25s
```

The `node` service already runs from the theme folder, so you don't need to `cd` into it.

### Development server

```bash
docker compose --profile dev up node
```

It installs the dependencies if `package-lock.json` has changed, then runs `npm run dev` (Vite with hot reload through Caddy).

- [Install](https://roots.io/sage/)
- [Docs](https://roots.io/sage/docs/installation/)

---

## Vite

### Environment variables

`vite.config.js` reads its settings from environment variables. The `node` service in `docker-compose.yml` sets them from `.env`:

| Vite variable | From `.env` | Example | Used for |
|---|---|---|---|
| `APP_URL` | `WORDPRESS_HOME` | `https://skelly-couch.localhost:8465` | `server.origin` (asset URLs during development) |
| `APP_HOST` | `CADDY_HOSTNAME` | `skelly-couch.localhost` | Hot-reload WebSocket host |
| `APP_PORT` | `WORDPRESS_SSL_PORT` | `8465` | Hot-reload WebSocket port (the browser connects to Caddy) |
| `NODE_PORT` | `NODE_PORT` | `5265` | Vite dev server port inside the container |
| `VITE_PATH` | `VITE_PATH` | `/wp-content/themes/codigo/public/build/` | `base` (public path of the built assets) |

> Sage's default `base` is `/app/themes/sage/public/build/`, which is for **Bedrock** sites. In this setup it must be `/wp-content/themes/<theme>/public/build/`.

### `vite.config.js`

Replace the default `vite.config.js` with this one:

```js
// wordpress/wp-content/themes/codigo/vite.config.js
import path from 'node:path';
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import laravel from 'laravel-vite-plugin';
import { wordpressPlugin, wordpressThemeJson } from '@roots/vite-plugin';

/*
 * Environment variables, set by the `node` service in docker-compose.yml (from .env):
 *
 *   APP_URL    <- WORDPRESS_HOME       e.g. https://skelly-couch.localhost:8465
 *   APP_HOST   <- CADDY_HOSTNAME       e.g. skelly-couch.localhost
 *   APP_PORT   <- WORDPRESS_SSL_PORT   e.g. 8465  (port the browser uses, through Caddy)
 *   NODE_PORT  <- NODE_PORT            e.g. 5265  (Vite dev server inside the container)
 *   VITE_PATH  <- VITE_PATH            e.g. /wp-content/themes/codigo/public/build/
 *
 * The fallbacks are only used when Vite runs outside Docker.
 */
const themeName = path.basename(process.cwd()); // npm scripts run from the theme folder

const env = {
  appUrl:   process.env.APP_URL   || 'http://example.test',
  appHost:  process.env.APP_HOST  || 'example.test',
  appPort:  Number(process.env.APP_PORT  || 8080),
  nodePort: Number(process.env.NODE_PORT || 5173),
  base:     process.env.VITE_PATH || `/wp-content/themes/${themeName}/public/build/`,
};

// laravel-vite-plugin reads APP_URL from the environment
process.env.APP_URL = env.appUrl;

export default defineConfig({
  base: env.base,

  server: {
    host: '0.0.0.0',          // listen inside the container
    port: env.nodePort,
    strictPort: true,
    origin: env.appUrl,       // asset URLs go through Caddy
    hmr: {
      protocol: 'wss',
      host: env.appHost,
      clientPort: env.appPort, // the browser connects to Caddy, not to Node directly
    },
  },

  plugins: [
    tailwindcss(),
    laravel({
      input: [
        'resources/css/app.css',
        'resources/js/app.js',
        'resources/css/editor.css',
        'resources/js/editor.js',
      ],
      refresh: true,
      // Copy and version images and fonts so Blade can use Vite::asset()
      assets: ['resources/images/**', 'resources/fonts/**'],
    }),

    wordpressPlugin(),

    // Generate public/build/assets/theme.json from the Tailwind theme
    // (the @theme variables in your CSS) and the theme's base theme.json
    wordpressThemeJson({
      disableTailwindColors: false,
      disableTailwindFonts: false,
      disableTailwindFontSizes: false,
      disableTailwindBorderRadius: false,
    }),
  ],

  resolve: {
    alias: {
      '@scripts': '/resources/js',
      '@styles': '/resources/css',
      '@fonts': '/resources/fonts',
      '@images': '/resources/images',
    },
  },
});
```

Notes:

- **`assets`** must stay in `laravel()`. Without it, `Vite::asset('resources/images/...')` in Blade won't find images and fonts in the production build.
- **Ports** come from the environment as text, so they're converted with `Number()`.
- **`disableTailwindBorderRadius`** adds your `--radius-*` values to the generated `theme.json`. If a build complains about this option, your installed `@roots/vite-plugin` is older. Update it or remove the line.
- **Hot reload doesn't connect?** Check that the `Caddyfile` sends the Vite requests (`VITE_PATH` and the WebSocket) to the `node` container on `NODE_PORT`.
- **File changes not detected on macOS?** Add `CHOKIDAR_USEPOLLING: "true"` to the `node` service's `environment` in `docker-compose.yml`.

---

## Tailwind CSS 4

Sage 11 uses **Tailwind CSS 4**, which is configured **in CSS**, not in a `tailwind.config.js` file.

- **You don't need `tailwind.config.js` / `tailwind.config.cjs` / `tailwind.site.js`.** Tailwind 4 doesn't load them automatically.
- Design tokens (colours, fonts, font sizes, breakpoints, radii…) go in an **`@theme`** block in `resources/css/base.css`. That's also where `wordpressThemeJson` reads them to build the Gutenberg `theme.json`.
- `base.css` is imported in `app.css`:

  ```css
  @import './base.css';
  ```

### Moving a Tailwind 3 config to Tailwind 4

If you're reusing a `tailwind.config.cjs` from an older project:

| Tailwind 3 (`tailwind.config.cjs`) | Tailwind 4 (CSS) |
|---|---|
| `theme.colors`, `fontFamily`, `fontSize`, `screens`, `zIndex`, `animation`, `keyframes` | `@theme { --color-walnut: #B4695F; --font-sans: …; --text-lg: …; --breakpoint-2xl: 1792px; --animate-appearsin: …; @keyframes appearsIn { … } }` |
| Replacing a whole default scale (e.g. `colors: {…}` instead of `extend`) | `@theme { --color-*: initial; … }` |
| `extend: {…}` | Just add the variables to `@theme` |
| `plugin(({ addBase }) => …)` | `@layer base { … }` |
| `plugin(({ addComponents }) => …)` (`.container` etc.) | `@layer components { … }` or `@utility container { … }` |
| `plugin(({ addVariant }) => …)` | `@custom-variant mobile-only (@media (width < theme(--breakpoint-sm)));` |
| `@media screen(md)` | `@media (width >= theme(--breakpoint-md))` |
| `theme('colors.chalk')` in JS | `var(--color-chalk)` in CSS |
| `presets: [require('tailwindcss/defaultConfig')]` | Not needed: Tailwind 4 includes its defaults |
| `content: [...]` | Not needed: Tailwind 4 finds your templates automatically |

> As a temporary measure, you can still load an old JS config with `@config "../../tailwind.config.cjs";` in `app.css`. Tailwind 3-only parts (`presets`, `screen()`, …) won't work there, though, so it's better to move everything to CSS.

---

## Custom CSS (PostCSS)

You can add your own CSS in `.pcss` files in `resources/css/pcss/` **without** a `postcss.config.js` or any extra packages. Tailwind 4 already handles `@import`, nesting and vendor prefixes.

The short version:

```css
/* resources/css/app.css */
@import "./pcss/assets/globals.pcss" layer(base);
@import "./pcss/layout/header.pcss" layer(components);
```

- Import every file **inside a layer** (`layer(base)` or `layer(components)`). Otherwise your custom CSS overrides Tailwind's utility classes.
- Write standard CSS: `/* */` comments, `@import` instead of `@use`, and full BEM selectors (`.card__title`, not `&__title`).
- Don't add `@tailwindcss/postcss`, `postcss-import` or `autoprefixer`. They're no longer needed, and `@tailwindcss/postcss` would process Tailwind twice.

👉 Full guide, including a checklist for moving old `.pcss` / `.scss` files: **[PostCSS.md](PostCSS.md)**

---

## Fonts

The app includes an empty `resources/fonts/` directory for any custom fonts you want to include in your theme.

### Step 1: Add your font file

Add your `.woff2` font file to the `resources/fonts/` directory. `.woff2` has excellent browser support, so you likely won't need other formats.

For this example, we'll use **Public Sans**, downloaded with [google-webfonts-helper](https://google-webfonts-helper.herokuapp.com/), a handy tool for getting font files and CSS snippets from Google Fonts.

Project structure:

```
resources
├── css
│   ├── app.css
│   ├── base.css         # Design tokens (@theme)
│   ├── fonts.css        # Create this file
│   └── editor.css
├── fonts
│   └── public-sans-v14-latin-regular.woff2
├── images
├── js
└── views
```

### Step 2: Add the CSS

You can put the font CSS wherever you prefer, but we recommend creating a `css/fonts.css` file and importing it into both `app.css` and `editor.css`:

```css
/* In app.css and editor.css */
@import './fonts.css';
```

Then define your `@font-face` in `fonts.css`:

```css
@font-face {
  font-display: swap;
  font-family: 'Public Sans';
  font-style: normal;
  font-weight: 400;
  src: url('@fonts/public-sans-v14-latin-regular.woff2') format('woff2');
}
```

### Step 3: Add the font to Tailwind

Add the font to the Tailwind theme in `base.css`:

```css
@theme {
  --font-sans: 'Public Sans', sans-serif;
}
```

For more details on customising fonts with Tailwind, see the [Tailwind CSS documentation](https://tailwindcss.com/docs/font-family).

### Font sizes

We use our own font sizes in both Tailwind CSS and the Gutenberg editor. Our goals are to:

- define font sizes once in CSS
- let Tailwind use the `--text-*` tokens
- automatically generate the `theme.json` font sizes for Gutenberg blocks

#### 1. Set the base font size

In `resources/css/base.css`, set the root font size and other base styles. This replaces the `addBase()` plugin from the old `tailwind.site.js`:

```css
@layer base {
  :root {
    font-size: 24px;      /* Base font size. The rem values are calculated from this. */
    letter-spacing: 0;
    line-height: 26px;
    font-weight: 300;

    /* Safari resize fix */
    min-height: 0vw;
  }
}
```

#### 2. Define the font sizes

In the same file, declare your font sizes as `--text-*` variables. You can use media queries for responsive sizes:

```css
@theme {
  /* ... */
  --text-base: clamp(1rem, 1.25vw, 1rem);
}

@layer base {
  :root {
    @media (width >= theme(--breakpoint-lg)) {
      --text-base: 1.25vw; /* 24px at 1920px */
    }
    /* ... */
  }
}
```

These are the default values:

```css
@theme {
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;
  --text-5xl: 3rem;
  --text-6xl: 3.75rem;
  --text-7xl: 4.5rem;
  --text-8xl: 6rem;
  --text-9xl: 8rem;
  /* ... */
}
```

To replace the whole scale instead of extending it, start the block with `--text-*: initial;`.

#### 3. Add the font sizes to Gutenberg

In `themes/codigo/theme.json`, edit the `settings.typography.fontSizes` section to choose which font sizes appear in the Gutenberg editor.

This is the default value:

```json
{
  "settings": {
    "typography": {
      "fontSizes": [
        {
          "name": "xs",
          "slug": "xs",
          "size": "8px"
        },
        {
          "name": "sm",
          "slug": "sm",
          "size": ".875rem"
        },
        {
          "name": "base",
          "slug": "base",
          "size": "1rem"
        },
        {
          "name": "lg",
          "slug": "lg",
          "size": "1.125rem"
        },
        {
          "name": "xl",
          "slug": "xl",
          "size": "1.25rem"
        },
        {
          "name": "2xl",
          "slug": "2xl",
          "size": "1.5rem"
        },
        {
          "name": "3xl",
          "slug": "3xl",
          "size": "1.875rem"
        },
        {
          "name": "4xl",
          "slug": "4xl",
          "size": "2.25rem"
        },
        {
          "name": "5xl",
          "slug": "5xl",
          "size": "3rem"
        },
        {
          "name": "6xl",
          "slug": "6xl",
          "size": "3.75rem"
        },
        {
          "name": "8xl",
          "slug": "8xl",
          "size": "6rem"
        },
        {
          "name": "9xl",
          "slug": "9xl",
          "size": "8rem"
        }
      ]
    }
  }
}
```

---

## Colours

We use our own colour palette in both Tailwind CSS and the Gutenberg editor. Our goals are to:

- define colours once in CSS
- let Tailwind use the `--color-*` tokens
- automatically generate the `theme.json` colour palette for Gutenberg

### 1. Define the colours in `base.css`

In `resources/css/base.css`, declare your colours as `--color-*` variables in an `@theme` block. Tailwind creates utilities from them (`bg-beige`, `text-beige`, `border-beige`…) and `wordpressThemeJson` adds them to Gutenberg:

```css
@theme {
  --color-beige: #ECECE4;
  /* ... */
}
```

### 2. Clear Tailwind's colour palette

To use **only** your colours and not Tailwind's default palette, start the block with `--color-*: initial;`:

```css
@theme {
  --color-*: initial; /* 👈 Remove Tailwind's default colours */

  --color-black: #000;
  --color-white: #fff;
  --color-beige: #ECECE4;
  /* ... */
}
```

This replaces `theme: { colors: {} }` from the old `tailwind.config.js`. You don't need a JS config file.

### 3. Add colours to Gutenberg

In `theme.json`, edit the `settings.color.palette` section to choose which colours appear in the Gutenberg colour picker:

```json
{
  "settings": {
    "color": {
      "palette": [
        {
          "name": "Beige",
          "slug": "beige",
          "color": "var(--color-beige)"
        },
        ...
      ]
    }
  }
}
```

### 4. Add colours to ACF

If you're using ACF, you can also add your colours to the ACF colour picker by editing `resources/js/acf-colors.js`:

```js
  acf.add_filter('color_picker_args', function (args, $field) {
    /* Colours (must match the @theme colours in resources/css/base.css) */
    args.palettes = [
      '#ECECE4', // Beige
      ...
    ]
    return args;
  });
```

### 5. Rebuild the theme

Run the build:

```bash
docker compose run --rm node sh -lc "npm run build"
```

Sage will:

- read the Tailwind theme (the `@theme` variables in your CSS)
- extract the `--color-*` variables
- generate `public/build/assets/theme.json` with a Gutenberg colour palette

### 6. Using the colours in Tailwind and Gutenberg

#### In Tailwind

Use the generated utilities:

```html
<div class="bg-blue text-white">
  Custom styled section
</div>
```

`var()` also works, e.g. `bg-(--color-blue)`, which is the Tailwind 4 shorthand for `bg-[var(--color-blue)]`.

#### In Gutenberg

Open a block like Paragraph or Group and choose one of your colours in the editor. No PHP or JSON editing is required.

---

## Gutenberg Block Extensions in Sage 11 (with Vite)

This project uses a modular system to register Gutenberg block **variations**, **styles** and **filters**, using Vite's `import.meta.glob()` to discover them automatically. This replaces the Bud.js system from earlier Sage versions.

### Auto-register Gutenberg styles, variations and filters

Sage 11 (Vite) does **not automatically load block styles, variations or filters** from the `resources/js` directory.

To automatically register the modules in `styles/`, `variations/` and `filters/`, add the following loader to `resources/js/editor.js`:

```js
import { addFilter } from '@wordpress/hooks';
import { registerBlockVariation, registerBlockStyle } from '@wordpress/blocks';

// Auto-register variations
const variationModules = import.meta.glob('./variations/*.js', { eager: true });
Object.values(variationModules).forEach((module) => {
  const variation = module.default;
  registerBlockVariation(variation.block, variation);
});

// Auto-register styles
const styleModules = import.meta.glob('./styles/*.js', { eager: true });
Object.values(styleModules).forEach((module) => {
  const style = module.default;
  registerBlockStyle(style.block, style);
});

// Auto-register filters
const filterModules = import.meta.glob('./filters/*.js', { eager: true });
Object.values(filterModules).forEach((module) => {
  if (module.hook && module.name && typeof module.callback === 'function') {
    addFilter(module.hook, module.name, module.callback);
  }
});
```

### Why this is necessary

Sage intentionally **doesn't register editor extensions automatically**, such as:

* block styles
* block variations
* editor filters

These are optional Gutenberg customisations, and different projects may structure them differently.

So Sage only provides the `editor.js` entry point and leaves the registration logic to the developer.

The code above creates a **simple auto-registration system** that uses Vite's `import.meta.glob()` to load all modules from specific directories.

### Folder structure

```
resources/js/
  editor.js
  styles/
    hide-mobile.style.js
  variations/
    arrow.down.variation.js
    arrow.left.variation.js
    arrow.up.variation.js
    arrow.right.variation.js
    button.inverse.variation.js
  filters/
    group.fullheight.variation.js
```

Each module should export a default configuration object.

Example style module:

```js
export default {
  block: 'core/button',
  name: 'outline',
  label: 'Outline',
};
```

This pattern lets you:

* keep styles, variations and filters **organised in separate folders**
* **register new modules automatically** without editing `editor.js`
* scale Gutenberg customisations cleanly across large themes

### Registering block variations

Each variation file (e.g. `arrow.down.variation.js`) exports a default object with this shape:

```js
export default {
  block: 'core/button',
  name: 'button-arrow-down',
  title: 'Arrow Down',
  icon: 'arrow-down-alt',
  description: 'Arrow with link.',
  attributes: {
    className: 'button-arrow-down',
  },
  scope: ['block', 'inserter', 'transform'],
  isActive: (attrs) => attrs.className === 'button-arrow-down',
};
```

They're registered automatically through `import.meta.glob()` in `editor.js`.

### Registering block styles

Each style file (e.g. `grid.style.js`) exports a default object:

```js
export default {
  block: 'core/group',
  name: 'featured',
  label: 'Featured',
  isDefault: false,
};
```

These are also registered automatically from the `/styles/` directory.

### Registering filters

Filters live in `/filters/` and export three named exports:

```js
export const hook = 'blocks.registerBlockType';
export const name = 'sage/button';
export function callback(settings, blockName) {
  if (blockName !== 'core/button') return settings;
  return {
    ...settings,
    styles: [{ label: 'Outline', name: 'outline' }],
  };
}
```

### Notes

- Variations and styles must use `export default`.
- Filters must export `hook`, `name` and `callback`.
- This approach keeps boilerplate to a minimum and discovers all editor extensions automatically.

---

## SAGE Tools

### Installing ACF Composer

ACF Composer is a tool for creating fields, blocks, widgets and option pages with ACF Builder in Sage.

See the [ACF Composer installation](https://github.com/Log1x/acf-composer?tab=readme-ov-file#installation).

#### Install through Composer

The `composer` service already runs from the theme folder:

```bash
docker compose --profile tools run --rm composer require log1x/acf-composer
```

Start by publishing the `config/acf.php` configuration file with Acorn:

```bash
docker compose run --rm wpcli acorn vendor:publish --tag="acf-composer"
```

If you get this warning:

```bash
INFO No publishable resources for tag [acf-composer].
```

run this command first:

```bash
docker compose run --rm wpcli acorn package:discover
INFO  Discovering packages.
nesbot/carbon ......................................................... DONE
nunomaduro/termwind ................................................... DONE
roots/sage ............................................................ DONE
```

And try again:

```bash
docker compose run --rm wpcli acorn vendor:publish --tag="acf-composer"
INFO  Publishing [acf-composer] assets.
Copying file [vendor/log1x/acf-composer/config/acf.php] to [config/acf.php] ............. DONE
```

##### Generating a field group

To create your first field group, run this generator command:

```bash
docker compose run --rm wpcli acorn acf:field Example
```

This creates `app/Fields/Example.php`, where you create and manage your first field group.

##### Generating a field partial

A field partial is a field group that can be reused and added to other field groups.

```bash
docker compose run --rm wpcli acorn acf:partial ContainerButtons
```

This creates `app/Fields/Partials/ContainerButtons.php`.

You can then use it in the `Example` field by passing its `::class` constant to `->addPartial()`:

```php
->addPartial(ContainerButtons::class);
```

##### Generating an option page

Option pages are a great way to create global settings for your theme. To create one, run:

```bash
docker compose run --rm wpcli acorn acf:option Example
```

This creates `app/Options/Example.php`, where you create and manage your first option page.

##### Generating a block

Generating a block works much like generating a field.

Start by creating the block with Acorn:

```bash
docker compose run --rm wpcli acorn acf:block Example

🎉 Example block successfully composed.
  ⮑  app/Blocks/Example.php
  ⮑  resources/views/blocks/example.blade.php
```

You can also add `--construct` to the command to generate a stub with the block properties set in an `attributes` method. This can be useful for translations, for example.

```bash
docker compose run --rm wpcli acorn acf:block Example --construct
```

Unlike a normal field, the block generator also creates a view in the `resources/views/blocks` directory.

Like the field generator, the example block contains a simple list repeater and works out of the box.

*Block preview view*

You can use `$block->preview` to change your block when it's shown in the editor, or render the editor preview with a separate view.

To do that, duplicate your existing view and add a `preview-` prefix to its name (e.g. `preview-example.blade.php`).

### Sage Directives

[Sage Directives](https://log1x.github.io/sage-directives-docs/) adds a variety of useful Blade directives for Sage, including directives for WordPress, ACF and various other helpers.

#### Install Sage Directives

```bash
docker compose --profile tools run --rm composer require log1x/sage-directives
```

#### Sage Directives examples

[WordPress](https://log1x.github.io/sage-directives-docs/usage/wordpress.html)

**`WP_Query`**

`@query` creates a standard `WP_Query` as `$query` and accepts the usual `WP_Query` parameters as an array.

```blade
@query([
  'post_type' => 'post'
])

@posts
  <h2  class="entry-title">@title</h2>
  <div  class="entry-content">
    @content
  </div>
@endposts
```

[ACF](https://log1x.github.io/sage-directives-docs/usage/acf.html)

**`@field`**

`@field` prints the given field using `get_field()`.

```blade
@field('text')
```

**`@option`**

`@option` prints the given theme options field using `get_field($field, 'option')`.

```blade
@option('text')
```

### SAGE commands

Clear the cache:

```bash
docker compose run --rm wpcli acorn optimize:clear
docker compose run --rm wpcli acorn view:clear
```

---

### Adding JS libraries

Install JS libraries through the `node` service. It runs from the theme folder.

#### Alpine.js

*Planned for a future release.*

Alpine.js adds small, reactive behaviour directly in your Blade markup. It doesn't need a Vite plugin or any change to `vite.config.js`.

1. Install Alpine.js with npm:

```bash
docker compose run --rm node sh -lc "npm install alpinejs"
```

2. Import and start it in `resources/js/app.js`:

```js
import Alpine from 'alpinejs';

window.Alpine = Alpine;
Alpine.start();
```

3. Use it in your Blade views:

```blade
<div x-data="{ open: false }">
  <button @click="open = !open">Menu</button>
  <nav x-show="open">…</nav>
</div>
```

#### Barba

Barba.js is a popular library for smooth page transitions on server-rendered sites. It intercepts link clicks and loads the new content without a full page refresh.

To add Barba.js to your Sage theme:

1. Install Barba.js with npm (this example also uses [GSAP](#gsap)):

```bash
docker compose run --rm node sh -lc "npm install @barba/core gsap"
```

2. Import and set up Barba in your `resources/js/app.js` file:

```js
import barba from '@barba/core';
import gsap from 'gsap';

barba.init({
  transitions: [
    {
      name: 'fade',
      leave(data) {
        return gsap.to(data.current.container, {
          opacity: 0,
        });
      },
      enter(data) {
        return gsap.from(data.next.container, {
          opacity: 0,
        });
      },
    },
  ],
});
```

#### Embla Carousel

*Embla* is a lightweight library for creating sliders and carousels in your theme.

1. Install Embla with npm:

```bash
docker compose run --rm node sh -lc "npm install embla-carousel"
```

2. Import and set up Embla in your module file:

```js
import EmblaCarousel from 'embla-carousel'

document.querySelectorAll('.embla-carousel').forEach((carousel) => {
  const viewport = carousel.querySelector('.carousel-viewport')

  EmblaCarousel(viewport, {
    loop: true
  })
})
```

For autoplay, you also need the autoplay package:

```bash
docker compose run --rm node sh -lc "npm install embla-carousel-autoplay"
```

#### GSAP

*GSAP* is a powerful JavaScript library for high-performance animations.

1. Install GSAP with npm:

```bash
docker compose run --rm node sh -lc "npm install gsap"
```

2. Import and set up GSAP in your module file:

```js
// typical import
import gsap from "gsap";

// get other plugins:
import ScrollTrigger from "gsap/ScrollTrigger";
import Flip from "gsap/Flip";
import Draggable from "gsap/Draggable";

// or all tools are exported from the "all" file (excluding members-only plugins):
import { gsap, ScrollTrigger, Draggable, MotionPathPlugin } from "gsap/all";

// don't forget to register plugins
gsap.registerPlugin(ScrollTrigger, Draggable, Flip, MotionPathPlugin);
```
