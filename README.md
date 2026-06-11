*This project has been created as part of the 42 curriculum by ael-jama.*

---

# Inception

## Description

**Inception** is a system administration project that focuses on Docker and containerization. The goal is to build a small infrastructure composed of multiple services running inside Docker containers, orchestrated using Docker Compose. This project simulates a real-world production environment with a WordPress website backed by MariaDB, served through Nginx with TLS encryption.

The infrastructure includes:
- **Nginx** — A reverse proxy server with TLS (HTTPS only on port 443)
- **WordPress** — A PHP-FPM based WordPress installation
- **MariaDB** — The database backend for WordPress
- **Redis** — Object caching for WordPress to improve performance
- **Adminer** — A lightweight database management tool
- **FTP** — An FTP server (vsftpd) for file transfers to the WordPress volume
- **Netdata** — Real-time performance monitoring dashboard
- **Static Website** — A simple static HTML website served via Nginx

All containers are built from `debian:bookworm` base image and are configured to restart automatically.

---

## Project Architecture

```
                            ┌─────────────────────────────────────────────────────────────┐
                            │                      Docker Network                          │
                            │                                                              │
    Internet                │  ┌─────────┐     ┌───────────┐     ┌──────────┐             │
       │                    │  │  Nginx  │────▶│ WordPress │────▶│ MariaDB  │             │
       │                    │  │  :443   │     │   :9000   │     │  :3306   │             │
       ▼                    │  └────┬────┘     └─────┬─────┘     └──────────┘             │
   ┌───────┐                │       │                │                                     │
   │ :443  │────────────────│───────┘                │          ┌──────────┐              │
   │ :21   │                │       │                └─────────▶│  Redis   │              │
   └───────┘                │       │                            │  :6379   │              │
                            │       ├───────────────────────────▶└──────────┘              │
                            │       │                                                      │
                            │       │   ┌──────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐│
                            │       └──▶│ Adminer  │  │   FTP   │  │ Netdata  │  │ Website ││
                            │           │  :8080   │  │   :21   │  │  :19999  │  │ (static)││
                            │           └──────────┘  └─────────┘  └──────────┘  └─────────┘│
                            │                                                              │
                            └─────────────────────────────────────────────────────────────┘
```

---

## Instructions

### Prerequisites

- Docker Engine (version 20.10+)
- Docker Compose (version 2.0+)
- Make

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Create required data directories:**
   ```bash
   sudo mkdir -p /home/ael-jama/data/mariadb
   sudo mkdir -p /home/ael-jama/data/wordpress
   sudo mkdir -p /home/ael-jama/data/redis
   ```

3. **Configure secrets:**
   Edit the secret files in `srcs/requirements/secrets/`:
   - `db_root_password.txt` — MariaDB root password
   - `db_user_password.txt` — WordPress database user password

4. **Update hosts file (optional):**
   ```bash
   echo "127.0.0.1 ael-jama.42.fr" | sudo tee -a /etc/hosts
   ```

### Running the Project

```bash
# Build and start all containers
make

# Or equivalently
make all

# Stop all containers
make down

# Rebuild and restart
make re

# Stop and remove all containers, images, volumes, and networks
make clean
```

### Accessing Services

| Service        | URL                                     | Description                    |
|----------------|-----------------------------------------|--------------------------------|
| WordPress      | https://ael-jama.42.fr                   | Main WordPress site            |
| Static Website | https://ael-jama.42.fr/static_website/   | Static HTML website            |
| Adminer        | https://ael-jama.42.fr/adminer/          | Database management interface  |
| Netdata        | https://ael-jama.42.fr/netdata/          | Real-time monitoring dashboard |
| FTP            | ftp://localhost:21                      | FTP access to WordPress files  |

---

## Technical Choices & Design Decisions

### Base Image
All services are built using `debian:bookworm` to ensure:
- Consistent environment across all containers
- Minimal image size
- Security through minimal packages

### Network Architecture
- **backend** network: Internal communication between services (MariaDB, WordPress, Redis, Adminer, Netdata, FTP)
- **frontend** network: Nginx connection to external traffic

### Service Configuration
- **Nginx**: Configured with TLSv1.2 and TLSv1.3, self-signed certificates
- **WordPress**: Uses WP-CLI for installation and configuration, PHP-FPM 8.4
- **MariaDB**: Custom entrypoint script for initialization
- **Redis**: Configured with 256MB memory limit and LRU eviction policy

---

## Comparisons

### Virtual Machines vs Docker

| Aspect          | Virtual Machines                          | Docker Containers                        |
|-----------------|-------------------------------------------|------------------------------------------|
| **Isolation**   | Full OS isolation with hypervisor         | Process-level isolation using namespaces |
| **Resource**    | High (each VM runs full OS)               | Low (shares host kernel)                 |
| **Startup**     | Minutes                                   | Seconds                                  |
| **Size**        | GBs per VM                                | MBs per container                        |
| **Use Case**    | Different OS requirements, legacy apps    | Microservices, CI/CD, development        |
| **Portability** | Less portable, hypervisor dependent       | Highly portable across environments      |

