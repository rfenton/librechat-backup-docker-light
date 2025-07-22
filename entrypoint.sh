#!/bin/bash

# Environment variables
MONGODB_HOST=${MONGODB_HOST:-"chat-mongodb"}
MONGODB_PORT=${MONGODB_PORT:-27017}
LOG_FILE="/var/log/backup.log"

# Simple logging function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Quick MongoDB connectivity check (non-blocking)
check_mongodb() {
    log "Checking MongoDB connectivity..."
    local attempts=0
    local max_attempts=10
    
    while [ $attempts -lt $max_attempts ]; do
        if echo 'db.adminCommand("ping")' | mongosh --host "$MONGODB_HOST" --port "$MONGODB_PORT" --quiet &>/dev/null; then
            log "✓ MongoDB is available at $MONGODB_HOST:$MONGODB_PORT"
            return 0
        fi
        attempts=$((attempts + 1))
        log "MongoDB not ready, attempt $attempts/$max_attempts"
        sleep 3
    done
    
    log "⚠️  MongoDB not available, but starting cron anyway (will retry during backup)"
    return 0
}

# Main entrypoint
main() {
    log "Starting LibreChat Backup - Lightweight Edition"
    
    # Optional connectivity check (non-blocking)
    check_mongodb
    
    # Install crontab
    crontab /etc/cron.d/backup-cron
    log "✓ Cron scheduled for daily backups at 2 AM"
    
    # Start cron in foreground (PID 1)
    log "✓ Starting cron daemon"
    exec crond -f -l 2
}

main "$@" 