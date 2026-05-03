# USER_DOC — User and Administrator Guide

This document is intended for an end user or administrator of the
Inception stack. For development and modification, see `DEV_DOC.md`.

## What this stack provides

The stack runs three containers behind a single HTTPS endpoint:

- **NGINX** — the only public entry point, listening on port 443 of
  the host. It terminates TLS (TLSv1.2 / TLSv1.3 only) using a
  self-signed certificate generated at image build time, and
  forwards PHP requests to WordPress over FastCGI.
- **WordPress + PHP-FPM** — runs the WordPress 6.4.2 codebase. The
  container has no web server of its own; it only speaks FastCGI to
  NGINX on port 9000.
- **MariaDB** — the database backing WordPress. Reachable only from
  inside the Docker network on port 3306; never published to the
  host.

The site is served at:

```
https://kinamura.42.fr
```

The same hostname also serves the WordPress administration panel at
`/wp-admin/` (and the login page at `/wp-login.php`).

## Starting and stopping the stack

All commands are run from the repository root. The `Makefile` is
the only entry point; `docker compose` does not need to be invoked
by hand.

### Start

```
make
```

(Equivalent to `make all`.) The first run takes longer because the
three images are built from scratch. Subsequent runs reuse the
cached images and start in a few seconds. When the command
returns, the three containers are up; verify with:

```
make status
```

You should see `nginx`, `wordpress`, and `mariadb`, all in `Up`
state. Only `nginx` exposes a port to the host (`0.0.0.0:443`).

### Stop without losing data

```
make down
```

Stops and removes the containers and the project network. Images
and volumes are kept; the next `make` starts again with the same
data.

### Stop and discard data

```
make clean
```

Stops the stack and removes the named volumes
(`docker compose down -v`). The next `make` reinstalls WordPress
and recreates the database from scratch.

### Full reset

```
make fclean
```

Equivalent to `make clean` plus removal of the built images, the
host data directory `/home/kinamura/data`, and a system-wide
`docker system prune -af`. Use this when you want to start from a
completely empty state. Requires `sudo` because the host data
directory is owned by `root`.

### Rebuild from scratch

```
make re
```

Equivalent to `make fclean && make all`.

## Watching the stack

### Service status

```
make status
```

Wraps `docker compose ps` and lists each container's state and
ports.

### Service logs (live tail)

```
make logs
```

Wraps `docker compose logs -f` and follows the logs of all three
containers in one stream. Press `Ctrl+C` to stop following; this
does not stop the containers.

For a single service, use `docker logs -f <service>`:

```
docker logs -f wordpress
docker logs -f mariadb
docker logs -f nginx
```

A healthy first start of `wordpress` ends with lines like:

```
Success: WordPress installed successfully.
Success: Created user 2.
Starting PHP...
```

A healthy `mariadb` ends with:

```
[Note] mysqld: ready for connections.
```

`nginx` is silent unless requests are coming in; that is expected.

### Build information

```
make info
```

Prints platform, architecture, Docker / Compose versions, the
resolved Compose file path, and the list of services.

## Accessing the website

Open a browser and navigate to:

```
https://kinamura.42.fr
```

For this domain to resolve, your `/etc/hosts` must contain:

```
127.0.0.1   kinamura.42.fr
```

The TLS certificate is self-signed, so the browser will show a
security warning the first time. Choose to proceed (the wording
varies between browsers). The warning is expected and unrelated
to any failure of the stack.

The WordPress front page is the default Twenty Twenty-Four theme
with one "Hello world!" post, authored by the administrator
account.

## Accessing the administration panel

Navigate to:

```
https://kinamura.42.fr/wp-login.php
```

Log in with the administrator credentials (see *Locating
credentials* below). From the dashboard you can:

- Edit posts and pages (Posts → All Posts; Pages → All Pages).
- Manage users (Users → All Users). The stack ships with two
  users: the administrator and an editor named `sample`.
- Change site settings (Settings → General).

Changes saved in the dashboard are immediately visible on the
public site.

## Locating and managing credentials

There are two places to look:

### `srcs/.env`

Holds non-secret configuration:

- `DOMAIN_NAME` — the host name served by NGINX.
- `MYSQL_DATABASE`, `MYSQL_USER` — database name and username.
- `WP_ADMIN_USER`, `WP_ADMIN_EMAIL` — WordPress administrator login
  and email.
- `WP_USER`, `WP_USER_EMAIL` — second WordPress user (editor)
  login and email.

This file never contains passwords. It is git-ignored.

### `secrets/`

Holds the four passwords used by the stack:

- `secrets/db_root_password.txt` — MariaDB root password.
- `secrets/db_password.txt` — password for the WordPress database
  user (`MYSQL_USER`).
- `secrets/credentials.txt` — `KEY=VALUE` file holding
  `WP_ADMIN_PASSWORD` (administrator) and `WP_USER_PASSWORD`
  (second user).

These files are mounted into the relevant containers as Docker
secrets at `/run/secrets/<name>` and are never copied into images
or environment variables. The `secrets/` directory is git-ignored.

### Changing a password

1. Edit the appropriate file under `secrets/`.
2. Run `make fclean && make` (or `make re`) to rebuild from a
   clean state.

Changing a password without resetting the volumes will leave
WordPress and MariaDB out of sync, because the existing volume
data was created with the old password.

## Verifying that the services are running

### Front-end smoke test

```
curl -k https://kinamura.42.fr | grep '<title>'
```

A working stack returns a line containing `<title>Inception</title>`.

### Database smoke test

Read the WordPress DB password from secrets and connect over TCP:

```
docker exec mariadb mariadb \
  -u wp_user \
  -p"$(cat secrets/db_password.txt)" \
  -h 127.0.0.1 \
  -e "SHOW DATABASES; SELECT user_login FROM wordpress.wp_users;"
```

You should see the `wordpress` database and the two configured
users (`kinamura`, `sample`). The `-h 127.0.0.1` matters: the
WordPress user is granted `'wp_user'@'%'`, which does **not**
match a Unix-socket connection (which MariaDB labels as
`localhost`).

Root access uses a separate file:

```
docker exec mariadb mariadb \
  -u root \
  -p"$(cat secrets/db_root_password.txt)" \
  -e "SHOW DATABASES;"
```

`'root'@'localhost'` is a socket-only account, so no `-h` is
needed.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Browser shows a certificate warning. | Certificate is self-signed. | Click through; this is expected. |
| Browser cannot resolve `kinamura.42.fr`. | `/etc/hosts` not configured. | Add `127.0.0.1   kinamura.42.fr`. |
| `502 Bad Gateway` from NGINX immediately after `make`. | WordPress is still initialising. | Wait a few seconds and reload, or `docker logs wordpress`. |
| `Error establishing a database connection`. | A password file was edited without running `make clean`. | `make fclean && make`. |
| `Access denied for user 'wp_user'@'localhost'`. | Connecting via Unix socket; the user only allows TCP (`'%'`). | Add `-h 127.0.0.1` to the `mariadb` command. |
| Site content vanished after a make invocation. | `make clean` or `make fclean` was run. | Data is gone; this is by design. |
| `make fclean` asks for `sudo` password. | The host data directory is owned by `root`. | Enter your sudo password (or pre-clean it manually). |