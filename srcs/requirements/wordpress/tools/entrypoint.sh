#!/bin/sh
set -e

echo "Starting WordPress container..."


USER_PASS=$(cat /run/secrets/db_user_password)
ADMINE_PASS=$(cat /run/secrets/wp_admin_password)

echo "Waiting for MariaDB to be ready..."

until mysql -h"$MYSQL_HOSTNAME" -u"$MYSQL_USER" -p"$USER_PASS" -e "SELECT 1;" >/dev/null 2>&1
do
	echo "MariaDB is not ready yet. Retrying in 2 seconds..."
    sleep 2
done

echo "MariaDB is ready."


if [ ! -f wp-settings.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root
fi


if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."

    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$USER_PASS" \
        --dbhost="$MYSQL_HOSTNAME" \
        --allow-root

    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_REDIS_TIMEOUT 1 --raw --allow-root

    wp config shuffle-salts --allow-root

    echo "wp-config.php created."
fi


if ! wp core is-installed --allow-root; then
    echo "Installing WordPress..."

    wp core install \
        --url="$DOMAIN_NAME" \
        --title="Inception Site" \
        --admin_user="$WP_ADMIN" \
        --admin_password="$ADMINE_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --allow-root

    echo "WordPress installed successfully."
else
    echo "WordPress already installed."
fi


chown -R www-data:www-data /var/www/html

exec "$@"
