#!/bin/bash
# Project Zomboid Restart Announcement via RCON
# Usage: ./announce-restart.sh [minutes_until_restart]

set -euo pipefail

# ===== CONFIG =====
RCON_HOST="127.0.0.1"
RCON_PORT=27015
RCON_PASSWORD="${RCON_PASSWORD:-CHANGE_ME}"
MINUTES="${1:-5}"

# ===== PRE-CHECKS =====
if ! command -v rcon-cli &> /dev/null; then
    echo "rcon-cli not installed" >&2
    exit 1
fi

if [[ "${RCON_PASSWORD}" == "CHANGE_ME" ]]; then
    echo "RCON_PASSWORD not set" >&2
    exit 1
fi

# ===== ANNOUNCE SEQUENCE =====
announce() {
    local msg="$1"
    rcon-cli -a "${RCON_HOST}:${RCON_PORT}" -P "${RCON_PASSWORD}" "servermsg \"${msg}\"" >/dev/null 2>&1 || true
}

log() { echo "[$(date +'%F %T')] $*"; }

# 5 min warning
if [[ ${MINUTES} -ge 5 ]]; then
    announce "⚠️ Server restarting in 5 minutes for maintenance. Please finish your activities."
    log "Announced: 5 minutes"
    sleep 240  # 4 min
fi

# 1 min warning
if [[ ${MINUTES} -ge 1 ]]; then
    announce "⚠️ Server restarting in 1 minute. Disconnect now to avoid inventory loss."
    log "Announced: 1 minute"
    sleep 50
fi

# 10 sec warning
announce "⚠️ Server restarting in 10 seconds. Disconnect NOW."
log "Announced: 10 seconds"
sleep 10

# Final kick
announce "🔴 Server restarting now. See you soon!"
log "Announced: restarting now"

# Trigger save before stop
rcon-cli -a "${RCON_HOST}:${RCON_PORT}" -P "${RCON_PASSWORD}" "save" >/dev/null 2>&1 || true
sleep 3

log "Announcement sequence complete"
