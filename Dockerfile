FROM alpine:3.18

# Install only essential tools
RUN apk add --no-cache \
    bash \
    mongodb-tools \
    dcron \
    tzdata \
    ca-certificates

# Copy backup scripts
COPY backup_librechat.sh /backup_librechat.sh
COPY entrypoint.sh /entrypoint.sh
COPY crontab /etc/cron.d/backup-cron

# Set permissions and create user
RUN chmod +x /backup_librechat.sh /entrypoint.sh && \
    chmod 0644 /etc/cron.d/backup-cron && \
    adduser -D -s /bin/bash backup && \
    mkdir -p /var/log && \
    chown backup:backup /var/log

# Switch to non-root user
USER backup

ENTRYPOINT ["/entrypoint.sh"] 