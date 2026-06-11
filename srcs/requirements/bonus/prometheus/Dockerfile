FROM alpine:3.19

# Install Prometheus
RUN apk add --no-cache prometheus

# Create configuration directory
RUN mkdir -p /etc/prometheus /prometheus

# Copy configuration
COPY conf/prometheus.yml /etc/prometheus/prometheus.yml

# Set permissions
RUN chown -R nobody:nobody /etc/prometheus /prometheus

# Expose Prometheus port
EXPOSE 9090

# Run Prometheus (no entrypoint script needed for simple service)
CMD ["prometheus", "--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.path=/prometheus", "--web.console.libraries=/usr/share/prometheus/web/console_libraries", "--web.console.templates=/usr/share/prometheus/web/consoles"]