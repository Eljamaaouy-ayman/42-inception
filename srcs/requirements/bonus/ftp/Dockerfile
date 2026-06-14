FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

# Create the secure chroot directory BEFORE creating the user
RUN mkdir -p /var/run/vsftpd/empty \
    && chmod 755 /var/run/vsftpd/empty

COPY vsftpd.conf /etc/vsftpd.conf

RUN useradd -m ftpuser \
    && echo "ftpuser:ftppass" | chpasswd \
    && mkdir -p /var/www/html \
    && chown ftpuser:ftpuser /var/www/html

EXPOSE 21 30000-30009

CMD ["vsftpd", "/etc/vsftpd.conf"]