
# Extending core Gutenberg blocks (Sage 11)

How to add our own features to an existing Gutenberg block instead of creating a new one, using the
**Image block's aperture "+" and comment "+"** (Skelly + Couch, Nov 2026) as the worked example.

Companion to [SAGE.md](SAGE.md) (setup, Vite, editor loaders) and [SAGE-BLOCKS.md](SAGE-BLOCKS.md) (when to use
core blocks, extensions or ACF blocks).

[![version](https://img.shields.io/badge/version-1.2-blue.svg)](https://semver.org)

---

## The idea in one picture

An extension touches four places. Each one does one job:

```
 EDITOR (JS)                                   DATABASE                              FRONT END (PHP → HTML → JS)
 ───────────                                   ────────                              ──────────────────────────
 1. Attributes   ── tell Gutenberg the block   <!-- wp:image {"id":12,               3. render_block_core/image
    filter          has new settings               "aperture":{…},                     reads the attributes and adds
                                                   "comments":[…]} -->                 extra markup around the <img>
 2. Edit filter  ── sidebar panels + preview   <figure class="wp-block-image">            │
    (React)         over the image                <img …/>                              4. JS components + CSS
                                               </figure>                                 bring the markup to life
                                               <!-- /wp:image -->
```

- The new settings live **in the block comment** (the JSON after `wp:image`), not in the HTML.
- The block's own HTML **doesn't change**, so Gutenberg never reports "This block contains unexpected or invalid content", and every existing Image block keeps working.
- Everything visible on the front end is **added by PHP at render time**, only when the settings are used.

> ACF can't add fields to core blocks. Extensions are written with the block editor's own APIs (JS) plus a PHP render filter. That's expected: it's the "Gutenberg first" route.

---

## The Image extension, file by file

All paths are relative to the theme (`wp-content/themes/codigo/`).

| # | File | Runs in | Job |
|---|---|---|---|
| 1 | `resources/js/filters/image.extras.attributes.js` | Editor | Adds the `aperture` and `comments` attributes to `core/image` |
| 2 | `resources/js/filters/image.extras.edit.js` | Editor | Wraps the Image block's edit component to add our UI |
| 2b | `resources/js/editor/image-extras.js` | Editor | The UI itself: "Aperture “+”" and "Comments “+”" sidebar panels, preview drawn over the image, click-to-place |
| — | `resources/js/editor.js` | Editor | Loader: registers every file in `filters/`, `styles/`, `variations/` automatically (SAGE.md) |
| 3 | `app/blocks.php` → `render_block_data`, `render_block_core/image`, `contrast_text()`, `comment_style()` | Server | Reads the attributes and adds the front-end markup; switches the lightbox off for click apertures |
| 3b | `resources/views/partials/image-extras.blade.php` | Server | The extra markup: aperture layers and "+" button, comment markers and notes |
| 4 | `resources/js/components/aperture.js`, `comments.js` (started in `resources/js/app.js`) | Browser | Behaviour: window following the cursor, growing, hover notes, magnifier |
| 4b | `resources/css/pcss/components/figure.pcss`, `aperture.pcss`, `comment.pcss` | Browser | Styles for the extra markup |
| — | `resources/css/pcss/blocks/flow.pcss` | Browser + editor | Where Image blocks sit on the page grid (alignment, Columns, captions) |

Naming: every file of one extension shares a prefix (`image.extras.*`, `image-extras.*`), so they're easy to find together.

### Folders in `resources/js/`: which names are fixed

Neither WordPress nor Gutenberg prescribes a folder structure. Sage 11 only sets `resources/js/` itself (Sage 10 used `resources/scripts/`). Inside it there are two groups:

| Folder | Name fixed? | Loaded by | What goes there |
|---|---|---|---|
| `filters/` | **Yes** | `editor.js`, automatically | One `addFilter` per file (exports `hook`, `name`, `callback`) |
| `styles/` | **Yes** | `editor.js`, automatically | One block style per file (`registerBlockStyle`) |
| `variations/` | **Yes** | `editor.js`, automatically | One block variation per file (`registerBlockVariation`); empty is fine |
| `editor/` | No, our convention | Imported by a filter | Larger editor-only code (panels, previews) that isn't a filter itself |
| `components/` | No, our convention | `app.js` | Front-end behaviour, one piece of the page per file (`initAperture(el)`), matching `pcss/components/` |
| `utils/` | No, our convention | Imported by components | Small shared helpers that don't own any part of the page (`motion.js`) |

- The first three names come from SAGE.md: the loader in `editor.js` looks for them, and they're named after the Gutenberg APIs they call. Keep the names and the file shape.
- The last three were chosen on Skelly + Couch as common, self-explanatory names. Nothing loads them automatically, so they could be renamed (updating the imports), but we keep them as the default for new projects.
- Don't put helper modules in `filters/`, `styles/` or `variations/`: the loader would try to register them and fail. That's what `editor/` is for.

---

## 1. Attributes: what the block can store

`resources/js/filters/image.extras.attributes.js`

```js
export const hook = 'blocks.registerBlockType';
export const name = 'sc/image-extras-attributes';

export function callback(settings, blockName) {
  if (blockName !== 'core/image') return settings;

  return {
    ...settings,
    attributes: {
      ...settings.attributes,
      aperture: { type: 'object', default: {} },  // { enabled, id, url, trigger, plus, x, y, size }
      comments: { type: 'array', default: [] },   // [{ x, y, anchor, style, text, plusInset, plusColor, noteColor }]
    },
  };
}
```

Rules:

- **No `source`** on the new attributes. Without a source, WordPress saves them in the block comment. With a source (`attribute`, `html`…) it would try to read them from the HTML and the block would break.
- **Don't touch `save`.** The block's saved HTML must stay exactly as core makes it.
- Use **one object or array per feature** (`aperture`, `comments`) rather than many loose attributes: easier to read, copy and reset.
- Prefix the filter `name` with the project (`sc/…`), so it's unique.
- The file exports `hook`, `name`, `callback`: the loader in `editor.js` calls `addFilter(hook, name, callback)` for every file in `filters/`.

---

## 2. Editor UI: sidebar panels and preview

### 2a. The filter that wraps the block

`resources/js/filters/image.extras.edit.js`

```js
import { createHigherOrderComponent } from '@wordpress/compose';
import { createElement as h, Fragment } from '@wordpress/element';
import { ImageExtras } from '../editor/image-extras.js';

export const hook = 'editor.BlockEdit';
export const name = 'sc/image-extras-edit';

export const callback = createHigherOrderComponent(
  (BlockEdit) => (props) => {
    if (props.name !== 'core/image') return h(BlockEdit, props);

    return h(Fragment, null, h(BlockEdit, props), h(ImageExtras, props));
  },
  'withImageExtras'
);
```

- `editor.BlockEdit` lets us render **next to** the core block's own editor, with the same `props` (`attributes`, `setAttributes`, `isSelected`, `clientId`).
- Return a **`Fragment`**, never a wrapping `<div>`: the block list expects the block's own element, and an extra wrapper can break selection and drag-and-drop.
- Always return the untouched `BlockEdit` for other blocks.

### 2b. The UI component

`resources/js/editor/image-extras.js` (simplified):

```js
import { createElement as h, Fragment, useState } from '@wordpress/element';
import { InspectorControls, useSettings } from '@wordpress/block-editor';
import { PanelBody, ToggleControl, RangeControl, ColorPalette } from '@wordpress/components';

export function ImageExtras({ attributes, setAttributes, isSelected, clientId }) {
  const aperture = attributes.aperture || {};
  const setAperture = (patch) => setAttributes({ aperture: { ...aperture, ...patch } });

  return h(Fragment, null,
    h(InspectorControls, null,                         // → the block's sidebar
      h(PanelBody, { title: 'Aperture “+”', initialOpen: !!aperture.enabled },
        h(ToggleControl, {
          label: 'Add an aperture',
          checked: !!aperture.enabled,
          onChange: (enabled) => setAperture({ enabled }),
        }),
        aperture.enabled && h(RangeControl, {
          label: 'Window size (% of the image width)', min: 4, max: 40,
          value: aperture.size ?? 10, onChange: (size) => setAperture({ size }),
        }),
      ),
    ),
    // + the preview over the image (see 2c below)
  );
}
```

Things worth knowing:

- **`createElement` instead of JSX.** `wordpressPlugin()` (from `@roots/vite-plugin`) maps `@wordpress/*` imports to the editor's globals, but not React's JSX runtime. `h(Component, props, ...children)` is the same as `<Component {...props}>children</Component>` and needs no extra build setup.
- **Update objects immutably:** `setAttributes({ aperture: { ...aperture, ...patch } })`. Mutating `attributes.aperture` directly doesn't save.
- **Components:** everything in `@wordpress/components` (`PanelBody`, `ToggleControl`, `SelectControl`, `RangeControl`, `TextareaControl`, `Button`, `Notice`, `BaseControl`, `ColorPalette`…) and `@wordpress/block-editor` (`InspectorControls`, `MediaUpload`, `MediaUploadCheck`, `useSettings`…). They look and behave like the rest of WordPress.
- **Theme colours** in a picker: `const [palette] = useSettings('color.palette');` then `h(ColorPalette, { colors: palette, value, onChange, clearable: true })`.
- **Media:** `MediaUploadCheck` + `MediaUpload` with `render: ({ open }) => h(Button, { onClick: open }, 'Choose image')`. Store the `id` (for the front end) and the `url` (for the editor preview).
- **Dependencies:** after `npm run build`, `public/build/assets/editor.deps.json` lists the WordPress scripts the editor bundle needs (`wp-blocks`, `wp-components`…). Sage's `setup.php` enqueues `editor.js` with them. If you import from a new `@wordpress/*` package, it appears there by itself.

### 2c. Interacting directly on the block: "Place on image" (a model)

The sidebar is enough for most settings. Some are easier to set **on the block itself**: a position, an area, a point of interest. The Image extension's "Place on image" button is the model for that. You press the button, the image turns into a target, you click where the comment (or aperture) should go, and the position is saved.

Everything lives in `resources/js/editor/image-extras.js`. It works in **five pieces**, and any future "edit on the block" interaction can reuse the same five.

```
 Sidebar                         Editor canvas (iframe)                          Block attributes
 ───────                         ──────────────────────                          ────────────────
 [Place on image] ──setPlacing(i)──▶  overlay over the <img>
   (turns blue:                       pointer-events: none → auto
   "Click on the image…")             cursor: crosshair, blue outline
                                           │ click
                                           ▼
                                      mouse position → % of the image  ──onPlace(x, y)──▶  comments[i].x / .y
                                      setPlacing(null): overlay lets clicks through again
```

#### ① Find the element and follow its size: `findImage()` + `useImageBox()` (lines 28–60)

The editor canvas is an **iframe**, so `document.querySelector` from our script would look in the wrong page. Look inside the iframe first, falling back to the main document (older editors and some screens have no iframe):

```js
function findImage(clientId) {
  const iframe = document.querySelector('iframe[name="editor-canvas"]');
  const doc = iframe?.contentDocument || document;
  return doc.querySelector(`[data-block="${clientId}"] img`);   // this block only
}
```

`useImageBox()` then keeps the image's **position and size** up to date:

```js
const attach = () => {
  const next = findImage(clientId);
  if (!next) { frame = requestAnimationFrame(attach); return; }   // not rendered yet: try next frame
  const host = img.parentElement;
  if (getComputedStyle(host).position === 'static') host.style.position = 'relative';
  const measure = () => setBox({ host, w: img.offsetWidth, h: img.offsetHeight, top: img.offsetTop, left: img.offsetLeft });
  ro = new (img.ownerDocument.defaultView.ResizeObserver)(measure);   // the iframe's own ResizeObserver
  ro.observe(img);
  measure();
};
```

- It only runs while the block is **selected** and a feature is in use (`active`), so unselected images cost nothing.
- `requestAnimationFrame` retries until the `<img>` exists (after an upload, for example).
- The `ResizeObserver` comes from the iframe's window, so it reacts when the image is resized, realigned or replaced. `deps` (url, width, height, aspectRatio, align) re-attach when the block's own settings change.
- The cleanup (`return () => …`) disconnects everything when the block is deselected or removed.

#### ② Remember what is being placed: one piece of state (line 146)

```js
const [placing, setPlacing] = useState(null);   // 'aperture' | comment index | null
useEffect(() => { if (!isSelected) setPlacing(null); }, [isSelected]);   // deselecting cancels
```

- `useState`, not an attribute: "I'm placing comment 2" is **temporary editor state**. It mustn't be saved in the post.
- One variable covers every target (`'aperture'`, `0`, `1`…), so only one thing can be placed at a time.
- Deselecting the block cancels placing, so the editor never gets stuck in "placing" mode.

#### ③ The button that starts and cancels: `placeButton()` (lines 176–181)

```js
const placeButton = (key, label) => h(Button, {
  variant: placing === key ? 'primary' : 'secondary',   // blue while active
  onClick: () => setPlacing(placing === key ? null : key),   // second click cancels
  disabled: !attributes.url,                             // nothing to click on without an image
}, placing === key ? 'Click on the image…' : label);
```

Used as `placeButton(i, 'Place on image')` for each comment and `placeButton('aperture', 'Place on image')` for the aperture. "Add comment" calls `setPlacing(comments.length)`, so a new comment is placed right away.

The button **tells the editor what to do next** ("Click on the image…"). That and the crosshair cursor are the whole user guide.

#### ④ The overlay that catches the click: `Preview` (lines 129–140)

```js
return createPortal(h('div', {
  style: {
    position: 'absolute', left: box.left, top: box.top, width: w, height: H, zIndex: 20,
    pointerEvents: isPlacing ? 'auto' : 'none',
    cursor: isPlacing ? 'crosshair' : 'default',
    boxShadow: isPlacing ? 'inset 0 0 0 3px #1e4db2' : 'none',
  },
  onClick: isPlacing ? (e) => {
    e.preventDefault(); e.stopPropagation();
    const r = e.currentTarget.getBoundingClientRect();
    onPlace(((e.clientX - r.left) / r.width) * 100, ((e.clientY - r.top) / r.height) * 100);
  } : undefined,
}, children), box.host);
```

- **`createPortal(…, box.host)`** renders our React layer *inside* the block in the iframe (in the `<img>`'s parent), exactly over the image. The core block's code is untouched, and React's clicks and state work as usual.
- **`pointer-events` is the switch.** Normally `none`: the layer only shows the preview (markers, aperture window) and every click goes through to the Image block (select, resize, toolbar). While placing it becomes `auto` and catches the click.
- **`preventDefault()` + `stopPropagation()`** stop that click from also selecting, linking or opening anything in the block.
- **Coordinates become percentages:** `(mouse − left edge) / width × 100`. Pixels would be wrong as soon as the image is shown at another size (another screen, the front end, a different alignment). Percentages work everywhere.
- `isPlacing = placing !== null`, **not** `placing ? …`: the first comment's index is `0`, which JavaScript treats as false. (This was the "Place on image does nothing for the first comment" bug.)

#### ⑤ Save and leave placing mode: `onPlace()` (lines 165–174)

```js
const onPlace = (px, py) => {
  if (placing === 'aperture' && box) {
    const size = aperture.size ?? 10;
    const sizeY = (size * box.w) / box.h;   // the window is square: its height in % of the image height
    setAperture({ x: round(clamp(px - size / 2, 0, 100 - size)), y: round(clamp(py - sizeY / 2, 0, 100 - sizeY)) });
  } else if (typeof placing === 'number') {
    setComment(placing, { x: round(px), y: round(py) });
  }
  setPlacing(null);
};
```

- Each target **interprets the click its own way**: a comment's point is the click; the aperture is centred on the click and `clamp`ed so the window stays inside the image.
- `round()` keeps one decimal (`37.4`), so the block comment stays readable.
- Saving goes through `setAttributes` (via `setComment` / `setAperture`), so it's a normal block change: undo/redo, autosave and copy-paste just work.
- `setPlacing(null)` turns the overlay back to `pointer-events: none`.

#### Keep a non-mouse way to do the same

The **Left / Top sliders** in each panel edit the same `x` / `y`. They're the fine-tuning tool and the way to set positions with the keyboard. Any on-block interaction should have a sidebar equivalent.

#### Reusing the pattern

For a new "edit on the block" feature (a focal point for cropping, a hotspot, an area to highlight, a start and end point…):

1. **Find and measure** the element with a `findX(clientId)` + `useXBox()` pair (iframe first, `ResizeObserver` from the iframe's window, only while selected).
2. **One `useState`** for the current mode (`null` when idle), reset when the block is deselected.
3. **A toggle button** in the sidebar that says what to do next and cancels on a second click.
4. **An overlay through `createPortal`**, `pointer-events: none` by default and `auto` only in that mode, converting the mouse position to **percentages** of the element.
5. **One handler** that turns the click into attributes with `setAttributes` and leaves the mode.
6. **A sidebar control** (sliders, number fields) for the same values.

Ideas to add when a feature needs them: `Escape` to cancel (a `keydown` listener on the iframe document while placing), dragging (`pointerdown` / `pointermove` / `pointerup` on the overlay, with `setPointerCapture`), and a short help line in the panel.

---

## 3. Front end: PHP adds the markup

`app/blocks.php`

```php
add_filter('render_block_core/image', function (string $html, array $block) {
    $attrs = $block['attrs'] ?? [];
    $aperture = $attrs['aperture'] ?? [];
    $hasAperture = ! empty($aperture['enabled']) && ! empty($aperture['id']);
    $comments = /* comments with text */;

    if (! $hasAperture && ! $comments) {
        return $html;                       // untouched: normal images cost nothing
    }

    // Edit the block's own <img> safely
    $tags = new \WP_HTML_Tag_Processor($html);
    $tags->next_tag('img');
    $tags->add_class('figure__img');
    $sizes = $tags->get_attribute('sizes');
    $html = $tags->get_updated_html();

    // Larger markup comes from a Blade partial
    $extras = view('partials.image-extras', [/* … */])->render();

    // Wrap the <img> with the positioning box + the extra layers
    return preg_replace('#<img\b[^>]*>#', '<div class="figure__media" data-aperture="…">$0'.$extras.'</div>', $html, 1);
}, 10, 2);
```

- **`render_block_{block name}`** (`render_block_core/image`, `render_block_core/video`…) runs for every instance of that block, on the front end only, with the rendered HTML and the parsed block (`$block['attrs']` holds our attributes).
- **Return the HTML untouched** when the feature isn't used.
- **`WP_HTML_Tag_Processor`** changes classes and attributes on existing tags without regex: safer, and it keeps everything core added (`srcset`, `sizes`, `loading`…).
- **Blade partials** (`resources/views/partials/…`) for anything more than a few tags. `view('partials.x', $data)->render()` works anywhere in the theme.
- **Data for JS** goes in data attributes (`data-aperture="{…}"`, JSON escaped with `esc_attr(wp_json_encode(...))`).
- **Escape and validate** everything coming from attributes: colours checked against a hex pattern, numbers clamped, text escaped by Blade's `{{ }}`. See `comment_style()`.
- **Changing core behaviour before render**: `render_block_data` runs earlier and can change the attributes core will use. The Image extension uses it to switch off "Expand on click" (the lightbox) when a click aperture is on:

  ```php
  add_filter('render_block_data', function (array $block) {
      if (($block['blockName'] ?? '') === 'core/image' && /* click aperture */) {
          $block['attrs']['lightbox'] = ['enabled' => false];
      }
      return $block;
  });
  ```

---

## 4. Behaviour and styles

- **JS** lives in `resources/js/components/` as small functions taking a root element (`initAperture(el)`), started from `app.js` by data attribute: `document.querySelectorAll('[data-aperture]').forEach(initAperture)`. They can become Alpine components later without changing what they do.
- **CSS** for the extra markup lives in `resources/css/pcss/components/` and can be layered (`layer(components)`), because it only styles our own classes.
- **CSS that styles or overrides core block markup** (`.wp-block-image`, alignments, captions) must be imported **without** a layer: WordPress's own block CSS isn't layered, and unlayered CSS always wins over layered CSS. See `pcss/blocks/flow.pcss`.
- **Per-instance values** (colours, spacing) go in as CSS custom properties on the element (`style="--plus-color: #233f7c; --plus-inset: 20"`) with defaults in the CSS (`color: var(--plus-color, var(--color-white))`).

---

## Recipe: adding a new feature to a core block

Example: a "Ken Burns" slow zoom on Image, with an on/off switch and a speed.

1. **Attributes.** In `resources/js/filters/image.kenburns.attributes.js`:

   ```js
   export const hook = 'blocks.registerBlockType';
   export const name = 'sc/image-kenburns-attributes';
   export function callback(settings, blockName) {
     if (blockName !== 'core/image') return settings;
     return { ...settings, attributes: { ...settings.attributes, kenBurns: { type: 'object', default: {} } } };
   }
   ```

2. **Editor UI.** In `resources/js/filters/image.kenburns.edit.js`, wrap `BlockEdit` (as in 2a) and add a panel:

   ```js
   h(InspectorControls, null,
     h(PanelBody, { title: 'Slow zoom', initialOpen: false },
       h(ToggleControl, { label: 'Zoom slowly while in view', checked: !!kb.enabled,
         onChange: (enabled) => setAttributes({ kenBurns: { ...kb, enabled } }) }),
       kb.enabled && h(RangeControl, { label: 'Duration (s)', min: 5, max: 30,
         value: kb.duration ?? 12, onChange: (duration) => setAttributes({ kenBurns: { ...kb, duration } }) })))
   ```

   Several extensions on the same block can each have their own filter: they stack.

3. **Front end.** In `app/blocks.php` (or `app/blocks/image-kenburns.php` if the file grows):

   ```php
   add_filter('render_block_core/image', function (string $html, array $block) {
       $kb = $block['attrs']['kenBurns'] ?? [];
       if (empty($kb['enabled'])) {
           return $html;
       }
       $tags = new \WP_HTML_Tag_Processor($html);
       $tags->next_tag('figure');
       $tags->add_class('has-ken-burns');
       $tags->set_attribute('style', '--kb-duration: '.max(5, min(30, (int) ($kb['duration'] ?? 12))).'s');
       return $tags->get_updated_html();
   }, 20, 2);   // after the aperture filter (priority 10)
   ```

4. **CSS / JS.** `resources/css/pcss/components/ken-burns.pcss` (+ import in `app.css`), and a component in `resources/js/components/` if it needs JS (e.g. start when in view).

5. **Build and test** (checklist below).

---

## Checklist before handing over

- [ ] `npm run build` passes; `editor.deps.json` lists any new `@wordpress/*` package.
- [ ] In the editor, an **existing** block of that type still opens without "invalid content" warnings.
- [ ] New settings save and reload (save the post, reload the editor, check the panel).
- [ ] Copy and paste the block to another page: the settings come with it.
- [ ] The front end is unchanged for blocks that don't use the feature.
- [ ] Core features of the block still work (alignment, size, caption, link, replace…), and anything switched off is explained in the panel.
- [ ] Numbers at their limits and the **first item of a list** (index `0`) behave.
- [ ] Keyboard and touch: buttons are `<button>`s with labels; hover effects also open on focus or tap.
- [ ] The extension's files share a prefix and are listed in the project docs.

---

## Reference

- Filters for blocks: [`blocks.registerBlockType`](https://developer.wordpress.org/block-editor/reference-guides/filters/block-filters/#blocks-registerblocktype), [`editor.BlockEdit`](https://developer.wordpress.org/block-editor/reference-guides/filters/block-filters/#editor-blockedit)
- Server side: [`render_block_{$name}`](https://developer.wordpress.org/reference/hooks/render_block_this-name/), [`render_block_data`](https://developer.wordpress.org/reference/hooks/render_block_data/), [`WP_HTML_Tag_Processor`](https://developer.wordpress.org/reference/classes/wp_html_tag_processor/)
- Components: [Gutenberg Storybook](https://wordpress.github.io/gutenberg/)
