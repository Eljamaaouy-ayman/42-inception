FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends redis-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /data && \
    chown redis:redis /data

COPY redis.conf /etc/redis/redis.conf

EXPOSE 6379

USER redis

CMD ["redis-server", "/etc/redis/redis.conf"]
