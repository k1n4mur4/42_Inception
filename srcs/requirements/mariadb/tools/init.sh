#!/bin/bash
set -e

# Read secrets (strip trailing newlines)
MYSQL_PASSWORD=$(cat /run/secrets/db_password | tr -d '\n')
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password | tr -d '\n')

mysqld --user=mysql --bind-address=0.0.0.0 &

# Wait for MariaDB to be ready (max 30 seconds)
MAX_RETRIES=30
RETRY=0
until mysqladmin ping --silent 2>/dev/null; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        echo "Error: MariaDB failed to start within ${MAX_RETRIES} seconds"
        exit 1
    fi
    echo "Waiting for MariaDB to start... ($RETRY/$MAX_RETRIES)"
    sleep 1
done
echo "MariaDB is running."

mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

exec mysqld --user=mysql --bind-address=0.0.0.0
