# 42_Inception
*This project has been created as part of the 42 curriculum by kinamura.*

## Description

Inception is a system administration project that uses Docker to set up a small infrastructure with multiple services. The project creates a WordPress website with NGINX, MariaDB, running in separate containers orchestrated by Docker Compose.

## Instructions

### Prerequisites
- Docker
- Docker Compose
- Make

### Installation

1. Clone the repository
2. Create secrets files in `secrets/` directory
3. Configure `.env` file in `srcs/`
4. Run `make`

### Usage
```bash
make        # Build and start all containers
make down   # Stop containers
make clean  # Stop containers and remove volumes
make re     # Rebuild everything
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI](https://wp-cli.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)

### AI Usage
AI was used to assist with understanding Docker concepts and debugging configuration issues.

## Project Description

### Virtual Machines vs Docker
- **VM**: Runs a complete OS with its own kernel on a hypervisor
- **Docker**: Shares the host kernel, runs isolated processes in containers
- Docker is lighter, faster to start, and uses fewer resources

### Secrets vs Environment Variables
- **Environment Variables**: Visible via `docker inspect` and process listings
- **Secrets**: Stored as files in `/run/secrets/`, accessible only within the container
- Secrets provide better security for sensitive data

### Docker Network vs Host Network
- **Host Network**: Container uses host's network directly, no isolation
- **Docker Network (bridge)**: Isolated network, containers communicate via DNS
- Docker Network provides better security and isolation

### Docker Volumes vs Bind Mounts
- **Docker Volumes**: Managed by Docker, stored in Docker's internal location
- **Bind Mounts**: User specifies exact host path
- Bind Mounts give more control over data location
EOF