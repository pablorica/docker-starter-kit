
# Custom CSS (PostCSS) with Sage 11 + Tailwind 4

How to add custom CSS to a Sage 11 theme, organised in `.pcss` files.

> **TL;DR:** you don't need a `postcss.config.js` or any extra packages. Tailwind 4 (through the `@tailwindcss/vite` plugin in `vite.config.js`) already handles `@import`, nesting, vendor prefixes and minification. Create your files, import them in `app.css` **inside a layer**, and run Vite.

---

## Why no PostCSS plugins?

Earlier projects (Tailwind 3) used several PostCSS plugins. In Tailwind 4 they're no longer needed:

| Old plugin | In Tailwind 4 |
|---|---|
| `@tailwindcss/postcss` | **Don't add it.** Tailwind already runs through the Vite plugin (`tailwindcss()` in `vite.config.js`), so adding it to PostCSS processes your CSS twice. Use one or the other. With Vite, use the Vite plugin. |
| `postcss-import` | Tailwind resolves `@import` itself. |
| `autoprefixer` | Tailwind adds vendor prefixes itself (it uses Lightning CSS). |
| `postcss-nested` | Tailwind supports standard CSS nesting. See the [BEM exception](#bem-style-nesting--and---). |

If an old project has a `postcss.config.js` with these plugins, delete it, and remove the packages from `package.json`:

```bash
docker compose run --rm node sh -lc "npm uninstall postcss postcss-import postcss-nested autoprefixer @tailwindcss/postcss"
```

---

## 1. Create the files

Put your custom CSS in `resources/css/pcss/`, organised by type:

```
resources/css/
├── app.css
├── base.css            # Design tokens (@theme), see SAGE.md
├── editor.css
└── pcss/
    ├── assets/
    │   └── globals.pcss
    ├── layout/
    │   ├── header.pcss
    │   └── footer.pcss
    └── blocks/
        └── hero.pcss
```

The `.pcss` extension is optional. Vite treats `.pcss` exactly like `.css`. Keep it if your editor highlights it nicely, or use `.css`.

---

## 2. Import the files in `app.css` (inside a layer)

```css
/* resources/css/app.css */
@import "tailwindcss";
@import "./base.css";

/* Custom CSS */
/* Assets */
@import "./pcss/assets/globals.pcss" layer(base);

/* Layout */
@import "./pcss/layout/header.pcss" layer(components);
@import "./pcss/layout/footer.pcss" layer(components);

/* Blocks */
@import "./pcss/blocks/hero.pcss" layer(components);
```

Keep the lines Sage already has at the top of `app.css` (`@import "tailwindcss"` or similar) and add yours below them.

### Why `layer(...)`?

Tailwind 4 puts its styles in CSS cascade layers (`base`, `components`, `utilities`). **CSS outside a layer always wins over CSS inside a layer**, whatever the selector. So without `layer(...)`:

```css
/* header.pcss, imported without a layer */
.site-header { color: red; }
```

```html
<header class="site-header text-blue">  <!-- ❌ stays red: text-blue can't override it -->
```

With `layer(components)`, utility classes still override your component styles, which is what you'd expect.

| Layer | Use it for |
|---|---|
| `layer(base)` | Element defaults: `body`, `a`, `h1`… |
| `layer(components)` | Classes for parts of the site: `.site-header`, `.card`, blocks… |
| *(no layer)* | Only when you really want something to override Tailwind utilities |

Instead of `layer(...)` on the import, you can wrap the contents of a file in `@layer components { … }`.

---

## 3. Write standard CSS

### Comments

Only `/* … */` works. `//` comments are SCSS syntax.

```diff
- // Header styles
+ /* Header styles */
```

### Imports between files

Use `@import` with a relative path. SCSS's `@use` doesn't exist in CSS.

```diff
- @use "blocks/header";
+ @import "./blocks/header.pcss";
```

### Nesting

Standard CSS nesting works without any plugin:

```css
.card {
  padding: 1rem;

  & .title { font-weight: 700; }      /* descendant: .card .title */
  &:hover { background: var(--color-beige); }
  &.is-active { border-color: var(--color-black); }

  @media (width >= theme(--breakpoint-md)) {
    padding: 2rem;
  }
}
```

### BEM-style nesting (`&__` and `&--`)

Sass-style name joining **doesn't work** in standard CSS:

```css
/* ❌ Doesn't create .card__title or .card--large */
.card {
  &__title { … }
  &--large { … }
}
```

Write the full selectors instead:

```css
/* ✅ */
.card { … }
.card__title { … }
.card--large { … }
```

> If you're moving a lot of old `.pcss` files that use `&__` / `&--`, you could try adding `postcss-nested` back (**only** that plugin) in a `postcss.config.js`. It isn't guaranteed to run before Tailwind processes the file, though, so test it with one file first. Writing full selectors is the safer option.

### Using your design tokens and Tailwind

The `@theme` variables from `base.css` are available everywhere as CSS variables:

```css
.site-header {
  background: var(--color-beige);
  font-family: var(--font-sans);
  font-size: var(--text-lg);
}
```

`@apply` works in files imported into `app.css`:

```css
.button {
  @apply inline-flex items-center px-4 py-2 rounded;
}
```

> A CSS file loaded **separately** (not imported into `app.css`) needs `@reference "../app.css";` at the top before it can use `@apply` or `theme()`.

### Breakpoints

```css
.hero {
  @media (width >= theme(--breakpoint-lg)) { … }
}
```

`@media screen(lg)` is Tailwind 3 syntax and no longer works.

---

## 4. Vite config

Nothing to change. Check that the `laravel()` inputs are as follows, and remove any `.scss` inputs or `@scss` aliases if they're left over from an old project:

```js
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
```

The `.pcss` files don't need their own inputs: they're part of `app.css`.

---

## 5. Run Vite

Development (hot reload):

```bash
docker compose --profile dev up node
```

Production build:

```bash
docker compose run --rm node sh -lc "npm run build"
```

Check the output in `public/build/` and confirm that your styles load in the browser.

---

## Moving old `.pcss` / `.scss` files: checklist

- [ ] `//` comments → `/* */`
- [ ] `@use "x"` → `@import "./x.pcss"`
- [ ] `&__element` / `&--modifier` → full selectors (`.block__element`)
- [ ] `@media screen(md)` → `@media (width >= theme(--breakpoint-md))`
- [ ] `theme('colors.chalk')` → `var(--color-chalk)`
- [ ] SCSS variables (`$color`), mixins (`@mixin` / `@include`) and functions (`darken()`…) → CSS variables, `@apply`, or `color-mix()`
- [ ] Each file imported in `app.css` with `layer(base)` or `layer(components)`
- [ ] No `postcss.config.js` with `@tailwindcss/postcss`, `postcss-import` or `autoprefixer`

---

## Common issues

| Error / symptom | Solution |
|---|---|
| `Invalid declaration: '//'` | Use `/* comment */` instead. |
| `Cannot apply unknown utility class: text-4lg` | Use a valid Tailwind class (e.g. `text-4xl`) or one defined in your `@theme`. |
| `Cannot apply unknown utility class` in a file that **isn't** imported into `app.css` | Add `@reference "../app.css";` at the top of that file. |
| Utility classes don't override your custom CSS | The file was imported without a layer. Add `layer(components)`. |
| `.card__title` styles don't apply | You used `&__title` inside `.card`. Write `.card__title` in full. |
| Styles are duplicated or compiled twice | Remove `@tailwindcss/postcss` from `postcss.config.js` (or delete the file). |
| `module is not defined` in `postcss.config.js` | If you need the file at all, use `export default { … }` (ESM). |
| `screen()` errors | Tailwind 3 syntax. Use `@media (width >= theme(--breakpoint-md))`. |
