# DEV_DOC — Developer Guide

This document is intended for a developer who needs to set up,
modify, or extend the Inception stack. For day-to-day operation,
see `USER_DOC.md`.

## Repository layout

```
.
├── Makefile                 ← build / run / clean orchestration
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                 ← Git-ignored, not part of the build context
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                 ← non-secret environment variables
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── init.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf      ← PHP-FPM pool configuration
            └── tools/
                ├── init.sh
                └── wp-config.php  ← template, placeholders rewritten by init.sh
```

Each service has its own folder under `srcs/requirements/`. The
build context for `docker compose build <service>` is that folder,
which keeps the per-service Dockerfile self-contained.

## Setting up from scratch

### 1. Host prerequisites

On a Linux 42 VM (the supported target):

- Docker Engine, including the `docker compose` plugin.
- The user running `make` is in the `docker` group, or `make` is
  invoked with `sudo`.
- `/etc/hosts` contains:

  ```
  127.0.0.1   kinamura.42.fr
  ```

On macOS (development only): Docker Desktop installed and running.
The `Makefile` detects macOS and sets `DATA_DIR` to
`/Users/$(USER)/tmp/data` instead of `/home/$(USER)/data`.

### 2. Environment variables

Create `srcs/.env`. Below is the full list of variables expected
by the stack, with safe example values:

```
INTRA_NAME=kinamura
DOMAIN_NAME=kinamura.42.fr

# MariaDB (passwords are NOT here, see secrets/)
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

# WordPress administrator (passwords are NOT here)
# The login MUST NOT contain "admin" or "Admin".
WP_ADMIN_USER=kinamura
WP_ADMIN_EMAIL=kinamura@example.com

# WordPress secondary user (passwords are NOT here)
WP_USER=sample
WP_USER_EMAIL=sample@example.com
```

