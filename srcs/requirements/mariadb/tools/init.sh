#!/bin/bash
set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d /var/lib/mysql/${MYSQL_DATABASE} ]; then

	mysqld --user=mysql &
	until mysqladmin ping --silent; do
		sleep 1
	done

	mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

	mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
fi

# b: 本番起動 (PID 1)
exec mysqld --user=mysql --bind-address=0.0.0.0