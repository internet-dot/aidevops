---
description: Vaultwarden self-hosted password management
mode: subagent
tools:
  read: true
  write: false
  edit: false
  bash: true
  glob: true
  grep: true
  webfetch: true
  task: true
---

# Vaultwarden (Self-hosted Bitwarden) Guide

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Type**: Self-hosted password manager (Bitwarden API compatible)
- **CLI**: `npm install -g @bitwarden/cli` then `bw`
- **Auth**: `bw login email` then `export BW_SESSION=$(bw unlock --raw)`
- **Config**: `configs/vaultwarden-config.json`
- **Commands**: `vaultwarden-helper.sh [instances|status|login|unlock|list|search|get|get-password|create|audit|start-mcp] [instance] [args]`
- **Session**: `BW_SESSION` env var required after unlock
- **Lock**: `bw lock` and `unset BW_SESSION` when done
- **MCP**: Port 3002 for AI assistant credential access
- **Backup**: `bw export --format json` (encrypt with GPG)

<!-- AI-CONTEXT-END -->

Vaultwarden is a self-hosted Bitwarden API implementation. The official `bw` CLI works identically with both Bitwarden Cloud and Vaultwarden — configure the server URL to switch.

## Bitwarden Cloud vs Vaultwarden

```bash
bw config server          # check current server
bw config server https://vault.yourdomain.com   # switch to self-hosted
bw config server https://vault.bitwarden.com    # switch to cloud
```

| Feature | Bitwarden Cloud | Vaultwarden |
|---------|-----------------|-------------|
| Hosting | Managed | Self-managed |
| Pricing | Free + paid plans | Free (open source) |
| Premium features (TOTP, attachments, emergency access) | Paid only | Always available |
| API rate limits | Enforced | Configurable |
| Admin panel | Web vault | `/admin` endpoint |
| Updates | Automatic | Manual (Docker pull) |

**Choose Vaultwarden** when you need all premium features without subscription, data sovereignty, or full infrastructure control.

## Configuration

```bash
# Copy template and edit with your instance details
cp configs/vaultwarden-config.json.txt configs/vaultwarden-config.json
```

Multi-instance config:

```json
{
  "instances": {
    "production": {
      "server_url": "https://vault.yourdomain.com",
      "description": "Production Vaultwarden instance",
      "users_count": 25,
      "organizations": [{ "name": "Company Organization", "id": "org-uuid-here" }]
    },
    "development": {
      "server_url": "https://dev-vault.yourdomain.com",
      "description": "Development Vaultwarden instance",
      "users_count": 10
    }
  }
}
```

## Commands

```bash
# Instance management
vaultwarden-helper.sh instances
vaultwarden-helper.sh status production
vaultwarden-helper.sh login production user@example.com
vaultwarden-helper.sh unlock

# Vault operations
vaultwarden-helper.sh list production
vaultwarden-helper.sh search production "github"
vaultwarden-helper.sh get production item-uuid
vaultwarden-helper.sh get-password production "GitHub Account"
vaultwarden-helper.sh get-username production "GitHub Account"

# Item management
vaultwarden-helper.sh create production "New Service" username password123 https://service.com
vaultwarden-helper.sh update production item-uuid password newpassword123
vaultwarden-helper.sh delete production item-uuid
vaultwarden-helper.sh generate 20 true

# Organization
vaultwarden-helper.sh org-list production org-uuid
vaultwarden-helper.sh sync production
vaultwarden-helper.sh export production json vault-backup.json

# Security & MCP
vaultwarden-helper.sh audit production
vaultwarden-helper.sh lock
vaultwarden-helper.sh start-mcp production 3002
vaultwarden-helper.sh test-mcp 3002
```

## Security

- HTTPS only for all instances
- Enable 2FA for all users
- Clear session when done: `unset BW_SESSION && bw lock`
- Run regular audits: `vaultwarden-helper.sh audit production`
- Role-based access control for shared vaults

## MCP Integration

```bash
# Start MCP server (port 3002)
vaultwarden-helper.sh start-mcp production 3002
vaultwarden-helper.sh test-mcp 3002
```

Add to MCP servers config:

```json
{
  "bitwarden": {
    "command": "bitwarden-mcp-server",
    "args": ["--port", "3002"],
    "env": { "BW_SERVER": "https://vault.yourdomain.com" }
  }
}
```

## Backup & Recovery

```bash
# Manual backup
vaultwarden-helper.sh export production json vault-backup-$(date +%Y%m%d).json
chmod 600 vault-backup-*.json
```

Automated backup script:

```bash
#!/bin/bash
INSTANCE="production"
BACKUP_DIR="/secure/backups/vaultwarden"
DATE=$(date +%Y%m%d-%H%M%S)

vaultwarden-helper.sh export "$INSTANCE" json "$BACKUP_DIR/vault-$DATE.json"

gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
    --s2k-digest-algo SHA512 --s2k-count 65536 --symmetric \
    "$BACKUP_DIR/vault-$DATE.json"

rm "$BACKUP_DIR/vault-$DATE.json"
find "$BACKUP_DIR" -name "vault-*.json.gpg" -mtime +30 -delete
```

## Troubleshooting

```bash
# Connection
curl -I https://vault.yourdomain.com
bw config server https://vault.yourdomain.com

# Auth
bw status
bw logout && bw login user@example.com
bw unlock

# Sync
bw sync --force
bw status
```
