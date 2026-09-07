
# Alpine

Alpine is ideal for **small interactive UI elements in server-rendered themes**

* **Lightweight interactivity:** Alpine lets you add small frontend behaviors (menus, modals, accordions, tabs, etc.) directly in your markup without building a full JavaScript application.
* **Minimal overhead:** It’s only ~10kB gzipped and requires almost no setup, which keeps the theme fast and simple.
* **Blade-friendly:** Alpine works very naturally with **Blade templates** in Sage, because logic can live directly in the HTML using attributes (`x-data`, `x-show`, `@click`, etc.).
* **Perfect for progressive enhancement:** It enhances server-rendered pages (WordPress output) rather than replacing them.




These are the libraries for UI behaviour:

```bash
docker compose run --rm node sh -lc "npm install alpinejs \
  @alpinejs/collapse \
  @alpinejs/focus \
  @alpinejs/intersect \
  @alpinejs/persist"

```

These are the **official Alpine plugins** and work perfectly with Sage.

### Collapse

Used for **menus, accordions, dropdowns**.

```html
<div x-data="{ open: false }">
  <button @click="open = !open">Toggle</button>

  <div x-show="open" x-collapse>
    Content
  </div>
</div>
```


### Focus

Great for **modals and accessibility**.

Example: focus trapping.

```html
<div x-data x-trap="open">
```

Useful for:

* modals
* dialogs
* offcanvas menus

### Intersect

Runs logic when element enters viewport.

Perfect for:

* animations
* lazy loading
* counters
* scroll triggers

```html
<div x-intersect="animate = true"></div>
```


### Persist

Stores Alpine state in **localStorage**.

Example:

```html
<div x-data="{ dark: $persist(false) }">
```

Great for:

* dark mode toggle
* remembering menu state



### How Alpine should be initialized in Sage

In Sage 11:

```
resources/js/app.js
```

Example setup:

```javascript
...
import Alpine from 'alpinejs'

import collapse from '@alpinejs/collapse'
import focus from '@alpinejs/focus'
import intersect from '@alpinejs/intersect'
import persist from '@alpinejs/persist'

Alpine.plugin(collapse)
Alpine.plugin(focus)
Alpine.plugin(intersect)
Alpine.plugin(persist)

window.Alpine = Alpine
Alpine.start()
...
```


### Small Sage tip (important)

If you plan to use external JS library , like **Barba.js page transitions**, make sure Alpine **re-initializes after page swaps**.

Otherwise Alpine components inside new pages won't work.

Example:

```javascript
document.addEventListener('barba:after', () => {
  Alpine.initTree(document.body)
})
```

This avoids many Alpine + Barba issues.



### Real-world Sage stack for interactive themes

Typical stack I deploy:

```
Sage 11
Bud
Tailwind
Alpine
Barba
Lenis (smooth scroll)
GSAP (animations)
```

This combo is **extremely powerful and lightweight**.

### Alpine Morph

Used to **diff and morph DOM elements**.

More advanced usage like:

* partial updates
* DOM transitions

Honestly **rare in WordPress projects**. We can  **skip morph** unless doing dynamic DOM swapping.

