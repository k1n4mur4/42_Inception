*This project has been created as part of the 42 curriculum by kinamura.*

# Inception

## Description

Inception is a 42 system administration project that introduces Docker
through the design and deployment of a small, multi-service web
infrastructure. The goal is to package three independent services —
NGINX, WordPress (with PHP-FPM), and MariaDB — as separate Docker
containers, link them through a private Docker network, persist their
state on Docker named volumes, and expose the whole stack to the host
machine over HTTPS only.

The stack is built and orchestrated entirely from a project-local
`Makefile` and a `docker-compose.yml`. No prebuilt images from
DockerHub are used (apart from the Debian base image): every service
ships with its own hand-written Dockerfile, configuration files, and
entrypoint script. NGINX is the single entry point on port 443 and
terminates TLS (TLSv1.2 / TLSv1.3 only) for `kinamura.42.fr`. WordPress
runs as PHP-FPM behind it, talking FastCGI on port 9000. MariaDB sits
behind WordPress and listens on port 3306, never exposed to the host.

WordPress is initialised on first boot through `wp-cli`: a non-`admin`
administrator (`kinamura`) and a second editor user (`sample`) are
created automatically. Database files live on the `mariadb_data` named
volume; WordPress site files live on the `wordpress_data` named
volume. Both volumes are bound to `/home/kinamura/data` on the host
(or `/Users/kinamura/tmp/data` when developed on macOS — the
`Makefile` detects the host OS).

## Instructions

### Prerequisites

- Linux VM (or macOS for development) with Docker Engine and the
  `docker compose` plugin installed.
- A line in `/etc/hosts` pointing the project domain to the loopback
  address: `127.0.0.1   kinamura.42.fr`.
- The three secret files described in `DEV_DOC.md` placed under
  `secrets/`. They are intentionally **not** committed to Git.
- A `srcs/.env` file with the non-secret environment variables
  (database name, user, WordPress admin login, etc.). A template is
  documented in `DEV_DOC.md`.

### Build and run

From the repository root:

```
make
```

This single command:

1. Creates the host directories that back the named volumes
   (`/home/kinamura/data/{wordpress,mariadb}` on Linux).
2. Builds three images (`nginx:inception`, `mariadb:inception`,
   `wordpress:inception`) from local Dockerfiles.
3. Starts all three containers in the background through
   `docker compose up -d`.

Open `https://kinamura.42.fr` in a browser (the certificate is
self-signed, so the browser will warn the first time).

### Common targets

- `make` — build images and start the stack.
- `make down` — stop the stack without deleting images or volumes.
- `make clean` — stop and remove containers and the project network.
- `make fclean` — `clean` plus removing built images and the host
  volume directories. Destroys all WordPress and database data.
- `make re` — `fclean` followed by a fresh build and start.

### Stopping the stack

```
make down
```

### Resetting everything

```
make fclean
```

This is also the right command when changing the database
configuration or WordPress admin credentials, since it wipes the
volumes that store first-boot state.

## Resources

The following references were used while building the project:

- Docker official documentation — Dockerfile reference, Compose file
  reference, named volumes, networks: <https://docs.docker.com/>.
- NGINX documentation — `ssl_protocols`, FastCGI proxying:
  <https://nginx.org/en/docs/>.
- MariaDB documentation — `mysqld --bind-address`, initial setup
  via `mariadb` client: <https://mariadb.com/kb/en/documentation/>.
- WordPress and `wp-cli` documentation — `wp core install`,
  `wp user create`: <https://developer.wordpress.org/cli/commands/>.
- 42's *Inception* subject (this repository's `Inception_v52.pdf`)
  for scope, naming, and validation rules.

### Use of AI

AI assistance (Claude) was used as a **design and concept-clarification
partner**, not as a code generator. Concretely, AI was used to:

- Walk through the conceptual differences between virtual machines and
  containers, between Docker named volumes and bind mounts, between
  Docker secrets and environment variables, and between a Docker
  network and the host network — i.e. the four comparisons required
  by the subject. Those discussions shaped the architectural choices
  documented in *Project description* below.
