
# Change Log

All notable changes to this project will be documented in this file.
 
The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

---

## [0.6.1]- 2026-11-06

### Changed
- `SAGE.md`: all Composer, npm and WP-CLI commands run through Docker. Added the Vite environment variables and the new `vite.config.js` (no Vue). Fonts and colours are configured in CSS for Tailwind 4 (`@theme`), with no JS config. Added a Tailwind 3 → 4 table and Alpine.js (planned).

## [0.6.0]- 2026-11-06

### Added
- `new-wp-sage.sh`: interactive script that creates a new local WordPress + Sage project on Docker from the `default` template.
  - Asks for project slug, site title, theme name, ports, MySQL passwords, production domain, WordPress admin details, Sage version and GitHub repository.
  - Suggests the next free ports from existing projects in `~/Dockers` (SSL +1, phpMyAdmin = SSL + 100, Node = SSL − 3200) and warns if a port is busy.
  - Generates passwords when left blank. Passwords are written to `.env` in single quotes so characters like `$`, `&` and `%` work.
  - Creates the mkcert certificates, copies the template files and writes `.env` (slug, theme, ports, passwords, `CADDY_PRODUCTION_DOMAIN`).
  - Starts the Docker stack and waits until MySQL accepts the WordPress user.
  - Optionally installs WordPress with WP-CLI and sets "Discourage search engines".
  - Installs Sage as the theme (removes its developer files), runs Composer and activates the theme.
  - Optionally connects the project to GitHub and pushes, keeping files already in the remote (e.g. LICENSE). Stops and asks before committing if `.env` or the certificate key isn't ignored by `.gitignore`.
  - Optionally starts the Node dev server at the end.
  - Every question can be answered in advance with an environment variable (e.g. `PROJECT=foo ./new-wp-sage.sh`).
- `README-new-wp-sage.md`: documentation for the script (requirements, questions, steps, defaults, troubleshooting), plus the full manual installation guide.

### Security
- No passwords or tokens are stored in the script. The GitHub instructions use SSH or `gh auth` instead of access tokens in URLs.

## [0.5.1] - 2026-07-28

### Updated

- [Services](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1216846847329163) - Add padding to the top and bottom of services section


## [0.5.0] - 2026-07-28

### Updated

- Docker files

## [0.3.5] - 2026-07-27

### Updated

- July 2026 Updates

## [0.3.4] - 2026-06-18

### Updated

- [Header | Small logo](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1215794859420147)

- [Top menu font to Bold instead of Light](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1215794859420145)



## [0.3.3] - 2026-06-18

### Updated

- [Footer Leading](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1215794859420155)


## [0.3.2] - 2026-06-18

### Updated

- [Mobile version](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1215794859420158)


## [0.3.1] - 2026-06-17

### Updated


- [Header | Small logo](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1215794859420147)


## [0.3.0] - 2026-06-17

### Added

- [Header | Dark layer over the image](https://app.asana.com/1/1198727466849836/project/1215042979527993/task/1215794859420141)

## [0.2.2] - 2026-06-16

### Added

- General page & title


## [0.2.1] - 2026-06-16

### Added

- Responsive layout


## [0.2.0] - 2026-06-15

### Added

- Staging


## [0.1.5] - 2026-06-15

### Added

- Grid

## [0.1.4] - 2026-06-15

### Added

- Footer

## [0.1.3] - 2026-06-15

### Added

- Header

## [0.1.2] - 2026-06-15

### Added

- SAGE ACF Composer

## [0.1.1] - 2026-06-12

### Added

 - Font sizes
 - PostCSS files

## [0.1.0] - 2026-06-11

### Added

 - Colour palette
 - Font family

## [0.0.10] - 2026-03-08

### Added

- APP_ENV variable to the project to differentiate between local, development and production environments
- docker-compose.override.yml.example
- wp-config.php.example 

### Updated

- wp-config.php file updated to use the new APP_ENV variable


## [0.0.9] - 2026-03-08

### Added

- SAGE Tools
  - ACF Composer
  - Sage Directives

## [0.0.8] - 2026-03-08

### Added

- Primary Menu


## [0.0.7] - 2026-03-08

### Added

- AlpineJS


## [0.0.6] - 2026-03-07

### Added

- PostCSS


## [0.0.5] - 2026-03-06

### Added

Added Gutenberg customisation for the block editor, including:
 - block styles
 - block variations
 - editor filters

## [0.0.4] - 2026-03-04

### Added

- Node added to Docker
  - To make **Sage (Vite) development work inside Docker with HTTPS**, we introduced a dedicated **Node service** and updated the **Caddy reverse proxy**.

## [0.0.3] - 2026-03-02

### Added

- Vite config

## [0.0.2] - 2026-03-02

### Added

- Fonts and colours 

## [0.0.1] - 2026-03-02

### Added

- First Push


