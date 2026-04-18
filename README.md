# 42_Inception
*This project has been created as part of the 42 curriculum by kinamura.*

## Description

Inception is a system administration project that builds a small HTTPS infrastructure using Docker Compose. Three services run in separate containers — NGINX (TLS termination), WordPress + php-fpm (CMS), and MariaDB (database) — communicating over an isolated Docker bridge network, with persistent data stored in named volumes at `/home/kinamura/data/`.

### Virtual Machines vs Docker

| | Virtual Machine | Docker |
|-|----------------|--------|
| Kernel | Own kernel via hypervisor | Shares host kernel |
| Startup | Minutes | Seconds |
| Resources | Heavy (full OS) | Lightweight (process isolation) |
| Use case | Full OS isolation needed | Microservice / process isolation |

Docker containers are not VMs. They share the host kernel and run as isolated processes, which makes them faster and more resource-efficient but with less isolation.

### Secrets vs Environment Variables

| | Environment Variables | Docker Secrets |
|-|----------------------|----------------|
| Storage | Process environment | File in `/run/secrets/` |
| Visibility | `docker inspect`, `/proc/*/environ` | Only accessible inside container |
| Use case | Non-sensitive config | Passwords, API keys |

This project uses `.env` for non-sensitive configuration (domain name, usernames) and Docker secrets for all passwords.

### Docker Network vs Host Network

| | Docker Bridge Network | Host Network |
|-|----------------------|--------------|
| Isolation | Containers get private IPs | Container uses host IP stack |
| DNS | Containers resolve each other by name | No Docker DNS |
| Security | Isolated from host and other networks | No isolation |

This project uses a bridge network so containers communicate by service name (e.g., `wordpress:9000`) without exposing internal ports to the host.

### Docker Volumes vs Bind Mounts

| | Named Volumes | Bind Mounts |
|-|--------------|-------------|
| Management | Docker-managed | User specifies exact host path |
| Portability | Portable across systems | Tied to host path |
| Usage in compose | `volumes:` top-level key | `- /host/path:/container/path` |

This project uses named volumes (backed by `/home/kinamura/data/`) to satisfy both the requirement for named volumes and for data to be accessible at a known host path.

## Instructions

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Make

### Installation

1. Clone the repository
2. Create `secrets/` files (see [DEV_DOC.md](DEV_DOC.md))
3. Create `srcs/.env` (see [DEV_DOC.md](DEV_DOC.md))
4. Add `127.0.0.1 kinamura.42.fr` to `/etc/hosts`
5. Run `make`

### Usage

```bash
make        # Build and start all containers
make down   # Stop containers
make clean  # Stop containers and remove volumes
make re     # Full rebuild from scratch
make logs   # Follow container logs
make status # Show service status
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)

### AI Usage

AI (Claude) was used in the following parts of this project:

- **Debugging**: Identifying that `wp core install` was skipped when `wp-config.php` already existed from a failed previous run, and fixing the init script to check `wp core is-installed` instead.
- **MariaDB init**: Replacing `sleep 5` with a proper `mysqladmin ping` wait loop and adding root password setup using the `db_root_password` secret.
- **Documentation**: Drafting the structure of USER_DOC.md and DEV_DOC.md based on subject requirements.

All generated content was reviewed, understood, and verified to work correctly before inclusion.
