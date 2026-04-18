#!/bin/bash
set -e

# type: none volume starts empty — copy WordPress core files from staging
if [ ! -f /var/www/html/wordpress/wp-login.php ]; then
    echo "Initializing WordPress files in volume..."
    cp -a /var/www/html/wordpress-src/. /var/www/html/wordpress/
    chown -R www-data:www-data /var/www/html/wordpress
fi

cd /var/www/html/wordpress

# Read secrets (strip trailing newlines)
MYSQL_PASSWORD=$(cat /run/secrets/db_password | tr -d '\n')
WP_ADMIN_PASSWORD=$(grep WP_ADMIN_PASSWORD /run/secrets/credentials | cut -d'=' -f2 | tr -d '\n')
WP_USER_PASSWORD=$(grep WP_USER_PASSWORD /run/secrets/credentials | cut -d'=' -f2 | tr -d '\n')

# wp-config.php
if [ ! -f wp-config.php ]; then
    cat > wp-config.php << EOF
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
    chown www-data:www-data wp-config.php
    chmod 640 wp-config.php

    # Wait for MariaDB (max 60 retries)
    echo "Waiting for MariaDB to be ready..."
    MAX_RETRIES=60
    RETRY=0
    while ! mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
        RETRY=$((RETRY + 1))
        if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
            echo "Error: MariaDB not ready after ${MAX_RETRIES} attempts"
            exit 1
        fi
        echo "MariaDB not ready yet... ($RETRY/$MAX_RETRIES)"
        sleep 2
    done
    echo "MariaDB is ready!"

    # WordPress
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    # second user
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root
fi

exec php-fpm8.2 -F
