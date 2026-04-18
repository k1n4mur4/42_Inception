# Developer Documentation

## Prerequisites

- Debian-based virtual machine (Debian 12+ recommended)
- Docker Engine 24+
- Docker Compose v2+ (`docker compose`, not `docker-compose`)
- GNU Make
- Git
- Host entry for `kinamura.42.fr` pointing to `127.0.0.1`

## Setting Up from Scratch

### 1. Clone the repository
```bash
git clone <repository-url> inception
cd inception
```

### 2. Configure the host

Add the domain to `/etc/hosts`:
```bash
echo "127.0.0.1 kinamura.42.fr" | sudo tee -a /etc/hosts
```

Create the data directory used by the bind-mounted named volumes:
```bash
mkdir -p /home/kinamura/data/wordpress /home/kinamura/data/mariadb
```
(The `make` target also does this automatically via the `setup` rule.)

### 3. Create secrets files

All secrets live in the top-level `secrets/` directory and are ignored by Git.

```bash
mkdir -p secrets

# MariaDB passwords (single value per file, no trailing newline)
printf 'YOUR_DB_PASSWORD' > secrets/db_password.txt
printf 'YOUR_DB_ROOT_PASSWORD' > secrets/db_root_password.txt

# WordPress passwords (KEY=VALUE format, one per line)
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_PASSWORD=YOUR_WP_ADMIN_PASSWORD
WP_USER_PASSWORD=YOUR_WP_USER_PASSWORD
EOF

# Restrict permissions
chmod 600 secrets/*.txt
```

### 4. Configure environment variables

Create `srcs/.env`:
```env
# Domain
DOMAIN_NAME=kinamura.42.fr

# MariaDB configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

# WordPress admin (must NOT contain 'admin' or 'administrator')
WP_ADMIN_USER=kinamura
WP_ADMIN_EMAIL=kinamura@student.42tokyo.jp

# WordPress second user (non-admin)
WP_USER=bob
WP_USER_EMAIL=bob@example.com
```

## Building and Launching

### Build and start everything
```bash
make
```

This will:
1. Create `/home/kinamura/data/{wordpress,mariadb}` if missing (`setup` rule)
2. Build Docker images for `nginx`, `wordpress`, and `mariadb`
3. Start all containers detached

### Rebuild from scratch
```bash
make re
```

### Other Makefile targets

| Target      | Description                                                |
|-------------|------------------------------------------------------------|
| `make`      | Default: `info` + `build` + `up`                          |
| `make build`| Build images only                                          |
| `make up`   | Start already-built images                                 |
| `make down` | Stop containers (preserves volumes and images)             |
| `make clean`| Stop containers and remove volumes                         |
| `make fclean`| `clean` + remove images, host data at `/home/kinamura/data`, and prune |
| `make logs` | Follow aggregated logs                                     |
| `make status`| List containers and their state                           |
| `make help` | Show available targets                                     |

## Managing Containers and Volumes

### View running containers
```bash
docker compose -f srcs/docker-compose.yml ps
```

### View all containers (including exited)
```bash
docker compose -f srcs/docker-compose.yml ps -a
```

### Access a container shell
```bash
docker compose -f srcs/docker-compose.yml exec nginx bash
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash
```

### View logs
```bash
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml logs nginx
```

### Stop everything
```bash
make down
```

### Remove volumes (data also in host path is kept)
```bash
make clean
```

### List Docker volumes
```bash
docker volume ls
```

You should see `srcs_wordpress_data` and `srcs_mariadb_data`.

## Data Storage

### Volumes

Two named volumes are bound to directories on the host, so data survives
container recreation even if the Docker volume is removed.

| Volume             | Container mount path          | Host path                         | Purpose                    |
|--------------------|-------------------------------|-----------------------------------|----------------------------|
| `wordpress_data`   | `/var/www/html/wordpress`     | `/home/kinamura/data/wordpress`   | WordPress site files       |
| `mariadb_data`     | `/var/lib/mysql`              | `/home/kinamura/data/mariadb`     | MariaDB data files         |

