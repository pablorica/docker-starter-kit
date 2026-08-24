
# VUE


#### 1. **Install Vue and the Vue plugin for Vite**

In your project root, run:

```bash
npm install vue
npm install -D @vitejs/plugin-vue
```


#### 2. **Update your `vite.config.js` to use the Vue plugin**

```js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue' // ← Add this line

export default defineConfig({
  base: '/wp-content/themes/codigo/public/build/',
  plugins: [
    vue(), // ← Add this line
    tailwindcss(),
    ...
  ]
})
```


#### 3. **Create a Vue component and mount it**

Example: `resources/js/app.js` or wherever you're booting your JavaScript:

```js
import { createApp } from 'vue'
import Example from './vuecomponents/Example.vue';


if (document.getElementById("vueExample")) {
  const app = createApp(Example);
  app.mount('#vueExample');
}

```

Make sure you have a root element in your Blade or HTML file like:

```html
<div id="vueExample"></div>
```


#### 4. **Add a Vue component**

Create a file like `resources/js/vuecomponents/Example.vue`:

```vue
<template>
  <div>Hello from Vue!</div>
</template>

<script>
export default {
  name: 'Example'
}
</script>
```

#### 5. Run the dev server

Back in your theme folder:

```bash
npm run dev
```

You should see “Hello from Vue!” rendered in your theme!

