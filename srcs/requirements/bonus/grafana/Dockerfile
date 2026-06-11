FROM alpine:3.19

# Install Grafana
RUN apk add --no-cache grafana

# Copy custom configuration
COPY conf/grafana.ini /etc/grafana/grafana.ini

# Create data directories
RUN mkdir -p /var/lib/grafana /var/log/grafana
RUN chown -R grafana:grafana /var/lib/grafana /var/log/grafana

EXPOSE 3000

CMD ["grafana-server", "--homepath=/usr/share/grafana", "--config=/etc/grafana/grafana.ini"]