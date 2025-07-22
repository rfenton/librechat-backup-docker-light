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

## Connecting to MongoDB

To ensure successful backups, the backup container must be able to connect to your MongoDB instance. Here’s how to configure and troubleshoot the connection:

### 1. Set the MongoDB Host and Port
- By default, the backup container expects MongoDB to be available at `chat-mongodb:27017`.
- If your MongoDB container/service has a different name or runs on a different port, update the following in your `docker-compose.yml`:
  ```yaml
  environment:
    - MONGODB_HOST=your-mongodb-container-name
    - MONGODB_PORT=your-mongodb-port
  ```

### 2. Ensure Network Connectivity
- Both the backup and MongoDB containers **must be on the same Docker network**.
- Example network section in `docker-compose.yml`:
  ```yaml
  networks:
    - librechat_network
  ...
  networks:
    librechat_network:
      external: true
      name: librechat_default  # or your actual network name
  ```
- You can list Docker networks with `docker network ls` and inspect with `docker network inspect <network-name>`.

### 3. Troubleshooting
- If you see repeated messages like `MongoDB not ready, attempt X/10`, the backup container cannot reach MongoDB.
- Double-check:
  - The MongoDB container is running and healthy
  - The network name matches your LibreChat setup
  - The `MONGODB_HOST` matches the actual container/service name
  - The port is correct (default is 27017)
- You can test connectivity from inside the backup container:
  ```bash
  docker-compose exec backup sh
  # Inside the container:
  mongosh --host $MONGODB_HOST --port $MONGODB_PORT --eval 'db.adminCommand("ping")'
  ```
- If you use Synology, ensure both containers are attached to the same user-defined bridge network in Container Manager or Portainer.

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

## Synology Installation: Container Manager & Portainer

### 1. Install Docker (Container Manager) on Synology
- Go to **Package Center** > search for **Container Manager** (or **Docker** on older DSM versions) and install it.
- Open **Container Manager** from the main menu.

### 2. (Optional) Install Portainer for Web UI Management
- Download the Portainer image:
  ```bash
  docker volume create portainer_data
  docker run -d -p 9000:9000 --name=portainer --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce
  ```
- Access Portainer at `http://<your-synology-ip>:9000` and follow the setup wizard.

### 3. Deploy the Backup App
- Place your `librechat-backup-docker-light` folder in a shared folder (e.g., `/volume1/docker/`).
- In **Container Manager**:
  - Go to **Projects** (or **Containers** > **Add** > **Import Compose**)
  - Select your `docker-compose.yml` file
  - Adjust volume paths to use Synology shares (e.g., `/volume1/LibreChat/backups:/backups`)
  - Set environment variables as needed for your MongoDB setup
  - Deploy the stack
- In **Portainer**:
  - Go to **Stacks** > **Add stack**
  - Upload or paste your `docker-compose.yml`
  - Deploy the stack

### 4. Monitoring & Logs
- Use Container Manager or Portainer to view logs, restart containers, and monitor resource usage.
- You can also use `docker-compose logs -f` from SSH/terminal.

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

## Synology NAS & Container Manager Notes

- **Volume Permissions:**  
  If you use a custom Docker user (PUID/PGID), ensure your `/backups` and `/var/log` volumes are writable by that user.  
  See the commented-out section in the Dockerfile for how to set PUID/PGID.

- **Resource Usage:**  
  The container is designed to use minimal resources between backups. You can adjust resource limits in `docker-compose.yml` as needed.

- **Log Rotation:**  
  Both backup and cron logs are automatically rotated if they exceed 1MB.

- **Troubleshooting:**  
  - If backups or logs are not being created, check container logs for permission errors.
  - Ensure the external Docker network (`librechat_default`) exists and is accessible.
  - If you encounter issues with log rotation, verify that the container is using Alpine Linux and that `wc` is available. 