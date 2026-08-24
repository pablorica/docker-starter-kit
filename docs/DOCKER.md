
# 1. Install Docker Desktop (Mac)

1. Download **Docker Desktop for Mac** (Apple Silicon vs Intel) and install it.
2. Open Docker Desktop once so it finishes setup.
3. Verify in Terminal:

   ```bash
   docker --version
   docker compose version
   ```

# 2. Make a WordPress project

Open Terminal and run:

```bash
cd ~/Dockers
mkdir default && cd default
```

## Use a `.env` file for secrets and a  `docker-compose.yml` file for configuration

1. Create `.env` in the same folder:

```env
MYSQL_DATABASE=default
MYSQL_USER=<your-user>
MYSQL_PASSWORD=<your-user-password>
MYSQL_ROOT_PASSWORD=<root-password>
WORDPRESS_PORT=8451
WORDPRESS_SSL_PORT=8451
WORDPRESS_TABLE_PREFIX=wpfh_
WORDPRESS_HOME=https://default.localhost

```

2. Create `docker-compose.yml` referencing `.env`:

```yaml
services:
  db:
    image: mysql:8.0.36
    command: --default-authentication-plugin=mysql_native_password
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    healthcheck: 
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 5s
      timeout: 3s
      retries: 20

  wordpress:
    image: wordpress:6.9.1-php8.2-apache
    depends_on:
      db:
        condition: service_healthy
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_HOME: ${WORDPRESS_HOME}
      WORDPRESS_SSL_PORT: ${WORDPRESS_SSL_PORT}
    volumes:
      - ./wp_data:/var/www/html
      - ./wp-config.php:/var/www/html/wp-config.php:ro   
      - ./logs:/var/www/html/logs
      - ./backups:/var/www/html/backups
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
    restart: unless-stopped

  phpmyadmin:
    image: phpmyadmin:5.2
    depends_on:
      - db
    environment:
      PMA_HOST: db
      PMA_USER: root
      PMA_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    restart: unless-stopped

  wpcli:             
    image: wordpress:cli-2.10.0-php8.2
    depends_on: [db, wordpress]
    working_dir: /var/www/html
    user: "www-data"                  
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_HOME: ${WORDPRESS_HOME}
      WORDPRESS_SSL_PORT: ${WORDPRESS_SSL_PORT}
    volumes:
      - ./wp_data:/var/www/html
      - ./wp-config.php:/var/www/html/wp-config.php:ro   
      - ./backups:/var/www/html/backups
    entrypoint: ["wp"]                  

volumes:
  db_data:
```

# 3. Start the stack

From the `~/Dockers/default` folder:

```bash
docker compose pull
# Pull latest images
docker compose up -d
```


## Prove credentials work directly in MySQL

Run the query inside the DB container:

```bash
# Simple ping
docker compose exec db mysqladmin ping -uroot -p

# Try logging in as the WP user
docker compose exec db mysql -u<your-user> -p -e "SELECT 1;" default
```

### If any of those commnads triggers an error

1) Create/grant the user for non‑localhost connections

```bash
# Run these as root in the DB container:
docker compose exec db mysql -uroot -p -e "
CREATE DATABASE IF NOT EXISTS default CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'pablo'@'%' IDENTIFIED WITH caching_sha2_password BY 'REPLACE_ME';
GRANT ALL PRIVILEGES ON default.* TO 'pablo'@'%';
FLUSH PRIVILEGES;"
```

**Why '%'?** WordPress connects over the Docker network (not via MySQL’s local socket), so MySQL sees the client as something like 172.18.0.x—not localhost. Granting 'pablo'@'%' covers that.

If you still hit auth errors, switch the auth plugin for compatibility:

```bash
docker compose exec db mysql -uroot -p -e "
ALTER USER 'pablo'@'%' IDENTIFIED WITH mysql_native_password BY 'REPLACE_ME';
FLUSH PRIVILEGES;"
```



## Use a pretty local domain like `default.localhost` instead of `localhost:8451`

Map ports 8451 and 80 and set the site URL in `Caddyfile`


```bash
# Main site over HTTPS on 8451 using your mkcert files
# Wordpress
https://default.localhost:8451 {
  tls /etc/caddy/certs/default.localhost.pem /etc/caddy/certs/default.localhost-key.pem
  encode zstd gzip

  # Everything else → WordPress
  reverse_proxy wordpress:80
}

# phpMyAdmin
https://pma.default.localhost:8451 {
	tls /etc/caddy/certs/default.localhost.pem /etc/caddy/certs/default.localhost-key.pem
  encode zstd gzip
	# Everything else → phpMyAdmin
	reverse_proxy phpmyadmin:80
}
```


