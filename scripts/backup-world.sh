#!/bin/bash
# Project Zomboid World Backup via RCON
# Runs daily via cron: 0 4 * * * /path/to/backup-world.sh

set -euo pipefail

# ===== CONFIG =====
RCON_HOST="127.0.0.1"
RCON_PORT=27015
RCON_PASSWORD="${RCON_PASSWORD:-CHANGE_ME}"
BACKUP_DIR="/mnt/Data/pz-backups"
RETENTION_DAYS=30
DATE=$(date +%F-%H%M)

# ===== COLORS =====
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%F %T')]${NC} $*"; }
error() { echo -e "${RED}[$(date +'%F %T')]${NC} $*"; }

# ===== PRE-CHECKS =====
if ! command -v rcon-cli &> /dev/null; then
    error "rcon-cli not installed. Install: go install github.com/gorcon/rcon-cli@latest"
    exit 1
fi

if [[ "${RCON_PASSWORD}" == "CHANGE_ME" ]]; then
    error "RCON_PASSWORD not set. Export RCON_PASSWORD or edit script."
    exit 1
fi

mkdir -p "${BACKUP_DIR}"

# ===== TRIGGER SAVE =====
log "Triggering world save via RCON..."
if ! rcon-cli -a "${RCON_HOST}:${RCON_PORT}" -P "${RCON_PASSWORD}" "save" >/dev/null 2>&1; then
    error "RCON save command failed"
    exit 1
fi

# Wait for save to complete
sleep 10

# ===== BACKUP WORLD FILES =====
WORLD_DIR="/home/trilayer/Servers/SarvarPZ/Zomboid/Server/sarvarpz"
BACKUP_FILE="${BACKUP_DIR}/sarvarpz-${DATE}.tar.gz"

log "Creating backup: ${BACKUP_FILE}"
tar -czf "${BACKUP_FILE}" -C "${WORLD_DIR}" .

if [[ $? -ne 0 ]]; then
    error "Backup creation failed"
    exit 1
fi

BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
log "Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})"

# ===== RETENTION =====
log "Applying retention (${RETENTION_DAYS} days)..."
find "${BACKUP_DIR}" -name 'sarvarpz-*.tar.gz' -mtime +${RETENTION_DAYS} -delete

# ===== OFFSITE (optional) =====
if command -v rclone &> /dev/null && rclone listremotes | grep -q "b2:"; then
    log "Syncing to offsite..."
    rclone copy "${BACKUP_DIR}/" "b2:pz-backups/" --progress --transfers 4
fi

log "Backup job completed"
