# Production build

This theme is deployed by uploading a zip through the WordPress admin. `build-theme-zip.sh` compiles the assets and packs only the files the theme needs to run.

### Requirements

- Docker with Compose
- `bash`, `rsync`, `zip` and `unzip`
- Composer (if it isn't installed, the script uses the `composer:2` Docker image)

### Usage


Make the script executable

```bash
cd wp_data/wp-content/themes/seadesign
chmod +x build-theme-zip.sh
ls -l build-theme-zip.sh
-rwxr-xr-x  1 pablo  staff  7211 Nov  4 19:48 build-theme-zip.sh
```
Run the script from the theme root:

```bash
cd wp_data/wp-content/themes/seadesign
./build-theme-zip.sh seadesign
```

The argument is the theme folder name on the server. It must match, because the compiled assets use it in their URLs. If you leave it out, the script uses the current folder name.

The zip is saved as `dist/<theme>-<YYYYMMDD-HHMM>.zip`. Upload it from **Appearance → Themes → Add New → Upload Theme**.

### What the script does

1. Builds the assets with `docker compose run --rm node sh -lc "npm run build"`.
2. Checks that the Vite manifest exists and that compiled asset URLs match the theme folder.
3. Copies the production files to a temporary folder.
4. Runs `composer install --no-dev` there, so your local `vendor/` isn't changed.
5. Creates the zip and checks that the required files are in it and no development files are.

### What goes in the zip

| Included | Excluded |
|---|---|
| `app/`, `config/` | `node_modules/` |
| `public/build/` | `resources/` source files (`js`, `css`, etc.) |
| `resources/views/` | Dotfiles such as `.env` |
| `vendor/` (production packages only) | `public/hot`, source maps and logs |
| `style.css`, `functions.php` and other theme files | Markdown files, tests, and npm, Vite, Tailwind and Docker config |

### Options

| Variable | Description | Example |
|---|---|---|
| `BUILD_CMD` | Replaces the default build command | `BUILD_CMD="npm run build"` |
| `COMPOSER_CMD` | Replaces the Composer command | `COMPOSER_CMD="composer"` |
| `KEEP_RESOURCES` | Keeps extra folders from `resources/` | `KEEP_RESOURCES="images fonts"` |
| `SKIP_BUILD` | Reuses the existing `public/build` | `SKIP_BUILD=1` |

Example:

```bash
SKIP_BUILD=1 KEEP_RESOURCES="images" ./build-theme-zip.sh seadesign
```

### Before uploading

- Review any warnings the script prints.
- Check that the server's PHP version meets the minimum printed at the end, if one is shown.
- Check that the zip fits the upload limit shown in **Media → Add New**.
- Download a backup of the active theme, because the upload replaces it.