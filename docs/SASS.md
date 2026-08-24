# SASS


#### 1. Install SASS:

```bash
npm install -D sass
```

#### 2. Add the SCSS files:

```bash
resources/scss/app.scss  
resources/scss/editor.scss
```

#### 3. Update `vite.config.js`:

```js
 import { defineConfig } from 'vite'
 import tailwindcss from '@tailwindcss/vite';
 import laravel from 'laravel-vite-plugin'
 import { wordpressPlugin, wordpressThemeJson } from '@roots/vite-plugin';

 export default defineConfig({
   base: '/app/themes/sage/public/build/',
   plugins: [
     tailwindcss(),
     laravel({
       input: [
         'resources/css/app.css',
         'resources/scss/app.scss',
         'resources/js/app.js',
         'resources/css/editor.css',
         'resources/scss/editor.scss',
         'resources/js/editor.js',
       ],
     }),
     wordpressThemeJson({
       disableTailwindColors: false,
       disableTailwindFonts: false,
       disableTailwindFontSizes: false,
     }),
   ],
   resolve: {
    alias: {
      '@scripts': '/resources/js',
      '@styles': '/resources/css',
      '@scss': '/resources/scss',
      '@fonts': '/resources/fonts',
      '@images': '/resources/images',
    },
  },
 })
```


#### 4. Update Blade template directive (`resources/views/layouts/app.blade.php`):

```diff
- @vite(['resources/css/app.css', 'resources/js/app.js'])
+ @vite(['resources/css/app.css', 'resources/css/app.scss', 'resources/js/app.js'])
```


#### 5. Update `block_editor_settings_all` filter in `app/setup.php`:

```diff
add_filter('block_editor_settings_all', function ($settings) {
-    $style = Vite::asset('resources/css/editor.css');
+    $editorCss = Vite::asset('resources/css/editor.css');
+    $editorScss = Vite::asset('resources/scss/editor.scss'); 

    $settings['styles'][] = [
-        'css' => "@import url('{$style}')",
+        'css' => "@import url('{$editorCss}')",
    ];

+   $settings['styles'][] = [
+       'css' => "@import url('{$editorScss}')",
+   ];

    return $settings;
});
```


**NOTE:** If you want to replace Tailwind CSS totally with SASS follow these steps:

[SASS Setup (Replacing Tailwind CSS)](https://roots.io/sage/docs/sass/)

