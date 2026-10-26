#!/bin/bash
# Project Zomboid Dedicated Server Startup Script
# Usage: ./start-server.sh -servername <name> [-adminpassword <pwd>] [-port <port>]

set -euo pipefail

# ===== DEFAULTS =====
SERVER_NAME="sarvarpz"
ADMIN_PASSWORD="CHANGE_ME"
SERVER_PORT=16261
RCON_PORT=27015
MAX_PLAYERS=16
PUBLIC=true
PUBLIC_NAME=""
PUBLIC_DESCRIPTION=""

# ===== PARSE ARGS =====
while [[ $# -gt 0 ]]; do
    case $1 in
        -servername) SERVER_NAME="$2"; shift 2 ;;
        -adminpassword) ADMIN_PASSWORD="$2"; shift 2 ;;
        -port) SERVER_PORT="$2"; shift 2 ;;
        -rconport) RCON_PORT="$2"; shift 2 ;;
        -maxplayers) MAX_PLAYERS="$2"; shift 2 ;;
        -publicname) PUBLIC_NAME="$2"; shift 2 ;;
        -publicdesc) PUBLIC_DESCRIPTION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ===== PATHS =====
PZ_DIR="/home/trilayer/Servers/SarvarPZ"
SERVER_DIR="${PZ_DIR}/Zomboid/Server/${SERVER_NAME}"
STEAM_DIR="${PZ_DIR}/steamcmd"
GAME_BIN="${PZ_DIR}/projectzomboid-dedicated/ProjectZomboid64"

# ===== VALIDATION =====
if [[ ! -f "${GAME_BIN}" ]]; then
    echo "ERROR: Game binary not found at ${GAME_BIN}"
    echo "Run steamcmd update first:"
    echo "  ${STEAM_DIR}/steamcmd.sh +force_install_dir ${PZ_DIR}/projectzomboid-dedicated +login anonymous +app_update 380870 validate +quit"
    exit 1
fi

if [[ ! -d "${SERVER_DIR}" ]]; then
    mkdir -p "${SERVER_DIR}"
    echo "Created server directory: ${SERVER_DIR}"
fi

# ===== SERVER INI =====
cat > "${SERVER_DIR}/${SERVER_NAME}.ini" << INI_EOF
[server]
name=${SERVER_NAME}
public=${PUBLIC}
publicname=${PUBLIC_NAME}
publicdescription=${PUBLIC_DESCRIPTION}
maxplayers=${MAX_PLAYERS}
port=${SERVER_PORT}
rconport=${RCON_PORT}
rconpassword=${ADMIN_PASSWORD}
password=
saveinterval=120
saveonquit=true
autosave=true
steamport1=16261
steamport2=16262
upnp=false
INI_EOF

echo "Generated ${SERVER_DIR}/${SERVER_NAME}.ini"

# ===== MODS =====
# Mods are managed via workshop.txt (Steam Workshop IDs)
WORKSHOP_FILE="${SERVER_DIR}/workshop.txt"
if [[ ! -f "${WORKSHOP_FILE}" ]]; then
    cat > "${WORKSHOP_FILE}" << 'WORKSHOP_EOF'
# SarvarPZ Mod List
# Add Workshop IDs (one per line) or use in-game mod manager
# Example:
# 2563557746  # More Traits
# 2663255355  # True Music
# 2508017452  # Hydrocraft
WORKSHOP_EOF
fi

# ===== START SERVER =====
echo "Starting Project Zomboid server: ${SERVER_NAME}"
echo "Port: ${SERVER_PORT} | RCON: ${RCON_PORT} | Max Players: ${MAX_PLAYERS}"

cd "${PZ_DIR}/projectzomboid-dedicated"

# JVM tuning for 4GB heap
export JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+ParallelRefProcEnabled"

exec ./ProjectZomboid64 \
    -servername "${SERVER_NAME}" \
    -adminpassword "${ADMIN_PASSWORD}" \
    -port "${SERVER_PORT}" \
    -rconport "${RCON_PORT}" \
    -maxplayers "${MAX_PLAYERS}" \
    -Xms2g -Xmx4g
