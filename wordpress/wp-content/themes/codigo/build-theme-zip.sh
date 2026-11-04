#!/usr/bin/env bash
#
# Builds a production zip of a Sage theme, ready for
# WordPress > Appearance > Themes > Add New > Upload Theme.
#
# Run it from the theme root:
#   ./build-theme-zip.sh [theme-folder-name]
#
# The theme name must match the folder the theme will live in on the server,
# because Vite's base path contains it. It defaults to the current folder name.
#
# Optional environment variables:
#   BUILD_CMD       Assets build command
#                   (default: docker compose run --rm node sh -lc "npm run build")
#   COMPOSER_CMD    Composer command (default: local composer, otherwise Docker)
#   KEEP_RESOURCES  Extra folders inside resources/ to ship, separated by spaces
#                   (resources/views is always included)
#                   Example: KEEP_RESOURCES="images fonts"
#   SKIP_BUILD=1    Reuse the existing public/build

set -euo pipefail

THEME="${1:-$(basename "$PWD")}"
BUILD_CMD="${BUILD_CMD:-docker compose run --rm node sh -lc \"npm run build\"}"
KEEP_RESOURCES="${KEEP_RESOURCES:-}"
SKIP_BUILD="${SKIP_BUILD:-0}"

ROOT="$PWD"
DIST="$ROOT/dist"
STAGE_ROOT="$DIST/.stage"
STAGE="$STAGE_ROOT/$THEME"
ZIP="$DIST/$THEME-$(date +%Y%m%d-%H%M).zip"
EXPECTED_BASE="/wp-content/themes/$THEME/public/build"
WARNINGS=0

step() { printf '\n==> %s\n' "$1"; }
warn() { printf 'WARNING: %s\n' "$1" >&2; WARNINGS=$((WARNINGS + 1)); }
fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

cleanup() { rm -rf "$STAGE_ROOT"; }
trap cleanup EXIT

# ---------------------------------------------------------------- pre-flight
[ -f style.css ] && [ -f functions.php ] && [ -f composer.json ] \
  || fail "Run this from the theme root (style.css, functions.php and composer.json are required)."
grep -qi 'Theme Name:' style.css || fail "style.css has no 'Theme Name:' header."
for tool in rsync zip unzip; do
  command -v "$tool" >/dev/null || fail "'$tool' is not installed."
done
[ -f composer.lock ] || warn "No composer.lock, so production dependencies may differ from local."

# Composer usually lives in a container in Docker setups
if [ -z "${COMPOSER_CMD:-}" ]; then
  if command -v composer >/dev/null; then
    COMPOSER_CMD="composer"
  elif command -v docker >/dev/null; then
    COMPOSER_CMD="docker run --rm -u $(id -u):$(id -g) -v $STAGE:/app -w /app composer:2"
  else
    fail "Neither composer nor docker was found. Set COMPOSER_CMD."
  fi
fi

# ---------------------------------------------------------------- 1. assets
if [ "$SKIP_BUILD" = "1" ]; then
  step "Skipping assets build (SKIP_BUILD=1)"
else
  step "Building assets: $BUILD_CMD"
  # bash -c keeps the quotes inside the command intact
  bash -c "$BUILD_CMD"
fi

[ -f public/build/manifest.json ] || [ -f public/build/.vite/manifest.json ] \
  || fail "No Vite manifest found in public/build. Did the build succeed?"

# Compiled CSS can contain absolute URLs. They break if the theme folder differs.
BASES=$(grep -rhoE "[^\"'() ,]*/themes/[A-Za-z0-9._-]+/public/build" public/build \
  --include='*.css' --include='*.js' 2>/dev/null | sort -u || true)
for base in $BASES; do
  case "$base" in
    *"$EXPECTED_BASE") ;;
    *) warn "Compiled assets point to '$base', expected '$EXPECTED_BASE'. Check base in vite.config.js." ;;
  esac
done

# ---------------------------------------------------------------- 2. staging
step "Copying production files"
rm -rf "$STAGE_ROOT"
mkdir -p "$STAGE"

