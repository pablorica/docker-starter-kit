# SAGE 10

Instructions to install [sage](https://github.com/roots/sage?tab=readme-ov-file) 

[![version](https://img.shields.io/badge/version-10-blue.svg)](https://semver.org)


## Installation


### Go to [root_folder] and clone the repository

    git clone https://github.com/pablorica/sparemytime
    Cloning into 'sparemytime'...
    remote: Enumerating objects: 182, done.
    remote: Counting objects: 100% (182/182), done.
    remote: Compressing objects: 100% (118/118), done.
    remote: Total 182 (delta 53), reused 165 (delta 40), pack-reused 0
    Receiving objects: 100% (182/182), 578.41 KiB | 16.53 MiB/s, done.
    Resolving deltas: 100% (53/53), done.

### Compile files

    $ cd [root_folder]/wp-content/themes/codigo
    $ composer install --prefer-dist --optimize-autoloader
    $ yarn install
    
    	➤ YN0000: · Yarn 4.2.2
    	➤ YN0000: ┌ Resolution step
    	➤ YN0085: │ + @roots/bud-tailwindcss@npm:6.16.1, @roots/bud@npm:6.16.1, and 976 more.
    	➤ ...
    	➤ YN0000: · Done with warnings in 34s 39ms
    
    $ yarn build
    	
    	╭ sage [1a24dfc8407595fc] ./public
    	│
    	│ app
    	│ ◉ js/runtime.e97f88.js ✔ 1.22 kB
    	│ ◉ css/app.182da0.css ✔ 9.57 kB
    	│ ◉ js/app.c6fc6f.js ✔ 359 bytes
    	│
    	│ editor
    	│ ◉ js/runtime.e97f88.js ✔ 1.22 kB
    	│ ◉ css/editor.a5ebf3.css ✔ 2.94 kB
    	│ ◉ js/editor.7f4d85.js ✔ 1.67 kB
    	│
    	│ assets
    	│ ◉ fonts/Aeonik/Aeonik-Regular.c2876d.eot 98.41 kB
    	│ ◉ fonts/Aeonik/Aeonik-Bold.7fa62f.woff 48.8 kB
    	│ ◉ fonts/Aeonik/Aeonik-Regular.413ab3.woff 47.71 kB
    	│ ◉ fonts/Aeonik/Aeonik-Bold.f42057.woff2 36.44 kB
    	│ ◉ fonts/Aeonik/Aeonik-Regular.7ddd98.woff2 35.4 kB
    	│ … 11 additional assets not shown
    	│
    	╰ 3s 759ms 8 modules [0/8 modules cached]

#### *Error: React is not installed*

If you have this error when running `yarn`, it means that React is not installed as a devDependency.

	node:internal/process/esm_loader:42
	internalBinding('errors').triggerUncaughtException...
	Required package: react (via "react/package.json")
	...

To fix this we need both react and react-dom as devDependencies.

```$ npm install --save-dev react react-dom```

Once installed, try again:

```$ yarn install```

#### *Error: NPM process is killed*

```⠸Killed```

The error and abrupt termination (indicated by Killed) when running the npm install command is often due to insufficient memory on your machine.
Verify if your system has enough memory (RAM) available


    free -h
                total        used        free      shared  buff/cache   available
    Mem:           1.9Gi       1.6Gi       324Mi       135Mi       351Mi       361Mi
    Swap:             0B          0B          0B


Your system has 1.9 GiB of total memory, but only 324 MiB free and 361 MiB available, which is insufficient for some npm install processes that can require more memory to complete. Additionally, you currently have no swap memory configured, so the system has no backup memory to fall back on when RAM is exhausted.
To resolve this issue, configure swap memory as follows:

```sudo fallocate -l 2G /swapfile```

Secure the swap file:

```sudo chmod 600 /swapfile```

Set up the swap area:


    sudo mkswap /swapfile
    Setting up swapspace version 1, size = 2 GiB (2147479552 bytes)
    no label, UUID=8d5bfea1-fb9d-4c04-ada8-79e48789a775


Enable the swap file:

```sudo swapon /swapfile```

Verify swap is active:


    swapon --show
    NAME      TYPE SIZE USED PRIO
    /swapfile file   2G   0B   -2


    free -h
                total        used        free      shared  buff/cache   available
    Mem:           1.9Gi       1.6Gi       223Mi       135Mi       406Mi       302Mi
    Swap:          2.0Gi          0B       2.0Gi


Make Swap Persistent. To ensure the swap file is enabled on reboot add it to /etc/fstab:

    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    /swapfile none swap sw 0 0


After setting up swap memory, retry the command:

```npm install --save-dev react react-dom```

#### NPM Errors
- *Error: Cannot find module '/@roots/bud-framework/scripts/postinstall.mjs* 
- *Error: npm error path /data/webs/sparemytime.codigo.co.uk/wp-content/themes/codigo/node_modules/@roots/bud-framework*


This is related with an Unsupported Node version. Delete 

    ```
    "devDependencies": {
        "@roots/bud": "6.16.1",
        "@roots/bud-sass": "6.16.1",
        "@roots/bud-tailwindcss": "6.16.1",
        "@roots/bud-vue": "6.16.1",
        "@roots/sage": "6.16.1"
    },
    ```

from `package.json` and run

```npm install --save-dev react react-dom```

You will see something like:

    npm WARN EBADENGINE Unsupported engine {
    npm WARN EBADENGINE   package: 'npm@10.8.3',
    npm WARN EBADENGINE   required: { node: '^18.17.0 || >=20.5.0' },
    npm WARN EBADENGINE   current: { node: 'v20.2.0', npm: '9.6.6' }
    npm WARN EBADENGINE }

Install a proper version of node and repeat the process

    nvm install 20.5.0 
    nvm use 20.5.0 


Once fixed, add the `devDependencies` again

    npm install @roots/bud --save-dev
    npm install @roots/bud-sass --save-dev
    npm install @roots/bud-tailwindcss --save-dev
    npm install @roots/bud-vue --save-dev
    npm install @roots/sage --save-dev

And try again

```yarn install```

### Install required plugins

Download the plugins folder from the staging server and copy it to the local installation.

[Plugins](https://sparemytime.codigo.co.uk/plugins.tar.gz)

Activate ACF and then the Codigo theme in the CMS

### Download the uploads folder from the staging server and copy it to the local installation.

[Uploads](https://sparemytime.codigo.co.uk/uploads.tar.gz)

### Update the database

- Download the database from the test server and replace it in the local installation

	[Database](https://sparemytime.codigo.co.uk/latest.sql.gz)

	`mysql -u root -p sparemytime_wp < latest.sql`
	
- Change db prefix using WP-CLI

	[WP-CLI Rename Database Prefix](https://github.com/iandunn/wp-cli-rename-db-prefix) is an add-on to WP_CLI that allows you to change the database prefix.

    `wp package install iandunn/wp-cli-rename-db-prefix --allow-root`
    
    `wp rename-db-prefix 'sparemytime_' --dry-run --allow-root`

	If the results are ok, remove the flag '--dry-run'

    `wp rename-db-prefix 'sparemytime_' --allow-root`

    *Warning: Use this at your own risk. If something goes wrong, it could break your site.
    Before running this, make sure to back up your `wp-config.php` file and run `wp db export`.
    Are you sure you want to rename hmo.localhost's database prefix from `wp_` to `sparemytime_`? [y/n]
    Success: Successfully renamed database prefix.*


- Find and replace using WP-CLI (hmo.localhost is the local domain)

	```
    wp search-replace 'sparemytime.localhost' 'sparemytime.codigo.co.uk' --dry-run --allow-root --all-tables
    ## If the results are ok, remove the flag '--dry-run'
    wp search-replace 'sparemytime.localhost' 'sparemytime.codigo.co.uk' --allow-root --all-tables
    ---> Success: Made 36 replacements.
	```


### VUE 3

The extension is pre-configured to support Vue 3 single file components (runtime only).

You can disable the `runtimeOnly` default by adding the following to your `bud.config.js` file:

    app.vue.setRuntimeOnly(false);

The `esm-bundler` builds of Vue expose global feature flags `__VUE_OPTIONS_API__` and `__VUE_PROD_DEVTOOLS__` , they must to be defined.
You may want to enable the options API and disable the devtools:

    app.define({
        __VUE_OPTIONS_API__: true,
        __VUE_PROD_DEVTOOLS__: false,
    });

[Read more](https://bud.js.org/extensions/bud-vue) about setting up Vue in Sage.


## Gutenberg Blocks

The `@roots/bud-preset-wordpress` package comes with an editor integration. This library adds support for registering *blocks*, *filters*, *formats*, *styles*, *variations* and *plugins*.

All modules registered with this API are registered in production and development. In development additional hot module reloading support is added.

### Adding support to your application

There are two steps:

- Making the root registration call for a given type or types.
- Adding modules to your application

In general, the above steps are the same for working with any of the supported APIs.

#### Making the root registration call

Open `resources/scripts/editor.js` and write the call `roots.register.[type]` , supplying the root directory where registrables are found.

For example, to register blocks in the application, we must add this call:

    roots.register.blocks('@scripts/blocks')

    /** Don't forget to accept any module updates! */
    if (import.meta.webpackHot) {
    import.meta.webpackHot.accept(console.error)
    }


#### Adding modules to the application

`bud.js` will look for modules in the directory indicated in the root registration call. Modules are named like `*.[type].[ext]`.

The module should export the required settings and the name of the entity.

Modules can be created using either *default exports* or *named exports*. As a general rule, we will use default exports whenever possible.

For example, to add a block variation in the Group block and add a Grid css feature, we would create a file `grid.variation.js` in the `resources/scripts/variations` directory:

    export default {
        block: `core/group`,
        name: 'group-grid',
        title: `Grid`,
        icon: 'grid-view',
        description: `Arrange blocks in a grid.`,
        attributes: {
            layout: {
                type: 'grid' 
            }
        },
        scope: [ 'block', 'inserter', 'transform' ],
        isActive: (blockAttributes) => blockAttributes.layout?.type === 'grid',
    }

#### Advantages of using this library

Without this library, if you have modified the content of a block you are developing in the editor and then make changes to a block's code that cause it to render differently, WordPress may mark the block as invalid.

This library intercepts the module update and caches the state of the block outside of WordPress' state tree. It then completely unregisters the block and then re-registers it. If the block was selected before the module update, it also deselects and reselects it.

WordPress is now looking at a different situation: a newly registered block with newly registered state. There is no discrepency and so the block is not flagged as invalid.

This library also provides a more declarative way of registering modules with WordPress than the default API, and is less prone to understandable errors importing the wrong registration functions, etc.

## Documents

### Installing Sage with Compose
See the [Sage installation documentation](https://roots.io/sage/docs/installation/).


Install Sage using Composer from your WordPress themes directory

    cd [root_folder]/wp-content/themes
    composer create-project roots/sage codigo

#### Build assets
You must build theme assets in order to access your site. 

**Run yarn from the theme directory to install dependencies**

    cd [root_folder]/wp-content/themes/codigo
    yarn


### Installing Acorn
See the [Acorn installation documentation](https://roots.io/acorn/docs/installation/).
 
Sage requires Acorn but doesn't ship with it included. This is to give you the flexibility to include it in a way that works best for your environment. There's a few different ways to install Acorn.

    cd [root_folder]/wp-content/themes/codigo
    composer require roots/acorn  

#### Add the autoload dump script

Acorn has a function that should be added to the scripts section of your composer.json file for the post-autoload-dump event. To automatically configure this script, run the following command:

    $ wp acorn acorn:init


#### Acorn Typical Errors

If you run

    wp acorn vendor:publish --provider="SomeVendor\SomePackage\Providers\SomePackageServiceProvider"

and you get

    No publishable resources for tag [].
    Publishing complete.

then run this `wp` command

    wp acorn clear-compiled

and then run the `wp acorn vendor:publish` command again.  
It should publish successfully now


### Go to CMS and select the Sage theme

Sage is ready to be used in your Wordpress installation. Go to the CMS and select the Sage theme.


## Quick Start

### Watch

```
clear
cd [root_folder]/wp-content/themes/codigo
yarn watch
```

Development URL:

http://localhost:3000/

Defined in `/bud.config.js`

```
...
  app
    .setUrl('http://localhost:3000')
    .setProxyUrl('https://sparemytime.localhost')
    .watch([
        `resources/views`,
        `resources/scripts`,
        `resources/css`,
    ]);
...
```

### Build

```
clear
cd [root_folder]/wp-content/themes/codigo
yarn build
```

Localhost URL:

https://sparemytime.localhost/

Defined in `/bud.config.js`

## Styling

### Tailwind Configuration File

    [root_folder]/wp-content/themes/codigo/tailwind.config.cjs

#### Compilation Errors

```
[sage] [@roots/bud-tailwindcss] › ✖  ReferenceError: require is not defined in ES module scope, you can use import instead 
This file is being treated as an ES module because it has a '.js' file extension and 'sparemytime/wp-content/themes/codigo/package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
```

  Solution: *Change file extension*

    [root_folder]/wp-content/themes/codigo/tailwind.config.js ---> [root_folder]/wp-content/themes/codigo/tailwind.config.cjs

### Setting up Support for Sass

Add the @roots/bud-sass extension:

    `yarn add @roots/bud-sass --dev`

[Read more](https://roots.io/sage/docs/sass/) about setting up Sass in Sage.

#### Configure Stylelint (optional)

Install `@roots/bud-stylelint`:

    `yarn add @roots/bud-stylelint --dev`

Create a Stylelint config file at `.stylelintrc.cjs`:

    module.exports = {
    	extends: ['@roots/bud-sass/config/stylelint'],
    	rules: {
    		'import-notation': null,
    		'no-empty-source': null,
    	},
    };


##### Maintaining Stylelint config

When `bud.js` updates you will automatically be upgraded to the latest versions of `stylelint-config-standard` and `stylelint-config-recommended-scss`. This may cause issues if you are now breaking a newly defined or changed rule. You will either want to make changes to your application or add an override to `module.exports.rules`.

This is normal. The preset is just supposed to be a base for your own config. There is nothing wrong with overriding rules to suit your preferences or your application's needs.

You could also:

- Not use the `@roots/bud-sass/config/stylelint` preset and maintain your own config entirely. This will give you maximum control over when updates are applied.

- Make an issue with `stylelint-config-standard` or `stylelint-config-recommended-scss` if you disagree with the change.

### CSS Files

    [root_folder]/wp-content/themes/codigo/resources/styles/css/

### SCSS Files
    

    [root_folder]/wp-content/themes/codigo/resources/styles/app.scss
    [root_folder]/wp-content/themes/codigo/resources/styles/editor.scss
    [root_folder]/wp-content/themes/codigo/resources/styles/scss/

### Set Up Fonts

Sage includes an empty `resources/fonts/` directory for you to use for any fonts you want to use in your theme.

The Sage extension in `jsconfig.json` also contains a @fonts alias that can be used to reference assets in the `fonts/` directory.

[Read more](https://roots.io/sage/docs/fonts-setup/) about setting up fonts in Sage.

## Javascript

The default configuration will generate the following JS files:

    app.js - The primary JavaScript file for the theme.
    editor.js - JavaScript for the block editor, i.e. block styles and variants.


## Setting up Support for Vue

Add the `@roots/bud-vue` extension:

    yarn add @roots/bud-vue --dev

**Important**: The `@roots/bud-vue` version must match `@roots/bud`

    "devDependencies": {
        "@roots/bud": "6.16.1",
        "@roots/bud-sass": "6.16.1",
        "@roots/bud-tailwindcss": "6.16.1",
        "@roots/bud-vue": "6.16.1",
        "@roots/sage": "6.16.1"
    },


Once installed, vue should be ready to use in your project. 

**Important:** The extension is pre-configured to support Vue 3 single file components (runtime only).

You can disable the `runtimeOnly` default by adding the following to your `bud.config.js` file:

    app.vue.setRuntimeOnly(false);

The `esm-bundler` builds of Vue expose global feature flags `__VUE_OPTIONS_API__` and `__VUE_PROD_DEVTOOLS__` , they must to be defined.
You may want to enable the options API and disable the devtools:

    app.define({
        __VUE_OPTIONS_API__: true,
        __VUE_PROD_DEVTOOLS__: false,
    });

[Read more](https://bud.js.org/extensions/bud-vue) about setting up Vue in Sage.

## Custom Post Types

**Update** Instead of Poet, we can use the new feature of ACF  to create Custom Post Types via CMS.

We will use [Log1x/poet](https://github.com/Log1x/poet) to create *Custom Post Types*. *Poet* provides simple configuration-based post type, taxonomy, editor color palette, block category, block pattern and block registration/modification.

### Getting Started

Install the package via Composer:

    composer require log1x/poet
    ...
    Using version ^2.1 for log1x/poet

Start with publishing the Poet configuration file using Acorn:

    $ wp acorn vendor:publish --provider="Log1x\Poet\PoetServiceProvider"

### Registering a Post Type

All configuration related to Poet is located in `config/poet.php`. Here you will find an example Book post type pre-configured with a few common settings:

    'post' => [
        'book' => [
            'enter_title_here' => 'Enter book title',
            'menu_icon' => 'dashicons-book-alt',
            'supports' => ['title', 'editor', 'author', 'revisions', 'thumbnail'],
            'show_in_rest' => true,
            'has_archive' => false,
            'labels' => [
                'singular' => 'Book',
                'plural' => 'Books',
            ],
        ],
    ],

#### Poet Typical Errors

#### *Error: No Custom Fields.*

If after downloading the files from a repository you don't see the new Custom Fields, you need to re-generate the `config/poet.php` file.

Rename the current file:
    
    mv config/poet.php config/poet.php.bak
    
Then run the following command:

    $ wp acorn vendor:publish --provider="Log1x\Poet\PoetServiceProvider"
    INFO Publishing assets.
    Copying file [vendor/log1x/poet/config/poet.php] to [config/poet.php]....................................................................... DONE


And rename again the files
    
    mv config/poet.php config/.poet.orig.php
    mv config/poet.php.bak config/poet.php  


#### *Error: No publishable resources for tag [poet].*

After running the command:

    $ wp acorn vendor:publish --provider="Log1x\Poet\PoetServiceProvider"

You get this message:

    INFO No publishable resources for tag [poet].

***Solution***: run this wp command

    $ wp acorn clear-compiled
    INFO Compiled services and packages files removed successfully.

and then run the wp acorn vendor:publish command again.

## Gutenberg Blocks

The `@roots/bud-preset-wordpress` package comes with an editor integration. This library adds support for registering *blocks*, *filters*, *formats*, *styles*, *variations* and *plugins*.

All modules registered with this API are registered in production and development. In development additional hot module reloading support is added.

### Adding support to your application

There are two steps:

- Making the root registration call for a given type or types.
- Adding modules to your application

In general, the above steps are the same for working with any of the supported APIs.

#### Making the root registration call

Open `resources/scripts/editor.js` and write the call `roots.register.[type]` , supplying the root directory where registrables are found.

For example, to register blocks in the application, we must add this call:

    roots.register.blocks('@scripts/blocks')

    /** Don't forget to accept any module updates! */
    if (import.meta.webpackHot) {
    import.meta.webpackHot.accept(console.error)
    }


#### Adding modules to the application

`bud.js` will look for modules in the directory indicated in the root registration call. Modules are named like `*.[type].[ext]`.

The module should export the required settings and the name of the entity.

Modules can be created using either *default exports* or *named exports*. As a general rule, we will use default exports whenever possible.

For example, to add a block variation in the Group block and add a Grid css feature, we would create a file `grid.variation.js` in the `resources/scripts/variations` directory:

    export default {
        block: `core/group`,
        name: 'group-grid',
        title: `Grid`,
        icon: 'grid-view',
        description: `Arrange blocks in a grid.`,
        attributes: {
            layout: {
                type: 'grid' 
            }
        },
        scope: [ 'block', 'inserter', 'transform' ],
        isActive: (blockAttributes) => blockAttributes.layout?.type === 'grid',
    }

#### Advantages of using this library

Without this library, if you have modified the content of a block you are developing in the editor and then make changes to a block's code that cause it to render differently, WordPress may mark the block as invalid.

This library intercepts the module update and caches the state of the block outside of WordPress' state tree. It then completely unregisters the block and then re-registers it. If the block was selected before the module update, it also deselects and reselects it.

WordPress is now looking at a different situation: a newly registered block with newly registered state. There is no discrepency and so the block is not flagged as invalid.

This library also provides a more declarative way of registering modules with WordPress than the default API, and is less prone to understandable errors importing the wrong registration functions, etc.


## Plugins

### Installing ACF Composer

ACF Composer is the ultimate tool for creating fields, blocks, widgets, and option pages using ACF Builder alongside Sage 10.

See the [ACF Composer installation](https://github.com/Log1x/acf-composer?tab=readme-ov-file#installation).


#### Install via Composer:

    $ composer require log1x/acf-composer

Start by publishing the `config/acf.php` configuration file using Acorn:

    $ wp acorn vendor:publish --tag="acf-composer"

If you have this warning

    INFO No publishable resources for tag [acf-composer].
    
try running this command first

    $ wp acorn package:discover
      INFO  Discovering packages.  
      nesbot/carbon ......................................................... DONE
      nunomaduro/termwind ................................................... DONE
      roots/sage ............................................................ DONE

And try again:

    $ wp acorn vendor:publish --tag="acf-composer"
      INFO  Publishing [acf-composer] assets.
      Copying file [vendor/log1x/acf-composer/config/acf.php] to [config/acf.php] ............. DONE

##### Generating a Field Group

To create your first field group, start by running the following generator command from your theme directory:   

    $ wp acorn acf:field Example

This will create `app/Fields/Example.php` which is where you will create and manage your first field group.

 **Note:** Check the [ACF Builder Cheatsheet](https://github.com/Log1x/acf-builder-cheatsheet?tab=readme-ov-file) to learn how to add ACF fields by code


##### Generating a Block

Generating a block is generally the same as generating a field as seen above.

Start by creating the block field using Acorn:

    $ wp acorn acf:block Example
    
    🎉 Example block successfully composed.
     ⮑  app/Blocks/Example.php
     ⮑  resources/views/blocks/example.blade.php

You may also pass --construct to the command above to generate a stub with the block properties set within an attributes method. This can be useful for localization, etc.

    $ wp acorn acf:block Example --construct

When running the block generator, one difference to a generic field is an accompanied View is generated in the resources/views/blocks directory.

Like the field generator, the example block contains a simple list repeater and is working out of the box.

 **Note:** Check the [ACF Builder Cheatsheet](https://github.com/Log1x/acf-builder-cheatsheet?tab=readme-ov-file) to learn how to add ACF fields by code



*Block Preview View*

While `$block->preview` is an option for conditionally modifying your block when shown in the editor, you may also render your block using a seperate view.

Simply duplicate your existing view prefixing it with `preview-` (e.g. `preview-example.blade.php`).



### Sage directives

[Sage Directives](https://log1x.github.io/sage-directives-docs/) adds a variety of useful Blade directives for use with Sage 10 including directives for WordPress, ACF, and various miscellaneous helpers.



#### Install Sage directives

    $ composer require log1x/sage-directives


#### Sage directives Examples

[Wordpress](https://log1x.github.io/sage-directives-docs/usage/wordpress.html)

**`WP_Query`**

`@query` initializes a standard `WP_Query` as `$query` and accepts the usual `WP_Query` parameters as an array.

    @query([
	    'post_type' => 'post'
    ])
    
    @posts
	    <h2  class="entry-title">@title</h2>
	    <div  class="entry-content">
		    @content
	    </div>
    @endposts


[ACF](https://log1x.github.io/sage-directives-docs/usage/acf.html)

**`@field`**


`@field` echo's the specified field using `get_field()`.

    @field('text')



## Integration with External Tools

### TypeForm

WE would like to include TypeForms in THGE website but with a custom design. However the TypeForm API does not allow automated submissions, so the respondent has to manually click on the button.

However there is way to do it for samall forms. We need to create a form with a single ‘statement’ field. The ‘statement’ field only shows a message and a ‘continue’ button, if that is the only field on the form, the ‘continue’ button is replaced by a ‘submit’ button.

Then we need to add some hidden fields to that form,the hidden fields must to be the same as the custom form fields, and the same name.

In the frontend hid the iframe where TytpeForm is embedded through CSS.
So when the responders load the web, they will just see our custom form. They will fill it in and click on my custom submit button.

Then the data is filled in the hidden fields of the TypeForm via javascript. For that I simply update the URL of the iframe adding the values to the hidden fields and reload it. Then I update the CSS class via  javascript again to show the iframe (and hide my custom form). Here is an example of the code:

        const form     = document.querySelector('.register-form');
        const typeform = document.querySelector('.wp-block-typeform-embed-plugin');

        const refreshIframe = (url) => {
            
            typeform.querySelector('.tf-v1-widget iframe').src = url;
            form.classList.add('invisible');

            //run function after one second
            setTimeout(() => {
                typeform.classList.add('show');
                form.classList.add('hidden');
            }, 1000);
        };
        const submitForm = (event) => {
            event.preventDefault();

            //const name = document.querySelector('#name').value;
            const email = document.querySelector('.register-form .wpcf7-email').value;
            const typeformUrl = `https://engsijc1gzx.typeform.com/to/SEpRzBid#email=${encodeURIComponent(email)}`;
            //window.location.href = typeformUrl;
            refreshIframe(typeformUrl);
        };

        //document.querySelector('.register-form').addEventListener('submit', submitForm);
        form.querySelector('input[type=submit]').addEventListener('click', submitForm)

The TypeForm appears showing only a confirmation message and a submit button. When the user clicks the button, all the data is sent to the TypeForm account


## Required Plugins

* [Advanced Custom Fields](https://www.advancedcustomfields.com/pro/)


## Required libraries

* [SAGE](https://github.com/roots/sage?tab=readme-ov-file)
* [Acorn](https://roots.io/acorn/).
* [Nextly](https://github.com/web3templates/nextly-template)
* [ACF Composer](https://github.com/Log1x/acf-composer)
* [Poet](https://github.com/Log1x/poet)
* [Sage Directives](https://log1x.github.io/sage-directives-docs/)


## Copyright and License

Copyright 2023 Codigo Wordpress Theme released under the [MIT](https://github.com/pablorica/sparemytime/blob/main/LICENSE) license.

## Versioning

We use [SemVer](https://semver.org/) for versioning. For the versions available, [list of tags can be found in this page](https://github.com/pablorica/sparemytime/tags).

### Changelog

[CHANGELOG.md](https://github.com/pablorica/sparemytime/blob/main/CHANGELOG.md)
