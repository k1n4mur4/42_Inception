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
cd inception
```

### 2. Create secrets files
```bash
mkdir -p secrets
echo "your_db_password" > secrets/db_password.txt
echo "your_root_password" > secrets/db_root_password.txt
echo "your_wp_admin_password" > secrets/wp_admin_password.txt
echo "your_wp_user_password" > secrets/wp_user_password.txt
```

### 3. Configure environment variables

Create `srcs/.env`:
```env
DOMAIN_NAME=login.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_ADMIN_USER=your_login
WP_ADMIN_EMAIL=your_email@example.com
WP_USER=user
WP_USER_EMAIL=user@example.com
```

### 4. Configure hosts file (VM only)
```bash
sudo echo "127.0.0.1 login.42.fr" >> /etc/hosts
```

## Building and Launching

### Build and start
```bash
make
```

### Rebuild from scratch
```bash
make re
```

## Managing Containers and Volumes

### View running containers
```bash
docker compose -f srcs/docker-compose.yml ps
```

### View all containers (including stopped)
```bash
docker compose -f srcs/docker-compose.yml ps -a
```

### Access container shell
```bash
docker compose -f srcs/docker-compose.yml exec nginx bash
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

### View logs
```bash
docker compose -f srcs/docker-compose.yml logs -f
```

### Stop containers
```bash
make down
```

### Stop and remove volumes
```bash
make clean
```

### List volumes
```bash
docker volume ls
```

## Data Storage

### Volumes

| Volume | Purpose | Container Path |
|--------|---------|----------------|
| wordpress_data | WordPress files | /var/www/html/wordpress |
| mariadb_data | Database files | /var/lib/mysql |

### For production (VM)

Volumes should be mapped to `/home/login/data`:
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/login/data/mariadb
```

## Project Structure
```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```
