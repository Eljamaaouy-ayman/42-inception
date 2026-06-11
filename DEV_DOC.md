# Inception — Developer Documentation

This guide provides technical instructions for developers to set up, build, and manage the Inception infrastructure.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Building and Launching](#building-and-launching)
4. [Container Management Commands](#container-management-commands)
5. [Volume Management](#volume-management)
6. [Data Persistence](#data-persistence)
7. [Development Workflow](#development-workflow)
8. [Debugging](#debugging)

---

## Prerequisites

### Required Software

| Software       | Minimum Version | Installation                              |
|----------------|-----------------|-------------------------------------------|
| Docker Engine  | 20.10+          | https://docs.docker.com/engine/install/   |
| Docker Compose | 2.0+            | Included with Docker Desktop              |
| Make           | 4.0+            | `sudo apt install make`                   |
| Git            | 2.0+            | `sudo apt install git`                    |

### Verify Installation

```bash
# Check Docker
docker --version
docker compose version

# Check Make
make --version

# Verify Docker daemon is running
docker info
```

### System Requirements

- **OS:** Linux (tested on Debian/Ubuntu)
- **RAM:** Minimum 2GB, recommended 4GB
- **Disk:** Minimum 5GB free space
- **Ports:** 443 (HTTPS), 21 (FTP), 30000-30009 (FTP passive)

---

## Environment Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd inception
```

### 2. Create Data Directories

The project stores persistent data in `/home/ael-jama/data/`. Create these directories:

```bash
sudo mkdir -p /home/ael-jama/data/mariadb
sudo mkdir -p /home/ael-jama/data/wordpress
sudo mkdir -p /home/ael-jama/data/redis

# Set appropriate permissions
sudo chown -R $USER:$USER /home/ael-jama/data
```

### 3. Configure Environment Variables

Edit the environment file at `srcs/requirements/.env`:

```bash
nano srcs/requirements/.env
```

**Current configuration:**

```env
DOMAIN_NAME=ael-jama.42.fr

MYSQL_DATABASE=wordpress
MYSQL_HOSTNAME=mariadb
MYSQL_USER=wp_user
```

| Variable         | Description                        | Default         |
|------------------|------------------------------------|-----------------|
| `DOMAIN_NAME`    | Domain for Nginx server_name       | ael-jama.42.fr   |
| `MYSQL_DATABASE` | WordPress database name            | wordpress       |
| `MYSQL_HOSTNAME` | MariaDB container hostname         | mariadb         |
| `MYSQL_USER`     | Database user for WordPress        | wp_user         |

### 4. Configure Secrets

Secrets are stored as plain text files in `srcs/requirements/secrets/`:

```bash
# Set database root password
echo "your_secure_root_password" > srcs/requirements/secrets/db_root_password.txt

# Set WordPress database user password
echo "your_secure_user_password" > srcs/requirements/secrets/db_user_password.txt
```

**Security best practices:**
- Use strong, unique passwords (minimum 16 characters)
- Never commit secrets to version control
- Add `secrets/*.txt` to `.gitignore`

### 5. Configure Local DNS

Add the domain to your hosts file:

```bash
echo "127.0.0.1 ael-jama.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching

### Makefile Targets

The project uses a Makefile for common operations:

| Target   | Command       | Description                                         |
|----------|---------------|-----------------------------------------------------|
| `all`    | `make`        | Build images and start containers in detached mode  |
| `down`   | `make down`   | Stop and remove containers (preserves volumes)      |
| `re`     | `make re`     | Rebuild and restart all containers                  |
| `clean`  | `make clean`  | Remove all containers, images, volumes, networks    |

### Build Process

```bash
# Build and start all services
make

# This executes:
docker compose -f ./srcs/docker-compose.yml up -d --build
```

**Build flags explained:**
- `-f ./srcs/docker-compose.yml` — Specify compose file location
- `up` — Create and start containers
- `-d` — Detached mode (run in background)
- `--build` — Build images before starting

### Verify Successful Build

```bash
# Check all containers are running
docker ps

# Expected output: 8 containers (nginx, wordpress, mariadb, redis, adminer, ftp, netdata, website)

# Check container logs for errors
docker compose -f ./srcs/docker-compose.yml logs
```

---

## Container Management Commands

### Docker Compose Commands

```bash
# Start services
docker compose -f ./srcs/docker-compose.yml up -d

# Stop services
docker compose -f ./srcs/docker-compose.yml down

# Restart a specific service
docker compose -f ./srcs/docker-compose.yml restart nginx

# View logs
docker compose -f ./srcs/docker-compose.yml logs -f

# View logs for specific service
docker compose -f ./srcs/docker-compose.yml logs -f wordpress

# Rebuild specific service
docker compose -f ./srcs/docker-compose.yml up -d --build wordpress

# Scale services (if applicable)
docker compose -f ./srcs/docker-compose.yml up -d --scale wordpress=2
```

### Docker Container Commands

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a container
docker stop <container_name>

# Start a container
docker start <container_name>

# Restart a container
docker restart <container_name>

# Remove a container
docker rm <container_name>

# Execute command in container
docker exec -it <container_name> <command>

# Open shell in container
docker exec -it wordpress bash
docker exec -it mariadb bash
docker exec -it nginx sh

# View container logs
docker logs <container_name>
docker logs -f <container_name>  # Follow mode

# Inspect container configuration
docker inspect <container_name>

# View container resource usage
docker stats
```

### Docker Image Commands

```bash
# List images
docker images

# Remove an image
docker rmi <image_name>

# Remove all unused images
docker image prune -a

# Build image manually
docker build -t myimage:tag ./srcs/requirements/nginx
```

### Docker Network Commands

```bash
# List networks
docker network ls

# Inspect network
docker network inspect srcs_backend
docker network inspect srcs_frontend

# View containers on a network
docker network inspect srcs_backend --format='{{range .Containers}}{{.Name}} {{end}}'
```

---

## Volume Management

### Volume Configuration

The project defines three named volumes in `docker-compose.yml`:

| Volume    | Container Path              | Host Path                      | Purpose                  |
|-----------|-----------------------------| ------------------------------ |--------------------------|
| db_data   | /var/lib/mysql              | /home/ael-jama/data/mariadb     | MariaDB database files   |
| wp_data   | /var/www/html               | /home/ael-jama/data/wordpress   | WordPress files          |
| rd_data   | /data                       | /home/ael-jama/data/redis       | Redis persistence        |
| site      | /var/www/html/static_website| Docker-managed                 | Static website files     |

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_db_data
docker volume inspect srcs_wp_data
docker volume inspect srcs_rd_data

# Remove a volume (WARNING: deletes data)
docker volume rm srcs_db_data

# Remove all unused volumes
docker volume prune

# Backup a volume
docker run --rm -v srcs_wp_data:/data -v $(pwd):/backup alpine \
    tar cvf /backup/wordpress_backup.tar /data

# Restore a volume
docker run --rm -v srcs_wp_data:/data -v $(pwd):/backup alpine \
    tar xvf /backup/wordpress_backup.tar -C /
```

### Volume Driver Configuration

The volumes use bind mount driver with specific options:

```yaml
volumes:
  db_data:
    driver: local
    driver_opts:
      type: none      # No special filesystem type
      o: bind         # Bind mount option
      device: /home/ael-jama/data/mariadb  # Host path
```

---

## Data Persistence

### Where Data Is Stored

```
/home/ael-jama/data/
├── mariadb/          # MariaDB database files
│   ├── ibdata1       # InnoDB data file
│   ├── ib_logfile0   # InnoDB log file
│   ├── mysql/        # MySQL system database
│   ├── wordpress/    # WordPress database
│   └── ...
├── wordpress/        # WordPress installation
│   ├── wp-admin/
│   ├── wp-content/
│   │   ├── plugins/
│   │   ├── themes/
│   │   └── uploads/
│   ├── wp-includes/
│   ├── wp-config.php
│   └── ...
└── redis/            # Redis persistence
    └── appendonly.aof
```

### Data Persistence Behavior

| Scenario                      | Data Preserved? | Notes                              |
|-------------------------------|-----------------|-------------------------------------|
| `make down`                   | ✅ Yes          | Containers stopped, volumes intact  |
| `docker restart <container>`  | ✅ Yes          | Container restarted                 |
| `make re`                     | ✅ Yes          | Rebuild preserves volumes           |
| `make clean`                  | ❌ No           | All volumes removed                 |
| `docker volume rm`            | ❌ No           | Specific volume deleted             |
| Host machine reboot           | ✅ Yes          | Data persists on disk               |

### Backup Strategy

**Manual backup:**

```bash
# Stop containers to ensure data consistency
make down

# Backup all data
sudo tar -czvf inception_backup_$(date +%Y%m%d).tar.gz /home/ael-jama/data/

# Restart containers
make
```

**Restore from backup:**

```bash
# Stop containers
make down

# Remove existing data
sudo rm -rf /home/ael-jama/data/*

# Restore backup
sudo tar -xzvf inception_backup_YYYYMMDD.tar.gz -C /

# Restart containers
make
```

---

## Development Workflow

### Making Changes to Dockerfiles

1. Edit the Dockerfile:
   ```bash
   nano srcs/requirements/nginx/Dockerfile
   ```

2. Rebuild specific service:
   ```bash
   docker compose -f ./srcs/docker-compose.yml up -d --build nginx
   ```

3. Or rebuild everything:
   ```bash
   make re
   ```

### Making Changes to Configuration Files

**Nginx configuration:**
```bash
# Edit config
nano srcs/requirements/nginx/nginx.conf

# Rebuild nginx
docker compose -f ./srcs/docker-compose.yml up -d --build nginx
```

**PHP-FPM configuration:**
```bash
# Edit config
nano srcs/requirements/wordpress/conf/www.conf

# Rebuild wordpress
docker compose -f ./srcs/docker-compose.yml up -d --build wordpress
```

**Redis configuration:**
```bash
# Edit config
nano srcs/requirements/bonus/redis/redis.conf

# Rebuild redis
docker compose -f ./srcs/docker-compose.yml up -d --build redis
```

### Adding a New Service

1. Create service directory:
   ```bash
   mkdir -p srcs/requirements/bonus/newservice
   ```

2. Create Dockerfile:
   ```dockerfile
   FROM debian:bookworm
   # ... configuration
   ```

3. Add to `docker-compose.yml`:
   ```yaml
   newservice:
     build: ./requirements/bonus/newservice
     container_name: newservice
     restart: always
     networks:
       - backend
   ```

4. Build and run:
   ```bash
   make re
   ```

### Testing Changes

```bash
# Test Nginx configuration
docker exec nginx nginx -t

# Test PHP configuration
docker exec wordpress php -v
docker exec wordpress php -m  # List modules

# Test MariaDB connection
docker exec mariadb mysql -u root -p -e "SHOW DATABASES;"

# Test Redis connection
docker exec redis redis-cli ping

# Test WordPress
curl -k https://ael-jama.42.fr
```

---

## Debugging

### Common Debug Commands

```bash
# View all logs
docker compose -f ./srcs/docker-compose.yml logs

# Follow logs in real-time
docker compose -f ./srcs/docker-compose.yml logs -f

# View specific service logs
docker logs nginx 2>&1 | tail -50
docker logs wordpress 2>&1 | tail -50
docker logs mariadb 2>&1 | tail -50

# Check container health
docker inspect --format='{{.State.Health.Status}}' <container>

# View container processes
docker top <container_name>

# Check resource usage
docker stats --no-stream
```

### Debugging Network Issues

```bash
# Check network connectivity between containers
docker exec wordpress ping -c 3 mariadb
docker exec wordpress ping -c 3 redis
docker exec nginx ping -c 3 wordpress

# Check port connectivity
docker exec wordpress nc -zv mariadb 3306
docker exec wordpress nc -zv redis 6379
docker exec nginx nc -zv wordpress 9000

# Inspect network configuration
docker network inspect srcs_backend
```

### Debugging Database Issues

```bash
# Connect to MariaDB
docker exec -it mariadb mysql -u root -p

# Check database exists
SHOW DATABASES;

# Check user permissions
SELECT user, host FROM mysql.user;
SHOW GRANTS FOR 'wp_user'@'%';

# Check WordPress tables
USE wordpress;
SHOW TABLES;
```

### Debugging WordPress Issues

```bash
# Check PHP-FPM status
docker exec wordpress ps aux | grep php

# Check WordPress files
docker exec wordpress ls -la /var/www/html/

# Check wp-config.php
docker exec wordpress cat /var/www/html/wp-config.php

# Test database connection from WordPress
docker exec wordpress php -r "
\$conn = new mysqli('mariadb', 'wp_user', 'password', 'wordpress');
if (\$conn->connect_error) die('Failed: ' . \$conn->connect_error);
echo 'Connected successfully';
"
```

### Clean Slate Debugging

If something is completely broken:

```bash
# Nuclear option - remove everything
make clean

# Remove data directories
sudo rm -rf /home/ael-jama/data/*

# Recreate directories
sudo mkdir -p /home/ael-jama/data/{mariadb,wordpress,redis}
sudo chown -R $USER:$USER /home/ael-jama/data

# Rebuild from scratch
make

# Watch logs during startup
docker compose -f ./srcs/docker-compose.yml logs -f
```

---

## Quick Reference

### File Locations

| File/Directory                              | Purpose                           |
|---------------------------------------------|-----------------------------------|
| `Makefile`                                  | Build automation                  |
| `srcs/docker-compose.yml`                   | Service orchestration             |
| `srcs/requirements/.env`                    | Environment variables             |
| `srcs/requirements/secrets/`                | Password files                    |
| `srcs/requirements/<service>/Dockerfile`    | Container build instructions      |
| `/home/ael-jama/data/`                       | Persistent data storage           |

### Port Mapping

| Service   | Container Port | Host Port   | Protocol |
|-----------|----------------|-------------|----------|
| Nginx     | 443            | 443         | HTTPS    |
| FTP       | 21             | 21          | FTP      |
| FTP       | 30000-30009    | 30000-30009 | PASV     |

### Internal Ports (Container-to-Container)

| Service   | Port  | Protocol |
|-----------|-------|----------|
| WordPress | 9000  | FastCGI  |
| MariaDB   | 3306  | MySQL    |
| Redis     | 6379  | Redis    |
| Adminer   | 8080  | HTTP     |
| Netdata   | 19999 | HTTP     |
| Website   | —     | N/A      |

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Configuration](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
