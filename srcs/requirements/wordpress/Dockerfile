FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    php-fpm \
    php-mysql \
    php-gd \
    php-mbstring \
    php-redis \
    php-cli \
    curl \
    wget \
    ca-certificates \
    netcat-openbsd \
    mariadb-client \
 && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

RUN mkdir -p /run/php

RUN ln -s /usr/sbin/php-fpm* /usr/local/bin/php-fpm

COPY ./conf/www.conf /tmp/www.conf
RUN cp /tmp/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY ./tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/php-fpm", "-F"]

EXPOSE 9000
