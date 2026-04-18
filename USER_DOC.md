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

Add the domain to `/etc/hosts` on the host machine (already done inside the VM):