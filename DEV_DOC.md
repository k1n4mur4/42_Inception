# Developer Documentation

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Make
- Git

## Setting Up from Scratch

### 1. Clone the repository

```bash
git clone <repository-url>
cd test
```

### 2. Create secrets files

```bash
mkdir -p secrets
echo "your_db_password" > secrets/db_password.txt
echo "your_root_password" > secrets/db_root_password.txt
cat > secrets/credentials.txt << EOF
WP_ADMIN_PASSWORD=your_admin_password
WP_USER_PASSWORD=your_user_password
EOF
```

> The `secrets/` directory is gitignored and must be created manually on each machine.

### 3. Configure environment variables

Create `srcs/.env` (also gitignored — must be created manually):

```env
DOMAIN_NAME=kinamura.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_ADMIN_USER=kinamura
WP_ADMIN_EMAIL=kinamura@student.42tokyo.jp
WP_USER=nop
WP_USER_EMAIL=nop@example.com
```

### 4. Configure hosts file

```bash
echo "127.0.0.1 kinamura.42.fr" | sudo tee -a /etc/hosts
```

## Building and Launching

```bash
make        # Build images and start all containers
make re     # Full rebuild from scratch (removes volumes)
make down   # Stop containers
make logs   # Follow container logs
make status # Show container status
```

## Managing Containers and Volumes

```bash
# View running containers
docker compose -f srcs/docker-compose.yml ps

# Access container shell
docker compose -f srcs/docker-compose.yml exec nginx bash
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash

# View logs
docker compose -f srcs/docker-compose.yml logs -f

# List volumes
docker volume ls
```

## Data Storage

| Volume | Host Path | Container Path |
|--------|-----------|----------------|
| wordpress_data | ~/data/wordpress | /var/www/html/wordpress |
| mariadb_data | ~/data/mariadb | /var/lib/mysql |

Volumes are named Docker volumes backed by host paths at `/home/kinamura/data/`.
They are created automatically by `make prepare` before the first build.

## Project Structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/               # gitignored — create manually
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt    # WP_ADMIN_PASSWORD=... / WP_USER_PASSWORD=...
└── srcs/
    ├── docker-compose.yml
    ├── .env               # gitignored — create manually
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   ├── ssl/       # self-signed cert for kinamura.42.fr
        │   └── html/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/init.sh
        └── mariadb/
            ├── Dockerfile
            └── tools/init.sh
```
