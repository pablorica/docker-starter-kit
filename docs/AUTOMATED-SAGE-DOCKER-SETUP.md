# Automated Sage + Docker setup

How to create a new WordPress + Sage project on Docker automatically with `new-wp-sage.sh`, plus every step for doing it by hand.

`new-wp-sage.sh` sets up a new local WordPress site that runs on Docker. It can also install a theme based on [Sage](https://github.com/roots/sage) and the ACF PRO plugin. Both are optional, so the same script works for Sage projects and for other WordPress projects (e.g. a headless WordPress with a separate React front end). It follows the same steps as the manual installation, using `~/Dockers/default` as the template project. Before it does anything, it asks you for every value that changes from one project to the next.

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [What the script asks](#what-the-script-asks)
- [What the script does](#what-the-script-does)
- [ACF PRO licence](#acf-pro-licence)
- [WordPress salts](#wordpress-salts)
- [Staging server (Nginx or Apache)](#staging-server-nginx-or-apache)
- [Personal defaults](#personal-defaults)
- [Manual installation (step by step)](#manual-installation-step-by-step)
- [Useful commands](#useful-commands)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)

---

## Requirements

On your machine:

| Tool | Notes |
|---|---|
| Docker + Docker Compose v2 | `docker compose version` must work and Docker must be running |
| mkcert | Run `mkcert -install` **once** per machine so browsers trust the local certificates |
| git | Used to push to GitHub |
| perl | Used to edit `.env` safely (preinstalled on macOS and most Linux) |

Composer and WP-CLI **don't** need to be installed locally. They run through Docker, using the `composer` (profile `tools`) and `wpcli` services in `docker-compose.yml`.

You also need:

- The template project at `~/Dockers/default` with these files:
  `.env.example`, `docker-compose.wordpress.yml`, `docker-compose.wordpress.remote.yml`, `Caddyfile.sage.example`, `uploads.ini.example`, `wp-config.php.example`, `.editorconfig.example`, `gitignore.wordpress.example`, `nginx.conf.staging`, `apache.conf.staging`, the `docker_sage/` folder, `docs/SAGE.md`, `docs/PostCSS.md`, `docs/ALPINE.md` and the custom Vite config at `wordpress/wp-content/themes/codigo/vite.config.js`.
- An **empty** GitHub repository for the project (optional), and GitHub access through SSH keys or the `gh` CLI (see [Security notes](#security-notes)).

---

## Quick start

```bash
# Once: put the script in ~/Dockers and make it executable
mv new-wp-sage.sh ~/Dockers/
chmod +x ~/Dockers/new-wp-sage.sh

# For each new project
cd ~/Dockers
./new-wp-sage.sh
```

Answer the questions. To accept a default shown in `[brackets]`, press **Enter**. Before it changes anything, the script shows a summary and asks you to confirm.

### Pre-answering questions

Any question can be answered in advance with an environment variable. The script then skips that question:

```bash
PROJECT=skelly-couch SITE_TITLE="Skelly & Couch" PROD_DOMAIN=beta.skelly-couch.tm-studio.co.uk ./new-wp-sage.sh
```

For a project without Sage (e.g. headless WordPress), pre-answer `DO_SAGE=n`. Add `DO_ACF=n` too if you don't need ACF PRO:

```bash
DO_SAGE=n ./new-wp-sage.sh
```

Variable names: `DOCKERS_DIR`, `TEMPLATE_DIR`, `PROJECT`, `SITE_TITLE`, `THEME`, `SSL_PORT`, `PMA_PORT`, `NODE_PORT`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `PROD_DOMAIN`, `DO_WP_INSTALL` (y/n), `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL`, `DO_SAGE` (y/n), `SAGE_VERSION`, `DO_ACF` (y/n), `ACF_PRO_LICENSE`, `ACF_LICENSE_URL`, `DO_GIT` (y/n), `GITHUB_ORG`, `GITHUB_REPO`, `START_NODE` (y/n).

---

## What the script asks

| Question | Default | Used for |
|---|---|---|
| Dockers folder | `~/Dockers` | Parent folder for all projects |
| Template project folder | `~/Dockers/default` | Source of the files that get copied |
| Project slug | — | Folder name, local domain (`<slug>.localhost`) and the replacement for `default` in `.env` |
| Site title | the slug | WordPress site title |
| Theme folder name | `codigo` | Sage theme folder, `WORDPRESS_THEMENAME` and the replacement for `template` in `.env` |
| WordPress SSL port | the highest port used in your other projects + 1 | `WORDPRESS_SSL_PORT` (replaces `8443`) |
| phpMyAdmin port | SSL port + 100 | `PHPMYADMIN_PORT` (replaces `8081`) |
| Node/Vite port | SSL port − 3200 | `NODE_PORT` (replaces `5173`) |
| MySQL password | generated if blank | `MYSQL_PASSWORD` |
| MySQL root password | generated if blank | `MYSQL_ROOT_PASSWORD` |
| Production domain | — (required) | `CADDY_PRODUCTION_DOMAIN`, e.g. `beta.skelly-couch.tm-studio.co.uk` or `freedmanhilmi.com` |
| Install WordPress automatically? | yes | Runs the WordPress install with WP-CLI instead of the browser |
| WP admin user | `pablo.rica` | WordPress admin account |
| WP admin password | generated if blank | WordPress admin account |
| WP admin email | `pablo@codigo.co.uk` | WordPress admin account |
| Install the Sage theme? | yes | If no, the Sage steps are skipped (see below) |
| Sage version constraint | blank = latest stable | Only asked with Sage. Pins a Sage version if needed, e.g. `11.*` |
| Install ACF PRO? | yes | Downloads, installs and activates Advanced Custom Fields PRO |
| ACF PRO licence key | — (hidden, required) | Written **only** to `.env` as `ACF_PRO_LICENSE` |
| Site URL the licence is activated for | `https://<production domain>` | Needed by ACF's Composer repository to download the plugin |
| Push to GitHub? | yes | Connects the project to a repository |
| GitHub user/organisation | `pablorica` | Builds the suggested repository URL |
| Repository URL | `git@github.com:<org>/<slug>.git` | `origin` remote |
| Start Node dev server at the end? | yes | Only asked with Sage. Runs `docker compose --profile dev up node` |

The script warns you when a port is already in use. Passwords can't contain a single quote (`'`).

**Example ports** (Skelly & Couch): SSL `8465`, phpMyAdmin `8565`, Node `5265`.

### Without Sage

If you answer **no** to *Install the Sage theme?*, the script:

- doesn't copy `docs/SAGE.md`, `docs/PostCSS.md` or `docs/ALPINE.md`, and doesn't need the custom `vite.config.js` in the template
- doesn't run `composer create-project`, copy the Vite config or activate a theme, so WordPress keeps its default theme
- doesn't offer to start the Node dev server

Everything else (Docker stack, `.env`, salts, WordPress install, ACF PRO, staging configs, GitHub) runs as normal. The theme folder name is still asked, because `.env` (`WORDPRESS_THEMENAME`, `VITE_PATH`) and `.gitignore` use it.

> **Node without Sage:** the template's `.env` sets `COMPOSE_PROFILES=dev`, so a plain `docker compose up -d` also starts `node`, which has no theme to build. Start the services by name (`docker compose --profile dev up -d mysql wordpress phpmyadmin caddy`), or remove `node` from that project's `docker-compose.yml`.

---

## What the script does

1. **Pre-flight checks.** It checks that docker, docker compose, mkcert, git and perl are installed and that Docker is running. It also checks that every template file exists and that the project folder doesn't exist yet or is empty.
2. **Project folder and SSL certificates.** It creates `~/Dockers/<slug>/certs` and runs `mkcert` for `<slug>.localhost` and `pma.<slug>.localhost`.
3. **Copies the template files** from `~/Dockers/default`, renaming them (e.g. `Caddyfile.sage.example` becomes `Caddyfile`). With Sage, this includes the Sage runbook (`docs/SAGE.md`), the custom CSS guide (`docs/PostCSS.md`) and the Alpine.js guide (`docs/ALPINE.md`).
4. **Creates `.env`** from `.env.example`:
   - replaces `default` with the slug and `template` with the theme name
   - replaces ports `8443`, `8081` and `5173` with the new ones
   - sets `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `WORDPRESS_THEMENAME` and `CADDY_PRODUCTION_DOMAIN`
   - writes passwords in single quotes, so characters like `$`, `&` and `%` work. Docker Compose would otherwise read `$m` as a variable.

   - generates **unique WordPress salts** for the project (`WORDPRESS_AUTH_KEY` … `WORDPRESS_NONCE_SALT`, 64 random characters each). See [WordPress salts](#wordpress-salts).

   It then fills in the placeholders in the other template files:
   - **`.gitignore`**: `__THEME__` becomes the theme folder name, so git tracks `wordpress/wp-content/themes/<theme>/` and ignores its `vendor/`, `node_modules/` and so on.
   - **`nginx.conf.staging`** and **`apache.conf.staging`**: the staging domain, the project folder on the server, and the WordPress and phpMyAdmin ports (see [Staging server](#staging-server-nginx-or-apache)).
5. **Starts Docker.** It pulls the images, then starts `mysql`, `wordpress`, `phpmyadmin` and `caddy` (Caddy is in the `dev` profile, so it's started by name). Then it waits until MySQL accepts the WordPress database user.
6. **Installs WordPress** (optional). It uses the `wpcli` service to run `wp core install` and set **Discourage search engines** (`blog_public = 0`). If this fails, it tells you to finish the install in the browser.
7. **Installs Sage with Composer** (optional). It removes any existing `wordpress/wp-content/themes/<theme>` folder, then runs `composer create-project roots/sage <theme>` through the `composer` service, as your user so the files aren't owned by root. This installs the latest stable Sage (or your version constraint) **and** `vendor/` in one step. Then it removes any Sage developer files that are left (`.github`, `.editorconfig`, `.gitattributes`, `.gitignore`) and replaces Sage's default `vite.config.js` with the custom one from the template project. That one reads `APP_URL`, `NODE_PORT`, `VITE_PATH` and the other variables set in `docker-compose.yml` (see `docs/SAGE.md`). It uses `sudo` only if a file belongs to the container user.
8. **Activates the theme** with the `wpcli` service (only with Sage).
   - **ACF PRO** (optional): downloads the plugin from ACF's official Composer repository. It runs in a temporary folder inside the `composer` container, so nothing is added to the theme's `composer.json`. It copies the plugin to `wp-content/plugins/advanced-custom-fields-pro`, then activates it with WP-CLI. The licence then activates automatically from `.env`, if the template is set up for it (see [ACF PRO licence](#acf-pro-licence)).
9. **GitHub** (optional):
    - runs `git init` and adds the remote
    - if the repository already has commits (e.g. a LICENSE), adopts its history and adds any files that are missing locally, without overwriting your files
    - stops and asks before committing if `.env` or `certs/local-key.pem` isn't ignored by `.gitignore`
    - commits and runs `git push -u origin <branch>`
10. **Summary.** It prints the URLs and credentials. With Sage, it then starts the Node dev server in the foreground (stop it with `Ctrl+C`).

If a command fails, the script stops and shows the line that failed.

---

## ACF PRO licence

The script installs ACF PRO, but **activating the licence** automatically needs these one-off changes to the template project (`~/Dockers/default`). Without them, ACF PRO is still installed, and you enter the key in **ACF → Updates**.

**1. `docker-compose.wordpress.yml`**: pass the key to the `wordpress` service:

```yaml
  wordpress:
    environment:
      # ...existing variables...
      ACF_PRO_LICENSE: ${ACF_PRO_LICENSE:-}
```

**2. `wp-config.php.example`**: define the constant ACF reads, **before** the `require_once ABSPATH . 'wp-settings.php';` line:

```php
// ACF PRO licence (from .env through docker-compose). Activates the licence automatically.
$acf_pro_license = getenv( 'ACF_PRO_LICENSE' );
if ( $acf_pro_license && ! defined( 'ACF_PRO_LICENSE' ) ) {
    define( 'ACF_PRO_LICENSE', $acf_pro_license );
}
unset( $acf_pro_license );
```

**3. `.env.example`** (optional): add an empty placeholder so every project has the variable:

```ini
ACF_PRO_LICENSE=
```

Notes:

- **The key is never in the script or in git.** You type it (hidden), and it's saved only in the project's `.env`. To avoid typing it, you can pass it from your password manager instead, e.g. `ACF_PRO_LICENSE="$(…)" ./new-wp-sage.sh`.
- **The site URL is the password ACF's Composer repository asks for.** It must be a site URL the licence is activated for. ACF recommends an existing production URL when the final URL isn't known yet. With a single-site licence, use that site's URL.
- **Staging and production** need the same `ACF_PRO_LICENSE` variable (or the `define`) in their own environment.
- **ACF PRO is a paid plugin.** It's fine in a **private** repository, but don't commit `wp-content/plugins/advanced-custom-fields-pro` to a public one.

---

## WordPress salts

The script generates **unique salts for each project** and saves them in `.env`:

```ini
WORDPRESS_AUTH_KEY='…64 random characters…'
WORDPRESS_SECURE_AUTH_KEY='…'
WORDPRESS_LOGGED_IN_KEY='…'
WORDPRESS_NONCE_KEY='…'
WORDPRESS_AUTH_SALT='…'
WORDPRESS_SECURE_AUTH_SALT='…'
WORDPRESS_LOGGED_IN_SALT='…'
WORDPRESS_NONCE_SALT='…'
```

`wp-config.php` already reads them (`getenv('WORDPRESS_AUTH_KEY')` …). For them to reach WordPress, the template needs these one-off changes (`~/Dockers/default`). Without them, the script warns you and WordPress keeps using the fallback values in `wp-config.php`.

**1. `docker-compose.wordpress.yml`**: pass them to the `wordpress` **and** `wpcli` services:

```yaml
  wordpress:
    environment:
      # ...existing variables...
      WORDPRESS_AUTH_KEY: ${WORDPRESS_AUTH_KEY:-}
      WORDPRESS_SECURE_AUTH_KEY: ${WORDPRESS_SECURE_AUTH_KEY:-}
      WORDPRESS_LOGGED_IN_KEY: ${WORDPRESS_LOGGED_IN_KEY:-}
      WORDPRESS_NONCE_KEY: ${WORDPRESS_NONCE_KEY:-}
      WORDPRESS_AUTH_SALT: ${WORDPRESS_AUTH_SALT:-}
      WORDPRESS_SECURE_AUTH_SALT: ${WORDPRESS_SECURE_AUTH_SALT:-}
      WORDPRESS_LOGGED_IN_SALT: ${WORDPRESS_LOGGED_IN_SALT:-}
      WORDPRESS_NONCE_SALT: ${WORDPRESS_NONCE_SALT:-}

  wpcli:
    environment:
      # ...existing variables...
      # (same eight lines as above)
```

**2. `wp-config.php.example`** (recommended): remove the hardcoded fallback salts, so no project ever shares them through the template repo:

```php
define('AUTH_KEY',         getenv('WORDPRESS_AUTH_KEY')         ?: '');
define('SECURE_AUTH_KEY',  getenv('WORDPRESS_SECURE_AUTH_KEY')  ?: '');
define('LOGGED_IN_KEY',    getenv('WORDPRESS_LOGGED_IN_KEY')    ?: '');
define('NONCE_KEY',        getenv('WORDPRESS_NONCE_KEY')        ?: '');
define('AUTH_SALT',        getenv('WORDPRESS_AUTH_SALT')        ?: '');
define('SECURE_AUTH_SALT', getenv('WORDPRESS_SECURE_AUTH_SALT') ?: '');
define('LOGGED_IN_SALT',   getenv('WORDPRESS_LOGGED_IN_SALT')   ?: '');
define('NONCE_SALT',       getenv('WORDPRESS_NONCE_SALT')       ?: '');
```

If a value is missing, WordPress then generates a random one itself and stores it in the database, which is safer than a shared fallback.

**3. `.env.example`** (optional): add the eight variables, empty. The script fills them in.

### New salts for staging or production

Each environment should have its own salts. To generate a new set for the server's `.env`:

```bash
for k in AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT; do
  printf "WORDPRESS_%s='%s'\n" "$k" "$(LC_ALL=C tr -dc 'A-Za-z0-9!#%+,./:;<=>?@^_~-' </dev/urandom | head -c 64)"
done
```

Changing the salts logs out everyone who is signed in, so do it before launch, or when you need everyone to sign in again.

---

## Staging server (Nginx or Apache)

The template has a config for each web server. Use the one your staging server runs:

| File | Server |
|---|---|
| `nginx.conf.staging` | Nginx |
| `apache.conf.staging` | Apache |

Both are **templates with placeholders**. The script fills them in for each project:

| Placeholder | Replaced with | Example |
|---|---|---|
| `__PROJECT__` | Project slug: the folder on the server (`/srv/docker/<slug>`), the `.htpasswd-pma` path and the log names | `skelly-couch` |
| `__DOMAIN__` | Production domain (`CADDY_PRODUCTION_DOMAIN`) | `beta.skelly-couch.tm-studio.co.uk` |
| `__APP_PORT__` | WordPress SSL port (`WORDPRESS_SSL_PORT`) | `8465` |
| `__PMA_PORT__` | phpMyAdmin port (`PHPMYADMIN_PORT`) | `8565` |
| `__LIVE_DOMAIN__` | **Not replaced.** Only used by the optional media offload in the Apache file. Fill it in by hand if you enable it. | `skelly-couch.com` |

> The ports come from `docker-compose.remote.yml`. On the server it publishes WordPress on `127.0.0.1:${WORDPRESS_SSL_PORT}` and phpMyAdmin on `127.0.0.1:${PHPMYADMIN_PORT}`, so the proxy uses the same two ports. If you change them in the server's `.env`, change them in the Nginx/Apache config too.

Both files **block `/logs/`**, because `debug.log` and `error.log` live in the web root. Nginx returns `404`. Apache returns `403` (`Require all denied`).

### Installing it on the server

**Nginx:**

```bash
sudo cp nginx.conf.staging /etc/nginx/sites-available/<project>.conf
sudo ln -s /etc/nginx/sites-available/<project>.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d <prod-domain>
```

**Apache:**

```bash
sudo a2enmod proxy proxy_http headers rewrite
sudo cp apache.conf.staging /etc/apache2/sites-available/<project>.conf
sudo a2ensite <project>
sudo apachectl configtest && sudo systemctl reload apache2
sudo certbot --apache -d <prod-domain>
```

> **Apache + certbot:** certbot copies the `VirtualHost` into `/etc/apache2/sites-available/<project>-le-ssl.conf` (port 443), which is the one that actually serves the site. If you change the config **after** running certbot (e.g. to enable the media offload), make the same change in the `-le-ssl.conf` file too.

phpMyAdmin is protected with basic auth. Create the password file once:

```bash
sudo htpasswd -c /srv/docker/<project>/.htpasswd-pma <user>
```

Check that the logs are blocked:

```bash
curl -I https://<prod-domain>/logs/debug.log   # 404 (Nginx) or 403 (Apache)
```

### The server's `.env`

Start from a copy of the local `.env`, then change these values:

| Variable | On the server | Why |
|---|---|---|
| `COMPOSE_PROFILES` | **empty** (`COMPOSE_PROFILES=`) | With `dev`, Caddy and Node start too. Caddy publishes `WORDPRESS_SSL_PORT` on all interfaces, which **conflicts** with the WordPress port and stops the stack from starting. Nginx or Apache does the proxying on the server. |
| `WORDPRESS_DEBUG` | `false` | Otherwise `debug.log` keeps growing (and `WP_DEBUG` is on by default). |
| `APP_ENV` | anything except `local` (e.g. `staging`) | With `local`, `wp-config.php` adds the port to the site URL. |
| `WORDPRESS_HOME` | `https://<prod-domain>` | The public URL, without a port. |
| `WORDPRESS_AUTH_KEY` … `WORDPRESS_NONCE_SALT` | **new values** | Each environment should have its own salts. See [WordPress salts](#wordpress-salts). |
| `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` | new passwords (recommended) | Don't reuse the local ones. |
| `ACF_PRO_LICENSE` | your key (if you use ACF PRO) | Activates the licence on the server too. |

Then start the stack with both compose files. The second one publishes the ports on `127.0.0.1`:

```bash
cd /srv/docker/<project>
docker compose -f docker-compose.yml -f docker-compose.remote.yml up -d
docker compose -f docker-compose.yml -f docker-compose.remote.yml ps
```

You should see `wordpress`, `mysql` and `phpmyadmin`, with **no** `caddy` or `node`.

---

## Personal defaults

The top of the script has a block of personal defaults. These are the values offered when you press Enter:

```bash
DEFAULT_DOCKERS_DIR="$HOME/Dockers"
DEFAULT_THEME="codigo"
DEFAULT_WP_USER="pablo.rica"
DEFAULT_WP_EMAIL="pablo@codigo.co.uk"
DEFAULT_GITHUB_ORG="pablorica"
SAGE_PACKAGE="roots/sage"

# Ports in .env.example that get replaced per project
TPL_SSL_PORT=8443
TPL_PMA_PORT=8081
TPL_NODE_PORT=5173
```

If you add or rename files in `~/Dockers/default`, update the `TEMPLATE_FILES` list in the same block (files every project gets) or `SAGE_TEMPLATE_FILES` (files copied only with Sage). Subfolders such as `docs/` are created automatically.

The custom Vite config's location in the template project is set in `TEMPLATE_VITE_CONFIG`:

```bash
TEMPLATE_VITE_CONFIG="wordpress/wp-content/themes/codigo/vite.config.js"
```

The config doesn't depend on the theme name (it uses `VITE_PATH` from `.env`), so the same file works for any theme.

---

## Manual installation (step by step)

These are the same steps the script runs, in case you need to run any of them by hand. Replace the placeholders:

| Placeholder | Example |
|---|---|
| `<project>` | `skelly-couch` |
| `<theme>` | `codigo` |
| `<ssl-port>` / `<pma-port>` / `<node-port>` | `8465` / `8565` / `5265` |
| `<prod-domain>` | `beta.skelly-couch.tm-studio.co.uk` |
| `<github-user>` | `pablorica` |

### 1. Docker

#### Create the project folder

```bash
mkdir ~/Dockers/<project>
cd ~/Dockers/<project>
```

#### Create the SSL certificates

```bash
mkdir -p ./certs
mkcert -cert-file ./certs/local.pem -key-file ./certs/local-key.pem \
  <project>.localhost pma.<project>.localhost
```

#### Copy the files from the template project

```bash
cd ~/Dockers/<project>
cp ../default/.env.example .env.example
cp ../default/docker-compose.wordpress.yml docker-compose.yml
cp ../default/docker-compose.wordpress.remote.yml docker-compose.remote.yml
cp ../default/Caddyfile.sage.example Caddyfile
cp ../default/uploads.ini.example uploads.ini
cp ../default/wp-config.php.example wp-config.php
cp ../default/.editorconfig.example .editorconfig
cp ../default/gitignore.wordpress.example .gitignore
cp ../default/nginx.conf.staging nginx.conf.staging
cp ../default/apache.conf.staging apache.conf.staging
cp -R ../default/docker_sage docker
mkdir -p docs
cp ../default/docs/SAGE.md docs/SAGE.md
cp ../default/docs/PostCSS.md docs/PostCSS.md
cp ../default/docs/ALPINE.md docs/ALPINE.md
```

#### Create and edit the `.env` file

```bash
cp .env.example .env
```

Replace in `.env`:

| Find | Replace with |
|---|---|
| `default` | `<project>` |
| `template` | `<theme>` |
| `8443` | `<ssl-port>` (`WORDPRESS_SSL_PORT`) |
| `8081` | `<pma-port>` (`PHPMYADMIN_PORT`) |
| `5173` | `<node-port>` (`NODE_PORT`) |

Set these values:

```ini
MYSQL_PASSWORD='<db-password>'
MYSQL_ROOT_PASSWORD='<root-password>'
WORDPRESS_THEMENAME=<theme>
CADDY_PRODUCTION_DOMAIN=<prod-domain>
```

> Put passwords that contain `$` in **single quotes**. Without them, Docker Compose reads `$something` as a variable.

#### Fill in the placeholders (`.gitignore` and staging server configs)

```bash
for f in .gitignore nginx.conf.staging apache.conf.staging; do
  perl -pi -e 's/__THEME__/<theme>/g; s/__PROJECT__/<project>/g; s/__DOMAIN__/<prod-domain>/g; s/__APP_PORT__/<ssl-port>/g; s/__PMA_PORT__/<pma-port>/g' "$f"
done
```

#### Add unique WordPress salts to `.env`

Use the command in [New salts for staging or production](#new-salts-for-staging-or-production) and paste its output into `.env`, replacing any existing `WORDPRESS_*_KEY` / `WORDPRESS_*_SALT` lines.

See [Staging server](#staging-server-nginx-or-apache) for what each placeholder means.

#### Start the stack

From `~/Dockers/<project>`:

`caddy` and `node` are in the `dev` profile because they're only used locally. On staging and production, Nginx or Apache does the proxying and the compiled assets are uploaded. The template's `.env` sets `COMPOSE_PROFILES=dev`, so locally a plain `docker compose up -d` starts **everything, including Node**.

During the first install, the theme doesn't exist yet, so start the services **by name** to keep Node out until the theme is in place:

```bash
# Pull the latest images
docker compose --profile dev pull

# Start
docker compose --profile dev up -d mysql wordpress phpmyadmin caddy

# Check it's running
docker compose --profile dev ps
```

Expected output:

```
NAME                    ...   PORTS
<project>_caddy         ...   0.0.0.0:<ssl-port>-><ssl-port>/tcp
<project>_mysql         ...   3306/tcp, 33060/tcp
<project>_phpmyadmin    ...   80/tcp
<project>_wordpress     ...   80/tcp
```

#### Optional: check the database

```bash
# Check MySQL is alive (root password)
docker compose exec mysql mysqladmin ping -uroot -p
# -> mysqld is alive

# Try logging in as the WordPress user (MYSQL_USER / MYSQL_DATABASE from .env)
docker compose exec mysql mysql -u<db-user> -p -e "SELECT 1;" <project>
```

#### Run the WordPress installation

**In the browser:** open `https://<project>.localhost:<ssl-port>/` and fill in:

- Site title
- Username / password / email
- **Discourage search engines from indexing this site** → checked

**Or with WP-CLI** through the `wpcli` service, as the script does:

```bash
docker compose run --rm wpcli core install \
  --url="https://<project>.localhost:<ssl-port>" --title="<Site title>" \
  --admin_user="<user>" --admin_password="<password>" --admin_email="<email>" --skip-email

docker compose run --rm wpcli option update blog_public 0
```

#### Check phpMyAdmin

`https://pma.<project>.localhost:<ssl-port>`

### 2. Sage

#### Create the theme with Composer (through Docker)

`composer create-project` downloads the latest **stable** Sage release into a folder with your theme name and installs `vendor/`. You don't need a separate `composer update` step.

```bash
cd ~/Dockers/<project>

# Remove the old theme folder (if it exists): create-project needs a missing or empty folder
rm -rf wordpress/wp-content/themes/<theme>

# Create the theme (runs in the themes folder, as your user so files aren't owned by root)
docker compose --profile tools run --rm --user "$(id -u):$(id -g)" \
  -e COMPOSER_HOME=/tmp/composer \
  -w /var/www/html/wp-content/themes \
  composer create-project --no-interaction roots/sage <theme>
```

To pin a Sage version, add a constraint at the end, e.g. `... create-project --no-interaction roots/sage <theme> "11.*"`.

#### Remove the Sage developer files (if present)

`create-project` doesn't keep a `.git` folder, but some of these files may still be there:

```bash
cd ~/Dockers/<project>/wordpress/wp-content/themes/<theme>
rm -rf .git .github .editorconfig .gitattributes .gitignore
```

#### Copy the custom `vite.config.js`

Replace Sage's default Vite config with the custom one from the template project. It reads the variables that `docker-compose.yml` passes to the `node` service (`APP_URL`, `APP_HOST`, `APP_PORT`, `NODE_PORT`, `VITE_PATH`). See the Vite section in `docs/SAGE.md`.

```bash
cd ~/Dockers/<project>
cp ../default/wordpress/wp-content/themes/codigo/vite.config.js \
   wordpress/wp-content/themes/<theme>/vite.config.js
```

#### Update Composer packages later (optional)

```bash
cd ~/Dockers/<project>
docker compose --profile tools run --rm composer update -W
```

#### Start the Node service and install the front-end dependencies

```bash
cd ~/Dockers/<project>
docker compose --profile dev up node
```

#### Activate the theme

In wp-admin, go to **Appearance → Themes** and activate `<theme>`. Then open `https://<project>.localhost:<ssl-port>`.

With WP-CLI:

```bash
docker compose run --rm wpcli theme activate <theme>
```

### 3. ACF PRO (optional)

#### Option A: Composer, as the script does

```bash
cd ~/Dockers/<project>

docker compose --profile tools run --rm -T --user 33:33 \
  -e COMPOSER_HOME=/tmp/composer \
  -e COMPOSER_AUTH='{"http-basic":{"connect.advancedcustomfields.com":{"username":"<licence-key>","password":"https://<activated-site>"}}}' \
  --entrypoint sh composer -c '
    set -e
    mkdir -p /tmp/acf && cd /tmp/acf
    cat > composer.json <<"JSON"
{
  "repositories": [{ "type": "composer", "url": "https://connect.advancedcustomfields.com" }],
  "require": { "wpengine/advanced-custom-fields-pro": "*" },
  "extra": { "installer-paths": { "wp-content/plugins/{$name}/": ["type:wordpress-plugin"] } },
  "config": { "allow-plugins": { "composer/installers": true } }
}
JSON
    composer update --no-interaction
    rm -rf /var/www/html/wp-content/plugins/advanced-custom-fields-pro
    cp -R wp-content/plugins/advanced-custom-fields-pro /var/www/html/wp-content/plugins/
  '

docker compose run --rm wpcli plugin activate advanced-custom-fields-pro
```

#### Option B: zip file

Download the zip from your ACF account (**Licenses** tab), then:

```bash
cp ~/Downloads/advanced-custom-fields-pro.zip wordpress/
docker compose run --rm wpcli plugin install advanced-custom-fields-pro.zip --activate
rm wordpress/advanced-custom-fields-pro.zip
```

#### Activate the licence

Add `ACF_PRO_LICENSE='<licence-key>'` to `.env` (with the template changes in [ACF PRO licence](#acf-pro-licence)), then recreate the WordPress container so it picks up the variable:

```bash
docker compose up -d wordpress
```

Or enter the key in **wp-admin → ACF → Updates**.

### 4. GitHub

Create the repository on GitHub first (e.g. `https://github.com/<github-user>/<project>`).

**Recommended (no token in the URL):**

```bash
cd ~/Dockers/<project>
git init
git remote add origin git@github.com:<github-user>/<project>.git

# If the repo was created with a LICENSE/README, adopt its history first:
git fetch origin
git reset origin/main          # keeps your local files untouched
git checkout origin/main -- LICENSE

# Make sure .env and certs are ignored
git check-ignore .env certs/local-key.pem

git add .
git commit -m "first push"
git push -u origin main
```

**The original manual method** (clone into a temporary folder and move `.git` across):

```bash
cd ~/Dockers/
mv <project> <project>-b
git clone git@github.com:<github-user>/<project>.git
mv <project>/.git <project>-b/
mv <project>/LICENSE <project>-b/
rm -R <project>
mv <project>-b <project>
cd ~/Dockers/<project>

git add .
git commit -m "first push"
git push
```

> Don't put a personal access token in the clone/push URL. It gets saved in your shell history and in notes. Use SSH or `gh auth login` instead.

---

## Useful commands

```bash
cd ~/Dockers/<project>

docker compose --profile dev up -d mysql wordpress phpmyadmin caddy   # start the stack
docker compose --profile dev up node         # Vite dev server (foreground)
docker compose --profile dev down            # stop everything
docker compose --profile dev ps              # status
docker compose logs -f wordpress             # follow logs (wordpress, mysql, caddy, phpmyadmin)
docker compose --profile tools run --rm composer update -W   # Composer (any composer command)
docker compose run --rm wpcli plugin list    # WP-CLI (any wp command)
```

---

## Troubleshooting

| Problem | What to check |
|---|---|
| "Port X looks busy" | Another project is running on that port. Stop it with `docker compose down` or choose different ports. |
| Browser shows a certificate warning | Run `mkcert -install` once, then restart the browser. |
| "MySQL didn't come up" | `docker compose logs mysql`. If you changed passwords after the first start, the old database volume still has the old ones. Run `docker compose down -v` (**deletes the database**) and start again. |
| Automatic WordPress install failed | Finish it in the browser at `https://<project>.localhost:<ssl-port>/`. The rest of the script continues. |
| "`KEY` not found in .env" | `.env.example` doesn't have that variable. Add it to `.env` by hand. |
| `Permission denied` in the themes folder | The folder belongs to the container user. Use `sudo` (the script does this automatically). |
| `vendor/` owned by root after `composer update` | On Linux, uncomment `user: "${UID:-1000}:${GID:-1000}"` in the `composer` service, or add `--user "$(id -u):$(id -g)"` to the command. |
| Composer complains about the PHP version | The `composer` image's PHP differs from the `wordpress` one. Add `--ignore-platform-reqs`, as long as the `wordpress` container meets Sage's requirements. |
| Caddy isn't running after `docker compose up -d` | It's in the `dev` profile. Check that `.env` has `COMPOSE_PROFILES=dev`, or start it with `docker compose --profile dev up -d caddy`. |
| Push failed | Check that GitHub access works: `ssh -T git@github.com` or `gh auth status`. Then run `git push -u origin main`. |
| ACF PRO install failed (`401` / authentication required) | Check the licence key, and that the site URL is one the licence is **activated** for, including `https://`. Or install it from the zip ([Option B](#option-b-zip-file)). |
| ACF PRO installed but the licence isn't active | Check that `ACF_PRO_LICENSE` is in `.env`, `docker-compose.yml` and `wp-config.php` (see [ACF PRO licence](#acf-pro-licence)), then run `docker compose up -d wordpress` and open wp-admin. Or enter the key in **ACF → Updates**. |

---

## Security notes

- **Never commit `.env` or `certs/`.** The script stops and asks if they aren't in `.gitignore`.
- **Don't store GitHub tokens or passwords in plain-text notes or in git URLs.** If a token has been exposed, revoke it in **GitHub → Settings → Developer settings → Personal access tokens**.
- For GitHub access, use SSH keys (`git@github.com:...`) or the GitHub CLI (`gh auth login`), which keeps your credentials securely.
- The script prints the generated passwords at the end so you can save them in your password manager. It **never** prints the ACF PRO licence key.
- The ACF PRO licence key is saved only in `.env`. During the install, it's passed only to the temporary `composer` container.
- Each project gets its own WordPress salts in `.env`. Generate a new set for each server environment, and remove the hardcoded fallbacks from `wp-config.php.example` (see [WordPress salts](#wordpress-salts)).