### docker-compose volume definition

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/kinamura/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/kinamura/data/mariadb
```

### Inspecting data on the host

```bash
ls -la /home/kinamura/data/wordpress
ls -la /home/kinamura/data/mariadb
```

Because MariaDB writes files as its own `mysql` user, some files in
`/home/kinamura/data/mariadb` will be owned by `systemd-coredump` or a numeric
UID on the host. This is expected with bind-mounted volumes.

## Project Structure

```
.
├── Makefile                    # Build orchestration (info/build/up/down/clean/fclean/re/logs/status)
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── LICENSE
├── .gitignore                  # Ignores secrets/, .env, *.sql, **/ssl/, *.key/*.crt/*.pem
├── secrets/                    # NOT tracked; holds db_password.txt, db_root_password.txt, credentials.txt
└── srcs/
    ├── .env                    # NOT tracked; DOMAIN_NAME and non-secret Mysql/WP identifiers
    ├── docker-compose.yml      # 3 services + 2 bind-mounted named volumes + inception network + 3 secrets
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile      # debian:bookworm; apt nginx+openssl; openssl req -x509 at build time
        │   └── conf/
        │       └── nginx.conf  # 443 only, TLSv1.2/1.3, fastcgi_pass wordpress:9000
        ├── wordpress/
        │   ├── Dockerfile      # debian:bookworm; php-fpm; wp-cli install; reads secrets/env
        │   ├── conf/
        │   │   └── www.conf    # php-fpm pool config (listen on 9000)
        │   └── tools/
        │       └── init.sh     # Entrypoint: wait for DB, wp core install, wp user create, exec php-fpm
        └── mariadb/
            ├── Dockerfile      # debian:bookworm; apt mariadb-server; custom entrypoint
            └── tools/
                └── init.sh     # Entrypoint: first-run init (user/DB/root pw), exec mysqld
```

## TLS Certificate

NGINX generates a self-signed certificate at image build time inside
`srcs/requirements/nginx/Dockerfile`:

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out    /etc/nginx/ssl/nginx.crt \
    -subj   "/C=JP/ST=Tokyo/L=Tokyo/O=42Tokyo/OU=kinamura/CN=kinamura.42.fr"
```

Key and certificate are never committed to Git (`**/ssl/`, `*.key`, `*.crt`,
`*.pem` are gitignored). A fresh cert is created on every `make build`
(and therefore on every `make re`).

## Secrets

All sensitive values are read at container start from files mounted by
Docker secrets at `/run/secrets/<name>`:

| Secret              | Consumers             | File                            |
|---------------------|-----------------------|---------------------------------|
| `db_password`       | mariadb, wordpress    | `secrets/db_password.txt`       |
| `db_root_password`  | mariadb               | `secrets/db_root_password.txt`  |
| `credentials`       | wordpress             | `secrets/credentials.txt`       |

`credentials.txt` is a KEY=VALUE file containing `WP_ADMIN_PASSWORD=...` and
`WP_USER_PASSWORD=...`. The `wordpress` entrypoint sources it and uses the
values with `wp user create` / `wp user update`.

No plaintext password appears in any Dockerfile, `docker-compose.yml`, or
`*.conf`. The verification step
`grep -rni password --include=Dockerfile --include='*.conf' srcs/` must
remain empty.

## Volumes and Data Directory

The host directory `/home/kinamura/data/{wordpress,mariadb}` is created by
the `setup` make target (called automatically by `build`). On macOS it is
`$(HOME)/tmp/data/{wordpress,mariadb}` instead — note that the
`docker-compose.yml` bind path is still `/home/kinamura/data/...`, so running
the stack on macOS as-is will fail; this is intentional because the grading
environment is the 42 Linux VM.

The `make fclean` target runs `sudo rm -rf $(DATA_DIR)` so expect a sudo
prompt during clean-up.

## Makefile Internals

- `VERBOSE=true make <target>` — show each `docker compose` command and leave
  its stdout/stderr visible.
- `QUIET=true make <target>` — skip the ANSI banner and per-phase notices.
- Default is colored output with `docker compose` stdout/stderr suppressed.

## Verification Checklist

The following must all pass before submitting:

```bash
find . -name "*.sql"  -not -path "./.git/*"                              # empty
find . \( -name "*.key" -o -name "*.pem" -o -name "*.crt" \) -not -path "./.git/*"  # empty
grep -rni password --include=Dockerfile --include='*.conf' srcs/         # empty
git check-ignore -v secrets/db_password.txt                              # hit
make -n all                                                              # no error
docker compose -f srcs/docker-compose.yml config                         # no error
```
