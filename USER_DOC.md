# User Documentation

## Services Overview

This stack provides the following services, all running as Docker containers:

| Service   | Description                           | Exposed Port |
|-----------|---------------------------------------|--------------|
| NGINX     | Reverse proxy and TLS termination     | 443 (HTTPS)  |
| WordPress | CMS application running with php-fpm  | internal only |
| MariaDB   | Relational database for WordPress     | internal only |

NGINX is the only service exposed to the host. WordPress and MariaDB are
reachable only through the internal Docker network `inception`.

## Starting and Stopping

### Start the stack
```bash
make
```
This builds all Docker images and starts every container in detached mode.

### Stop the stack (keep data)
```bash
make down
```

### Stop and remove volumes (keep host data, images)
```bash
make clean
```

### Fully reset (also removes host data at `/home/kinamura/data` and images)
```bash
make fclean
```

### Rebuild from scratch
```bash
make re
```

## Accessing the Website

Add the domain to `/etc/hosts` on the host machine (already done inside the 42 VM):

```bash
echo "127.0.0.1 kinamura.42.fr" | sudo tee -a /etc/hosts
```

Then open the site in a browser:

- https://kinamura.42.fr/        — WordPress front page
- https://kinamura.42.fr/wp-admin — Admin dashboard

### Self-signed certificate warning

NGINX presents a self-signed certificate generated at image build time
(`/etc/nginx/ssl/nginx.{key,crt}`, `CN=kinamura.42.fr`, 365 days, RSA 2048).
Every browser will show "Not secure" / "NET::ERR_CERT_AUTHORITY_INVALID" on
first visit. Accept the warning to continue — this is expected for the
42 Inception project and the server only speaks TLSv1.2 / TLSv1.3.

## Logging in

### WordPress admin

- User: value of `WP_ADMIN_USER` in `srcs/.env`
- Password: `WP_ADMIN_PASSWORD` line from `secrets/credentials.txt`

### Second WordPress user (non-admin)

- User: value of `WP_USER` in `srcs/.env`
- Password: `WP_USER_PASSWORD` line from `secrets/credentials.txt`

## Troubleshooting

| Symptom                               | Check                                                               |
|---------------------------------------|---------------------------------------------------------------------|
| Browser can't reach `kinamura.42.fr`  | `/etc/hosts` entry; `make status` shows `nginx` Up; port 443 free   |
| 502 Bad Gateway                       | `docker compose -f srcs/docker-compose.yml logs wordpress`          |
| WordPress cannot connect to DB        | `docker compose -f srcs/docker-compose.yml logs mariadb`; secrets   |
| Changes to `.env` / secrets not seen  | `make re` (rebuild from scratch) — env is baked at container start |
