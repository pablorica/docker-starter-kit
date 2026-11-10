#!/usr/bin/env bash
#
# new-wp-sage.sh — scaffold a new local WordPress project on Docker (optionally
# with a Sage theme and ACF PRO), following the ~/Dockers/default template workflow.
#
# Usage:
#   ./new-wp-sage.sh
#
# Every question shows a default in [brackets]. Any question can be pre-answered
# by exporting its variable, e.g.:
#   PROJECT=skelly-couch SITE_TITLE="Skelly & Couch" ./new-wp-sage.sh
#
# Host requirements: docker (compose v2), mkcert (run `mkcert -install` once),
# git, perl. Composer and WP-CLI run through Docker (the `composer` and `wpcli`
# services in docker-compose.yml), so they don't need to be installed locally.

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Personal defaults — edit once
# ---------------------------------------------------------------------------
DEFAULT_DOCKERS_DIR="$HOME/Dockers"
DEFAULT_THEME="codigo"
DEFAULT_WP_USER="pablo.rica"
DEFAULT_WP_EMAIL="pablo@codigo.co.uk"
DEFAULT_GITHUB_ORG="pablorica"
SAGE_PACKAGE="roots/sage"

# Ports used in .env.example that get replaced per project
TPL_SSL_PORT=8443
TPL_PMA_PORT=8081
TPL_NODE_PORT=5173

# "source in template dir : destination in project dir"
TEMPLATE_FILES=(
  ".env.example:.env.example"
  "docker-compose.wordpress.yml:docker-compose.yml"
  "docker-compose.wordpress.remote.yml:docker-compose.remote.yml"
  "Caddyfile.sage.example:Caddyfile"
  "uploads.ini.example:uploads.ini"
  "wp-config.php.example:wp-config.php"
  ".editorconfig.example:.editorconfig"
  "gitignore.wordpress.example:.gitignore"
  "nginx.conf.staging:nginx.conf.staging"
  "apache.conf.staging:apache.conf.staging"
  "docker_sage:docker"
)

# Copied only when Sage is installed
SAGE_TEMPLATE_FILES=(
  "docs/SAGE.md:docs/SAGE.md"
  "docs/PostCSS.md:docs/PostCSS.md"
  "docs/ALPINE.md:docs/ALPINE.md"
)

# Custom Vite config, copied into the new theme after Sage is installed
# (path relative to the template project folder)
TEMPLATE_VITE_CONFIG="wordpress/wp-content/themes/codigo/vite.config.js"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then B=$'\e[1m' G=$'\e[32m' Y=$'\e[33m' R=$'\e[31m' N=$'\e[0m'; else B='' G='' Y='' R='' N=''; fi
step() { printf '\n%s%s==> %s%s\n' "$B" "$G" "$*" "$N"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '%s[!] %s%s\n' "$Y" "$*" "$N" >&2; }
die()  { printf '%s[x] %s%s\n' "$R" "$*" "$N" >&2; exit 1; }
trap 'die "Command failed (line $LINENO): $BASH_COMMAND"' ERR

# ask VAR "Question" [default]   (skipped if VAR is already set in the environment)
ask() {
  local __v=$1 __q=$2 __d=${3:-} __a
  if [[ -n ${!__v:-} ]]; then info "$__q: ${!__v}"; return; fi
  read -rp "  $__q${__d:+ [$__d]}: " __a || true
  printf -v "$__v" '%s' "${__a:-$__d}"
}

# ask_yn VAR "Question" y|n
ask_yn() {
  local __v=$1 __q=$2 __d=${3:-y} __a __hint="y/N"
  [[ $__d == y ]] && __hint="Y/n"
  if [[ -n ${!__v:-} ]]; then return; fi
  read -rp "  $__q [$__hint]: " __a || true
  __a=${__a:-$__d}
  if [[ $__a =~ ^[Yy] ]]; then printf -v "$__v" y; else printf -v "$__v" n; fi
}

