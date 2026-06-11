#!/bin/bash
set -e

ROOT_PASS=$(cat /run/secrets/db_root_password)
USER_PASS=$(cat /run/secrets/db_user_password)
GRAFANA_READER_PASSWORD=$(cat /run/secrets/grafana_reader_password)

# Log file location
LOG_FILE="/var/log/mariadb-init.log"

if [ -z "$ROOT_PASS" ] || [ -z "$USER_PASS" ]; then
    echo "Error: Database passwords not found in secrets." >> $LOG_FILE
    exit 1
fi

if [ ! -d "/var/lib/mysql/$MYSQL_DATABASE" ]; then
    echo "$(date) - Initializing MariaDB data directory..." >> $LOG_FILE
    mysql_install_db --user=mysql --ldata=/var/lib/mysql

    mysqld --user=mysql --skip-networking &
    pid="$!"

    echo "$(date) - Waiting for MariaDB to start..." >> $LOG_FILE
    for i in $(seq 1 30); do
        if mysqladmin ping >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    echo "$(date) - Configuring MariaDB..." >> $LOG_FILE
    mysql -u root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';

-- Create WordPress database and user
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${USER_PASS}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- ============================================
-- CREATE READ-ONLY USER FOR GRAFANA
-- ============================================
CREATE USER IF NOT EXISTS 'grafana_reader'@'%' IDENTIFIED BY '${GRAFANA_READER_PASSWORD}';
GRANT SELECT ON ${MYSQL_DATABASE}.* TO 'grafana_reader'@'%';

-- Apply all changes
FLUSH PRIVILEGES;
EOF

    mysqladmin -u root -p"${ROOT_PASS}" shutdown

    echo "$(date) - MariaDB initialization complete." >> $LOG_FILE
else
    echo "$(date) - MariaDB data directory already initialized. Skipping initialization." >> $LOG_FILE
fi

exec "$@"