The Makefile reads `INTRA_NAME` to build the host data directory
path. `DOMAIN_NAME` is consumed by both the NGINX build (as a
build-arg for the certificate's `CN`) and the WordPress runtime
(passed through `environment:` and used by `wp core install`).

### 3. Secrets

Create three files under `secrets/`. They are mounted into
containers as Docker secrets and read from `/run/secrets/<name>`
inside the container.

```
secrets/db_root_password.txt
secrets/db_password.txt
secrets/credentials.txt
```

`db_root_password.txt` and `db_password.txt` each contain a single
password on a single line, with no trailing newline if possible.

`credentials.txt` is a `KEY=VALUE` file:

```
WP_ADMIN_PASSWORD=<replace-me>
WP_USER_PASSWORD=<replace-me>
```

The WordPress `init.sh` reads it with `source /run/secrets/credentials`
to populate `$WP_ADMIN_PASSWORD` and `$WP_USER_PASSWORD`.

The `secrets/` directory is listed in `.gitignore` and is never
copied into a Docker image. Committing real credentials to Git is a
project failure per the subject.

## Building and launching

### Building images

```
make build
```

(or `make` with no target, which builds and then starts.) Equivalent
to:

```
docker compose -f srcs/docker-compose.yml build
```

The Makefile sets `DATA_DIR` and exports it before invoking Compose,
which is required because `docker-compose.yml` references `${DATA_DIR}`
in volume declarations.

### Starting the stack

```
make
```

Equivalent to `make build` followed by `docker compose -f
srcs/docker-compose.yml up -d`. The `setup` Make target ensures
`/home/kinamura/data/{wordpress,mariadb}` exist before Compose tries
to bind-mount them.

### Following logs

```
docker logs -f wordpress
docker logs -f mariadb
docker logs -f nginx
```

### Validating the Compose file

```
docker compose -f srcs/docker-compose.yml config
```

This expands all `${VAR}` references (warning if `DATA_DIR` is
unset, which is normal when running `docker compose` directly
instead of through `make`) and prints the effective configuration.

## Managing containers and volumes

### Container management

```
docker compose -f srcs/docker-compose.yml ps              # status
docker compose -f srcs/docker-compose.yml stop            # stop
docker compose -f srcs/docker-compose.yml start           # start
docker compose -f srcs/docker-compose.yml restart nginx   # restart one
docker compose -f srcs/docker-compose.yml down            # stop + remove
```

Or via the corresponding Make targets (`make down`, `make clean`,
`make re`).

### Inspecting a running container

```
docker exec -it nginx     bash       # poke around in nginx
docker exec -it wordpress bash       # poke around in WordPress / php-fpm
docker exec -it mariadb   bash       # poke around in MariaDB
```

`docker inspect <container>` is the canonical way to confirm the
network the container is attached to, the volumes it has mounted,
and the entrypoint it ran with.

### Volume management

```
docker volume ls
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

`docker volume inspect` should show a `device` field pointing at
`/home/kinamura/data/wordpress` (or `/home/kinamura/data/mariadb`),
which is what the subject requires.

To list the WordPress files visible from the host:

```
ls -la /home/kinamura/data/wordpress
```

### Removing volumes

`make fclean` removes containers, images, and the host directories
backing the volumes. To remove the volumes themselves through
Docker (rather than the host paths) without going through the
Makefile:

```
docker compose -f srcs/docker-compose.yml down -v
```

## Where data lives

| Data | Lives in (host) | Mounted in container at |
|---|---|---|
| WordPress files (themes, plugins, uploads, `wp-config.php`) | `/home/kinamura/data/wordpress/` | `/var/www/html/wordpress` (in both `wordpress` and `nginx`) |
| MariaDB data files | `/home/kinamura/data/mariadb/` | `/var/lib/mysql` (in `mariadb`) |
| Source tarball of WordPress 6.4.2 | inside the `wordpress` image at `/var/www/html/wordpress-src/` | copied to the volume on first boot |
| TLS certificate and key | inside the `nginx` image at `/etc/nginx/ssl/` | generated at build time |
| Secrets | `secrets/*.txt` on host | `/run/secrets/<name>` (read-only `tmpfs`) |

## How the named volumes end up under `/home/kinamura/data`

The volumes are declared with the `local` driver and `driver_opts`
that bind them to a specific host path:

```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_DIR}/wordpress
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_DIR}/mariadb
```

This is still a Docker named volume — it is listable through
`docker volume ls`, inspectable through `docker volume inspect`,
and deletable through `docker volume rm`. But its bytes are stored
exactly where the subject demands: under `/home/kinamura/data` on
the Linux VM, or `/Users/kinamura/tmp/data` in the macOS
development setup. The Makefile chooses between the two based on
the host OS, exports the result as `DATA_DIR`, and `setup` runs
`mkdir -p` on it before Compose binds the directories.

## How initialisation works

### MariaDB first boot

`requirements/mariadb/tools/init.sh` runs as the container's PID 1.
On first boot the data directory does not yet contain the target
database, so the script:

1. Reads the root and user passwords from `/run/secrets/`.
2. Starts `mysqld` in the background.
3. Waits for `mysqladmin ping` to succeed.
4. Creates the database, the WordPress user, grants privileges,
   and sets the root password.
5. Shuts that background `mysqld` down cleanly.
6. `exec`s the foreground `mysqld --user=mysql --bind-address=0.0.0.0`
   that becomes the container's main process.

`--bind-address=0.0.0.0` is required so the WordPress container can
reach MariaDB through the Docker network; the Debian default of
`127.0.0.1` accepts only intra-container connections.

On subsequent boots the data directory already contains the database
and the script skips the initialisation block, going straight to
`exec mysqld`.

### WordPress first boot

`requirements/wordpress/tools/init.sh` runs as the container's PID 1.
It:

1. Reads `MYSQL_PASSWORD` from `/run/secrets/db_password` and
   `WP_ADMIN_PASSWORD` / `WP_USER_PASSWORD` from
   `/run/secrets/credentials` (sourced as a `KEY=VALUE` file).
2. Waits for MariaDB to accept connections (`mariadb-admin ping
   -h mariadb`).
3. If `wp-login.php` is absent on the volume, copies the
   WordPress 6.4.2 source tree from `/var/www/html/wordpress-src`
   to `/var/www/html/wordpress` and fixes up file ownership and
   permissions.
4. If `wp-config.php` is absent, copies the template from
   `/usr/local/share/wp-config.php`, then `sed`s the four
   placeholders (`__DB_NAME__`, `__DB_USER__`, `__DB_PASSWORD__`,
   `__DB_HOST__`) with their runtime values.
5. Runs `wp core install` to seed the database and create the
   administrator, then `wp user create` for the second user.
   Both invocations pass `--path=/var/www/html/wordpress` and
   `--allow-root`.
6. `exec`s `php-fpm8.2 -F` as the container's main process.

On subsequent boots the volume already has the WordPress files and
`wp-config.php`, so the entire initialisation block is skipped and
the script jumps straight to `exec php-fpm8.2 -F`.

## How NGINX reaches WordPress

The `nginx.conf` `server` block sets `root` to
`/var/www/html/wordpress`. A `location /` block uses `try_files
$uri $uri/ /index.php?$args`, which is the standard WordPress
permalink fallback. A `location ~ \.php$` block forwards PHP
requests to `wordpress:9000` over FastCGI, with
`fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name`.

For `SCRIPT_FILENAME` to resolve to a real file inside the
WordPress container, both containers must agree on the path. That
is why the same `wordpress_data` volume is mounted at
`/var/www/html/wordpress` in both NGINX and WordPress.

## Modifying the stack

### Changing the WordPress version

Edit `srcs/requirements/wordpress/Dockerfile`: bump
`wordpress-6.4.2.tar.gz` to the desired version, both in the
download URL and in the `tar -xzf` line. Then:

```
make fclean && make
```

`fclean` is required because the existing volume already contains
the old version's files.

### Changing PHP-FPM tuning

Edit `srcs/requirements/wordpress/conf/www.conf` and rebuild the
`wordpress` image. The pool name `[www]`, `listen = 0.0.0.0:9000`,
and the `pm = dynamic` directive are required for the rest of the
stack to keep working; the `pm.max_children` and friends can be
tuned freely.

### Changing the TLS configuration

Edit `srcs/requirements/nginx/conf/nginx.conf` to adjust
`ssl_protocols`, `ssl_ciphers`, etc. The certificate itself is
generated by the NGINX Dockerfile's `openssl req` line and uses
`${DOMAIN_NAME}` (passed via `ARG`) as the `CN`. Rebuild with
`docker compose build nginx`.

### Resetting the WordPress installation only

```
make down
sudo rm -rf /home/kinamura/data/wordpress/*
make
```

(Or `make fclean && make` for a full reset including the database.)