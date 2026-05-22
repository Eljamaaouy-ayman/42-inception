# Inception — User Documentation

This guide explains how to use and manage the Inception infrastructure stack in simple terms.

---

## Table of Contents

1. [What This Project Does](#what-this-project-does)
2. [Services Overview](#services-overview)
3. [Starting and Stopping the Project](#starting-and-stopping-the-project)
4. [Accessing the Website and Admin Panels](#accessing-the-website-and-admin-panels)
5. [Managing Credentials](#managing-credentials)
6. [Checking Service Status](#checking-service-status)
7. [Troubleshooting](#troubleshooting)

---

## What This Project Does

Inception is a complete web hosting stack that runs a **WordPress website** with all necessary supporting services. Everything runs inside Docker containers, making it easy to deploy, manage, and maintain.

**In simple terms:** This project gives you a fully functional WordPress website with a database, caching, monitoring, and file transfer capabilities — all running in isolated containers.

---

## Services Overview

| Service            | What It Does                                                   |
|--------------------|----------------------------------------------------------------|
| **WordPress**      | The main website — a content management system for blogs/sites |
| **Nginx**          | Web server that handles HTTPS and routes traffic               |
| **MariaDB**        | Database that stores all WordPress content                     |
| **Redis**          | Cache that makes the website faster                            |
| **Adminer**        | Web tool to manage the database                                |
| **FTP**            | File transfer server to upload/download WordPress files        |
| **Netdata**        | Dashboard showing real-time server performance                 |
| **Static Website** | A simple static HTML website served via Nginx                  |

---

## Starting and Stopping the Project

### Starting the Project

Open a terminal in the project folder and run:

```bash
make
```

This will:
- Build all container images
- Start all services
- Run everything in the background

**Wait about 30-60 seconds** for all services to fully initialize.

### Stopping the Project

To stop all services (containers keep their data):

```bash
make down
```

### Restarting the Project

To rebuild and restart all services:

```bash
make re
```

### Complete Cleanup

⚠️ **Warning:** This removes all containers, images, and data!

```bash
make clean
```

---

## Accessing the Website and Admin Panels

### Prerequisites

1. Add the domain to your hosts file (one-time setup):
   ```bash
   echo "127.0.0.1 mbouhia.42.fr" | sudo tee -a /etc/hosts
   ```

2. Accept the self-signed certificate warning in your browser.

### WordPress Website

| Access         | URL                                  |
|----------------|--------------------------------------|
| **Homepage**   | https://mbouhia.42.fr                |
| **Admin Login**| https://mbouhia.42.fr/wp-admin       |

To log into WordPress admin:
1. Go to https://mbouhia.42.fr/wp-admin
2. Enter your WordPress username and password
3. Click "Log In"

### Database Management (Adminer)

| Access     | URL                                  |
|------------|--------------------------------------|
| **Adminer**| https://mbouhia.42.fr/adminer/       |

To log into Adminer:
1. Go to https://mbouhia.42.fr/adminer/
2. Fill in:
   - **System:** MySQL
   - **Server:** mariadb
   - **Username:** wp_user
   - **Password:** (see [Managing Credentials](#managing-credentials))
   - **Database:** wordpress
3. Click "Login"

### Server Monitoring (Netdata)

| Access      | URL                                  |
|-------------|--------------------------------------|
| **Netdata** | https://mbouhia.42.fr/netdata/       |

No login required. Shows real-time CPU, memory, disk, and network usage.

### Static Website

| Access           | URL                                       |
|------------------|-------------------------------------------|
| **Static Site**  | https://mbouhia.42.fr/static_website/     |

A simple static HTML website. No login required.

### FTP Access

| Access | Details                              |
|--------|--------------------------------------|
| Host   | localhost                            |
| Port   | 21                                   |
| User   | ftpuser                              |
| Pass   | ftppass                              |

Use any FTP client (FileZilla, WinSCP, etc.) to connect and manage WordPress files.

---

## Managing Credentials

### Where Credentials Are Stored

All sensitive passwords are stored as **Docker secrets** in:

```
srcs/requirements/secrets/
├── db_root_password.txt    # MariaDB root password
└── db_user_password.txt    # WordPress database user password
```

### Viewing Credentials

```bash
# View database root password
cat srcs/requirements/secrets/db_root_password.txt

# View WordPress database user password
cat srcs/requirements/secrets/db_user_password.txt
```

### Changing Credentials

1. **Stop the project:**
   ```bash
   make down
   ```

2. **Edit the password files:**
   ```bash
   # Change database root password
   nano srcs/requirements/secrets/db_root_password.txt
   
   # Change WordPress database user password
   nano srcs/requirements/secrets/db_user_password.txt
   ```

3. **Remove old data (required for password changes to take effect):**
   ```bash
   sudo rm -rf /home/mbouhia/data/mariadb/*
   ```

4. **Restart the project:**
   ```bash
   make re
   ```

### Default Credentials Summary

| Service  | Username  | Password Location                            |
|----------|-----------|----------------------------------------------|
| MariaDB  | root      | `secrets/db_root_password.txt`               |
| MariaDB  | wp_user   | `secrets/db_user_password.txt`               |
| FTP      | ftpuser   | ftppass (hardcoded in Dockerfile)            |

---

## Checking Service Status

### Quick Status Check

See all running containers:

```bash
docker ps
```

You should see 8 containers running:
- `nginx`
- `wordpress`
- `mariadb`
- `redis`
- `adminer`
- `ftp`
- `netdata`
- `website`

### Detailed Health Checks

**Check if Nginx is serving HTTPS:**
```bash
curl -k https://mbouhia.42.fr
```
✅ Success: Returns HTML content  
❌ Failure: Connection refused or timeout

**Check if WordPress is responding:**
```bash
docker exec wordpress php -v
```
✅ Success: Shows PHP version

**Check if MariaDB is running:**
```bash
docker exec mariadb mysqladmin ping -u root -p
```
Enter the root password when prompted.  
✅ Success: "mysqld is alive"

**Check if Redis is running:**
```bash
docker exec redis redis-cli ping
```
✅ Success: Returns "PONG"

### Viewing Container Logs

To see what's happening inside a container:

```bash
# View Nginx logs
docker logs nginx

# View WordPress logs
docker logs wordpress

# View MariaDB logs
docker logs mariadb

# Follow logs in real-time (Ctrl+C to stop)
docker logs -f nginx
```

### Using Netdata Dashboard

1. Open https://mbouhia.42.fr/netdata/
2. Check the following metrics:
   - **CPU Usage** — Should be stable, not constantly at 100%
   - **Memory Usage** — Should have available memory
   - **Disk I/O** — Normal read/write activity
   - **Network Traffic** — Active when users access the site

---

## Troubleshooting

### Website Not Loading

1. **Check if containers are running:**
   ```bash
   docker ps
   ```

2. **Check Nginx logs:**
   ```bash
   docker logs nginx
   ```

3. **Restart the stack:**
   ```bash
   make down && make
   ```

### Database Connection Error

1. **Check MariaDB status:**
   ```bash
   docker logs mariadb
   ```

2. **Verify database is accessible:**
   ```bash
   docker exec mariadb mysql -u wp_user -p -e "SHOW DATABASES;"
   ```

3. **Check if WordPress can reach MariaDB:**
   ```bash
   docker exec wordpress nc -zv mariadb 3306
   ```

### Permission Issues

If you see permission errors:

```bash
# Fix data directory permissions
sudo chown -R 1000:1000 /home/mbouhia/data/wordpress
sudo chown -R 999:999 /home/mbouhia/data/mariadb
```

### Starting Fresh

If something is broken beyond repair:

```bash
# Stop everything
make down

# Remove all data
sudo rm -rf /home/mbouhia/data/*

# Recreate directories
sudo mkdir -p /home/mbouhia/data/{mariadb,wordpress,redis}

# Rebuild from scratch
make
```

---

## Quick Reference Card

| Action                    | Command                                   |
|---------------------------|-------------------------------------------|
| Start project             | `make`                                    |
| Stop project              | `make down`                               |
| Restart project           | `make re`                                 |
| View running containers   | `docker ps`                               |
| View container logs       | `docker logs <container-name>`            |
| Access WordPress          | https://mbouhia.42.fr                     |
| Access Admin panel        | https://mbouhia.42.fr/wp-admin            |
| Access Static Website     | https://mbouhia.42.fr/static_website/     |
| Access Adminer            | https://mbouhia.42.fr/adminer/            |
| Access Netdata            | https://mbouhia.42.fr/netdata/            |

---

## Need Help?

1. Check the container logs for error messages
2. Verify all services are running with `docker ps`
3. Use Netdata to monitor system resources
4. Consult the main [README.md](README.md) for technical details