**Project Choice**: Docker is used for its lightweight nature, fast deployment, and ability to define infrastructure as code through Dockerfiles and docker-compose.yml.

### Secrets vs Environment Variables

| Aspect         | Environment Variables                    | Docker Secrets                            |
|----------------|------------------------------------------|-------------------------------------------|
| **Security**   | Visible in process list, logs            | Encrypted at rest, tmpfs in container     |
| **Access**     | Available to all processes               | Mounted as files, limited access          |
| **Swarm**      | Works everywhere                         | Native to Swarm, works with Compose       |
| **Use Case**   | Non-sensitive configuration              | Passwords, API keys, certificates         |

**Project Choice**: Docker Secrets are used for sensitive data (database passwords) mounted at `/run/secrets/`. Non-sensitive configuration uses environment variables via `.env` file.

### Docker Network vs Host Network

| Aspect          | Docker Bridge Network                    | Host Network                             |
|-----------------|------------------------------------------|------------------------------------------|
| **Isolation**   | Containers isolated from host            | Container shares host network stack      |
| **Port Mapping**| Explicit port mapping required           | No port mapping, direct host ports       |
| **Security**    | Better isolation, controlled exposure    | Less isolation, all ports exposed        |
| **Performance** | Slight overhead from NAT                 | No NAT overhead                          |
| **DNS**         | Built-in DNS resolution by name          | Uses host DNS                            |

**Project Choice**: Custom bridge networks (`backend`, `frontend`) for service isolation and DNS-based service discovery. Services communicate using container names.

### Docker Volumes vs Bind Mounts

| Aspect          | Docker Volumes                           | Bind Mounts                              |
|-----------------|------------------------------------------|------------------------------------------|
| **Management**  | Managed by Docker                        | Managed by user/filesystem               |
| **Location**    | Docker storage area                      | Anywhere on host filesystem              |
| **Portability** | More portable, abstracted                | Host path dependent                      |
| **Performance** | Optimized by Docker                      | Direct filesystem access                 |
| **Backup**      | Docker CLI tools                         | Standard filesystem tools                |

**Project Choice**: The project uses named volumes with bind mount driver (`type: none, o: bind`) to persist data in specific host directories (`/home/ael-jama/data/`), combining the benefits of both approaches.

---

## Services Details

### Core Services

| Service   | Base Image          | Port  | Description                              |
|-----------|---------------------|-------|------------------------------------------|
| nginx     | debian:bookworm  | 443   | Reverse proxy with TLS termination       |
| wordpress | debian:bookworm  | 9000  | PHP-FPM WordPress with WP-CLI            |
| mariadb   | debian:bookworm  | 3306  | MySQL-compatible database                |

### Bonus Services

| Service   | Base Image          | Port  | Description                              |
|-----------|---------------------|-------|------------------------------------------|
| redis     | debian:bookworm  | 6379  | In-memory cache for WordPress            |
| adminer   | debian:bookworm  | 8080  | Web-based database management            |
| ftp       | debian:bookworm  | 21    | FTP server for file transfers            |
| netdata   | debian:bookworm  | 19999 | Real-time performance monitoring         |
| website   | debian:bookworm  | —     | Static HTML website via Nginx            |

---

## File Structure

```
inception/
├── Makefile                           # Build automation
├── README.md                          # This file
└── srcs/
    ├── docker-compose.yml             # Service orchestration
    └── requirements/
        ├── .env                       # Environment variables
        ├── secrets/                   # Sensitive credentials
        │   ├── db_root_password.txt
        │   └── db_user_password.txt
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/entrypoint.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── nginx.conf
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/entrypoint.sh
        └── bonus/
            ├── adminer/Dockerfile
            ├── ftp/
            │   ├── Dockerfile
            │   └── vsftpd.conf
            ├── netdata/
            │   ├── Dockerfile
            │   └── tools/setup-netdata.sh
            ├── redis/
            │   ├── Dockerfile
            │   └── redis.conf
            └── website/
                ├── Dockerfile
                └── static_website/index.html
```

---

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Documentation](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)
- [Redis Documentation](https://redis.io/documentation)

### Tutorials & Articles
- [Docker for Beginners](https://docker-curriculum.com/)
- [Docker Secrets Best Practices](https://docs.docker.com/engine/swarm/secrets/)
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [WordPress with Docker](https://docs.docker.com/samples/wordpress/)

### AI Usage
AI tools were used in this project for:
- **Documentation**: Assistance in structuring and writing this README file
- **Debugging**: Help with troubleshooting container networking issues
- **Configuration**: Suggestions for optimizing nginx.conf and PHP-FPM settings
- **Best Practices**: Recommendations for Docker security and secrets management

All AI-assisted content was reviewed, tested, and validated to ensure correctness and alignment with project requirements.

---

## License

This project is part of the 42 school curriculum. All rights reserved.

---

## Author

**ael-jama** — 42 Student
