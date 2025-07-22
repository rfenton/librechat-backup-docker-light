# LibreChat Backup Docker - Lightweight Edition

An ultra-lightweight Docker container solution for automated MongoDB backups of LibreChat. This system is optimized for resource-constrained environments like Synology DiskStation, Raspberry Pi, or any low-resource deployment.

## 🚀 Ultra-Lightweight Features

This lightweight version is designed for **minimal resource consumption**:

- **Tiny Footprint**: ~50MB Alpine-based image (vs 700MB+ standard MongoDB image)
- **Minimal Memory**: 5-10MB idle, 30-50MB during backup
- **Low CPU Usage**: <0.01 CPU idle, 0.05-0.1 CPU during backup
- **Essential Tools Only**: No unnecessary MongoDB server components
- **Streamlined Process**: No continuous monitoring loops
- **Optional On-Demand**: Can run without persistent container

## Resource Comparison

| Component | Standard | Lightweight | Savings |
|-----------|----------|-------------|---------|
| **Image Size** | ~700MB | ~50MB | **93% smaller** |
| **Idle Memory** | 50-100MB | 5-10MB | **90% reduction** |
| **CPU Limit** | 0.5 cores | 0.1 cores | **80% reduction** |
| **Processes** | 3-4 | 1 | **75% fewer** |

## Quick Start

1. **Clone or create the lightweight version**:
   ```bash
   mkdir librechat-backup-docker-light
   cd librechat-backup-docker-light
   ```

2. **Configure backup location in `docker-compose.yml`**:
   ```yaml
   volumes:
     - /path/to/your/backup/location:/backups
   ```

3. **Start the lightweight backup service**:
   ```bash
   docker-compose up -d
   ```

## Features

- 🔄 Automated daily backups at 2 AM
- 🗜️ Backup compression and archiving
- 📅 90-day backup retention policy (configurable)
- 🧹 Automatic cleanup of old backups
- 🐳 Alpine-based Docker for minimal footprint
- ⚡ Streamlined validation (no test database imports)
- 🎯 Resource-optimized for NAS and low-power devices
- 💾 Backs up all essential LibreChat collections:
  - conversations, messages, users, presets
  - prompts, files, assistants, agents

## Configuration Options

### Standard Mode (Persistent Container)

```yaml
# docker-compose.yml
services:
  backup:
    build: .
    deploy:
      resources:
        limits:
          cpus: '0.1'
          memory: 64M
    volumes:
      - ./backups:/backups
    environment:
      - MONGODB_HOST=chat-mongodb
      - DB_NAME=LibreChat
```

### On-Demand Mode (Zero Idle Resources)

```yaml
# docker-compose-ondemand.yml
services:
  backup:
    build: .
    profiles: ["backup"]
    command: ["/backup_librechat.sh"]
    volumes:
      - ./backups:/backups
    environment:
      - MONGODB_HOST=chat-mongodb
      - DB_NAME=LibreChat
```

**Usage:**
```bash
# Run backup on-demand
docker-compose -f docker-compose-ondemand.yml --profile backup run --rm backup

# Schedule via host cron
0 2 * * * cd /path/to/project && docker-compose -f docker-compose-ondemand.yml --profile backup run --rm backup
```

## Usage

### Standard Operations

```bash
# View logs
docker-compose logs -f backup

# Run manual backup
docker-compose exec backup /backup_librechat.sh

# Check resource usage
docker stats

# Stop backup service
docker-compose down
```

### Backup Location

Backups are stored as compressed archives:
```
/your/backup/path/YYYY-MM-DD_HH-MM-SS.tar.gz
```

### Restore from Backup

1. Extract backup:
   ```bash
   tar -xzf YYYY-MM-DD_HH-MM-SS.tar.gz
   ```

2. Restore collections:
   ```bash
   # Example for conversations
   mongoimport --host chat-mongodb --db LibreChat --collection conversations --file conversations.json
   ```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGODB_HOST` | `chat-mongodb` | MongoDB container hostname |
| `MONGODB_PORT` | `27017` | MongoDB port |
| `DB_NAME` | `LibreChat` | Database name to backup |
| `BACKUP_DIR` | `/backups` | Backup directory path |
| `RETENTION_DAYS` | `90` | Days to keep backups |

## Synology DiskStation Deployment

This lightweight version is **perfect for Synology NAS**:

```yaml
# Synology-optimized configuration
services:
  backup:
    build: .
    deploy:
      resources:
        limits:
          cpus: '0.1'
          memory: 64M
    volumes:
      - /volume1/LibreChat/backups:/backups  # Synology path
    networks:
      - librechat_network
    environment:
      - MONGODB_HOST=librechat_mongodb
      - DB_NAME=LibreChat
      - RETENTION_DAYS=90
    restart: unless-stopped

networks:
  librechat_network:
    external: true
    name: librechat_default
```

## Troubleshooting

### Common Issues

1. **Connection Issues**
   - Verify network name matches your LibreChat setup
   - Check MongoDB container name
   - Ensure containers are on the same network

2. **Permission Issues**
   - Check backup directory permissions
   - Ensure user `backup` can write to `/backups`

3. **Resource Issues**
   - Monitor with `docker stats`
   - Adjust memory limits if needed
   - Consider on-demand mode for lowest usage

## Security

- 🔒 Runs as non-root user `backup`
- 📁 Backup files contain sensitive data - secure the backup location
- 🔐 Consider implementing backup encryption for additional security
- 📊 Monitor backup directory disk usage

## License

MIT License - See LICENSE file for details. 