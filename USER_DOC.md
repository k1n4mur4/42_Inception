# User Documentation

## Services Overview

This stack provides the following services:

| Service | Description | Port |
|---------|-------------|------|
| NGINX | Web server with TLS | 443 |
| WordPress | CMS application | - |
| MariaDB | Database | - |

## Starting and Stopping

### Start the project
```bash
make
```

### Stop the project
```bash
make down
```

### Full reset (removes all data)
```bash
make clean
```

## Accessing the Website

1. Open your browser
2. Navigate to `https://kinamura.42.fr` (or `https://localhost` for testing)
3. Accept the self-signed certificate warning

## Accessing the Admin Panel

1. Navigate to `https://kinamura.42.fr/wp-admin`
2. Login with administrator credentials

### Default Users

| Role | Username | 
|------|----------|
| Administrator | kinamura |
| Author | user |

Passwords are stored in the `secrets/` directory.

## Managing Credentials

Credentials are stored in the following files:
- `secrets/db_password.txt` - Database user password
- `secrets/db_root_password.txt` - Database root password
- `secrets/wp_admin_password.txt` - WordPress admin password
- `secrets/wp_user_password.txt` - WordPress user password

To change a password, edit the corresponding file and run `make re`.

## Checking Service Status
```bash
docker compose -f srcs/docker-compose.yml ps
```

All services should show "Up" status.

### Viewing Logs
```bash
# All services
docker compose -f srcs/docker-compose.yml logs

# Specific service
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```
