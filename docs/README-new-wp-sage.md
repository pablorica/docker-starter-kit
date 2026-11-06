# new-wp-sage.sh — New WordPress + Sage project on Docker

`new-wp-sage.sh` sets up a new local WordPress site that runs on Docker and uses a theme based on [Sage](https://github.com/roots/sage). It follows the same steps as the manual installation, using `~/Dockers/default` as the template project. Before it does anything, it asks you for every value that changes from one project to the next.

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [What the script asks](#what-the-script-asks)
- [What the script does](#what-the-script-does)
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
  `.env.example`, `docker-compose.wordpress.yml`, `docker-compose.wordpress.remote.yml`, `Caddyfile.sage.example`, `uploads.ini.example`, `wp-config.php.example`, `.editorconfig.example`, `.gitignore.example`, `nginx.conf.staging`, the `docker_sage/` folder, `docs/SAGE.md`, `docs/PostCSS.md`, `docs/ALPINE.md` and the custom Vite config at `wordpress/wp-content/themes/codigo/vite.config.js`.
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

Variable names: `DOCKERS_DIR`, `TEMPLATE_DIR`, `PROJECT`, `SITE_TITLE`, `THEME`, `SSL_PORT`, `PMA_PORT`, `NODE_PORT`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `PROD_DOMAIN`, `DO_WP_INSTALL` (y/n), `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`, `WP_ADMIN_EMAIL`, `SAGE_VERSION`, `DO_GIT` (y/n), `GITHUB_ORG`, `GITHUB_REPO`, `START_NODE` (y/n).

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
| Sage version constraint | blank = latest stable | Pins a Sage version if needed, e.g. `11.*` |
| Push to GitHub? | yes | Connects the project to a repository |
| GitHub user/organisation | `pablorica` | Builds the suggested repository URL |
| Repository URL | `git@github.com:<org>/<slug>.git` | `origin` remote |
| Start Node dev server at the end? | yes | Runs `docker compose --profile dev up node` |

The script warns you when a port is already in use. Passwords can't contain a single quote (`'`).

**Example ports** (Skelly & Couch): SSL `8465`, phpMyAdmin `8565`, Node `5265`.

---

## What the script does

1. **Pre-flight checks.** It checks that docker, docker compose, mkcert, git and perl are installed and that Docker is running. It also checks that every template file exists and that the project folder doesn't exist yet or is empty.
2. **Project folder and SSL certificates.** It creates `~/Dockers/<slug>/certs` and runs `mkcert` for `<slug>.localhost` and `pma.<slug>.localhost`.
3. **Copies the template files** from `~/Dockers/default`, renaming them (e.g. `Caddyfile.sage.example` becomes `Caddyfile`). This includes the Sage runbook (`docs/SAGE.md`), the custom CSS guide (`docs/PostCSS.md`) and the Alpine.js guide (`docs/ALPINE.md`).
4. **Creates `.env`** from `.env.example`:
   - replaces `default` with the slug and `template` with the theme name
   - replaces ports `8443`, `8081` and `5173` with the new ones
   - sets `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `WORDPRESS_THEMENAME` and `CADDY_PRODUCTION_DOMAIN`
   - writes passwords in single quotes, so characters like `$`, `&` and `%` work. Docker Compose would otherwise read `$m` as a variable.
5. **Starts Docker.** It pulls the images, then starts `mysql`, `wordpress`, `phpmyadmin` and `caddy` (Caddy is in the `dev` profile, so it's started by name). Then it waits until MySQL accepts the WordPress database user.
6. **Installs WordPress** (optional). It uses the `wpcli` service to run `wp core install` and set **Discourage search engines** (`blog_public = 0`). If this fails, it tells you to finish the install in the browser.
7. **Installs Sage with Composer.** It removes any existing `wordpress/wp-content/themes/<theme>` folder, then runs `composer create-project roots/sage <theme>` through the `composer` service, as your user so the files aren't owned by root. This installs the latest stable Sage (or your version constraint) **and** `vendor/` in one step. Then it removes any Sage developer files that are left (`.github`, `.editorconfig`, `.gitattributes`, `.gitignore`) and replaces Sage's default `vite.config.js` with the custom one from the template project. That one reads `APP_URL`, `NODE_PORT`, `VITE_PATH` and the other variables set in `docker-compose.yml` (see `docs/SAGE.md`). It uses `sudo` only if a file belongs to the container user.
8. **Activates the theme** with the `wpcli` service.
9. **GitHub** (optional):
    - runs `git init` and adds the remote
    - if the repository already has commits (e.g. a LICENSE), adopts its history and adds any files that are missing locally, without overwriting your files
    - stops and asks before committing if `.env` or `certs/local-key.pem` isn't ignored by `.gitignore`
    - commits and runs `git push -u origin <branch>`
10. **Summary.** It prints the URLs and credentials, then starts the Node dev server in the foreground (stop it with `Ctrl+C`).

If a command fails, the script stops and shows the line that failed.

---

## Personal defaults

The top of the script has a block of personal defaults. These are the values offered when you press Enter:

```bash
DEFAULT_DOCKERS_DIR="$HOME/Dockers"
DEFAULT_THEME="codigo"
DEFAULT_WP_USER="pablo.rica"
DEFAULT_WP_EMAIL="pablo@codigo.co.uk"
DEFAULT_GITHUB_ORG="pablorica"
SAGE_REPO="https://github.com/roots/sage.git"

# Ports in .env.example that get replaced per project
TPL_SSL_PORT=8443
TPL_PMA_PORT=8081
TPL_NODE_PORT=5173
```

If you add or rename files in `~/Dockers/default`, update the `TEMPLATE_FILES` list in the same block. Subfolders such as `docs/` are created automatically.

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
cp ../default/.gitignore.example .gitignore
cp ../default/nginx.conf.staging nginx.conf.staging
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

### 3. GitHub

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

---

## Security notes

- **Never commit `.env` or `certs/`.** The script stops and asks if they aren't in `.gitignore`.
- **Don't store GitHub tokens or passwords in plain-text notes or in git URLs.** If a token has been exposed, revoke it in **GitHub → Settings → Developer settings → Personal access tokens**.
- For GitHub access, use SSH keys (`git@github.com:...`) or the GitHub CLI (`gh auth login`), which keeps your credentials securely.
- The script prints the generated passwords at the end so you can save them in your password manager.
