
# SAGE (11)

Instructions to install [sage](https://github.com/roots/sage?tab=readme-ov-file) 

[![version](https://img.shields.io/badge/version-11-blue.svg)](https://semver.org)

If you need informaton of prior versions of SAGE, check [SAGE_10.md](SAGE_10.md)

## Installation 


The theme is based in Sage 11, which is a powerful WordPress starter theme that uses Laravel Blade templating and Vite for asset management.


```bash
cd wordpress-root/wp-content/themes

$ composer create-project roots/sage codigo

  Creating a "roots/sage" project at "./codigo"
  Installing roots/sage (11.0.4)
    - Downloading roots/sage (11.0.4)
    - Installing roots/sage (11.0.4): Extracting archive
  Created project in ./codigo

## Install JS libraries

docker compose run --rm node sh -lc "cd /workspace/wp-content/themes/codigo && rm -rf node_modules package-lock.json && npm i"
docker compose run --rm node sh -lc "npm run build"

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

  [PLUGIN_TIMINGS] Your build spent significant time in plugin `@tailwindcss/vite:generate:build`. See https://rolldown.rs/options/checks#plugintimings for more details.

  ✓ built in 3.25s
```


 - [Install](https://roots.io/sage/)
 - [Docs](https://roots.io/sage/docs/installation/)


---

## Vite

###  Update `vite.config.js` with the theme base path and input files:

```js
// wordpress/wp-content/themes/codigo/vite.config.js
import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite';
import laravel from 'laravel-vite-plugin'
import { wordpressPlugin, wordpressThemeJson } from '@roots/vite-plugin';

// Set APP_URL if it doesn't exist for Laravel Vite plugin
if (! process.env.APP_URL) {
  process.env.APP_URL = 'http://example.test';
}
if (! process.env.APP_HOST) {
  process.env.APP_HOST = 'example.test';
}

if (! process.env.VITE_BASE) {
  process.env.VITE_BASE = '/app/themes/sage/public/build/';
}

if (! process.env.VITE_SERVERPORT) {
  process.env.VITE_SERVERPORT = 3000;
}
if (! process.env.VITE_CLIENTPORT) {
  process.env.VITE_CLIENTPORT = 8800;
}


export default defineConfig({
  base: process.env.VITE_BASE,
  server: {
    host: '0.0.0.0',
    port: process.env.VITE_SERVERPORT,
    strictPort: true,
    origin: process.env.APP_URL,
    hmr: {
      host: process.env.APP_HOST,
      protocol: 'wss',
      clientPort: process.env.VITE_CLIENTPORT,
      path: '/_vite/ws',
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
      assets: ['resources/images/**', 'resources/fonts/**'],
    }),

    wordpressPlugin(),

    // Generate the theme.json file in the public/build/assets directory
    // based on the Tailwind config and the theme.json file from base theme folder
    wordpressThemeJson({
      disableTailwindColors: false,
      disableTailwindFonts: false,
      disableTailwindFontSizes: false,
      //disableTailwindBorderRadius: false,
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
})
```

---

## Fonts

The app includes an empty `resources/fonts/` directory for you to use for any custom fonts you'd like to include in your theme.

### Step 1: Add Your Font File

The first step is to add your `.woff2` font file to the `resources/fonts/` directory. Since `.woff2` has excellent browser support, you likely won't need any other formats.

For this example, we’ll use **Public Sans**, downloaded via [google-webfonts-helper](https://google-webfonts-helper.herokuapp.com/), a handy tool for grabbing font files and CSS snippets from Google Fonts.

Project structure:

```
resources
├── css
│   ├── app.css
│   ├── fonts.css        # Create this file
│   └── editor.css
├── fonts
│   └── public-sans-v14-latin-regular.woff2
├── images
├── js
└── views
```

### Step 2: Add the CSS

You can place the font CSS wherever you prefer, but we recommend creating a `css/fonts.css` file and importing it into both `app.css` and `editor.css`:

```css
/* In app.css and editor.css */
@import './fonts.css';
```

Then, define your `@font-face` in `fonts.css`:

```css
@font-face {
  font-display: swap;
  font-family: 'Public Sans';
  font-style: normal;
  font-weight: 400;
  src: url('@fonts/public-sans-v14-latin-regular.woff2') format('woff2');
}
```

### Step 3: Add the Font to Tailwind

Finally, update your Tailwind theme by adding the font to your `base.css`:

```css
@theme {
  --font-sans: 'Public Sans', sans-serif;
}
```

Import  `base.css` in `app.css`

```css
@import './base.css';
```

For more details on customizing fonts with Tailwind, see the [Tailwind CSS documentation](https://tailwindcss.com/docs/font-family).

### Font sizes

We are going to use our own font sizes set across Tailwind CSS and Gutenberg editor. Our goal is to:

- Define font sizes once in CSS
- Let Tailwind use `var(--text-*)` tokens
- Automatically generate a `theme.json` fontSizes for Gutenberg blocks

#### 1. Define font sizes in `base.css` and  `tailwind.site.js`

In `tailwind.site.js` declare the base font size as a CSS variable:

```js
export default {
  plugins: [
    plugin(function({ addBase, theme }) {
      addBase({
        ':root': {
          // Fluid typography from 1 rem to 1.2 rem with fallback to 26px.
          fontSize: '24px', //<- Base font size. The rem values are calculated based on this.
          letterSpacing: '0',
          lineHeight: '26px', // calc(1.5 / 1),
          fontWeight: '300',

          // Safari resize fix.
          minHeight: '0vw',
        },
      })
    }),],
};
```

In `resources/css/base.css`, declare your design tokens as CSS variables (you can add media breakpoint queries for responsive font sizes):

```css
@theme {
  ...
  --text-base: clamp(1rem,1.25vw,1rem);
}
@layer base {
  :root {
    @media (min-width: theme("screens.lg")) {
      --text-base: 1.25vw; /* 24px at 1920px */
    }
    ...
  }
}
```

These are the default values

```css
@theme {
  --text-xs: 0.75rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem; 
  --text-5xl: 3rem;
  --text-6xl: 3.75rem;
  --text-7xl: 4.5rem;
  --text-8xl: 6rem;
  --text-9xl: 8rem;
  ...
}
  ```


#### 3. Add font sizes to Gutenberg
In `themes/codigo/theme.json` edit the `settings.typography.fontSizes` section to display your custom colours in the Gutenberg color picker:

This is the default value

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

We are going to use our own colour palette across Tailwind CSS and Gutenberg editor. Our goal is to:

- Define colours once in CSS
- Let Tailwind use `var(--color-*)` tokens
- Automatically generate a `theme.json` colour palette for Gutenberg


### 1. Define Colours in `base.css`

In `resources/css/base.css`, declare your design tokens as CSS variables:

```css
@layer base {
  :root {
    --color-beige:     #ECECE4;
    ...
  }
}
```

### 2. Clear Tailwind’s Colour Palette

In `tailwind.config.js` or `tailwind.site.js`, disable Tailwind’s default colours:

```js
export default {
  theme: {
    colors: {}, // 👈 Important: allow Sage to use CSS variable colors instead
  },
  plugins: [],
};
```

This prevents Tailwind from injecting its default palette, allowing Sage to fully control the colour output.

### 3. Add colours to Gutenberg
In theme.json edit the `settings.color.palette` section to display your custom colours in the Gutenberg color picker:

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
If you’re using ACF, you can also add your colours to the ACF colour picker by editing `resources/js/acf-colors.js`:

```js
  acf.add_filter('color_picker_args', function (args, $field) {
    /* Colours (must match with resources/css/app.css ) */
    args.palettes = [
      '#ECECE4', // Beige
      ...
    ]
    return args;
  });
```

### 5. Rebuild the Theme

Run the build process:

```bash
npm run build
```

Sage will:
- Parse your `base.css`
- Extract `--color-*` variables
- Generate `public/build/asses/theme.json` with a Gutenberg colour palette

### 6. Using the colours in Tailwind and Gutenberg

#### In Tailwind:

Use the variables directly:

```html
<div class="bg-[var(--color-blue)] text-[var(--color-white)]">
  Custom styled section
</div>
```

####  In Gutenberg:

Open a block like Paragraph or Group and select from your custom colours in the editor UI — no PHP or JSON editing required!


---


##  Gutenberg Block Extensions in Sage 11 (with Vite)

This project uses a modular system to register Gutenberg block **variations**, **styles**, and **filters** using Vite's `import.meta.glob()` for auto-discovery. This replaces the old Bud.js system from previous Sage versions.


### Auto-register Gutenberg styles, variations and filters

Sage 11 (Vite) does **not automatically load block styles, variations or filters** from the `resources/js` directory.

To automatically register modules placed in `styles/`, `variations/`, and `filters/`, add the following loader to `resources/js/editor.js`.

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

Sage intentionally **does not include automatic registration for editor extensions** such as:

* block styles
* block variations
* editor filters

These features are optional Gutenberg customizations and different projects may structure them differently.

Therefore, Sage only provides the `editor.js` entry point and leaves the registration logic to the developer.

The code above creates a **simple auto-registration system** using Vite's `import.meta.glob()` feature to load all modules from specific directories.


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


This pattern allows you to:

* keep styles, variations and filters **organized in separate folders**
* **automatically register new modules** without editing `editor.js`
* scale Gutenberg customizations cleanly across large themes


### Registering Block Variations

Each variation file (e.g. `arrow.down.variation.js`) exports a default object with the shape:

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

They are automatically registered via `import.meta.glob()` in `editor.js`.


### Registering Block Styles

Each style file (e.g. `grid.style.js`) exports a default object:

```js
export default {
  block: 'core/group',
  name: 'featured',
  label: 'Featured',
  isDefault: false,
};
```

These are also auto-registered from the `/styles/` directory.


### Registering Filters

Filters live in `/filters/` and export three named exports:

```js
export const hook = 'blocks.registerBlockType';
export const name = 'sage/button';
export function callback(settings, blockName) {
  if (blockName !== 'core/button') return settings;
  return {
    ...settings,
    styles: [{ label: 'Outlinearrrggg', name: 'outline' }],
  };
}
```


### Notes

- All files must use `export default` for variations and styles.
- Filters must export `hook`, `name`, and `callback`.
- This approach ensures minimal boilerplate and automatic discovery of all editor extensions.



---


## SAGE Tools

### Installing ACF Composer

ACF Composer is the ultimate tool for creating fields, blocks, widgets, and option pages using ACF Builder alongside Sage 10.

See the [ACF Composer installation](https://github.com/Log1x/acf-composer?tab=readme-ov-file#installation).


#### Install via Composer:

```bash
cd wordpress/wp-content/themes/codigo
composer require log1x/acf-composer
```

Start by publishing the `config/acf.php` configuration file using Acorn:

```bash
docker compose run wpcli acorn vendor:publish --tag="acf-composer"
```


If you have this warning

```bash
INFO No publishable resources for tag [acf-composer].
```

try running this command first

```bash
docker compose run wpcli acorn package:discover
INFO  Discovering packages.  
nesbot/carbon ......................................................... DONE
nunomaduro/termwind ................................................... DONE
roots/sage ............................................................ DONE
```

And try again:

```bash
docker compose run wpcli acorn vendor:publish --tag="acf-composer"
INFO  Publishing [acf-composer] assets.
Copying file [vendor/log1x/acf-composer/config/acf.php] to [config/acf.php] ............. DONE
```

##### Generating a Field Group

To create your first field group, start by running the following generator command from your theme directory:   

```bash
docker compose run wpcli acorn acf:field Example
```

This will create `app/Fields/Example.php` which is where you will create and manage your first field group.

##### Generating a Field Partial

A field partial consists of a field group that can be re-used and/or added to existing field groups.

```bash
docker compose run wpcli acorn acf:partial ContainerButtons
```
This will create `app/Fields/Partials/ListItems.php`.

This can be utilized in our `Example` field by passing the `::class` constant to `->addPartial()`

```php
->addPartial(ContainerButtons::class);
```

##### Generating a Option Group
Option pages are a great way to create global settings for your theme. To create an option page, run the following command:

```bash
docker compose run wpcli acorn acf:option Example
```
This will create `app/Options/Example.php` which is where you will create and manage your first option page.

##### Generating a Block

Generating a block is generally the same as generating a field as seen above.

Start by creating the block field using Acorn:

```bash
docker compose run wpcli acorn acf:block Example
    
🎉 Example block successfully composed.
  ⮑  app/Blocks/Example.php
  ⮑  resources/views/blocks/example.blade.php
```

You may also pass --construct to the command above to generate a stub with the block properties set within an attributes method. This can be useful for localization, etc.

```bash
docker compose run wpcli acorn acf:block Example --construct
```

When running the block generator, one difference to a generic field is an accompanied View is generated in the resources/views/blocks directory.

Like the field generator, the example block contains a simple list repeater and is working out of the box.

*Block Preview View*

While `$block->preview` is an option for conditionally modifying your block when shown in the editor, you may also render your block using a seperate view.

Simply duplicate your existing view prefixing it with `preview-` (e.g. `preview-example.blade.php`).



### Sage directives

[Sage Directives](https://log1x.github.io/sage-directives-docs/) adds a variety of useful Blade directives for use with Sage 10 including directives for WordPress, ACF, and various miscellaneous helpers.



#### Install Sage directives

```bash
cd /wp_data/wp-content/themes/seadesign
composer require log1x/sage-directives
```

#### Sage directives Examples

[Wordpress](https://log1x.github.io/sage-directives-docs/usage/wordpress.html)

**`WP_Query`**

`@query` initializes a standard `WP_Query` as `$query` and accepts the usual `WP_Query` parameters as an array.

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


`@field` echoes the specified field using `get_field()`.

```blade
@field('text')
```


**`@option`**


`@option` echoes the specified theme options field using ` get_field($field, 'option')`.

```blade
@option('text')
```

### SAGE commands

Clear cache

```bash
docker compose run wpcli acorn optimize:clear
docker compose exec app php artisan view:clear
```


---


### Adding JS Libraries

#### Barba

Barba.js is a popular library for creating smooth page transitions in server-rendered applications. It works by intercepting link clicks and dynamically loading new content without a full page refresh.

To add Barba.js to your Sage theme:

1. Install Barba.js via npm:

```bash
docker compose run --rm node sh -lc "npm install @barba/core"
```
2. Import and initialize Barba in your `resources/js/app.js` file:

```js
import barba from '@barba/core';

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

*Embla* is a lightweight carousel library that can be used to create sliders and carousels in your theme.

```bash
docker compose run --rm node sh -lc "npm install embla-carousel"
```

2. Import and initialize Embla in your module file:

```js
import EmblaCarousel from 'embla-carousel'

document.querySelectorAll('.embla-carousel').forEach((carousel) => {
  const viewport = carousel.querySelector('.carousel-viewport')

  EmblaCarousel(viewport, {
    loop: true
  })
})
```

You’ll also need the autoplay package installed:

```bash
docker compose run --rm node sh -lc "npm install embla-carousel-autoplay"
```

#### GSAP

*GSAP* is a powerful JavaScript library for creating high-performance animations.

```bash
docker compose run --rm node sh -lc "npm install gsap"
```

2. Import and initialize Gsap in your module file:

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