rsync -a \
  --exclude='/.*' \
  --exclude='.git' \
  --exclude='.DS_Store' \
  --exclude='/dist/' \
  --exclude='/node_modules/' \
  --exclude='/vendor/' \
  --exclude='/resources/' \
  --exclude='/tests/' \
  --exclude='/docker/' \
  --exclude='/public/hot' \
  --exclude='*.map' \
  --exclude='*.log' \
  --exclude='*.md' \
  --exclude='/package.json' \
  --exclude='/package-lock.json' \
  --exclude='/npm-shrinkwrap.json' \
  --exclude='/yarn.lock' \
  --exclude='/pnpm-lock.yaml' \
  --exclude='/bun.lockb' \
  --exclude='/vite.config.*' \
  --exclude='/tailwind.config.*' \
  --exclude='/postcss.config.*' \
  --exclude='/tsconfig.json' \
  --exclude='/jsconfig.json' \
  --exclude='/phpcs.xml*' \
  --exclude='/phpunit.xml*' \
  --exclude='/pint.json' \
  --exclude='/docker-compose*' \
  --exclude='/compose.y*ml' \
  --exclude='/Dockerfile*' \
  --exclude='/Caddyfile*' \
  --exclude="/$(basename "$0")" \
  ./ "$STAGE/"

# Only the Blade views are needed at runtime: compiled assets live in public/build
[ -d resources/views ] || fail "resources/views was not found."
mkdir -p "$STAGE/resources"
cp -R resources/views "$STAGE/resources/views"
for folder in $KEEP_RESOURCES; do
  [ -d "resources/$folder" ] || fail "resources/$folder was not found."
  cp -R "resources/$folder" "$STAGE/resources/$folder"
done

# Warn about code that reads source files directly instead of the Vite manifest
RAW_REFS=$(grep -rnE "resource_path\(|get_(theme_file|template_directory|stylesheet_directory)[a-z_]*\(.*resources/|get_(template|stylesheet)_directory(_uri)?\(\) *\. *['\"]/resources" \
  app resources/views functions.php 2>/dev/null | grep -v "views" || true)
if [ -n "$RAW_REFS" ]; then
  warn "This code may load files from resources/ directly. Ship them with KEEP_RESOURCES if so:"
  printf '%s\n' "$RAW_REFS" >&2
fi

# ---------------------------------------------------------------- 3. composer
step "Installing production PHP dependencies"
# This runs in the staging folder, so your local vendor/ keeps its dev packages
[ -f auth.json ] && cp auth.json "$STAGE/auth.json"
(
  cd "$STAGE"
  $COMPOSER_CMD install \
    --no-dev \
    --no-scripts \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --optimize-autoloader \
    --ignore-platform-reqs
)
rm -f "$STAGE/auth.json" "$STAGE/composer.lock"

[ -f "$STAGE/vendor/autoload.php" ] || fail "vendor/autoload.php is missing after composer install."

# ---------------------------------------------------------------- 4. zip
step "Creating zip"
(
  cd "$STAGE_ROOT"
  zip -rqX "$ZIP" "$THEME"
)

# ---------------------------------------------------------------- 5. verify
step "Verifying zip"
# Read from a file, not a pipe: grep -q stops at the first match, which breaks
# the writing side of a pipe on long listings and fails under pipefail.
LISTING_FILE="$STAGE_ROOT/listing.txt"
unzip -Z1 "$ZIP" > "$LISTING_FILE"
for required in style.css functions.php composer.json vendor/autoload.php resources/views/; do
  grep -qxF "$THEME/$required" "$LISTING_FILE" || fail "$required is missing from the zip."
done
grep -q "^$THEME/public/build/" "$LISTING_FILE" || fail "public/build is missing from the zip."
if grep -qE "^$THEME/(public/hot|node_modules/|\.env)" "$LISTING_FILE"; then
  fail "The zip contains development files (public/hot, node_modules or .env)."
fi

PLATFORM_CHECK="$STAGE/vendor/composer/platform_check.php"
if [ -f "$PLATFORM_CHECK" ]; then
  PHP_NEEDED=$(grep -oE 'PHP version \\?">= [0-9.]+' "$PLATFORM_CHECK" | head -1 | grep -oE "[0-9.]+$" || true)
fi

SIZE_MB=$(( $(wc -c < "$ZIP") / 1024 / 1024 ))
printf '\nDone: %s\n' "$ZIP"
printf 'Files: %s\n' "$(wc -l < "$LISTING_FILE" | tr -d ' ')"
printf 'Size: about %s MB (must fit the server upload limit in Media > Add New)\n' "$SIZE_MB"
[ -n "${PHP_NEEDED:-}" ] && printf 'Server PHP must be at least: %s\n' "$PHP_NEEDED"
[ "$WARNINGS" -gt 0 ] && printf '\n%s warning(s) above, review them before uploading.\n' "$WARNINGS"
exit 0