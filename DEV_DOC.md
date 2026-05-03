# DEV_DOC — Developer Guide

This document is intended for a developer who needs to set up,
modify, or extend the Inception stack. For day-to-day operation,
see `USER_DOC.md`.

## Repository layout

```
.
├── Makefile                       ← orchestration entry point
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore                     ← ignores .env, secrets/, .vscode/, .DS_Store, *.log
├── secrets/                       ← git-ignored, NOT part of any build context
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                       ← git-ignored, non-secret config
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       ├── init.sh        ← PID 1, idempotent first-boot init
        │       └── init.sql       ← SQL template, placeholders rewritten by init.sh
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   └── www.conf       ← PHP-FPM pool configuration
            └── tools/
                ├── init.sh        ← PID 1, idempotent first-boot init
                └── wp-config.php  ← template, placeholders rewritten by init.sh
```

Each service has its own folder under `srcs/requirements/`. The
build context for `docker compose build <service>` is that folder.

## Setting up from scratch

### 1. Host prerequisites

On a Linux 42 VM (the supported target):

- Docker Engine including the `docker compose` plugin.
- The user running `make` is in the `docker` group.
- `/etc/hosts` contains:

  ```
  127.0.0.1   kinamura.42.fr
  ```

On macOS (development only): Docker Desktop installed and running.
The `Makefile` detects macOS via `uname -s` and sets
`DATA_DIR=$HOME/tmp/data` instead of `/home/kinamura/data`.

### 2. Environment variables (`srcs/.env`)

Create `srcs/.env` with the following keys:

```
INTRA_NAME=kinamura
DOMAIN_NAME=kinamura.42.fr

# MariaDB (passwords are NOT here, see secrets/)
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

# WordPress administrator (password is NOT here)
# The login MUST NOT contain "admin" or "Admin".
WP_ADMIN_USER=kinamura
WP_ADMIN_EMAIL=kinamura@example.com

# WordPress secondary user (password is NOT here)
WP_USER=sample
WP_USER_EMAIL=sample@example.com
```

