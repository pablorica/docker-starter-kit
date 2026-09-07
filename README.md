# Docker Started Kit:  Docker distribution of a Wordpress/Statamic Project
A clean starter application you can copy/paste and reuse for Docker projects. its ready for Wordpress and Laravel


[![version](https://img.shields.io/badge/version-0.5.1-blue.svg)](https://semver.org)


## Staging Server

https://default.codigo.co.uk/


## Download Database

https://default.codigo.co.uk/latest.sql.gz


## Download Plugins

https://default.codigo.co.uk/plugins.tar.gz



## Download Assets


https://default.codigo.co.uk/uploads.tar.gz



---

## Layout

### Breakpoints
  
* `--breakpoint-sm: 600px;  /* Matches Gutenberg small */`
* `--breakpoint-md: 782px;  /*  Matches Gutenberg medium */`
* `--breakpoint-lg: 960px;  /*  Matches Gutenberg large */`
* `--breakpoint-xl: 1280px;`
* `--breakpoint-2xl: 1536px;`
* `--breakpoint-3xl: 1792px;`


### Sizes

- Normalised to 1920px viewport
- Formula: font-size: (target_px / 1920) * 100vw;
  - sm: 16px → 0.8333vw
  - base: 24px → 1.25vw
  - 30px → 1.5625vw
  - h1: 72px → 3.75vw
  - h2: 36px → 1.875vw
  - 50px → 2.6042vw
  - 7xl (large): 100px → 5.2083vw
  - 130px → 6.7708vw;
  - 200px → 10.4167vw;
  - 300px -> 15.625vw;
  - 1144px → 59.7917vw;


---

## Installation

### Docker Installation

[DOCKER.md](docs/DOCKER.md)


### Install Sage


The theme is based in Sage 11, which is a powerful WordPress starter theme that uses Laravel Blade templating and Vite for asset management.

[SAGE.md](docs/SAGE.md)


### PostCSS

[PostCSS.md](docs/PostCSS.md)

SASS is deprecated in favour of PostCSS.. We strongly recommend to use PostCSS, but if you prefer to use SASS instead, follow these steps:

[SASS.md](docs/SASS.md)

#### Migrating from SCSS to PostCSS in a WordPress + Vite + Tailwind App

If it was installed SCSS, the recommended approach is to migrate to PostCSS.

The SCSS formatter often throws errors on @apply and other Tailwind CSS directives because they aren’t part of standard SCSS syntax. As a result, many SCSS linters and formatters don’t recognize these directives as valid, even though they work when processed by Tailwind via PostCSS.

To avoid these compatibility issues, it's recommended to migrate from SCSS to PostCSS. PostCSS is Tailwind’s native environment and allows full use of its features—like @apply, @tailwind, and @layer—without conflicting with formatting or compilation tools.

This guide walks you through the process of migrating from SCSS to PostCSS in a WordPress project using Tailwind CSS and Vite.

**The main reasons to migrate are:**

- Native support for Tailwind directives like `@apply` and `@tailwind`
- Simpler tooling (no need for Sass)
- Better compatibility with PostCSS plugins (e.g., nesting, imports)


### Alpine

[ALPINE.md](docs/ALPINE.md)

**Why Alpine instead of Vue**

Alpine is ideal for small interactive UI elements in server-rendered themes, giving you Vue-like reactivity with much less complexity and weight.

* **No SPA needed:** WordPress themes are typically **server-rendered**, so a full SPA framework like Vue is usually unnecessary.
* **Much simpler:** Alpine avoids component compilation, build complexity, and state management overhead.
* **Better fit for small UI behaviors:** For things like dropdowns, collapses, and modals, Alpine is far quicker to implement.
* **Smaller bundle:** Vue adds significantly more JS and complexity for features that most WordPress themes don’t need.

However, if you have a specific use case that requires Vue’s advanced reactivity, component system, or ecosystem, it can be integrated into Sage with Vite as well:


[VUE.md](docs/VUE.md)


---


## Local Setup: Importing Project Files and Database

### Get Plugins

Navigate to your `wp-content` directory and download the plugins archive:

```bash
cd /default.localhost/wp-content
wget --user codigo --password default https://default.codigo.co.uk/plugins.tar.gz
mv plugins/ .plugins/
tar -xzvf plugins.tar.gz
rm -R .plugins/

```


### Get Media Files

Media files are stored here:

```bash
wget --user codigo --password default https://default.codigo.co.uk/uploads.tar.gz
```

### Load Database

1. Navigate to the database folder:

```bash
wget --user codigo --password default https://default.codigo.co.uk/latest.sql.gz
```

2. Import the database using MySQL:

Database: latest.sql.gz


```bash
gunzip latest.sql.gz
mysql -u root -p sparemytime_penny < latest.sql
```

**Important!** Set the siteurl and homeurl to `default.localhost` in the wp-config.php file:

```php
define('WP_HOME', 'http://default.localhost');
define('WP_SITEURL', 'http://default.localhost');
```


### Optional: Find & Replace the site URL with WP-CLI

1. Navigate to the project root:

```bash
cd default.localhost/
```

2. Run a dry-run search and replace:

```bash
wp search-replace 'canvascareers.localhost' 'default.localhost' --dry-run --allow-root --all-tables
```

3. If everything looks good, run it for real:

```bash
wp search-replace 'canvascareers.localhost' 'default.localhost' --allow-root --all-tables
# ---> Success: Made 27 replacements..
```


###  Optional: Create a Database Backup

```bash
cd /default.localhost/wp-content/themes/wp-codigo-ltv/_database

mysqldump -u root -proot default | gzip > wp-codigo-ltv.sql.gz
```


---


## Deploying 


1. **Build theme assets:**

   ```bash
   npm run build
   ```

2. **Install Composer dependencies (without dev packages):**

   ```bash
   composer install --no-dev --optimize-autoloader
   ```

3. **Upload your theme files:**

   Upload all files and folders in your theme directory **except** the `node_modules` folder to your host.


### Optimisation

Similar to deploying a Laravel app, Acorn supports an `optimize` command that caches your configuration and views. This command should be part of your deployment process:

```bash
wp acorn optimize
```

---

## Server Configuration


### Securing Blade Templates

By default, any file in the theme directory is publicly accessible in WordPress. This includes `*.blade.php` files, which — if accessed directly — can expose your view code as plain text. To avoid this, add a web server rule to block public access to `.blade.php` files.

#### Nginx

If you're using **Nginx**, add this to your site configuration **before the final `location` block**:

```nginx
location ~* \.(blade\.php)$ {
    deny all;
}
```

#### Apache

If you're using **Apache**, add this to your virtual host configuration or `.htaccess` file:

```apache
<FilesMatch ".+\.(blade\.php)$">
    # Apache 2.4
    <IfModule mod_authz_core.c>
        Require all denied
    </IfModule>

    # Apache 2.2
    <IfModule !mod_authz_core.c>
        Order deny,allow
        Deny from all
    </IfModule>
</FilesMatch>
```

**NOTE:** You can find more information about deploying a SAGE theme here

[Deployment](https://roots.io/sage/docs/deployment/)


---


## Required Plugins

* [Advanced Custom Fields](https://www.advancedcustomfields.com/pro/)


---

## Required libraries

* [SAGE](https://github.com/roots/sage?tab=readme-ov-file)
* [Acorn](https://roots.io/acorn/).
* [ACF Composer](https://github.com/Log1x/acf-composer)
* [Sage Directives](https://log1x.github.io/sage-directives-docs/)

---

## Optional libraries

* [Nextly](https://github.com/web3templates/nextly-template)
* [Poet](https://github.com/Log1x/poet)


## Copyright and License

Copyright 2025 Codigo Wordpress Theme released under the [MIT](https://github.com/pablorica/sparemytime/blob/main/LICENSE) license.

## Versioning

We use [SemVer](https://semver.org/) for versioning. For the versions available, [list of tags can be found in this page](https://github.com/pablorica/docker-starter-kit/tags).

### Changelog

[CHANGELOG.md](https://github.com/pablorica/docker-starter-kit/blob/main/CHANGELOG.md)

