
# Alpine.js with Sage 11

[Alpine.js](https://alpinejs.dev) is ideal for **small interactive UI elements in server-rendered themes**:

* **Lightweight interactivity:** add small frontend behaviours (menus, modals, accordions, tabs…) directly in your markup, without building a full JavaScript application.
* **Minimal overhead:** around 15 kB gzipped and almost no setup, which keeps the theme fast and simple.
* **Blade-friendly:** the logic lives in HTML attributes (`x-data`, `x-show`, `@click`…), which fits naturally with Blade templates.
* **Progressive enhancement:** it enhances the pages WordPress renders instead of replacing them.

No Vite plugin or change to `vite.config.js` is needed.

---

## 1. Install

Alpine plus the official plugins we use for UI behaviour:

```bash
docker compose run --rm node sh -lc "npm install alpinejs \
  @alpinejs/collapse \
  @alpinejs/focus \
  @alpinejs/intersect \
  @alpinejs/persist"
```

---

## 2. Set it up in `resources/js/app.js`

```js
import Alpine from 'alpinejs';

import collapse from '@alpinejs/collapse';
import focus from '@alpinejs/focus';
import intersect from '@alpinejs/intersect';
import persist from '@alpinejs/persist';

// Plugins must be registered before Alpine.start()
Alpine.plugin(collapse);
Alpine.plugin(focus);
Alpine.plugin(intersect);
Alpine.plugin(persist);

// Reusable components (see section 4)
const components = import.meta.glob('./alpine/*.js', { eager: true });
Object.values(components).forEach(({ name, default: component }) => {
  if (name && component) Alpine.data(name, component);
});

window.Alpine = Alpine; // handy for debugging in the browser console
Alpine.start();
```

Notes:

- Load Alpine **only in `app.js`** (the front end), not in `editor.js`. The block editor doesn't need it.
- Call `Alpine.start()` **once**. Vite loads `app.js` as a module, which runs after the HTML has been parsed, so you don't need to wait for `DOMContentLoaded`.

---

## 3. Hide elements until Alpine is ready (`x-cloak`)

Without this, elements with `x-show="false"` flash on screen for a moment while the page loads. Add this to `resources/css/app.css`:

```css
/* Outside any layer, so it always wins */
[x-cloak] { display: none !important; }
```

And add `x-cloak` to anything that should start hidden:

```html
<div x-show="open" x-cloak>…</div>
```

---

## 4. Reusable components (`resources/js/alpine/`)

For anything bigger than a line or two, move the logic out of the Blade template into its own file. Every file in `resources/js/alpine/` is registered automatically with `Alpine.data()` by the loader in `app.js`. It's the same `import.meta.glob()` idea we use for Gutenberg extensions in `editor.js`.

```
resources/js/
  app.js
  alpine/
    dropdown.js
    modal.js
```

Each file exports a `name` and a default function that returns the component:

```js
// resources/js/alpine/dropdown.js
export const name = 'dropdown';

export default () => ({
  open: false,
  toggle() {
    this.open = !this.open;
  },
  close() {
    this.open = false;
  },
});
```

Use it in Blade:

```blade
<div x-data="dropdown" @click.outside="close()" @keydown.escape.window="close()">
  <button @click="toggle()" :aria-expanded="open">Menu</button>
  <ul x-show="open" x-collapse x-cloak>
    …
  </ul>
</div>
```

To pass data from PHP, give the function arguments, e.g. `x-data="slider({{ json_encode($slides) }})"` with `export default (slides = []) => ({ slides, … })`.

---

## 5. Plugins

### Collapse

Smooth height animation for **menus, accordions and dropdowns**. Use it together with `x-show`:

```html
<div x-data="{ open: false }">
  <button @click="open = !open" :aria-expanded="open">Toggle</button>

  <div x-show="open" x-collapse x-cloak>
    Content
  </div>
</div>
```

### Focus

Traps keyboard focus inside an element. Good for **modals, dialogs and off-canvas menus** (and accessibility):

```html
<div x-data="{ open: false }">
  <button @click="open = true">Open</button>

  <div x-show="open" x-trap.inert.noscroll="open" @keydown.escape.window="open = false" x-cloak>
    <p>Dialog content</p>
    <button @click="open = false">Close</button>
  </div>
</div>
```

- `x-trap="open"` traps focus while `open` is true.
- `.inert` makes the rest of the page unreachable for screen readers while the dialog is open.
- `.noscroll` stops the page from scrolling behind it.

### Intersect

Runs code when an element enters or leaves the viewport. Good for **animations, lazy loading, counters and scroll triggers**:

```html
<div x-data="{ shown: false }" x-intersect.once="shown = true"
     :class="shown ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'"
     class="transition duration-700">
  …
</div>
```

- `.once` runs only the first time.
- Use `x-intersect:leave` for when the element leaves the viewport.
- `.half` / `.full` wait until half or all of the element is visible.

### Persist

Saves Alpine state in **localStorage**, so it survives page loads. Good for a **dark mode toggle or remembering a menu's state**:

```html
<div x-data="{ dark: $persist(false).as('theme-dark') }" :class="{ 'dark': dark }">
  <button @click="dark = !dark">Toggle dark mode</button>
</div>
```

Use `.as('…')` to give each stored value a unique name. Otherwise two components with a property of the same name share the same value.

### Morph (not installed)

`@alpinejs/morph` updates the DOM by comparing old and new HTML. It's rarely needed in WordPress projects, so we skip it unless a project swaps HTML dynamically.

---

## 6. Alpine with Blade

- **`@click` and other `@` shortcuts** work in Blade, because Blade only processes `@` words that are Blade directives. If one ever clashes (e.g. with a directive from Sage Directives), use the long form `x-on:click`, or escape it as `@@click`.
- **Alpine doesn't use `{{ }}`.** It uses `x-text` and `:attribute`, so there's no clash with Blade's `{{ }}`.
- **Pass PHP data as JSON:** `x-data="{ items: {{ json_encode($items) }} }"`. For data with quotes, use `@js($items)` (Laravel's helper, available in Sage through Acorn).
- **Tailwind classes** inside `:class="…"` are detected automatically by Tailwind 4, as long as they're written in full (`'opacity-100'`, not `'opacity-' + value`).

---

## 7. Alpine with Barba.js (page transitions)

Barba loads new pages without a full page reload, so `Alpine.start()` only runs once, on the first page.

Alpine 3 **automatically initialises** components added to the page later. So usually components on the new pages just work, and you don't need anything extra.

If a component doesn't start after a Barba transition, initialise the new container with Barba's hooks:

```js
import barba from '@barba/core';
import Alpine from 'alpinejs';

barba.hooks.beforeLeave(({ current }) => {
  Alpine.destroyTree(current.container); // clean up the old page's components
});

barba.hooks.after(({ next }) => {
  Alpine.initTree(next.container); // only the new page, not the whole body
});
```

> Barba doesn't dispatch a `barba:after` DOM event, so `document.addEventListener('barba:after', …)` never runs. Use `barba.hooks` instead.

---

## Typical stack for interactive themes

```
Sage 11
Vite
Tailwind CSS 4
Alpine.js
Barba.js (page transitions)
Lenis (smooth scroll)
GSAP (animations)
```

A powerful but lightweight combination. Add each library only when a project needs it. See "Adding JS libraries" in [SAGE.md](SAGE.md).
