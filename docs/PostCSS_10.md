
# PostCSS

### 1. Install Required PostCSS Plugins

```bash
docker compose run --rm node sh -lc "npm install -D postcss postcss-import postcss-nested autoprefixer @tailwindcss/postcss"

```

#### 2. Add the PCSS files:

```bash
resources/css/pcss/...
```

### 3. Create `themes/codigo/postcss.config.js`

Create `postcss.config.js` with ESM syntax (ESM stands for ECMAScript Modules, which is a standardized module system in JavaScript. It allows developers to organize code into reusable modules, making it easier to manage dependencies and maintain code.)


```js
import postcssImport from 'postcss-import';
import tailwindcss from '@tailwindcss/postcss';
import autoprefixer from 'autoprefixer';
import nested from 'postcss-nested';

export default {
  plugins: [
    postcssImport(),
    tailwindcss(),
    autoprefixer(),
    nested(),
  ],
};
```

### 4. Update `vite.config.js`

In theory there is nothing to update in the vite config.

Just check that Laravel Vite plugin input array is as follows, (removing any SCSS files if needed)

```js
laravel({
  input: [
    'resources/css/app.css',
    'resources/css/editor.css',
    'resources/js/app.js',
    'resources/js/editor.js',
  ],
  refresh: true,
}),
```

Also remove:
- Any `resources/scss/*.scss` inputs if any
- Any `@scss` aliases from the `resolve.alias` section


### 5. Fix Imports and Syntax in `.pcss` Files

PostCSS does **not support SCSS `@use`** or `//` comments.

#### In the .pcss files, replace any SCSS imports with PostCSS imports:
```diff
    // SCSS-style --> PostCSS-style
-   @use "blocks/header";
+   @import "./blocks/header.pcss";
```

Also, replace all `// comments` with `/* comments */`.

### 6. Import .pcss files in the styles

Ensure each `.pcss` file is included in the `resources/css/app.css` file:

```css
...
/* PCSS files */
/* Assets */
@import "./pcss/assets/globals.pcss";

/* Layout */
@import "./pcss/layout/header.pcss";
...
```


### 7. Run Vite Dev Server

```bash
npm run dev
```

Check for build output in `public/build/` and confirm your styles load properly in the browser.


#### Common Issues

| Error | Solution |
|-------|----------|
| `Invalid declaration: '//'` | Use `/* comment */` instead |
| `Cannot apply unknown utility class: text-4lg` | Use valid Tailwind classes like `text-4xl` |
| `module is not defined` | Use `export default {}` in `postcss.config.js` |
| `tailwindcss must be imported from @tailwindcss/postcss` | Install and use `@tailwindcss/postcss` |


### 8. Cleanup

- Remove unused `.scss` files and aliases (`@scss`) from Vite config (if any)


**You're now using PostCSS with Tailwind in your WordPress + Vite setup** 