`DOMAIN_NAME` is consumed by both the NGINX build (as a
`build-arg` for the certificate's `CN`) and the WordPress runtime
(passed through `environment:` and used by `wp core install`).

`INTRA_NAME` is recorded for documentation purposes; the host
data path is currently fixed in the Makefile (see *How the named
volumes end up under `/home/kinamura/data`* below).

### 3. Secrets

Create three files under `secrets/`:

```
secrets/db_root_password.txt
secrets/db_password.txt
secrets/credentials.txt
```

`db_root_password.txt` and `db_password.txt` each contain a single
password (one line, no surrounding quotes).

`credentials.txt` is a `KEY=VALUE` file:

```
WP_ADMIN_PASSWORD=<replace-me>
WP_USER_PASSWORD=<replace-me>
```

The WordPress `init.sh` reads it via `source /run/secrets/credentials`
to populate `$WP_ADMIN_PASSWORD` and `$WP_USER_PASSWORD`.

These files are mounted into containers as Docker secrets at
`/run/secrets/<name>` and never copied into any image. The
`secrets/` directory is listed in `.gitignore`. Committing real
credentials to Git is a project failure per the subject.

## Building and launching

The `Makefile` is the only intended entry point. It exports
`DATA_DIR` before invoking `docker compose`, which is required
because `docker-compose.yml` references `${DATA_DIR}` in volume
declarations.

### Targets

| Target | Action |
|---|---|
| `all` (default) | `setup` + `build` + `up` + elapsed-time banner |
| `setup` | `mkdir -p $(DATA_DIR)/{wordpress,mariadb}` |
| `build` | `docker compose -f srcs/docker-compose.yml build` |
| `up` | `docker compose ... up -d` |
| `down` | `docker compose ... down` (containers + network) |
| `clean` | `docker compose ... down -v` (volumes too) |
| `fclean` | `clean` + remove all images + `sudo rm -rf $(DATA_DIR)` + `docker system prune -af` |
| `re` | `fclean` then `all` |
| `logs` | `docker compose ... logs -f` |
| `status` | `docker compose ... ps` |
| `info` | print resolved configuration |
| `help` | list targets |

### Validating the Compose file

```
docker compose -f srcs/docker-compose.yml config
```

Run this **after** `export DATA_DIR=/home/kinamura/data`, otherwise
Compose warns that `DATA_DIR` is unset and substitutes an empty
string — the warning is harmless when running through `make`,
which exports `DATA_DIR` itself.

## Managing containers and volumes

### Container management

```
docker compose -f srcs/docker-compose.yml ps              # status
docker compose -f srcs/docker-compose.yml stop            # stop, keep
docker compose -f srcs/docker-compose.yml start           # start again
docker compose -f srcs/docker-compose.yml restart nginx   # restart one
```

The Makefile's `down`, `clean`, and `fclean` are the canonical
ways to shut down.

### Inspecting a running container

```
docker exec -it nginx     bash       # nginx
docker exec -it wordpress bash       # WordPress / php-fpm
docker exec -it mariadb   bash       # MariaDB
```

`docker inspect <container>` confirms the network the container is
attached to, the volumes it has mounted, and the entrypoint it
ran with.

### Volume management

```
docker volume ls
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

`docker volume inspect` shows a `device` field pointing at
`/home/kinamura/data/wordpress` (or `/home/kinamura/data/mariadb`),
which is what the subject requires.

The host-side files are directly browsable:

```
ls -la /home/kinamura/data/wordpress
ls -la /home/kinamura/data/mariadb
```

### Network management

```
docker network ls
docker network inspect srcs_inception
```

The `inception` network is a user-defined bridge. Containers
resolve each other by service name through the network's embedded
DNS.

## Where data lives

| Data | Lives in (host) | Mounted in container at |
|---|---|---|
| WordPress files (themes, plugins, uploads, `wp-config.php`) | `/home/kinamura/data/wordpress/` | `/var/www/html/wordpress` (in both `wordpress` and `nginx`) |
| MariaDB data files | `/home/kinamura/data/mariadb/` | `/var/lib/mysql` (in `mariadb`) |
| WordPress 6.4.2 source | inside the `wordpress` image at `/var/www/html/wordpress-src/` | copied to the volume on first boot |
| TLS certificate and key | inside the `nginx` image at `/etc/nginx/ssl/` | generated at build time |
| Secrets | `secrets/*.txt` on host | `/run/secrets/<name>` (read-only `tmpfs`) |
| `wp-config.php` template | inside the `wordpress` image at `/usr/local/share/wp-config.php` | rendered into volume on first boot |
| `init.sql` template | inside the `mariadb` image at `/usr/local/share/init.sql` | rendered to `/tmp/init.sql`, run, deleted |

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
the Linux VM, or under `$HOME/tmp/data` in the macOS development
setup. The Makefile chooses between the two based on the host OS,
exports the result as `DATA_DIR`, and `setup` runs `mkdir -p` on
it before Compose binds the directories.

## How initialisation works

### MariaDB first boot (`requirements/mariadb/tools/init.sh`)

`init.sh` is the container's PID 1. On first boot the data
directory does not yet contain the target database, so the script:

1. Reads the root and user passwords from `/run/secrets/`.
2. Starts `mysqld` in the background so the SQL client can talk
   to it.
3. Waits for `mysqladmin ping` to succeed.
4. Copies `/usr/local/share/init.sql` to `/tmp/init.sql`,
   rewrites the four `__...__` placeholders with `sed`, and runs
   `mariadb -u root < /tmp/init.sql`. The SQL creates the
   database, creates `wp_user@'%'`, grants privileges on the
   WordPress DB, and sets the root password.
5. Removes `/tmp/init.sql` so no plaintext password remains on
   disk.
6. Cleanly shuts the background `mysqld` down.
7. `exec`s the foreground
   `mysqld --user=mysql --bind-address=0.0.0.0`, which becomes
   the container's PID 1.

`--bind-address=0.0.0.0` is required so the WordPress container
can reach MariaDB through the Docker network; the Debian default
of `127.0.0.1` accepts only intra-container connections.

On subsequent boots the data directory already contains the
database (`/var/lib/mysql/${MYSQL_DATABASE}` exists), the
initialisation block is skipped, and the script jumps straight to
`exec mysqld`.

### WordPress first boot (`requirements/wordpress/tools/init.sh`)

`init.sh` is the container's PID 1. It:

1. Reads `MYSQL_PASSWORD` from `/run/secrets/db_password` and
   `WP_ADMIN_PASSWORD` / `WP_USER_PASSWORD` from
   `/run/secrets/credentials` (sourced as a `KEY=VALUE` file).
2. Waits for MariaDB to accept connections (`mariadb-admin ping
   -h "$MYSQL_HOST"`).
3. If `wp-login.php` is absent on the volume, copies the
   WordPress 6.4.2 source tree from `/var/www/html/wordpress-src`
   to `/var/www/html/wordpress` and fixes ownership and
   permissions.
4. If `wp-config.php` is absent, copies the template from
   `/usr/local/share/wp-config.php`, then `sed`s the four
   placeholders (`__DB_NAME__`, `__DB_USER__`, `__DB_PASSWORD__`,
   `__DB_HOST__`) with their runtime values, then runs
   `wp core install` (administrator) and `wp user create`
   (second user). Both invocations pass
   `--path=/var/www/html/wordpress` and `--allow-root`.
5. `exec`s `php-fpm8.2 -F`, which becomes the container's PID 1.

On subsequent boots the volume already has the WordPress files
and `wp-config.php`, so the entire initialisation block is
skipped and the script jumps straight to `exec php-fpm8.2 -F`.

## How NGINX reaches WordPress

The `nginx.conf` `server` block sets `root` to
`/var/www/html/wordpress`. A `location /` block uses
`try_files $uri $uri/ /index.php?$args`, which is the standard
WordPress permalink fallback. A `location ~ \.php$` block forwards
PHP requests to `wordpress:9000` over FastCGI, with
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
make re
```

`re` is required because the existing volume already contains the
old version's files.

### Changing PHP-FPM tuning

Edit `srcs/requirements/wordpress/conf/www.conf` and rebuild the
`wordpress` image. The pool name `[www]`, `listen = 0.0.0.0:9000`,
and the `pm = dynamic` directive are required for the rest of
the stack to keep working; the `pm.max_children` and friends can
be tuned freely.

### Changing the TLS configuration

Edit `srcs/requirements/nginx/conf/nginx.conf` to adjust
`ssl_protocols`, `ssl_ciphers`, etc. The certificate itself is
generated by the NGINX Dockerfile's `openssl req` line and uses
`${DOMAIN_NAME}` (passed via `ARG`) as the `CN`. Rebuild with
`docker compose -f srcs/docker-compose.yml build nginx` (or
`make build`).

### Changing the bootstrap SQL

Edit `srcs/requirements/mariadb/tools/init.sql`. Existing
placeholders may be reused; new placeholders must be added to
the `sed` block in `mariadb/tools/init.sh`. Then `make re`.

### Resetting the WordPress installation only

```
make down
sudo rm -rf /home/kinamura/data/wordpress/*
make
```

The MariaDB volume is preserved, but WordPress is reinstalled
from scratch. Note that this leaves the database with the old
WordPress tables; for a clean state, prefer `make re` (or
`make clean && make`).

## CI / sanity checks

A few quick post-build checks worth running:

```
make status                                      # 3 containers Up
docker compose -f srcs/docker-compose.yml config # YAML valid
docker network ls | grep srcs_inception          # network exists
docker volume ls  | grep srcs_                   # both volumes exist
docker exec mariadb mariadb -u root \
  -p"$(cat secrets/db_root_password.txt)" \
  -e "SHOW DATABASES;"                           # wordpress DB exists
curl -k https://kinamura.42.fr | grep '<title>'  # title is "Inception"
```