Update `WP_HOME`  and `WP_SITEURL` service in `wp-config.php`:

```php
// Site URLs (override via env if you want)
$port = getenv('WORDPRESS_SSL_PORT') ?: '443';
$baseHome = getenv('WORDPRESS_HOME') ?: 'https://wordpress.localhost';
// If baseHome already includes a port, don't double-append.
// (Simple check: if ":" appears after "https://", assume port present.)
$hasPort = preg_match('#^https?://[^/]+:\d+#', $baseHome) === 1;
$wphome = $hasPort ? $baseHome : ($baseHome . ":$port");
// $wphome = getenv('WORDPRESS_HOME') ? getenv('WORDPRESS_HOME').":$port" : "https://wordpress.localhost:$port";


define('WP_HOME',    $wphome);
define('WP_SITEURL', $wphome);
define('FORCE_SSL_ADMIN', true);
```

Then:

```bash
docker compose up -d --force-recreate
```

Visit: `http://default.localhost:8451`

> If port 8451 is busy, either free it (`sudo lsof -i :8451`) or keep your old port and use Option 1.



# 4 Finish WordPress setup

* Open **[http://default.localhost:8451](http://default.localhost:8451)** → choose language, site title, admin user/password.
* Optional DB UI: **[http://default.localhost:8081](http://default.localhost:8081)** (phpMyAdmin).

  * Server: `db`
  * User: `root`
  * Password: from `.env` (`MYSQL_ROOT_PASSWORD`)



# 5 Where your data lives

* **WordPress files** (plugins/themes/uploads): volume `wp_data`
* **MySQL data**: volume `db_data`
  Volumes are managed by Docker, so your data survives `docker compose down`.


# 6 Backups (quick + reliable)

From the project folder:

```bash
# Database dump to a file
docker compose exec db sh -c 'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > ./backup.sql

# WordPress files (zip)
docker run --rm -v wordpress-docker_wp_data:/data -v "$PWD":/backup busybox sh -c 'cd /data && tar czf /backup/wp_files.tgz .'
```

You’ll get `backup.sql` and `wp_files.tgz` in your project folder.

# 7 Enable SSL

Add a tiny reverse proxy (Caddy) that terminates HTTPS using a local, trusted cert from **mkcert**.

## 1 Create and trust a local certificate for Wordpress & phpMyAdmin

Terminal on your Mac:

```bash
brew install mkcert nss     # nss helps Firefox trust the cert too
mkcert -install

cd ~/Dockers/default
mkdir -p ./certs
mkcert -cert-file ./certs/default.localhost.pem \
       -key-file  ./certs/default.localhost-key.pem \
       default.localhost pma.default.localhost

Created a new certificate valid for the following names 📜
 - "default.localhost"
 - "pma.default.localhost"

The certificate is at "./certs/default.localhost.pem" and the key at "./certs/default.localhost-key.pem" ✅

It will expire on 15 November 2027 🗓
```

## 2 Add Caddy to your `docker-compose.yml`

Add this new service (keep the rest of your file as-is). You can use non-standard ports.

```yaml
services:
  # ... your existing db, wordpress, phpmyadmin

  caddy:
    image: caddy:2
    restart: unless-stopped
    depends_on:
      - wordpress
      - phpmyadmin
    ports:
      # - "80:80"
      # - "443:443"
      # - "${WORDPRESS_PORT}:${WORDPRESS_PORT}"   # optional HTTP listener for redirect
      - "${WORDPRESS_SSL_PORT}:${WORDPRESS_SSL_PORT}"   # HTTPS on custom port
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./certs:/etc/caddy/certs:ro
```

### Update WordPress URLs to HTTPS

Change your `$wphome` variable so WordPress knows it lives at **https**:

```php
// Site URLs (override via env if you want)
$port = getenv('WORDPRESS_SSL_PORT') ?: '443';
$baseHome = getenv('WORDPRESS_HOME') ?: 'https://wordpress.localhost';
// If baseHome already includes a port, don't double-append.
// (Simple check: if ":" appears after "https://", assume port present.)
$hasPort = preg_match('#^https?://[^/]+:\d+#', $baseHome) === 1;
$wphome = $hasPort ? $baseHome : ($baseHome . ":$port");
// $wphome = getenv('WORDPRESS_HOME') ? getenv('WORDPRESS_HOME').":$port" : "https://wordpress.localhost:$port";


define('WP_HOME',    $wphome);
define('WP_SITEURL', $wphome);
define('FORCE_SSL_ADMIN', true);

```


## 3 Create a `Caddyfile` (next to your compose file)

```caddy
# Optional: HTTP on 8451 → redirect to HTTPS:8448
# http://default.localhost:8451 {
#  redir https://default.localhost:8448{uri}
# }

# Main site over HTTPS on 8448 using your mkcert files
https://default.localhost:8448 {
  tls /etc/caddy/certs/default.localhost.pem /etc/caddy/certs/default.localhost-key.pem
  encode zstd gzip
  # Everything else → WordPress
  reverse_proxy wordpress:80
}

https://pma.default.localhost:8448 {
  tls /etc/caddy/certs/default.localhost.pem /etc/caddy/certs/default.localhost-key.pem
  encode zstd gzip
  # Everything else → phpMyAdmin
  reverse_proxy phpmyadmin:80
}
```

Now phpMyAdmin will be at `https://pma.default.localhost:8448`.

## 4 Clean restart to free the port

```bash
# bring the stack down
docker compose down

# see who still holds 8448 (container or app)
docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Ports}}' | grep 8448 || true
lsof -iTCP:8448 -sTCP:LISTEN || true  # if some local app grabbed it

# if you see a container, stop it:
# docker stop <ID-or-NAME>

# back up with the fixed compose ( Bring it up)
docker compose up -d --force-recreate
```

Visit: **[https://default.localhost:8448](https://default.localhost:8448)** ✅

# 8) Further Wordpress configuration

## Add a error log file

You can create log files to be stored at **`/var/www/html/logs/error.log`**. And to read those fils we will nount a host folder for logs

###  Mount a host folder for logs

Bind-mount a local `./logs` dir and log there, so you can open the file in your editor.

* In `docker-compose.yml` (wordpress → volumes):

```yaml
volumes:
  - wp_data:/var/www/html
  - ./logs:/var/www/html/logs
```

###  Add log files to your WP configuration

* In `docker-compose.yml` (wordpress → WORDPRESS_CONFIG_EXTRA):

```php
ini_set('log_errors',TRUE);
ini_set('error_reporting', E_ALL);
ini_set('error_log', dirname(__FILE__) . '/logs/error.log');
```

###  Then read locally:

```bash
open ./logs/error.log
```

### WordPress-style debug log (alternative)

Instead of `ini_set`, you can use WP’s built-ins (logs to `wp-content/debug.log`):

```php
define('WP_DEBUG', true);
define('WP_DEBUG_DISPLAY', false);   // keep errors off the screen
define('WP_DEBUG_LOG', true);        // => /var/www/html/wp-content/debug.log
```

You can enable it adding this to `.env`

```bash
WORDPRESS_DEBUG=true
```

Read it with:

```bash
docker compose exec wordpress sh -lc 'tail -n 100 /var/www/html/wp-content/debug.log'
```


### Also useful: web server logs

Apache logs still go to the container’s stderr/stdout:

```bash
docker compose logs -f wordpress
```

### Notes

* The log file will appear only **after the first error happens**.
* If you ever see “Permission denied” when logging to a bind-mounted dir, fix ownership:

```bash
docker compose exec -u root wordpress chown -R www-data:www-data /var/www/html/logs
```
* Avoid defining the same constant twice: if you use `WP_DEBUG_LOG`, you can drop the `ini_set('error_log', ...)` (or vice-versa).


# 9) Add WP-CLI

Add a **wp-cli container** to your compose stack:


**1) Update `docker-compose.yml`**

```yaml
services:
  # ... db, wordpress, phpmyadmin, caddy (unchanged)

  wpcli:
    image: wordpress:cli                # official image with WP-CLI
    depends_on: [db, wordpress]
    working_dir: /var/www/html
    user: "www-data"                    # avoid root-owned files
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_HOME: ${WORDPRESS_HOME}
      WORDPRESS_SSL_PORT: ${WORDPRESS_SSL_PORT}
    volumes:
      - wp_data:/var/www/html
      - ./wp-content/themes/codigo:/var/www/html/wp-content/themes/codigo
      - ./wp-content/plugins:/var/www/html/wp-content/plugins
      - ./backups:/var/www/html/backups
    entrypoint: ["wp"]                  # so `docker compose run wpcli <cmd>` runs `wp <cmd>`
```

> No ports needed; it just shares the same files and DB as your `wordpress` service.

**2) Use it**

```bash
# Info & versions
docker compose run --rm wpcli --info
docker compose run --rm wpcli core version

# Plugins/themes
docker compose run --rm wpcli plugin list
docker compose run --rm wpcli plugin install query-monitor --activate

# DB export/import
docker compose run --rm wpcli db export /var/www/html/wp-content/db-backup.sql
docker compose cp wordpress:/var/www/html/wp-content/db-backup.sql ./db-backup.sql

# Search-replace (dry run first!)
docker compose run --rm wpcli search-replace \
  'http://default.localhost:8451' \
  'https://default.localhost:8448' \
  --all-tables --precise --dry-run
```

Tips:

* If you see a permissions warning, keep `user: "www-data"`.
* You can omit `WP_HOME/SITEURL` envs; they just help some commands.

# 10) Increase uploads limits


Tthe "Maximum upload file size: 2 MB" message in WordPress isn’t really about Docker itself, it’s about **PHP and web server configuration inside your container**. By default, PHP (used by WordPress) limits uploads to 2 MB. You need to raise that limit.


### Steps if you’re using `docker-compose` with `wordpress` official image

Add a custom `.ini` file into `/usr/local/etc/php/conf.d/`:

First create the file in your root:

```bash
cd ~/Dockers/default
echo "upload_max_filesize = 64M
post_max_size = 64M
memory_limit = 256M" > uploads.ini
```

Then mount it editing `docker-compose.yml`

```yaml
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini
```

### If using **nginx** as reverse proxy

Also check your `nginx.conf` (inside container or custom config):

```nginx
server {
    client_max_body_size 64M;
}
```

Without this, Nginx may still block uploads bigger than 2M even if PHP is configured.


### Restart containers

After changes, restart:

```bash
docker compose down
docker compose up -d
```


# 10) Common gotchas

* **Port already in use**: change `WORDPRESS_PORT` (e.g., 8082) or in compose `ports: - "8082:80"`.
* **Apple Silicon (M1/M2)**: these images are multi-arch; no special flags needed.
* **File permissions**: macOS is permissive via Docker Desktop; if a plugin can’t write, try restarting containers:
  `docker compose restart` (rare with this setup).
* **Email from WordPress** (password resets, etc.): add an SMTP plugin later (e.g., WP Mail SMTP) and use your provider’s SMTP creds.

* **SSL**
* If Firefox complains about trust, run `mkcert -install` after installing `nss` (done above).
* If port 443 is in use: `sudo lsof -i :443` to see the blocker, stop it, then retry.
* If you previously visited the HTTP site (8451), some content URLs might still be `http://…`. Either:

  * keep the 8451 port until you’ve saved permalinks once under HTTPS, or
  * run a quick search/replace later (e.g., WP-CLI or a plugin) to update old content URLs.



# 11) Repository

**Commit both** your code **and** the Docker setup. Treat the stack as *infrastructure as code* so your staging server can run the exact same containers with one command.

## What to put in Git


* `docker-compose.yml` (and any `compose.*.yml` overrides)
* Any `Dockerfile`s, reverse-proxy config (e.g. `Caddyfile`/`traefik.yml`)
* `wp-content/` (your **themes**, **plugins**, **mu-plugins** only)
* `README.md`, deploy scripts

**Do NOT commit:**

* Secrets (`.env`) → commit a **`.env.example`** instead
* Database dumps, uploads, or named volumes
* WordPress core files (they come from the image)
* Cache/transients/logs

## Suggested repo layout

```
default/
  docker-compose.yml
  compose.staging.yml          # optional override for staging
  .env.example                 # sample vars, no secrets
  wp-content/
    themes/your-theme/
    plugins/your-plugin/
    mu-plugins/
  reverse-proxy/               # optional (Caddy/Traefik)
    Caddyfile
  README.md
  .gitignore
```

**`.gitignore` (minimal)**

```
.env
wp-content/uploads/
*.sql
*.tgz
.DS_Store
vendor/                      
```

## Tip for local dev: bind-mount your code

Keep WordPress core in a Docker volume, but bind-mount your theme/plugin so edits are tracked by Git:

```yaml
wordpress:
  volumes:
    - wp_data:/var/www/html
    - ./wp-content/themes/your-theme:/var/www/html/wp-content/themes/your-theme
    - ./wp-content/plugins/your-plugin:/var/www/html/wp-content/plugins/your-plugin
```

## Staging on DigitalOcean (Docker Compose)

1. Install Docker & Compose on the droplet.
2. `git clone` your repo to the server.
3. Copy `.env.example` → `.env` and fill **staging** values (DB passwords, domain).
4. Start it:

```bash
docker compose -f docker-compose.yml -f compose.staging.yml up -d
```

### Optional: easy HTTPS with a tiny reverse proxy

Add Caddy (auto-TLS via Let’s Encrypt):

```yaml
services:
  caddy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes:
      - ./reverse-proxy/Caddyfile:/etc/caddy/Caddyfile
    depends_on: [wordpress]
```

`Caddyfile`:

```
your-staging-domain.com {
  reverse_proxy wordpress:80
}
```

## Why this setup?

* Reproducible: dev == staging (same images, same env).
* Safer: no secrets in Git, no DB/uploads bloat.
* Portable: spin up anywhere with `docker compose up -d`.

If you want, tell me your theme/plugin paths and I’ll spit out a tailored `docker-compose.yml`, `compose.staging.yml`, and `.env.example` you can drop into your repo.


---


# Working with Wordpress Safge: Dev Environment Changes (Docker + Vite + Sage)

To make **Sage (Vite) development work inside Docker with HTTPS**, we introduced a dedicated **Node service** and updated the **Caddy reverse proxy**.

## 1. Added `node` service to `docker-compose.yml`

Purpose:

* Run **Vite dev server inside Docker** instead of the host OS.
* Ensure the same **Node environment for all developers and CI**.
* Allow the Vite server to access the project files via mounted volumes.

Key points:

* Uses `node:20-alpine`.
* Runs `npm run dev -- --host 0.0.0.0` so Vite is reachable from other containers.
* Exposes port **5173** internally for Caddy to proxy.
* Allows running builds with:

```bash
docker compose run --rm node npm run build
```

Benefits:

* No dependency on the developer's local Node installation.
* Consistent builds across environments.
* Easier CI/CD integration.


## 2. Updated `vite.config.js`

Purpose:

* Ensure Vite works behind HTTPS and Docker networking.

Changes:

* Added `server` configuration for HMR and Docker compatibility.

Key settings:

* `host: 0.0.0.0` → allows access from other containers.
* `origin: https://projecturl:port` → correct URL written to the Vite `hot` file.
* `hmr` configured to use `wss` and the correct hostname.

Benefits:

* Prevents incorrect `0.0.0.0` URLs in `public/hot`.
* Enables Hot Module Reloading through HTTPS.


## 3. Updated `Caddyfile`

Purpose:

* Proxy **Vite dev assets and WebSocket connections** through the same HTTPS origin as WordPress.

Added reverse proxy routes:

* Proxy Vite asset requests:

```
/wp-content/themes/sagefolder/public/build/*
```

* Proxy Vite HMR WebSocket endpoint:

```
/_vite/ws
```

Both routes forward to:

```
node:5173
```

Benefits:

* Avoids **mixed-content errors** (HTTPS site loading HTTP assets).
* Allows **Vite HMR to work through Caddy and Docker**.
* Browser only communicates with the main HTTPS domain.


## 4. Development Workflow

Start environment:

```bash
docker compose up
```

Run Vite dev server:

* Automatically started in the **node container**.

Build production assets:

```bash
docker compose run --rm node npm run build
```

Commit generated assets:

```
wp_data/wp-content/themes/sagefolder/public/build
```


## Result

The development environment now provides:

* Docker-based Node/Vite execution
* HTTPS-compatible Vite dev server
* Working HMR through Caddy
* Reproducible builds independent of the host OS

---



# Useful commands

```bash
# See what’s running
docker compose ps

# Watch logs (Ctrl+C to stop viewing)
docker compose logs -f

# Restart just WordPress (after plugin/theme changes)
docker compose restart wordpress

# Stop everything
docker compose down

# Stop but KEEP data (volumes are preserved by default)
docker compose down

# Stop and DELETE data (careful!)
docker compose down -v

# Update images then recreate containers
docker compose pull && docker compose up -d

# Bring it up
docker compose up -d --force-recreate


# disable all plugins
docker compose run --rm wpcli plugin deactivate --all

# activate a default theme (if present)
docker compose run --rm wpcli theme activate twentytwentyfive

# clear caches
docker compose run --rm wpcli cache flush

# disable emoticons
docker compose run --rm wpcli option update use_smilies 0

# Read wp-config
docker compose exec wordpress sh -lc 'cat /var/www/html/wp-config.php'

# Verify php values inside the container
docker compose exec wordpress php -i | grep upload_max_filesize
docker compose exec wordpress php -i | grep post_max_size

# Quick reload after big changes
cd ~/Dockers/default
docker compose up -d --force-recreate

cd ~/Dockers/default/wp-content/themes/seadesign
npm run dist ## OR npm run watch

```