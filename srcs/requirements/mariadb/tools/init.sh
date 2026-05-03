#!/bin/bash
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d /var/lib/mysql/${MYSQL_DATABASE} ]; then

	mysqld --user=mysql &
	until mysqladmin ping --silent; do
		sleep 1
	done

	cp /usr/local/share/init.sql /tmp/init.sql
	sed -i "s|__DB_NAME__|${MYSQL_DATABASE}|g" /tmp/init.sql
	sed -i "s|__DB_USER__|${MYSQL_USER}|g" /tmp/init.sql
	sed -i "s|__DB_PASSWORD__|${MYSQL_PASSWORD}|g" /tmp/init.sql
	sed -i "s|__DB_ROOT_PASSWORD__|${MYSQL_ROOT_PASSWORD}|g" /tmp/init.sql

	mariadb -u root < /tmp/init.sql

	rm /tmp/init.sql

	mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi

exec mysqld --user=mysql --bind-address=0.0.0.0