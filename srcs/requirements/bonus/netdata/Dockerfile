FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    iproute2 \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY tools/setup-netdata.sh /usr/local/bin/setup-netdata.sh
RUN chmod +x /usr/local/bin/setup-netdata.sh

RUN /usr/local/bin/setup-netdata.sh

EXPOSE 19999

CMD ["netdata", "-D"]
