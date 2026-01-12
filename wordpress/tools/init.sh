#!/bin/bash

# wp-config.phpが存在しなければ作成
if [ ! -f /var/www/html/wordpress/wp-config.php ]; then
    cat > /var/www/html/wordpress/wp-config.php << EOF
<?php
define('DB_NAME', '${MYSQL_DATABASE}');
define('DB_USER', '${MYSQL_USER}');
define('DB_PASSWORD', '${MYSQL_PASSWORD}');
define('DB_HOST', '${MYSQL_HOST}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');

\$table_prefix = 'wp_';

define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
    chown www-data:www-data /var/www/html/wordpress/wp-config.php
fi

exec php-fpm8.2 -F