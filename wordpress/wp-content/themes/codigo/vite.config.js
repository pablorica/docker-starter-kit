// wordpress/wp-content/themes/<theme>/vite.config.js
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