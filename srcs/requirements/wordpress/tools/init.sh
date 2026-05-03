#!/bin/bash
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
source /run/secrets/credentials

echo "Waiting for MariaDB to be ready..."
until mariadb-admin ping -h"${MYSQL_HOST}" --silent; do
	sleep 1
done

if [ ! -f /var/www/html/wordpress/wp-login.php ]; then
	cp -r /var/www/html/wordpress-src/* /var/www/html/wordpress/
	chown -R www-data:www-data /var/www/html/wordpress
	find /var/www/html -type d -exec chmod 755 {} \;
	find /var/www/html -type f -exec chmod 644 {} \;
fi

if [ ! -f "/var/www/html/wordpress/wp-config.php" ]; then
	echo "Waiting for Wordpress install..."
	cp /usr/local/share/wp-config.php /var/www/html/wordpress/wp-config.php
	sed -i "s|__DB_NAME__|${MYSQL_DATABASE}|g" /var/www/html/wordpress/wp-config.php
	sed -i "s|__DB_USER__|${MYSQL_USER}|g" /var/www/html/wordpress/wp-config.php
	sed -i "s|__DB_PASSWORD__|${MYSQL_PASSWORD}|g" /var/www/html/wordpress/wp-config.php
	sed -i "s|__DB_HOST__|${MYSQL_HOST}|g" /var/www/html/wordpress/wp-config.php

	echo "Installing wp core..."
	wp core install \
		--url=https://${DOMAIN_NAME} \
		--admin_user=${WP_ADMIN_USER} \
		--admin_password=${WP_ADMIN_PASSWORD} \
		--admin_email=${WP_ADMIN_EMAIL} \
		--allow-root \
		--skip-email \
		--title="Inception" \
		--path=/var/www/html/wordpress

	echo "Creating user..."
	wp user create ${WP_USER} ${WP_USER_EMAIL} \
		--user_pass=${WP_USER_PASSWORD} \
		--role=editor \
		--allow-root \
		--path=/var/www/html/wordpress

	
else
	echo "WordPress is already installed."
fi

echo "Starting PHP..."
exec php-fpm8.2 -F