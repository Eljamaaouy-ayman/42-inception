FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx openssl ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
      -out /etc/nginx/ssl/nginx.crt \
      -keyout /etc/nginx/ssl/nginx.key \
      -subj "/C=MA/ST=Morocco/L=benguerir/O=1337/OU=Student/CN=localhost"

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /run/nginx

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
