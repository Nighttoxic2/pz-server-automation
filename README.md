# Project Zomboid Server Automation

Automated deployment and management for Project Zomboid B42 dedicated server with 80+ mods, systemd integration, and RCON tooling.

## 🎮 Server Specs

| Parameter | Value |
|-----------|-------|
| **Game** | Project Zomboid Build 42 |
| **Mods** | 80+ (QoL, Maps, Weapons, Vehicles, Crafting, Farming, Medical, Admin) |
| **Players** | 16 max |
| **Ports** | 16261/16262 (Steam), 27015 (RCON) |
| **Memory** | 4GB heap (JVM tuned) |
| **Uptime** | 24/7 via systemd |

## 📁 Repository Structure

```
pz-server-automation/
├── systemd/
│   └── sarvarpz.service           # systemd unit with hardening
├── scripts/
│   ├── start-server.sh            # SteamCMD update + JVM launch
│   ├── backup-world.sh            # RCON save + tar + offsite sync
│   └── announce-restart.sh        # Player warnings (5m/1m/10s)
└── docs/
    └── mod-list.md                # 80+ mods categorized with Workshop IDs
```

## ⚙️ Systemd Service Features

- **Auto-update** via SteamCMD on start (`ExecStartPre`)
- **Restart policy** — on-failure, 30s delay, burst limit
- **Resource limits** — 4GB RAM, 200% CPU quota
- **Security hardening** — NoNewPrivileges, PrivateTmp, ProtectSystem=strict
- **Logging** — journald with SyslogIdentifier

```ini
# Key hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/home/trilayer/Servers/SarvarPZ /mnt/Data/pz-backups
```

## 🚀 Deployment

```bash
# 1. Install systemd unit
sudo cp systemd/sarvarpz.service /etc/systemd/system/
sudo systemctl daemon-reload

# 2. Configure
# Edit start-server.sh with your admin password
# Add Workshop IDs to Zomboid/Server/sarvarpz/workshop.txt

# 3. Enable and start
sudo systemctl enable --now sarvarpz
```

## 💾 Backup Strategy

```bash
# Daily cron: 0 4 * * * /path/backup-world.sh
# - RCON "save" command
# - Tar world directory
# - 30-day local retention
# - Offsite sync to B2 (optional)
```

## 📢 Restart Announcements

```bash
# Graceful restart with player warnings
./scripts/announce-restart.sh 5
# Announces at 5m, 1m, 10s, then saves and stops
```

## 📋 Mod Management

See [mod-list.md](docs/mod-list.md) for 80+ mods organized by category:
- Quality of Life (15)
- Maps & Exploration (8)
- Weapons & Combat (12)
- Vehicles (8)
- Crafting & Building (10)
- Farming & Nature (8)
- Medical & Survival (8)
- Admin & Server Tools (6)

**Load order documented** — critical for Hydrocraft compatibility.

## 🔒 Security

- RCON password via environment variable (`${RCON_PASSWORD}`)
- No secrets committed
- Systemd hardening applied
- Firewall rules in parent `sarvar-infra` repo

## 📄 License

MIT
