# USER_DOC — User and Administrator Guide

This document is intended for an end user or administrator of the
Inception stack. It does not cover development or modification of
the project; for that, see `DEV_DOC.md`.

## What this stack provides

The stack runs three containers behind a single HTTPS endpoint:

- **NGINX** — the only public entry point, listening on port 443 of
  the host. It terminates TLS (TLSv1.2 / TLSv1.3 only) using a
  self-signed certificate generated at image build time, and forwards
  PHP requests to WordPress over FastCGI.
- **WordPress + PHP-FPM** — runs the WordPress 6.4.2 codebase. The
  container has no web server of its own; it only speaks FastCGI to
  NGINX on port 9000.
- **MariaDB** — the database backing WordPress. Reachable only from
  inside the Docker network; never published on the host.

The site is served at:

```
https://kinamura.42.fr
```

The same URL also serves the WordPress administration panel at
`/wp-admin/` (and the login page at `/wp-login.php`).

## Starting and stopping the stack

All commands are run from the repository root.

### Start

```
make
```

The first run takes longer because the three images are built from
scratch. Subsequent runs reuse the cached images and start in a few
seconds.

When the command returns, the three containers are up. Verify with:

```
docker ps
```

You should see `nginx`, `wordpress`, and `mariadb`, all in `Up`
state. Only `nginx` exposes a port to the host (`0.0.0.0:443`).

### Stop

```
make down
```

This stops and removes the containers and the project network, but
leaves images and volumes intact. Data on the WordPress and database
volumes is preserved.

### Reset

```
make fclean
```

This is the full reset: containers, network, images, **and** the
host data directories that back the named volumes are removed. The
next `make` will reinstall WordPress from scratch and recreate the
database. Use this when you want to discard all content.

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
varies between browsers). The warning is expected and unrelated to
any failure of the stack.

The WordPress front page is the default Twenty Twenty-Four theme
with one "Hello world!" post, authored by the administrator account.

## Accessing the administration panel

Navigate to:

```
https://kinamura.42.fr/wp-login.php
```

Log in with the administrator credentials (see *Locating credentials*
below). From the dashboard you can:

- Edit posts and pages (Posts → All Posts; Pages → All Pages).
- Manage users (Users → All Users). The stack ships with two users:
  the administrator and an editor named `sample`.
- Change site settings (Settings → General).

Changes saved in the dashboard are immediately visible on the
public site.

## Locating and managing credentials

There are two places to look:

### `srcs/.env`

Holds non-secret configuration: domain name, database name, database
user name, WordPress admin login, WordPress admin email, second
WordPress user login and email. This file should never contain
passwords. It is in the repository (typically Git-ignored in real
deployments, included here for evaluation).

### `secrets/`

Holds the four passwords used by the stack:

- `secrets/db_root_password.txt` — MariaDB root password.
- `secrets/db_password.txt` — password for the WordPress database
  user.
- `secrets/credentials.txt` — `KEY=VALUE` file holding
  `WP_ADMIN_PASSWORD` (administrator) and `WP_USER_PASSWORD`
  (second user).

These files are mounted into the relevant containers as Docker
secrets at `/run/secrets/<name>` and are never copied into images
or environment variables.

To change a password:

1. Edit the appropriate file under `secrets/`.
2. Run `make fclean && make` to rebuild the stack from a clean
   state. Changing a password without resetting the database will
   leave WordPress and MariaDB out of sync and the site will fail
   to load.

## Verifying that the services are running

### Quick check

```
docker ps
```

All three containers should be `Up`. If any is missing or stuck in
`Restarting`, inspect its logs.

### Per-service logs

```
docker logs nginx
docker logs wordpress
docker logs mariadb
```

A healthy first start of `wordpress` ends with lines similar to:

```
Success: WordPress installed successfully.
Success: Created user 2.
Starting PHP...
```

A healthy `mariadb` ends with:

```
[Note] mysqld: ready for connections.
```

A healthy `nginx` is silent unless requests are coming in.

### Front-end smoke test

```
curl -k https://kinamura.42.fr | grep '<title>'
```

A working stack returns a line containing `<title>Inception</title>`.

### Database smoke test

```
docker exec -it mariadb mariadb -u root -p
```

After entering the root password (from
`secrets/db_root_password.txt`):

```sql
USE wordpress;
SHOW TABLES;
SELECT user_login FROM wp_users;
```

You should see the twelve standard `wp_*` tables and the two
configured users.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Browser shows certificate warning. | Certificate is self-signed. | Click through; this is expected. |
| Browser cannot resolve `kinamura.42.fr`. | `/etc/hosts` not configured. | Add `127.0.0.1   kinamura.42.fr`. |
| `502 Bad Gateway` from NGINX. | WordPress container is not yet ready. | Wait a few seconds and reload, or check `docker logs wordpress`. |
| WordPress page shows "Error establishing a database connection". | MariaDB is unreachable or the password files were changed without `make fclean`. | Run `make fclean && make`. |
| Site content vanished after a `make` invocation. | A `make fclean` removed the host data directories. | Data is gone; restart from scratch. |