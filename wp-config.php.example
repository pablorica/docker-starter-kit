<?php
// === Load DB creds from env (set in docker-compose) ===
define('DB_NAME',     getenv('WORDPRESS_DB_NAME')     ?: getenv('MYSQL_DATABASE') ?: 'default');
define('DB_USER',     getenv('WORDPRESS_DB_USER')     ?: getenv('MYSQL_USER')     ?: 'default');
define('DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: getenv('MYSQL_PASSWORD') ?: 'default');
define('DB_HOST',     getenv('WORDPRESS_DB_HOST')     ?: 'db:3306');

define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Table prefix
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_';

// Reverse proxy / Caddy HTTPS detection
if (!empty($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
  $_SERVER['HTTPS'] = 'on';
}

// Site URLs (override via env if you want)
$port = getenv('WORDPRESS_SSL_PORT') ?: '443';
$baseHome = getenv('WORDPRESS_HOME') ?: 'https://default.localhost';
$wphome = $baseHome;
// $wphome = getenv('WORDPRESS_HOME') ? getenv('WORDPRESS_HOME').":$port" : "https://default.localhost:$port";
if (getenv('APP_ENV') === 'local') {
  // enable port only for local dev, since in remote we expect the reverse proxy to handle it and provide the correct URL via env
  // If baseHome already includes a port, don't double-append.
  // (Simple check: if ":" appears after "https://", assume port present.)
  $hasPort = preg_match('#^https?://[^/]+:\d+#', $baseHome) === 1;
  $wphome = $hasPort ? $baseHome : ($baseHome . ":$port");
}

define('WP_HOME',    $wphome);
define('WP_SITEURL', $wphome);
define('FORCE_SSL_ADMIN', true);


// Salts — copy the ones from .env; WordPress generates its own if empty
define('AUTH_KEY',         getenv('WORDPRESS_AUTH_KEY') ?: '');
define('SECURE_AUTH_KEY',  getenv('WORDPRESS_SECURE_AUTH_KEY') ?: '');
define('LOGGED_IN_KEY',    getenv('WORDPRESS_LOGGED_IN_KEY') ?: '');
define('NONCE_KEY',        getenv('WORDPRESS_NONCE_KEY') ?: '');
define('AUTH_SALT',        getenv('WORDPRESS_AUTH_SALT') ?: '');
define('SECURE_AUTH_SALT', getenv('WORDPRESS_SECURE_AUTH_SALT') ?: '');
define('LOGGED_IN_SALT',   getenv('WORDPRESS_LOGGED_IN_SALT') ?: '');
define('NONCE_SALT',       getenv('WORDPRESS_NONCE_SALT') ?: '');



//define('WP_ALLOW_REPAIR', true);

// Debug flags (recommended for dev)
if (!defined('WP_DEBUG')) define('WP_DEBUG', getenv('WORDPRESS_DEBUG') ? (getenv('WORDPRESS_DEBUG') === 'true') : true);
if (!defined('WP_DEBUG_DISPLAY')) define('WP_DEBUG_DISPLAY', false);
if (!defined('WP_DEBUG_LOG')) define('WP_DEBUG_LOG', dirname(__FILE__) . '/logs/debug.log');

// Check error logs in Docker via 'docker compose logs wordpress'

// Optional
//ini_set('log_errors', '1');
//ini_set('error_reporting', (string) E_ALL);
//ini_set('error_log', dirname(__FILE__) . '/logs/error.log');


// ABSPATH and bootstrap
if (!defined('ABSPATH')) define('ABSPATH', __DIR__ . '/');

// ACF PRO licence (from .env through docker-compose). Activates the licence automatically.
$acf_pro_license = getenv( 'ACF_PRO_LICENSE' );
if ( $acf_pro_license && ! defined( 'ACF_PRO_LICENSE' ) ) {
    define( 'ACF_PRO_LICENSE', $acf_pro_license );
}
unset( $acf_pro_license );

require_once ABSPATH . 'wp-settings.php';