gen_pass() { { LC_ALL=C tr -dc 'A-Za-z0-9%^*_+=-' </dev/urandom || true; } | head -c 20; }
# 64-character WordPress salt (no quotes, $, \ or spaces, so it's safe in .env)
gen_salt() { { LC_ALL=C tr -dc 'A-Za-z0-9!#%+,./:;<=>?@^_~-' </dev/urandom || true; } | head -c 64; }
WP_SALT_KEYS=(AUTH_KEY SECURE_AUTH_KEY LOGGED_IN_KEY NONCE_KEY AUTH_SALT SECURE_AUTH_SALT LOGGED_IN_SALT NONCE_SALT)

# ask_secret VAR "Question"   (blank = generate)
ask_secret() {
  local __v=$1 __q=$2 __a __b
  if [[ -n ${!__v:-} ]]; then return; fi
  while :; do
    read -rsp "  $__q (blank = generate): " __a || true; echo
    if [[ -z $__a ]]; then __a=$(gen_pass); info "Generated: $__a"; break; fi
    if [[ $__a == *"'"* ]]; then warn "Single quotes (') aren't allowed."; continue; fi
    read -rsp "  Repeat: " __b || true; echo
    [[ $__a == "$__b" ]] && break
    warn "They didn't match, try again."
  done
  printf -v "$__v" '%s' "$__a"
}

# ask_hidden VAR "Question"   (required, typing hidden, no generation; skipped if VAR is set)
ask_hidden() {
  local __v=$1 __q=$2 __a
  if [[ -n ${!__v:-} ]]; then info "$__q: (taken from the environment)"; return; fi
  while :; do
    read -rsp "  $__q: " __a || true; echo
    if [[ -z $__a ]]; then warn "Required."; continue; fi
    if [[ $__a == *"'"* || $__a == *'"'* ]]; then warn "Quotes aren't allowed."; continue; fi
    break
  done
  printf -v "$__v" '%s' "$__a"
}

