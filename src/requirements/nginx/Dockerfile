FROM alpine:3.19

RUN apk update && apk upgrade && \
    apk add --no-cache nginx openssl

RUN mkdir -p /run/nginx /var/www/html

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/self-signed.crt /etc/nginx/ssl/
COPY conf/self-signed.key /etc/nginx/ssl/
COPY tools/entrypoint.sh /

RUN chmod +x /nginx.conf
ENTRYPOINT ["/nginx.conf"]
CMD ["nginx", "-g", "deamon off;"]