- Sanity-check the boot order and the failure modes of each service.
  In particular, AI helped reason about why MariaDB needs
  `--bind-address=0.0.0.0` (so the WordPress container can reach it
  through the Docker network), why PHP-FPM must listen on
  `0.0.0.0:9000` rather than a Unix socket, and why
  `/var/www/html/wordpress` must be the mount point shared by both
  the NGINX and the WordPress containers so that
  `SCRIPT_FILENAME` resolves consistently on both sides of the
  FastCGI hop.
- Cross-read error messages during integration. Examples:
  `mv: cannot move 'wordpress'` revealed a missing `mkdir -p
  /var/www/html`; `unknown --skip-email parameter` revealed that the
  flag exists for `wp core install` but not for `wp user create`;
  `the process manager is missing` revealed an incomplete `www.conf`.
  In every case the fix was understood, applied, and verified by
  hand before moving on.

All Dockerfiles, `init.sh` scripts, configuration files, the
`Makefile`, and `docker-compose.yml` were written and edited by hand,
reviewed line by line, and validated by running and inspecting the
stack.

## Project description

### Architecture overview

```
                          WWW
                           │
                          443 (TLSv1.2 / TLSv1.3)
                           │
            ┌──────────────▼───────────────┐
            │ Host (Linux VM, kinamura)    │
            │  /home/kinamura/data/        │
            │  ├── mariadb/   (volume)     │
            │  └── wordpress/ (volume)     │
            │                              │
            │  ┌──── Docker network ────┐  │
            │  │                        │  │
            │  │  nginx ──9000──► wp    │  │
            │  │                  │     │  │
            │  │                3306    │  │
            │  │                  │     │  │
            │  │                  ▼     │  │
            │  │               mariadb  │  │
            │  └────────────────────────┘  │
            └──────────────────────────────┘
```

NGINX is the only container with a host-published port (`443:443`).
WordPress and MariaDB are reachable only from within the
`inception` Docker network, by their service names (`wordpress`,
`mariadb`).

### Sources included

- `Makefile` — orchestration, OS-aware data directory setup,
  build / clean targets.
- `srcs/docker-compose.yml` — service, volume, network, and secret
  declarations.
- `srcs/.env` — non-secret environment variables (domain, DB names,
  user logins). **Never** contains passwords.
- `secrets/` — three local secret files (`db_password.txt`,
  `db_root_password.txt`, `credentials.txt`). Git-ignored.
- `srcs/requirements/nginx/` — Dockerfile, `nginx.conf`, generated
  TLS material.
- `srcs/requirements/mariadb/` — Dockerfile, first-boot `init.sh`
  that bootstraps the database and user from secrets.
- `srcs/requirements/wordpress/` — Dockerfile, `www.conf` for
  PHP-FPM, `wp-config.php` template, first-boot `init.sh` that runs
  `wp core install` and `wp user create`.

### Main design choices

- **Debian Bookworm** as the base image for all three services. The
  subject allows either Debian or Alpine; Debian was chosen for the
  more predictable package layout (`php-fpm` → `/usr/sbin/php-fpm8.2`,
  `mariadb-server` → `mysqld`) and for the breadth of available
  documentation.
- **One Dockerfile per service**, named after the service, never
  pulling a prebuilt application image. The `latest` tag is never
  used.
- **Foreground PID 1.** Every container's main process runs in the
  foreground (`nginx -g 'daemon off;'`, `mysqld --user=mysql`,
  `php-fpm8.2 -F`). No `tail -f`, no `sleep infinity`, no shell
  loops keeping the container alive.
- **Idempotent first-boot init scripts.** `mariadb/tools/init.sh`
  and `wordpress/tools/init.sh` detect existing state on the named
  volumes and skip initialisation on subsequent restarts, then
  `exec` the long-running daemon so signals propagate correctly.