port_in_use() { (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; }

# wait_for "description" timeout_seconds cmd...
wait_for() {
  local desc=$1 timeout=$2; shift 2
  local t=0
  printf '    Waiting for %s' "$desc"
  until "$@" >/dev/null 2>&1; do
    (( t >= timeout )) && { echo " timed out"; return 1; }
    printf '.'; sleep 2; (( t += 2 ))
  done
  echo " ok"
}

# .env editing (perl + env vars, so passwords with & % $ are safe)
env_replace_all()  { FROM=$1 TO=$2 perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g' .env; }
env_replace_port() { FROM=$1 TO=$2 perl -pi -e 's/(?<!\d)\Q$ENV{FROM}\E(?!\d)/$ENV{TO}/g' .env; }
set_env() { # set_env KEY VALUE [quote]
  if ! grep -q "^$1=" .env; then warn "$1 not found in .env — set it manually."; return 0; fi
  local v=$2; [[ ${3:-} == quote ]] && v="'$v'"
  K=$1 V=$v perl -pi -e 's/^\Q$ENV{K}\E=.*/$ENV{K}=$ENV{V}/' .env
}
get_env() { sed -n "s/^$1=//p" .env | tail -n1 | sed -e "s/^['\"]//" -e "s/['\"]\$//"; }
# file_replace FILE FROM TO   (literal text, safe for any characters)
file_replace() { FROM=$2 TO=$3 perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g' "$1"; }

# Run a command, retry with sudo if it fails (theme folder may be owned by www-data)
sudo_if_needed() { "$@" 2>/dev/null || { warn "Retrying with sudo: $*"; sudo "$@"; }; }

dc() { docker compose "$@"; }
# WP-CLI through the `wpcli` service (runs as www-data, entrypoint = wp)
wp() { dc run --rm -T wpcli "$@"; }
# Composer through the `composer` service, as your user (no root-owned files)
composer_run() {
  dc --profile tools run --rm -T --user "$(id -u):$(id -g)" \
    -e COMPOSER_HOME=/tmp/composer "$@"
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
for cmd in docker git mkcert perl; do
  command -v "$cmd" >/dev/null || die "'$cmd' is not installed."
done
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 ('docker compose') is required."
docker info >/dev/null 2>&1 || die "Docker isn't running."

# ---------------------------------------------------------------------------
# Questions
# ---------------------------------------------------------------------------
step "Project configuration"
while :; do
  ask PROJECT "New project slug (folder + local domain, e.g. skelly-couch)"
  [[ $PROJECT =~ ^[a-z0-9][a-z0-9-]*$ ]] && break
  warn "Use lowercase letters, numbers and hyphens only."; PROJECT=''
done

ask DOCKERS_DIR "Folder where your Docker projects live" "$DEFAULT_DOCKERS_DIR"
DOCKERS_DIR=${DOCKERS_DIR/#\~/$HOME}
while :; do
  ask TEMPLATE_DIR "Template project to copy files from (press Enter for the default)" "$DOCKERS_DIR/default"
  TEMPLATE_DIR=${TEMPLATE_DIR/#\~/$HOME}
  # A bare name like "default" means a folder inside the Dockers folder
  [[ $TEMPLATE_DIR == /* ]] || TEMPLATE_DIR="$DOCKERS_DIR/$TEMPLATE_DIR"
  [[ -d $TEMPLATE_DIR ]] && break
  warn "Template folder not found: $TEMPLATE_DIR"; TEMPLATE_DIR=''
done
ask SITE_TITLE "Site title" "$PROJECT"
while :; do
  ask THEME "Theme folder name" "$DEFAULT_THEME"
  [[ $THEME =~ ^[a-z0-9][a-z0-9_-]*$ ]] && break
  warn "Use lowercase letters, numbers, - or _ only."; THEME=''
done

# Suggest ports: next SSL port after the highest one used by existing projects
# (strip inline comments and quotes first: "8443   # all 3 vhosts…" must read as 8443)
last_ssl=$(grep -hs '^WORDPRESS_SSL_PORT=' "$DOCKERS_DIR"/*/.env 2>/dev/null \
  | cut -d= -f2 | sed 's/#.*//' | tr -dc '0-9\n' \
  | awk '$1 >= 1 && $1 <= 65535' | sort -n | tail -n1 || true)
sug_ssl=$(( ${last_ssl:-$TPL_SSL_PORT} + 1 ))
ask SSL_PORT  "WordPress SSL port (WORDPRESS_SSL_PORT)" "$sug_ssl"
ask PMA_PORT  "phpMyAdmin port (PHPMYADMIN_PORT)"       "$(( SSL_PORT + 100 ))"
ask NODE_PORT "Node/Vite port (NODE_PORT)"              "$(( SSL_PORT - 3200 ))"
for p in "$SSL_PORT" "$PMA_PORT" "$NODE_PORT"; do
  [[ $p =~ ^[0-9]+$ ]] && (( p >= 1 && p <= 65535 )) || die "Invalid port: $p"
  port_in_use "$p" && warn "Port $p looks busy on this machine."
done

ask_secret MYSQL_PASSWORD      "MySQL password for the WordPress DB user"
ask_secret MYSQL_ROOT_PASSWORD "MySQL root password"
while :; do
  ask PROD_DOMAIN "Production domain (CADDY_PRODUCTION_DOMAIN, e.g. beta.$PROJECT.tm-studio.co.uk)"
  [[ $PROD_DOMAIN =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && break
  warn "Enter a domain like example.com (no https://)."; PROD_DOMAIN=''
done

ask_yn DO_WP_INSTALL "Install WordPress automatically (WP-CLI)?" y
if [[ $DO_WP_INSTALL == y ]]; then
  ask WP_ADMIN_USER  "WP admin user"  "$DEFAULT_WP_USER"
  ask_secret WP_ADMIN_PASSWORD "WP admin password"
  ask WP_ADMIN_EMAIL "WP admin email" "$DEFAULT_WP_EMAIL"
fi

ask_yn DO_SAGE "Install the Sage theme?" y
if [[ $DO_SAGE == y ]]; then
  ask SAGE_VERSION "Sage version constraint (blank = latest stable, e.g. 11.*)" ""
fi

ask_yn DO_ACF "Install ACF PRO?" y
if [[ $DO_ACF == y ]]; then
  ask_hidden ACF_PRO_LICENSE "ACF PRO licence key"
  ask ACF_LICENSE_URL "Site URL the licence is activated for (used to download ACF PRO)" "https://$PROD_DOMAIN"
fi

ask_yn DO_GIT "Push to a GitHub repository?" y
if [[ $DO_GIT == y ]]; then
  ask GITHUB_ORG  "GitHub user/organisation" "$DEFAULT_GITHUB_ORG"
  ask GITHUB_REPO "Repository URL (SSH recommended)" "git@github.com:$GITHUB_ORG/$PROJECT.git"
fi
# The Node/Vite dev server builds the Sage theme, so it's only offered with Sage
if [[ $DO_SAGE == y ]]; then
  ask_yn START_NODE "Start the Node dev server at the end?" y
else
  START_NODE=n
fi

# Files to copy for this project
COPY_FILES=("${TEMPLATE_FILES[@]}")
if [[ $DO_SAGE == y ]]; then COPY_FILES+=("${SAGE_TEMPLATE_FILES[@]}"); fi

PROJECT_DIR="$DOCKERS_DIR/$PROJECT"
SITE_URL="https://$PROJECT.localhost:$SSL_PORT"
PMA_URL="https://pma.$PROJECT.localhost:$SSL_PORT"

# Check template files before touching anything
for pair in "${COPY_FILES[@]}"; do
  [[ -e "$TEMPLATE_DIR/${pair%%:*}" ]] || die "Missing template file: $TEMPLATE_DIR/${pair%%:*}"
done
if [[ $DO_SAGE == y ]]; then
  [[ -f "$TEMPLATE_DIR/$TEMPLATE_VITE_CONFIG" ]] || die "Missing template file: $TEMPLATE_DIR/$TEMPLATE_VITE_CONFIG"
fi
if [[ -e $PROJECT_DIR ]] && [[ -n $(ls -A "$PROJECT_DIR" 2>/dev/null) ]]; then
  die "$PROJECT_DIR already exists and isn't empty."
fi

step "Summary"
cat <<EOF
    Folder        $PROJECT_DIR
    Site          $SITE_URL  ("$SITE_TITLE")
    phpMyAdmin    $PMA_URL
    Theme         $( [[ $DO_SAGE == y ]] && echo "$THEME (Sage ${SAGE_VERSION:-latest stable})" || echo "no Sage (folder name $THEME used in .env / .gitignore)" )
    Ports         SSL $SSL_PORT · PMA $PMA_PORT · Node $NODE_PORT
    Production    $PROD_DOMAIN
    WP install    $DO_WP_INSTALL${WP_ADMIN_USER:+ (user: $WP_ADMIN_USER, $WP_ADMIN_EMAIL)}
    ACF PRO       $DO_ACF
    GitHub        ${GITHUB_REPO:-no}
EOF
ask_yn GO "Continue?" y
[[ $GO == y ]] || die "Aborted."

# ---------------------------------------------------------------------------
# 1. Folder + SSL certificates
# ---------------------------------------------------------------------------
step "Creating project folder and SSL certificates"
mkdir -p "$PROJECT_DIR/certs"
cd "$PROJECT_DIR"
mkcert -cert-file ./certs/local.pem -key-file ./certs/local-key.pem \
  "$PROJECT.localhost" "pma.$PROJECT.localhost"

# ---------------------------------------------------------------------------
# 2. Copy template files
# ---------------------------------------------------------------------------
step "Copying files from $TEMPLATE_DIR"
for pair in "${COPY_FILES[@]}"; do
  src=${pair%%:*}; dst=${pair#*:}
  mkdir -p "$(dirname "$dst")"
  cp -R "$TEMPLATE_DIR/$src" "$dst"
  info "$src -> $dst"
done

# ---------------------------------------------------------------------------
# 3. .env
# ---------------------------------------------------------------------------
step "Creating .env"
cp .env.example .env
env_replace_all  "default"  "$PROJECT"
env_replace_all  "template" "$THEME"
env_replace_port "$TPL_SSL_PORT"  "$SSL_PORT"
env_replace_port "$TPL_PMA_PORT"  "$PMA_PORT"
env_replace_port "$TPL_NODE_PORT" "$NODE_PORT"
set_env WORDPRESS_SSL_PORT      "$SSL_PORT"
set_env PHPMYADMIN_PORT         "$PMA_PORT"
set_env NODE_PORT               "$NODE_PORT"
set_env MYSQL_PASSWORD          "$MYSQL_PASSWORD" quote
set_env MYSQL_ROOT_PASSWORD     "$MYSQL_ROOT_PASSWORD" quote
set_env WORDPRESS_THEMENAME     "$THEME"
set_env CADDY_PRODUCTION_DOMAIN "$PROD_DOMAIN"
if [[ $DO_ACF == y ]]; then
  # The licence key lives only in .env (which must stay out of git)
  if grep -q '^ACF_PRO_LICENSE=' .env; then
    set_env ACF_PRO_LICENSE "$ACF_PRO_LICENSE" quote
  else
    printf "\n# ACF PRO licence (never commit .env)\nACF_PRO_LICENSE='%s'\n" "$ACF_PRO_LICENSE" >> .env
  fi
fi
# Unique WordPress salts for this project (read by wp-config.php as WORDPRESS_*)
salts_added=n
for k in "${WP_SALT_KEYS[@]}"; do
  if grep -q "^WORDPRESS_$k=" .env; then
    set_env "WORDPRESS_$k" "$(gen_salt)" quote
  else
    [[ $salts_added == n ]] && printf '\n# WordPress salts (unique per project, never commit .env)\n' >> .env
    printf "WORDPRESS_%s='%s'\n" "$k" "$(gen_salt)" >> .env
    salts_added=y
  fi
done
info "Unique WordPress salts generated."
if ! grep -q 'WORDPRESS_AUTH_KEY' docker-compose.yml; then
  warn "docker-compose.yml doesn't pass WORDPRESS_AUTH_KEY… to WordPress, so the new salts won't be used."
  warn "Update the template (see 'WordPress salts' in AUTOMATED-SAGE-DOCKER-SETUP.md)."
fi

DB_USER=$(get_env MYSQL_USER || true)
DB_NAME=$(get_env MYSQL_DATABASE || true)
info "Done (DB user: ${DB_USER:-?}, DB name: ${DB_NAME:-?})"

# ---------------------------------------------------------------------------
# 3b. Staging server configs (Nginx / Apache)
# ---------------------------------------------------------------------------
# On the server, docker-compose.remote.yml publishes WordPress on 127.0.0.1:${WORDPRESS_SSL_PORT}
# and phpMyAdmin on 127.0.0.1:${PHPMYADMIN_PORT}, so the proxy uses the same two ports.
step "Filling in .gitignore, nginx.conf.staging and apache.conf.staging"
for conf in .gitignore nginx.conf.staging apache.conf.staging; do
  [[ -f $conf ]] || continue
  file_replace "$conf" "__THEME__"    "$THEME"
  file_replace "$conf" "__PROJECT__"  "$PROJECT"
  file_replace "$conf" "__DOMAIN__"   "$PROD_DOMAIN"
  file_replace "$conf" "__APP_PORT__" "$SSL_PORT"
  file_replace "$conf" "__PMA_PORT__" "$PMA_PORT"
  # __LIVE_DOMAIN__ (optional media offload in Apache) is left for you to fill in
  left=$(grep -o '__[A-Z_]*__' "$conf" | grep -v '__LIVE_DOMAIN__' | sort -u | tr '\n' ' ' || true)
  if [[ -n $left ]]; then
    warn "$conf still has placeholders: $left"
  elif [[ $conf == .gitignore ]]; then
    info "$conf: tracks the theme wordpress/wp-content/themes/$THEME/"
  else
    info "$conf: $PROD_DOMAIN -> 127.0.0.1:$SSL_PORT (phpMyAdmin $PMA_PORT)"
  fi
done

# ---------------------------------------------------------------------------
# 4. Docker stack
# ---------------------------------------------------------------------------
step "Starting Docker stack"
# caddy and node are in the "dev" profile. Start caddy (and the services it
# depends on) now; node starts at the end, once the theme exists.
dc --profile dev pull
dc --profile dev up -d mysql wordpress phpmyadmin caddy
dc --profile dev ps

db_ok() {
  if [[ -n $DB_USER && -n $DB_NAME ]]; then
    dc exec -T -e MYSQL_PWD="$MYSQL_PASSWORD" mysql mysql -u"$DB_USER" -e 'SELECT 1;' "$DB_NAME"
  else
    dc exec -T -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql mysqladmin ping -uroot --silent
  fi
}
wait_for "MySQL" 120 db_ok || die "MySQL didn't come up. Check: docker compose logs mysql"

# ---------------------------------------------------------------------------
# 5. WordPress install
# ---------------------------------------------------------------------------
WPCLI=n
if [[ $DO_WP_INSTALL == y ]]; then
  step "Installing WordPress"
  if wait_for "WordPress core files" 120 test -f "$PROJECT_DIR/wordpress/wp-includes/version.php"; then
    if wp core is-installed >/dev/null 2>&1; then
      info "WordPress is already installed."; WPCLI=y
    elif wp core install --url="$SITE_URL" --title="$SITE_TITLE" \
           --admin_user="$WP_ADMIN_USER" --admin_password="$WP_ADMIN_PASSWORD" \
           --admin_email="$WP_ADMIN_EMAIL" --skip-email; then
      WPCLI=y
    fi
    if [[ $WPCLI == y ]]; then
      wp option update blog_public 0 >/dev/null && info "Search engines discouraged."
    fi
  fi
  [[ $WPCLI == y ]] || warn "Automatic install failed — finish it in the browser: $SITE_URL"
fi

# ---------------------------------------------------------------------------
# 6. Sage theme
# ---------------------------------------------------------------------------
if [[ $DO_SAGE == y ]]; then
  step "Installing Sage as '$THEME'"
  THEMES_DIR="$PROJECT_DIR/wordpress/wp-content/themes"
  wait_for "themes folder" 60 test -d "$THEMES_DIR" || die "Not found: $THEMES_DIR"
  # create-project needs a missing or empty target folder
  sudo_if_needed rm -rf "${THEMES_DIR:?}/$THEME"
  # Runs in the themes folder; also installs vendor/ (no separate composer step needed)
  # shellcheck disable=SC2086
  composer_run -w /var/www/html/wp-content/themes composer \
    create-project --no-interaction "$SAGE_PACKAGE" "$THEME" ${SAGE_VERSION:+"$SAGE_VERSION"}
  # Remove Sage developer files, if present
  for f in .git .github .editorconfig .gitattributes .gitignore; do
    if [[ -e "$THEMES_DIR/$THEME/$f" ]]; then sudo_if_needed rm -rf "${THEMES_DIR:?}/$THEME/$f"; fi
  done
  # Replace Sage's default vite.config.js with our custom one (reads APP_URL, NODE_PORT, VITE_PATH…)
  sudo_if_needed cp "$TEMPLATE_DIR/$TEMPLATE_VITE_CONFIG" "$THEMES_DIR/$THEME/vite.config.js"
  info "Custom vite.config.js copied."

  if [[ $WPCLI == y ]]; then
    if wp theme activate "$THEME"; then :; else warn "Activate '$THEME' manually in wp-admin."; fi
  fi
else
  step "Skipping Sage (WordPress keeps its default theme)"
fi

# ---------------------------------------------------------------------------
# 6b. ACF PRO (official Composer repository, run in a throwaway folder
#     inside the composer container, then copied into wp-content/plugins)
# ---------------------------------------------------------------------------
if [[ $DO_ACF == y ]]; then
  step "Installing ACF PRO"
  read -r -d '' ACF_INSTALL_SH <<'SH' || true
set -e
rm -rf /tmp/acf && mkdir -p /tmp/acf && cd /tmp/acf
cat > composer.json <<'JSON'
{
  "repositories": [{ "type": "composer", "url": "https://connect.advancedcustomfields.com" }],
  "require": { "wpengine/advanced-custom-fields-pro": "*" },
  "extra": { "installer-paths": { "wp-content/plugins/{$name}/": ["type:wordpress-plugin"] } },
  "config": { "allow-plugins": { "composer/installers": true } }
}
JSON
composer update --no-interaction --no-progress
rm -rf /var/www/html/wp-content/plugins/advanced-custom-fields-pro
cp -R wp-content/plugins/advanced-custom-fields-pro /var/www/html/wp-content/plugins/
SH
  # Licence key = username, activated site URL = password (passed only to this container)
  ACF_AUTH=$(printf '{"http-basic":{"connect.advancedcustomfields.com":{"username":"%s","password":"%s"}}}' \
    "$ACF_PRO_LICENSE" "$ACF_LICENSE_URL")
  # Runs as www-data (33), the owner of wp-content in the WordPress image
  if dc --profile tools run --rm -T --user 33:33 \
       -e COMPOSER_HOME=/tmp/composer -e COMPOSER_AUTH="$ACF_AUTH" \
       --entrypoint sh composer -c "$ACF_INSTALL_SH"; then
    info "ACF PRO downloaded to wp-content/plugins/advanced-custom-fields-pro"
    if [[ $WPCLI == y ]]; then
      if wp plugin activate advanced-custom-fields-pro; then :; else warn "Activate ACF PRO manually in wp-admin."; fi
    fi
  else
    warn "ACF PRO install failed. Check the licence key and the activated site URL, or install it manually (see docs)."
  fi
  unset ACF_AUTH

  # Automatic licence activation needs ACF_PRO_LICENSE passed to WordPress
  if grep -q 'ACF_PRO_LICENSE' wp-config.php && grep -q 'ACF_PRO_LICENSE' docker-compose.yml; then
    info "Licence will be activated automatically from .env"
  else
    warn "ACF_PRO_LICENSE isn't wired into wp-config.php / docker-compose.yml, so the licence won't activate"
    warn "automatically. Enter it in ACF → Updates, or update the template files (see AUTOMATED-SAGE-DOCKER-SETUP.md)."
  fi
fi

# ---------------------------------------------------------------------------
# 7. GitHub
# ---------------------------------------------------------------------------
if [[ $DO_GIT == y ]]; then
  step "Connecting to GitHub: $GITHUB_REPO"
  git init -q
  git remote add origin "$GITHUB_REPO"
  BRANCH=$(git ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/{sub("refs/heads/","",$2); print $2}' || true)
  BRANCH=${BRANCH:-main}
  git symbolic-ref HEAD "refs/heads/$BRANCH"
  if git fetch -q origin "$BRANCH" 2>/dev/null; then
    # Adopt the remote history (e.g. LICENSE) without touching local files
    git reset -q "origin/$BRANCH"
    while IFS= read -r f; do
      [[ -e $f ]] || git checkout -q "origin/$BRANCH" -- "$f"
    done < <(git ls-tree -r --name-only "origin/$BRANCH")
  fi

  PUSH=y
  for secret in .env certs/local-key.pem; do
    if ! git check-ignore -q "$secret"; then
      warn "$secret is NOT in .gitignore and would be committed."
      PUSH=''; ask_yn PUSH "Commit anyway?" n
    fi
  done
  if [[ $PUSH == y ]]; then
    git add -A
    git commit -q -m "Initial commit: WordPress + Sage scaffold"
    if git push -u origin "$BRANCH"; then info "Pushed to $BRANCH."
    else warn "Push failed — check your GitHub auth, then run: git push -u origin $BRANCH"; fi
  else
    warn "Skipped commit. Fix .gitignore, then commit and push manually."
  fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
step "All set 🎉"
cat <<EOF
    Site          $SITE_URL
    Admin         $SITE_URL/wp-admin/
    phpMyAdmin    $PMA_URL
    Folder        $PROJECT_DIR
EOF
[[ $DO_WP_INSTALL == y ]] && info "WP admin      $WP_ADMIN_USER / $WP_ADMIN_PASSWORD"
info "DB            ${DB_USER:-?} / $MYSQL_PASSWORD  (root: $MYSQL_ROOT_PASSWORD)"

if [[ $START_NODE == y ]]; then
  step "Starting Node dev server (Ctrl+C to stop)"
  exec docker compose --profile dev up node
elif [[ $DO_SAGE == y ]]; then
  info "Start the dev server later with: cd $PROJECT_DIR && docker compose --profile dev up node"
else
  info "No Sage theme, so don't start the 'node' service. Start the stack by name:"
  info "  cd $PROJECT_DIR && docker compose --profile dev up -d mysql wordpress phpmyadmin caddy"
fi
