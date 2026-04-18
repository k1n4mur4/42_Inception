# User Documentation

## Services Overview

| Service | Description | Port |
|---------|-------------|------|
| NGINX | Web server with TLS | 443 (HTTPS) |
| WordPress | CMS application | internal only |
| MariaDB | Database | internal only |

## Starting and Stopping

```bash
make        # Build and start all containers
make down   # Stop containers
make clean  # Stop containers and remove volumes
make re     # Full rebuild from scratch
```

## Accessing the Website

1. Open your browser
2. Navigate to `https://kinamura.42.fr`
3. Accept the self-signed certificate warning

## Accessing the Admin Panel

Navigate to `https://kinamura.42.fr/wp-admin` and log in with administrator credentials.

### Default Users

| Role | Username |
|------|----------|
| Administrator | kinamura |
| Author | nop |

## Managing Credentials

All credentials are stored in the `secrets/` directory (not committed to git):

- `secrets/db_password.txt` — WordPress database user password
- `secrets/db_root_password.txt` — MariaDB root password
- `secrets/credentials.txt` — WordPress user passwords, in the format:
  ```
  WP_ADMIN_PASSWORD=your_admin_password
  WP_USER_PASSWORD=your_user_password
  ```

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