- **Secrets, not env vars, for passwords.** Database root and user
  passwords, plus the WordPress admin / second-user passwords, live
  in files under `secrets/` and are mounted into the relevant
  containers at `/run/secrets/...`. The `.env` file holds only
  non-secret configuration.
- **Host-name routing.** The domain `kinamura.42.fr` is mapped to
  `127.0.0.1` via `/etc/hosts`, and `server_name kinamura.42.fr` in
  `nginx.conf` matches it.

### Virtual Machines vs Docker

A virtual machine emulates a complete computer: a hypervisor allocates
CPU, memory, and virtual hardware to a guest OS that runs its own
kernel. Each VM ships its own kernel, its own init system, its own
device drivers — gigabytes of state, minutes to boot.

A Docker container shares the host kernel and isolates only what
needs to be isolated: process IDs, mount points, network interfaces,
user IDs (through Linux namespaces), and resource quotas (through
cgroups). A container is a process tree with a private filesystem
view, not a separate machine.

The practical consequence for this project: starting all three
services takes seconds, the images are tens of megabytes each, and
the host can run dozens of them without strain — none of which would
be true if `nginx`, `mariadb`, and `wordpress` were separate VMs.

The trade-off is that a container is **not** a security boundary
equivalent to a VM. A kernel exploit on the host affects every
container. For an isolation-critical workload, a VM (or a VM-per-tenant
model on top of containers) is still the right choice.

On a macOS development machine, Docker Desktop runs a small Linux VM
under the hood and runs containers inside it; the model on the
target Linux 42 VM is the simpler one above.

### Secrets vs Environment Variables

Environment variables are convenient but are visible to anyone who can
inspect the process: `docker inspect`, `/proc/<pid>/environ`,
`ps eww`, child processes inherited via `fork`/`exec`, and crash
dumps. They also tend to leak into logs whenever a script accidentally
echoes its environment.

Docker secrets are file-mounted at `/run/secrets/<name>` inside the
container. They are not exported into the environment, are owned by
`root` with restrictive permissions, and live on a `tmpfs` that is
unmounted when the container stops. A secret can be read by code that
opens the file, but it never appears in `docker inspect` output.

In this project the database root password, the WordPress DB
password, and the two WordPress user passwords are all secrets. The
DB **name**, the DB **user name**, the WordPress admin **login**, and
the **domain name** are environment variables: they are not sensitive
on their own, and putting them in `.env` keeps the config diffable
and reviewable.

### Docker Network vs Host Network

`network_mode: host` would make each container share the host's
network namespace: the container's `localhost` and the host's
`localhost` would be the same loopback. Two containers cannot both
bind port 3306 in that mode. There is also no DNS service-name
resolution between containers, because there is no separate network
to resolve names on.

A user-defined Docker bridge network — the `inception` network in
this project — gives each container its own network namespace,
assigns it a private IP, and runs an embedded DNS server that
resolves service names (`mariadb`, `wordpress`, `nginx`) to those
private IPs. NGINX therefore reaches PHP-FPM as `wordpress:9000`,
and PHP-FPM reaches MariaDB as `mariadb:3306`, without anyone
guessing IP addresses.

The subject also forbids `network_mode: host`, `--link`, and
`links:`. The bridge network is the only correct choice given the
rules and the design.

### Docker Volumes vs Bind Mounts

A bind mount maps an arbitrary host path into a container. The host
path is whatever the user specifies; permissions, ownership, and
existence are the host's responsibility, and the container has no
say in any of that.

A Docker named volume is a managed mount point. Docker creates the
backing storage, tracks the volume in its own metadata, sets sane
default permissions, and lets `docker volume ls` / `docker volume
inspect` enumerate and describe it. Volumes survive `docker compose
down`; they are removed only with `docker compose down -v` or
`docker volume rm`.

The subject requires named volumes for both persistent stores, with
their data physically located under `/home/kinamura/data`. This
project achieves both at once by declaring named volumes whose
`driver_opts` bind them to subdirectories of `/home/kinamura/data`:
the volume is a managed Docker resource (named, listable,
inspectable), and at the same time the bytes on disk live exactly
where the subject demands.