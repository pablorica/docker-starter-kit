
# SAGE — Building pages with Gutenberg blocks

How pages are built in every Sage project: **Gutenberg first: extend core blocks before creating new ones, and ACF (through ACF Composer) only when Gutenberg can't do it.**

Read this before building any page, template or content type. It complements [SAGE.md](SAGE.md) (installation, Vite, Tailwind, editor extensions, ACF Composer) — this file is about *how content is modelled*.

[![version](https://img.shields.io/badge/version-1.0-blue.svg)](https://semver.org)

---

## The rule

1. **Pages and posts are built from blocks** in the post content. Never a big ACF field group (Flexible Content, repeaters of sections…) that models the whole page.
2. **Core blocks first.** Paragraph, Heading, List, Image, Columns, Table, Buttons, Quote, Details, Video, Embed… styled with **block styles** and **variations** when the design needs a different look.
3. **Extend a core block before creating a new one.** If a core block already does most of the job (an image with hotspots is still an image), add the missing features *to that block*: new attributes and a sidebar panel in the editor, extra markup on the front end. Editors keep everything the core block already has. See [Extending a core block](#extending-a-core-block).
4. **Custom blocks with ACF Composer** only when no core block fits, even extended: containers with their own design, components with no core equivalent.
5. **ACF field groups (not blocks) only for data**, information about a post that is used *outside* its own page: a team member's role in a list, a project's sector for filters, an option page. Never for page layout.

Why:

- Blocks can be **copied and pasted** between pages and posts in the CMS.
- The editor shows a **visual preview** of the real page.
- Editors build new pages without a developer.

> If you're about to create an ACF field group to lay out a page, stop: it should be blocks.

---

## Deciding what to use

| The design needs… | Use |
|---|---|
| Text, headings, lists, quotes, simple images, buttons | Core block |
| A core block that looks different (e.g. a table with no borders, a text link with a "+") | Core block + **block style** (`resources/js/styles/`) |
| A preset of a core block (e.g. Columns already set up for the grid) | Core block + **variation** (`resources/js/variations/`) |
| A behaviour change on a core block | **Filter** (`resources/js/filters/`) |
| A core block plus extra features (image + hotspots, video + chapters, quote + photo) | **Extend the core block**: attributes + sidebar panel (JS filters) and front-end markup (PHP `render_block_{name}`) |
| A row of images or cards, with any number of items and widths | Core **Columns** or **Grid** (+ theme CSS for margins and gutter) |
| An element that can be narrow, wide or full width | **Alignment** support (`wide`, `full`), mapped to the grid in CSS |
| A container with its own design (coloured band, chapter with a sticky bar, horizontal scroller) | **ACF Composer block** with `InnerBlocks` |
| An element with structured fields or JS behaviour and no core equivalent (stats, team list, related posts) | **ACF Composer block** |
| Data about a post used elsewhere (role, sector, key projects, card image) | **ACF field group** (`app/Fields`) or core features (featured image, excerpt) |
| A post type's starting layout | `template` in `register_post_type()` |

When a custom block is needed, prefer one that **contains core blocks** (InnerBlocks) over one that re-creates them with fields: the editor keeps its normal text editing, copy/paste and formatting.

**Give editors freedom, not fixed layouts.** Don't build a block with a "layout" select (pair, three-up, full width…). Use what Gutenberg already has:

- **Alignment** (`'align' => ['wide', 'full']` in the block supports) for how wide a single element is. Map none / Wide / Full width to the design grid in CSS.
- **Columns** (any number, any widths) and **Grid** (Group block, grid layout) for rows of elements. The theme CSS places them on the page margins with the design's gutter; whatever is inside fills its column.

A custom block then only needs to know about *itself* (an image with hotspots, a stat, a quote), not about the row it sits in.

---

## Extending a core block

ACF can't add fields to core blocks, so a core block is extended with three small pieces:

**1. Attributes** (`resources/js/filters/image.aperture.attributes.js`). Attributes without a `source` are saved in the block comment (`<!-- wp:image {"aperture":{…}} -->`), not in the HTML, so the core block's `save()` output doesn't change: no "invalid block" warnings, and existing blocks keep working.

```js
export const hook = 'blocks.registerBlockType';
export const name = 'theme/image-aperture-attributes';
export function callback(settings, blockName) {
  if (blockName !== 'core/image') return settings;
  return {
    ...settings,
    attributes: {
      ...settings.attributes,
      aperture: { type: 'object', default: {} },
      comments: { type: 'array', default: [] },
    },
  };
}
```

**2. Sidebar panel** (`resources/js/filters/image.aperture.edit.js`): wrap the block's edit component and add `InspectorControls`. This is also where editor-only helpers go (e.g. showing the hotspots over the image, placing them with a click).

```js
import { createHigherOrderComponent } from '@wordpress/compose';
import { InspectorControls } from '@wordpress/block-editor';
import { PanelBody, ToggleControl } from '@wordpress/components';

export const hook = 'editor.BlockEdit';
export const name = 'theme/image-aperture-edit';
export const callback = createHigherOrderComponent((BlockEdit) => (props) => {
  if (props.name !== 'core/image') return <BlockEdit {...props} />;
  const { attributes: { aperture }, setAttributes } = props;
  return (
    <>
      <BlockEdit {...props} />
      <InspectorControls>
        <PanelBody title="Aperture" initialOpen={false}>
          <ToggleControl
            label="Add an aperture"
            checked={!!aperture.enabled}
            onChange={(enabled) => setAttributes({ aperture: { ...aperture, enabled } })}
          />
        </PanelBody>
      </InspectorControls>
    </>
  );
}, 'withImageAperture');
```

(JSX in `resources/js` works with Vite; `@wordpress/*` imports are mapped to the editor's globals by `wordpressPlugin()`.)

**3. Front-end markup** (`app/blocks.php`): filter the block's rendered HTML and add what's needed, only when the new attributes are set. Use `WP_HTML_Tag_Processor` for classes and attributes, and a Blade partial for larger pieces of markup.

```php
add_filter('render_block_core/image', function (string $html, array $block) {
    $aperture = $block['attrs']['aperture'] ?? [];
    if (empty($aperture['enabled'])) {
        return $html;
    }

    $extra = view('partials.image-aperture', ['aperture' => $aperture])->render();

    return preg_replace('#(<img\b[^>]*>)#', '<div class="image__media">$1'.$extra.'</div>', $html, 1);
}, 10, 2);
```

Notes:

- Keep the core block's own features working; switch off only what clashes (e.g. the image lightbox when a click interaction is added), and say so in the panel.
- Front-end behaviour stays in `resources/js/components/`, initialised from data attributes the PHP filter prints.

---

## Custom blocks with ACF Composer

Generate the block:

```bash
docker compose run --rm wpcli acorn acf:block Example
```

This creates `app/Blocks/Example.php` and `resources/views/blocks/example.blade.php`.

### Block class

Always use ACF Blocks V3 + Block API v3 (works in the iframe editor):

```php
<?php

namespace App\Blocks;

use Log1x\AcfComposer\Block;
use Log1x\AcfComposer\Builder;

class Example extends Block
{
    public $name = 'Example';
    public $description = 'What it is and when to use it — editors read this.';
    public $category = 'project-slug';      // the theme's own category (see below)
    public $icon = 'align-wide';
    public $keywords = ['example'];
    public $post_types = [];                // limit to post types if it only makes sense there

    // ACF Blocks V3 + WP Block API v3 (iframe-compatible)
    public $blockVersion = 3;
    public $apiVersion = 3;

    public $supports = [
        'align' => false,
        'anchor' => true,
        'jsx' => true,                      // needed for <InnerBlocks />
        'color' => ['background' => true, 'text' => false, 'gradients' => false],
    ];

    // Starting inner blocks (nested with 'innerBlocks')
    public $template = [
        'core/heading' => ['level' => 2, 'placeholder' => 'Title…'],
        'core/paragraph' => ['placeholder' => 'Text…'],
    ];

    public function with(): array
    {
        return [
            'layout' => get_field('layout') ?: 'default',
        ];
    }

    public function fields(): array
    {
        $fields = Builder::make('example');

        $fields->addSelect('layout', [
            'label' => 'Layout',
            'choices' => ['default' => 'Default', 'wide' => 'Wide'],
        ]);

        return $fields->build();
    }
}
```

Notes:

- **Fields in the block sidebar:** keep them few and short. No `wrapper` widths (the sidebar is narrow); repeaters with `'layout' => 'block'`.
- **Use Gutenberg supports instead of ACF fields** where they exist: background colour (`color`), anchor, alignment, spacing. They come with the editor's own UI and the theme palette.
- **Block data needed elsewhere** (e.g. a hero image reused in listings): `public $usePostMeta = true;` saves the fields as post meta, so `get_field('hero_image', $post_id)` works outside the block. Only for blocks used once per post (`'multiple' => false`).
- **Child blocks:** `public $parent = ['acf/container'];` keeps a block inside its container.
- **Shared field sets** (e.g. the same hotspot fields on several blocks) go in `app/Fields/Partials` and are added with `->addPartial(Partial::class)`.

### CSS for blocks and cascade layers

WordPress's own block CSS (`wp-block-library`, global styles) is **not in a cascade layer**, and unlayered CSS always beats layered CSS, whatever the specificity. So CSS that styles or overrides core blocks (block styles like `.is-style-facts`, Columns/Grid spacing, text placement inside containers) must be imported **without** `layer()`:

```css
/* resources/css/app.css (and editor.css) */
@import "./pcss/components/figure.pcss" layer(components);  /* our own markup only: layered is fine */
@import "./pcss/blocks/flow.pcss";                          /* touches core blocks: no layer */
```

Keep `layer(base)` / `layer(components)` for CSS that only styles the theme's own markup (header, menu, components).

### Block view

```blade
{{-- resources/views/blocks/example.blade.php --}}
<section {{ $attributes->class(['example', 'example--'.$layout]) }}>
  <InnerBlocks
    template="{{ $block->template }}"
    allowedBlocks='@json(["core/heading", "core/paragraph", "acf/figure"])'
  />
</section>
```

- `$attributes` carries the classes and inline styles from the block supports (colour, anchor…) on the front end.
- `$block->preview` is `true` in the editor: use it for placeholders ("Choose an image in the block settings") or to leave out things that only work on the front end.
- ACF wraps the inner blocks in an extra `.acf-innerblocks-container` element (on the front end too, with Blocks V3), and in the editor each ACF block also gets a wrapper (`.wp-block-acf-<name>`) that carries the alignment class. CSS that targets direct children must cover these cases:

  ```css
  :is(.example, .example > .acf-innerblocks-container) > p { … }
  .grid > .acf-innerblocks-container { display: contents; } /* keep editor children on the parent's grid */
  ```

### Block category

Put the theme's blocks in their own category, first in the inserter:

```php
add_filter('block_categories_all', fn (array $categories) => array_merge(
    [['slug' => 'project-slug', 'title' => 'Project Name', 'icon' => null]],
    $categories
));
```

### JS behaviour

- Front-end behaviour lives in small vanilla components in `resources/js/components/` (one function per component, taking its root element), so they can become Alpine components later.
- To run the same behaviour in the editor preview, hook into ACF's preview render in `editor.js`:

  ```js
  window.acf?.addAction('render_block_preview/type=example', ($el) => {
    $el[0].querySelectorAll('[data-example]').forEach(initExample);
  });
  ```

---

## Core blocks: styles, variations, filters

Registered automatically from `resources/js/styles/`, `variations/` and `filters/` (loader in `editor.js`, see [SAGE.md](SAGE.md#gutenberg-block-extensions-in-sage-11-with-vite)). One file per style:

```js
// resources/js/styles/table.facts.style.js
export default { block: 'core/table', name: 'facts', label: 'Facts' };
```

The CSS targets the class WordPress adds: `.wp-block-table.is-style-facts { … }`.

Remove core styles that don't fit the design:

```js
import domReady from '@wordpress/dom-ready';
import { unregisterBlockStyle } from '@wordpress/blocks';

domReady(() => {
  unregisterBlockStyle('core/table', 'stripes');
  unregisterBlockStyle('core/button', 'outline');
});
```

---

## The editor must look like the page

- **Design tokens** go in `resources/css/base.css` (`@theme`): colours (`--color-*`, start with `--color-*: initial;`) and font sizes (`--text-*`, start with `--text-*: initial;`). `wordpressThemeJson` turns them into the editor palette and font sizes.
- **Names editors see** go in the theme's `theme.json` (`settings.color.palette`, `settings.typography.fontSizes`). Entries there win over the generated ones. Use **hex values** for the palette (the colour swatches are drawn outside the editor iframe, where CSS variables don't exist); font sizes can use `var(--text-*)`.
- Lock the editor down to the design: `color.custom: false`, `defaultPalette: false`, `typography.customFontSize: false`, `defaultFontSizes: false`.
- **`editor.css` imports the same CSS as the front end** for everything that appears inside the content (tokens, components, blocks), plus a small `pcss/editor.pcss` for editor-only fixes. Header, menu and footer stay out.
- Give every preset font size its line height and tracking in CSS (`.has-lead-font-size { … }`), and repeat the size there too.
- Turn off WordPress spacing that fights the design when needed: `settings.spacing.blockGap: false`, `styles.spacing.blockGap: "0px"`, and no `settings.layout.contentSize` if full-width blocks get squeezed in the editor.

---

## Post types

- `show_in_rest => true` and `editor` in `supports`, so the post type uses the block editor.
- A **`template`** gives every new post the right starting blocks:

  ```php
  'template' => [
      ['acf/project-hero'],
      ['acf/section', ['backgroundColor' => 'blue']],
      ['acf/chapter'],
  ],
  ```

- Featured image, excerpt and title are core features: use them instead of ACF fields for card image, summary and name.
- The single template just prints the blocks:

  ```blade
  @while (have_posts()) @php(the_post())
    <article @php(post_class())>@php(the_content())</article>
  @endwhile
  ```

---

## Seeding example content

For a reference page from the design, write a WP-CLI script that builds the post from blocks, rather than typing it in:

```bash
docker compose run --rm wpcli eval-file wp-content/themes/<theme>/scripts/seed-<page>.php
```

- Build the content with `serialize_blocks()`. Core blocks need exactly the HTML their `save()` produces, otherwise the editor marks them invalid.
- ACF block data goes in `attrs.data` in ACF's stored format: `name => value` plus `_name => field_key`, groups and repeaters flattened (`group_sub`, `repeater` = row count, `repeater_0_sub`). Read the field keys at runtime with `acf_get_block_fields(['name' => 'acf/example'])` instead of hard-coding them.
- Make the script safe to run again (update the same post, reuse images found by a meta key).

---

## Working with Claude

- Read [SAGE.md](SAGE.md) and this file before building anything.
- Propose the list of blocks (core + styles, custom ACF blocks, data fields) **before writing code**, and wait for approval.
- Claude delivers each change as a patch file for a feature branch. The developer tests it locally with `git apply file.patch` (no commit), then commits and pushes when it works. Each new patch builds on the previous one: if the developer edits the same files while testing, tell Claude so the next patch starts from that version.
- Packagist may be blocked in Claude's workspace: Composer packages are added by the developer (`docker compose --profile tools run --rm composer require …`).
- After the developer applies a patch, Claude checks the editor and the front end on the local site (Chrome), including that core blocks open without "invalid block" warnings.
