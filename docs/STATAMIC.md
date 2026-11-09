# Pinaco

A Statamic website for **[Pinaco](https://pinaco.art/)**
 
based in [Statamic Starter Kit](https://github.com/pablorica/statamic_starter_kit) 


[![version](https://img.shields.io/badge/version-1.1.0-green.svg)](https://semver.org)


## Production version

[https://pinaco.art/](https://pinaco.art/) 


## Staging version

[https://pinaco.codigo.co.uk/](https://pinaco.codigo.co.uk/) 

- login:    pinaco
- password: tmstudioqa

### Public and content folders

- [https://pinaco.art/content.last.tar.gz](https://pinaco.art/content.last.tar.gz)

- [https://pinaco.art/public.last.tar.gz](https://pinaco.art/public.last.tar.gz)


## Installation instructions

1. run `composer install`
2. run `npm install`
3. Create supersuser
	- run `php please make:user` and follow the instructions
4.  `npm run watch` or `npm run dev` to start the development server

## Compilation errors

### Vite Errors

#### Cannot read properties

If there is a Vite Error when running
```bash
➜  npm run build

> build
> vite build

failed to load config from /data/webs/artform.localhost/vite.config.js
error during build:
TypeError: Cannot read properties of undefined (reading 'startsWith')
```

**Solution**

It can be due a wrong value in .env
`APP_URL="http://wrongsite.co.uk"`

Or a wrog hot file in public, in that case delete it
```bash
rm public/hot
```

#### getaddrinfo ENOTFOUND

```bash
error when starting dev server:
Error: getaddrinfo ENOTFOUND <local-url.localhost>
at GetAddrInfoReqWrap.onlookup [as oncomplete] (dns.js:69:26)
npm ERR! code ELIFECYCLE
npm ERR! errno 1
```

**Solution**

Vite does not recognize "localhost" (or the local server name you are using)

You need to first bind that host to 127.0.0.1 or the public IP of your own machine in `/etc/hosts`.


### Valet Error

```bash
➜ npm run watch

> watch
> vite

error when starting dev server:
Error: Unable to find Valet certificate files for your host [artform.localhost]. Ensure you have run "valet secure".
```

**Solution**

This is becasue the local server has a SSL certificate not recognizable by Laravel. Probably the server is managed by MAMP and Laravel was expecting Valet.

In that case simply remove the SSL from youyr local server and use HTTP instead of HTTPS.

## Site errors

### 403 Forbidden

The home page is not loading and the error is 403 Forbidden. 
Check that the swerver configuration is pointing to the correct folder: `public` 

## Additional commands

### Clear cache and static files

```bash
php please stache:clear
php please static:clear
php please cache:clear
php artisan cache:clear
```
Reference to [Statamic Cache](https://statamic.dev/static-caching#by-force)

## Environment file contents (*.env* file)

---

## Tailwind Configuration

[TAILWIND.md](https://github.com/TsevdosMcNeil/pinaco/blob/main/docs/TAILWIND.md)

---

## Add JS Libraries

[JSLIBRARIES.md](https://github.com/TsevdosMcNeil/pinaco/blob/main/docs/JSLIBRARIES.md)

---

## Livewire

[LIVEWIRE.md](https://github.com/TsevdosMcNeil/pinaco/blob/main/docs/LIVEWIRE.md)

---


## Create Collections

To add a **"Projects"** link to your **navigation menu** in Statamic, follow these steps:

### 1. Create a new collection "Projects"

 - Create the **content** file `content/collections/projects.yaml` or use the CMS to create a new Collection

 - Create the blueprint file `resources/blueprints/collections/projects/projects.yaml` or use the CMS to create a new Blueprint

 - Create taxonomies if needed

### 2. Create an Index Page for "Projects"

Since a **Collection** doesn't automatically generate an index page, you need to create one:

1. **Go to** `resources/views/` and create a new template:
   ```
   resources/views/projects/index.antlers.html
   ```
2. **Add basic code** to display your projects:
   ```antlers
   {{ collection:projects }}
       <h2><a href="{{ url }}">{{ title }}</a></h2>
   {{ /collection }}
   ```

3. **Optional: Ensure a route exists** in `routes/web.php`:
   ```php
   Route::statamic('projects', 'projects.index', ['title' => 'Projects']);
   ```
   - This makes `/projects` load the `projects/index.antlers.html` template.



### 3. Add "Projects" to Navigation

#### **Option 1: Using Statamic’s Navigation UI**
1. **Go to** Statamic Control Panel → **Navigation**.
2. Click on the **Primary Navigation (or your nav set)**.
3. Click **"Add Item"** → Select **"Entry"**.
4. Choose **"Manual URL"** and enter `/projects` as the URL.
5. Set the **label** to `"Projects"`, then **Save**.

#### **Option 2: Add It Manually in Your Template**
If you're manually rendering the navigation, modify your nav template (`resources/views/partials/navigation.antlers.html`):

```antlers
<ul>
    {{ nav from="main_navigation" }}
        <li><a href="{{ url }}">{{ title }}</a></li>
    {{ /nav }}
    <li><a href="/projects">Projects</a></li>  {# Manually add the Projects link #}
</ul>
```

---


### Hierarchical Taxonomies in Statamic (Workaround Guide)

#### The Problem

Statamic does **not natively support hierarchical taxonomies**.

Even though you can define a `structure:` in a taxonomy's YAML file (e.g., `locations.yaml`), **this has no effect**. The Control Panel will not display a drag-and-drop UI for taxonomy terms like it does for structured collections (such as "Pages").

This is a known limitation — even with Statamic Pro.

#### The Workaround

To simulate hierarchy in a taxonomy (e.g., `Locations`), you can create a **manual parent-child relationship** using a `Taxonomy Terms` field.

##### 1. Update the Taxonomy Blueprint

1. Go to the `Locations` taxonomy blueprint (in the CP or `resources/blueprints/taxonomies/locations.yaml`).
2. Add a new field:

   - **Field Name:** `parent_location`
   - **Field Type:** `Taxonomy Terms`
   - **Taxonomy to Reference:** `locations` (yes, self-referencing)

This allows each term to optionally point to another term as its "parent".


##### 2. Organize Terms Manually

When editing a term (e.g., “London”), you can now select another term (e.g., “United Kingdom”) as its parent.

This manually builds a hierarchy.


##### 3. Displaying the Hierarchy in Templates

You can use Antlers logic to loop through parent terms and their children.

**Example (2 levels deep):**

```antlers
{{ taxonomy:locations }}
    {{ if no_parent_location }}
        <h2>{{ title }}</h2>

        {{ taxonomy:locations where="parent_location:id == {id}" }}
            <h3>– {{ title }}</h3>
        {{ /taxonomy:locations }}

    {{ /if }}
{{ /taxonomy:locations }}
```

You can extend this logic to support deeper nesting as needed.

---


## Custom Modifier: Color Name

 ```bash
/app/Modifiers/ColorName.php
 ```
```php
{{ title_css = collapse_title_colour ? ('group-hover:text-'+ collapse_title_colour | color_name) : 'group-hover:text-neutral' }}
```

---


## Add a Favicon

### Put your favicon in assets

In your project, add your favicon image (e.g., favicon.png) into an assets folder that Statamic knows about.

 ```bash
/public/favicons/favicon.png
 ```

Or if you use a different assets container, use that path instead.


### Use the modifier in your template

In your <head> section of your Antlers layout (e.g., `statamic/resources/views/layout.antlers.html`):

```antlers
{{ '/favicons/favicon.png' | favicon }}
 ```

This will output something like:

```html
<link rel="shortcut icon" type="image/x-icon" href="/assets/img/favicon.png">
 ```

Add additional favicons to cover different devices and Google widgets. 
Create a new favicons folder inside public and add all the required favicon images there.

```html
 <!-- Favicons -->
  {{ '/favicons/favicon.ico' | favicon }}
  <link rel="icon" type="image/png" sizes="16x16" href="/favicons/favicon-16x16.png">
  <link rel="icon" type="image/png" sizes="32x32" href="/favicons/favicon-32x32.png">
  <link rel="icon" type="image/png" sizes="48x48" href="/favicons/favicon-48x48.png">
  <link rel="icon" type="image/png" sizes="192x192" href="/favicons/favicon-192x192.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
  <link rel="manifest" href="/favicons/site.webmanifest">
 ```

---


## Add Addons

### Example: Install Statamic Tabs

```sh
composer require eminos/statamic-tabs
```

### Current Addons

- [Tabs](https://statamic.com/addons/kiwikiwi/tabs)
- [Bard Text Color](https://statamic.com/addons/xndbogdan/Statamic-3-Bard-Text-Color)

---

## Instagram

[INSTAGRAM.md](https://github.com/TsevdosMcNeil/pinaco/blob/main/docs/INSTAGRAM.md)

---


### Local Configuration

Copy the `statamic/env.example` file to `.env`

The following is a local example that uses file caching:

```env
APP_NAME="Pinaco"
APP_ENV=local
APP_KEY="base64:XORaj66Nw/Ikq7MdCVXKWKn10JRxRfyn8ZvFitH9B+s="
APP_DEBUG=true
APP_URL="http://pinaco.localhost"

DEBUGBAR_ENABLED=false

LOG_CHANNEL=stack

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_DATABASE=
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=0.0.0.0
MAIL_PORT=1025
MAIL_USERNAME=testuser
MAIL_PASSWORD=testpwd
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=null
MAIL_FROM_NAME="${APP_NAME}"

IMAGE_MANIPULATION_DRIVER=imagick

STATAMIC_LICENSE_KEY=
STATAMIC_THEME=business

STATAMIC_API_ENABLED=true
STATAMIC_REVISIONS_ENABLED=false

STATAMIC_GIT_ENABLED=false
STATAMIC_GIT_PUSH=false
STATAMIC_GIT_DISPATCH_DELAY=5

SAVE_CACHED_IMAGES=true
STATAMIC_CACHE_TAGS_ENABLED=false
STATAMIC_STACHE_WATCHER=true
STATAMIC_STATIC_CACHING_STRATEGY=null

#STATAMIC_CUSTOM_CMS_NAME=
#STATAMIC_CUSTOM_LOGO_OUTSIDE_URL=
STATAMIC_CUSTOM_LOGO_OUTSIDE_URL="/visuals/pinaco.svg"
#STATAMIC_CUSTOM_FAVICON_URL=
#STATAMIC_CUSTOM_CSS_URL=
```

### Production

Dump your .env values here with sensitive data removed. The following is a production example that uses full static caching:

```env
APP_NAME="Pinaco"
APP_ENV=production
APP_KEY="base64:XORaj66Nw/Ikq7MdCVXKWKn10JRxRfyn8ZvFitH9B+s="
APP_DEBUG=false
APP_URL="https://pinaco.co.uk"

DEBUGBAR_ENABLED=false

LOG_CHANNEL=stack

BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=redis
SESSION_DRIVER=file
SESSION_LIFETIME=120

REDIS_HOST=127.0.0.1
REDIS_DATABASE=
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.postmarkapp.com
MAIL_PORT=587
MAIL_ENCRYPTION=tls
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_FROM_ADDRESS=
MAIL_FROM_NAME="${APP_NAME}"

IMAGE_MANIPULATION_DRIVER=imagick

STATAMIC_LICENSE_KEY=
STATAMIC_THEME=business

STATAMIC_API_ENABLED=false
STATAMIC_REVISIONS_ENABLED=false

STATAMIC_GIT_ENABLED=true
STATAMIC_GIT_PUSH=true
STATAMIC_GIT_DISPATCH_DELAY=5

STATAMIC_STATIC_CACHING_STRATEGY=full
SAVE_CACHED_IMAGES=false
STATAMIC_STACHE_WATCHER=false
STATAMIC_CACHE_TAGS_ENABLED=true

#STATAMIC_CUSTOM_CMS_NAME=
STATAMIC_CUSTOM_LOGO_OUTSIDE_URL="/visuals/pinaco.svg"
#STATAMIC_CUSTOM_LOGO_NAV_URL=
#STATAMIC_CUSTOM_FAVICON_URL=
#STATAMIC_CUSTOM_CSS_URL=
```

## NGINX config

If you have a NGINX server, use these instructions for the configuration file

Add the following to your NGINX config __inside the server block__ to enable static resource caching:
```
expires $expires;
```

And this __outside the server block__:
```
map $sent_http_content_type $expires {
	default off;
	text/css max;
	~image/ max;
	application/javascript max;
	application/octet-stream max;

}
```

---
## Updating Statamic

[UPDATING.md](https://github.com/pablorica/pinaco/blob/main/docs/UPDATING.md)

---

## Install Statamic in Docker


```bash
docker compose up -d --build
```

### Install Statamic

```bash
docker compose exec app composer create-project statamic/statamic statamic
```

#### Create /statamic/.env

```bash
cd statamic
cp env.example .env
```

#### Check Node and npm are installed and working

```bash
# Check Node is there
docker compose exec node node -v
docker compose exec node npm -v

# Install/update packages (run in the container that has Node)
docker compose exec node npm install
docker compose exec node npm update

# Dev server (Vite)
docker compose exec node npm run dev -- --host

# Production build
docker compose exec node npm run build
```

If you have issues runnig those commands, Run a one-off install in the node image (no need for the service to be running):
```bash
# from the repo root where your compose file is
docker compose run --rm -w /var/www/html node npm install
```


#### Udpate vite.config.js

```javascript
import laravel from 'laravel-vite-plugin'
import { defineConfig, loadEnv } from 'vite'
import { networkInterfaces } from 'os'
import VitePluginBrowserSync from 'vite-plugin-browser-sync'

/** @type {import('vite').UserConfig} */
export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const ip = Object.values(networkInterfaces()).flat().find((i) => i.family == 'IPv4' && !i.internal)?.address
  const isSecuredSite = env.APP_URL.startsWith('https://')
  const url = env.APP_URL
  const urlObj = new URL(url)
  const hostname = urlObj.hostname
  const useBrowserSync = env.VITE_BROWSERSYNC && ip

  console.log('The URL is ', url);
  console.log('The host is ', hostname);
  console.log('isSecuredSite? ', isSecuredSite);

  if (useBrowserSync && isSecuredSite) {
    console.log('\x1b[31m%s\x1b[0m', 'Sorry, we didn\'t manage to get BrowserSync working with secured sites.');
    console.log('\x1b[31m%s\x1b[0m', 'If you can provide a solution, please enlighten us (https://github.com/studio1902/statamic-peak/pulls).');
    process.exit(1)
  }

  return {
    plugins: [
      laravel({
        refresh: true,
        detectTls: isSecuredSite ? hostname : false,
        input: [
          'resources/css/site.css',
          'resources/js/site.js',
        ]
      }),
      (() => {
        return useBrowserSync ? VitePluginBrowserSync({
          bs: {
            proxy: url,
            notify: false,
            open: 'external',
          },
        }) : null;
      })()
    ],
    server: {
      host: '0.0.0.0',
      port: env.NODE_PORT,
      strictPort: true,
      hmr: {
        host: hostname,
      },
      open: false,
    }
  }
});

```



#### Compile files

```bash
docker compose exec app composer update
docker compose exec node npm update

## Delete public/hot and fluch caches
docker compose exec app php please stache:clear
docker compose exec app php please static:clear
docker compose exec app php please cache:clear
docker compose exec app php artisan cache:clear

docker compose exec node npm run dev
```


Open: **https://constructure.localhost:8454** 

To install Statamic if not already done:
```bash
docker compose exec app php artisan statamic:install
```


---

## Image Recovery Script (Statamic)

We suffered an attack, the server was compromised and many of the original images stored in public/images were deleted.

Fortunately, Statamic keeps cached image versions in public/img/containers/images, and many of those folders still contained copies of the original images. We created a small recovery script that scans those directories, identifies the largest file in each image folder (usually the original), and restores it back into public/images.

This allowed us to recover most of the missing images.

The process is documented here:

[RECOVERY.md](docs/RECOVERY.md)


---

## Search and Replace in Statamic

Statamic has no database by default. Everything editable in the control panel (entries, pages, globals, navigation, form config) is stored as YAML/Markdown files under `statamic/content/`. These files *are* the database, so a text search-and-replace there is the standard way to change a value everywhere.

[statamic-replace-email-in-content.md](docs/statamic-replace-email-in-content.md)



---

## Acknowledgements

* [Statamic Starter Kit](https://github.com/pablorica/statamic_starter_kit)
* [Statamic Peak](https://statamic.com/starter-kits/studio1902/peak)
  

---


## Copyright and License

Copyright 2024 Pinaco website released under the [MIT](https://github.com/pablorica/pinaco/blob/main/LICENSE) license.

## Versioning

We use [SemVer](https://semver.org/) for versioning.

### Changelog

[CHANGELOG.md](https://github.com/pablorica/pinaco/blob/main/CHANGELOG.md)
