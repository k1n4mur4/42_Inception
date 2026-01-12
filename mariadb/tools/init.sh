#!/bin/bash

mysqld --user=mysql --bind-address=0.0.0.0 & sleep 5

mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY 'wppass';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
EOF

mysqladmin -u root shutdown

exec mysqld --user=mysql --bind-address=0.0.0.0