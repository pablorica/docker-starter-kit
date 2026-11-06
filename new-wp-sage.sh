#!/usr/bin/env bash
#
# new-wp-sage.sh — scaffold a new local WordPress + Sage project on Docker,
# following the ~/Dockers/default template workflow.
#
# Usage:
#   ./new-wp-sage.sh
#
# Every question shows a default in [brackets]. Any question can be pre-answered
# by exporting its variable, e.g.:
#   PROJECT=skelly-couch SITE_TITLE="Skelly & Couch" ./new-wp-sage.sh
#
# Host requirements: docker (compose v2), mkcert (run `mkcert -install` once),
# git, perl, curl inside the wordpress container (official image has it).

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Personal defaults — edit once
# ---------------------------------------------------------------------------
DEFAULT_DOCKERS_DIR="$HOME/Dockers"
DEFAULT_THEME="codigo"
DEFAULT_WP_USER="pablo.rica"
DEFAULT_WP_EMAIL="pablo@codigo.co.uk"
DEFAULT_GITHUB_ORG="pablorica"
SAGE_REPO="https://github.com/roots/sage.git"

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
  ".gitignore.example:.gitignore"
  "nginx.conf.staging:nginx.conf.staging"
  "docker_sage:docker"
)

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

# Run a command, retry with sudo if it fails (theme folder may be owned by www-data)
sudo_if_needed() { "$@" 2>/dev/null || { warn "Retrying with sudo: $*"; sudo "$@"; }; }

dc() { docker compose "$@"; }
wp() { dc exec -T -u www-data wordpress php /tmp/wp-cli.phar --path=/var/www/html "$@"; }

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
ask DOCKERS_DIR  "Dockers folder" "$DEFAULT_DOCKERS_DIR"
DOCKERS_DIR=${DOCKERS_DIR/#\~/$HOME}
ask TEMPLATE_DIR "Template (default) project folder" "$DOCKERS_DIR/default"
TEMPLATE_DIR=${TEMPLATE_DIR/#\~/$HOME}
[[ -d $TEMPLATE_DIR ]] || die "Template folder not found: $TEMPLATE_DIR"

while :; do
  ask PROJECT "Project slug (folder + local domain, e.g. skelly-couch)"
  [[ $PROJECT =~ ^[a-z0-9][a-z0-9-]*$ ]] && break
  warn "Use lowercase letters, numbers and hyphens only."; PROJECT=''
done
ask SITE_TITLE "Site title" "$PROJECT"
while :; do
  ask THEME "Theme folder name" "$DEFAULT_THEME"
  [[ $THEME =~ ^[a-z0-9][a-z0-9_-]*$ ]] && break
  warn "Use lowercase letters, numbers, - or _ only."; THEME=''
done

# Suggest ports: next SSL port after the highest one used by existing projects
last_ssl=$(grep -hs '^WORDPRESS_SSL_PORT=' "$DOCKERS_DIR"/*/.env 2>/dev/null \
  | cut -d= -f2 | tr -dc '0-9\n' | sort -n | tail -n1 || true)
sug_ssl=$(( ${last_ssl:-$TPL_SSL_PORT} + 1 ))
ask SSL_PORT  "WordPress SSL port (WORDPRESS_SSL_PORT)" "$sug_ssl"
ask PMA_PORT  "phpMyAdmin port (PHPMYADMIN_PORT)"       "$(( SSL_PORT + 100 ))"
ask NODE_PORT "Node/Vite port (NODE_PORT)"              "$(( SSL_PORT - 3200 ))"
for p in "$SSL_PORT" "$PMA_PORT" "$NODE_PORT"; do
  [[ $p =~ ^[0-9]+$ ]] || die "Invalid port: $p"
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

ask SAGE_REF "Sage branch/tag (blank = latest)" ""

ask_yn DO_GIT "Push to a GitHub repository?" y
if [[ $DO_GIT == y ]]; then
  ask GITHUB_ORG  "GitHub user/organisation" "$DEFAULT_GITHUB_ORG"
  ask GITHUB_REPO "Repository URL (SSH recommended)" "git@github.com:$GITHUB_ORG/$PROJECT.git"
fi
ask_yn START_NODE "Start the Node dev server at the end?" y

PROJECT_DIR="$DOCKERS_DIR/$PROJECT"
SITE_URL="https://$PROJECT.localhost:$SSL_PORT"
PMA_URL="https://pma.$PROJECT.localhost:$SSL_PORT"

# Check template files before touching anything
for pair in "${TEMPLATE_FILES[@]}"; do
  [[ -e "$TEMPLATE_DIR/${pair%%:*}" ]] || die "Missing template file: $TEMPLATE_DIR/${pair%%:*}"
done
if [[ -e $PROJECT_DIR ]] && [[ -n $(ls -A "$PROJECT_DIR" 2>/dev/null) ]]; then
  die "$PROJECT_DIR already exists and isn't empty."
fi

step "Summary"
cat <<EOF
    Folder        $PROJECT_DIR
    Site          $SITE_URL  ("$SITE_TITLE")
    phpMyAdmin    $PMA_URL
    Theme         $THEME (Sage${SAGE_REF:+ @ $SAGE_REF})
    Ports         SSL $SSL_PORT · PMA $PMA_PORT · Node $NODE_PORT
    Production    $PROD_DOMAIN
    WP install    $DO_WP_INSTALL${WP_ADMIN_USER:+ (user: $WP_ADMIN_USER, $WP_ADMIN_EMAIL)}
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
for pair in "${TEMPLATE_FILES[@]}"; do
  src=${pair%%:*}; dst=${pair#*:}
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
DB_USER=$(get_env MYSQL_USER || true)
DB_NAME=$(get_env MYSQL_DATABASE || true)
info "Done (DB user: ${DB_USER:-?}, DB name: ${DB_NAME:-?})"

# ---------------------------------------------------------------------------
# 4. Docker stack
# ---------------------------------------------------------------------------
step "Starting Docker stack"
dc pull
dc up -d
dc ps

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
  if wait_for "WordPress core files" 120 dc exec -T wordpress test -f /var/www/html/wp-includes/version.php \
     && dc exec -T -u www-data wordpress sh -c \
        'curl -fsSL -o /tmp/wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar'; then
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
step "Installing Sage as '$THEME'"
THEMES_DIR="$PROJECT_DIR/wordpress/wp-content/themes"
wait_for "themes folder" 60 test -d "$THEMES_DIR" || die "Not found: $THEMES_DIR"
TMP_SAGE="$PROJECT_DIR/.sage-tmp"
rm -rf "$TMP_SAGE"
# shellcheck disable=SC2086
git clone --depth 1 ${SAGE_REF:+--branch "$SAGE_REF"} "$SAGE_REPO" "$TMP_SAGE"
rm -rf "$TMP_SAGE"/{.git,.github,.editorconfig,.gitattributes,.gitignore}
sudo_if_needed rm -rf "${THEMES_DIR:?}/$THEME"
sudo_if_needed mv "$TMP_SAGE" "$THEMES_DIR/$THEME"

step "Installing Composer dependencies (vendor/)"
dc --profile tools run --rm composer update -W

if [[ $WPCLI == y ]]; then
  if wp theme activate "$THEME"; then :; else warn "Activate '$THEME' manually in wp-admin."; fi
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
else
  info "Start the dev server later with: cd $PROJECT_DIR && docker compose --profile dev up node"
fi
