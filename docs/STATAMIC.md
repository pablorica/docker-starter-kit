# Statamic


## Installation instructions

1. run `composer install`
2. run `npm install`
3. Create a superuser
	- run `php please make:user` and follow the instructions
4. `npm run dev` to start the development server (`npm run watch` is an alias of the same command)
5. `npm run build` to compile the production files into `public/build`

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

It can be due to a wrong value in `.env`
`APP_URL="http://wrongsite.co.uk"`

Or a leftover `hot` file in `public` (created by the dev server). In that case delete it

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

This is because the local server has a SSL certificate not recognizable by Laravel. Probably the server is managed by MAMP and Laravel was expecting Valet.

In that case simply remove the SSL from your local server and use HTTP instead of HTTPS.

## Site errors

### 403 Forbidden

The home page is not loading and the error is 403 Forbidden. 
Check that the server configuration is pointing to the correct folder: `public` 

## Additional commands

### Clear cache and static files

Run these from the `statamic/` folder. `php please` is Statamic's command-line tool and `php artisan` is Laravel's (Statamic is built on Laravel). `please` also accepts any Laravel command, so `php please cache:clear` and `php artisan cache:clear` are the same command: you only need one.

```bash
php please stache:clear
php please static:clear
php artisan cache:clear
php artisan config:clear
php artisan view:clear
php artisan route:clear
php artisan optimize        # production only, run it last
```

#### What each command does

**Statamic caches**

| Command | What it does | When you need it |
|---|---|---|
| `php please stache:clear` | Clears the **stache**, Statamic's index of all content (entries, globals, navigation…). It rebuilds itself on the next request. | After editing files in `content/` directly (e.g. a search and replace), or when content looks out of date. |
| `php please static:clear` | Clears the **static cache**: whole pages saved as ready-made HTML, if static caching is enabled. | After any content or template change, so visitors don't get old saved pages. Harmless if static caching is off. |
| `php please glide:clear` | Deletes the resized/cropped image cache (Glide), in `public/img/containers/…` or `storage/statamic/glide`. | Rarely: only if resized images are wrong. **Caution:** this cache is what made the image recovery below possible. Don't clear it unless the original images are backed up. |

**Laravel caches**

| Command | What it does | When you need it |
|---|---|---|
| `php artisan cache:clear` | Empties the general application cache (anything saved with Laravel's cache, such as fetched data or computed values). | When something cached looks stale. |
| `php artisan config:clear` | Removes the cached copy of the configuration (`config/*.php` combined with `.env`). | After changing `.env` or anything in `config/` (e.g. mail settings). |
| `php artisan view:clear` | Deletes the compiled templates (Antlers/Blade views turned into PHP). | After template changes. |
| `php artisan route:clear` | Removes the cached list of URLs (routes). | After route changes, or if a page returns 404 when it shouldn't. |

**Rebuild and speed up**

| Command | What it does | When you need it |
|---|---|---|
| `composer dump-autoload` | Regenerates Composer's class map (which file each PHP class lives in). | Only after adding, renaming or removing PHP classes (e.g. a new modifier in `app/Modifiers`) or updating packages. Not needed for template, CSS or content changes. |
| `php artisan optimize` | Rebuilds the config and route caches in one go so the site runs a little faster. | Last, on production, after the clears above. |

> **Order matters:** run `optimize` after the clears. While its config cache is in place, later edits to `.env` are ignored until you run `php artisan config:clear` (or `optimize` again).

#### Which ones for which change

| Change | Commands |
|---|---|
| Content edited by hand in `content/` | `stache:clear`, `static:clear` |
| Templates / CSS / JS (new build) | `view:clear`, `static:clear` |
| `.env` or `config/` | `config:clear` (then `optimize` on production) |
| New PHP classes or packages | `composer dump-autoload`, then `optimize` on production |
| "Reset everything" after a deploy | all of the above, `optimize` last |

None of these commands touches the content files themselves.

#### In Docker

Prefix each command with `docker compose exec -u www-data <service>`, run from the folder with the `docker-compose.yml`:

```bash
docker compose exec -u www-data statamic php please stache:clear
docker compose exec -u www-data statamic php please static:clear
docker compose exec -u www-data statamic php artisan cache:clear
docker compose exec -u www-data statamic php artisan config:clear
docker compose exec -u www-data statamic composer dump-autoload
docker compose exec -u www-data statamic php artisan view:clear
docker compose exec -u www-data statamic php artisan route:clear
docker compose exec -u www-data statamic php artisan optimize
```

- `docker compose exec` runs a command inside a container that is already running.
- `-u www-data` runs it as the same user as PHP/the web server, so any cache files it creates stay writable by the site. Running as root can leave root-owned files that the site (and the control panel) can't write to.
- `statamic` is the service name in `docker-compose.yml`. Older projects use `app`; check with `docker compose ps`.

Reference: [Statamic static caching](https://statamic.dev/static-caching#by-force)

## Environment file contents (*.env* file)

---

## Tailwind Configuration

[TAILWIND.md](docs/TAILWIND.md)

---

## Add JS Libraries

[JSLIBRARIES.md](docs/JSLIBRARIES.md)

---

## Livewire

[LIVEWIRE.md](docs/LIVEWIRE.md)

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
3. Click **"Add Nav Item"** (a manual link, rather than "Link to Entry").
4. Enter `/projects` as the URL and `Projects` as the title, then **Save**.

#### **Option 2: Add It Manually in Your Template**
If you're manually rendering the navigation, modify your nav template (`resources/views/partials/navigation.antlers.html`):

```antlers
<ul>
    {{ nav:main_navigation }}
        <li><a href="{{ url }}">{{ title }}</a></li>
    {{ /nav:main_navigation }}
    <li><a href="/projects">Projects</a></li>  {{# Manually add the Projects link #}}
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
    {{ if !parent_location }}
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

[INSTAGRAM.md](docs/INSTAGRAM.md)

---


### Local Configuration

Copy the `statamic/env.example` file to `.env`


### Production

Dump your .env values here with sensitive data removed. 

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

[UPDATING.md](docs/UPDATING.md)

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

If you have issues running those commands, Run a one-off install in the node image (no need for the service to be running):

```bash
# from the repo root where your compose file is
docker compose run --rm -w /var/www/html node npm install
```


#### Update vite.config.js

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

## Delete public/hot and flush caches
rm -f public/hot
docker compose exec -u www-data app php please stache:clear
docker compose exec -u www-data app php please static:clear
docker compose exec -u www-data app php artisan cache:clear

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
  

