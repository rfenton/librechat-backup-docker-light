#!/bin/bash

# Configuration
LOG_FILE="/var/log/backup.log"
MONGODB_HOST=${MONGODB_HOST:-"chat-mongodb"}
MONGODB_PORT=${MONGODB_PORT:-27017}
BACKUP_DIR=${BACKUP_DIR:-"/backups"}
DB_NAME=${DB_NAME:-"LibreChat"}
RETENTION_DAYS=${RETENTION_DAYS:-90}

# Collections to backup
COLLECTIONS=("conversations" "messages" "users" "presets" "prompts" "files" "assistants" "agents")

# Logging function
log() {
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

# Error handling
handle_error() {
    log "❌ ERROR: $1"
    exit 1
}

# Main backup process
main() {
    log "🚀 Starting LibreChat backup (Lightweight)"
    
    # Create timestamped backup directory
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_path="$BACKUP_DIR/$timestamp"
    
    mkdir -p "$backup_path" || handle_error "Cannot create backup directory"
    
    # Export collections
    local exported_count=0
    for collection in "${COLLECTIONS[@]}"; do
        # Quick existence check
        local count=$(echo "db.getSiblingDB('$DB_NAME').$collection.countDocuments()" | \
                     mongosh --host "$MONGODB_HOST" --port "$MONGODB_PORT" --quiet 2>/dev/null || echo "0")
        
        if [ "$count" = "0" ] || [ -z "$count" ]; then
            log "⏩ Skipping empty collection: $collection"
            continue
        fi
        
        # Export collection
        if mongoexport --host "$MONGODB_HOST" --port "$MONGODB_PORT" \
                      --db="$DB_NAME" --collection="$collection" \
                      --out="$backup_path/$collection.json" &>/dev/null; then
            log "✅ Exported $collection ($count documents)"
            exported_count=$((exported_count + 1))
        else
            log "❌ Failed to export $collection"
        fi
    done
    
    # Check if any collections were exported
    if [ $exported_count -eq 0 ]; then
        log "⚠️  No collections exported, removing empty backup directory"
        rm -rf "$backup_path"
        return 1
    fi
    
    # Compress backup
    if tar -czf "$backup_path.tar.gz" -C "$BACKUP_DIR" "$(basename "$backup_path")" 2>/dev/null; then
        rm -rf "$backup_path"  # Remove uncompressed directory
        local size=$(du -h "$backup_path.tar.gz" | cut -f1)
        log "✅ Backup completed: $backup_path.tar.gz ($size)"
    else
        handle_error "Backup compression failed"
    fi
    
    # Cleanup old backups
    local deleted_count=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete -print 2>/dev/null | wc -l)
    if [ $deleted_count -gt 0 ]; then
        log "🧹 Cleaned up $deleted_count old backup(s) (>"${RETENTION_DAYS}" days)"
    fi
    
    # Rotate log file if too large (>1MB)
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt 1048576 ]; then
        tail -n 100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
        log "📄 Log file rotated"
    fi
    
    log "🎉 Backup process completed successfully"
}

# Run main function
main "$@" 