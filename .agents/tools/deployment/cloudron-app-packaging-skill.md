---
name: cloudron-app-packaging
description: "Official Cloudron app packaging skill - Dockerfile patterns, manifest, addons, build methods"
mode: subagent
imported_from: external
tools:
  read: true
  write: true
  edit: true
  bash: true
  webfetch: true
  task: true
---

# Cloudron App Packaging (Official Skill)

A Cloudron app is a Docker image plus `CloudronManifest.json`. Expect a readonly app filesystem, addon-provided services, and platform-managed backup/restore.

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Upstream**: [git.cloudron.io/docs/skills](https://git.cloudron.io/docs/skills) (`cloudron-app-packaging`) | [docs.cloudron.io/packaging](https://docs.cloudron.io/packaging/)
- **Reference files**: `cloudron-app-packaging-skill/manifest-ref.md`, `cloudron-app-packaging-skill/addons-ref.md`
- **Implementation guide**: `cloudron-app-packaging.md` (aidevops-native workflow, helper scripts, detailed Dockerfile/start.sh patterns, pre-packaging assessment)

<!-- AI-CONTEXT-END -->

## Key Constraints

| Constraint | Detail |
|------------|--------|
| Filesystem readonly | Writable paths: `/tmp`, `/run` (ephemeral), `/app/data` (persisted, usually via `localstorage`) |
| Addons for services | Databases, cache, mail, auth come from addons; re-read injected env vars every start |
| Manifest declares all | `CloudronManifest.json` defines metadata, ports, and addon requirements |
| HTTP only | App serves HTTP; Cloudron terminates TLS |
| Memory default | Default limit is 256 MB (RAM + swap); raise with `memoryLimit` |

## Build Methods (9.1+)

| Method | Command | Notes |
|--------|---------|-------|
| On-Server (default) | `cloudron install` / `cloudron update` | Uploads source, builds on server. No local Docker. Source backed up; rebuilds on restore |
| Local Docker | `cloudron build` → `cloudron install`/`update` | Requires `docker login` |
| Build Service | `cloudron build login` → `cloudron build` | Source sent to remote builder |

## Dockerfile Patterns

Use `Dockerfile`, `Dockerfile.cloudron`, or `cloudron/Dockerfile`. For runtime-specific patterns (PHP, Node, Python, nginx, Apache), see `cloudron-app-packaging.md` "Dockerfile Patterns".

```dockerfile
FROM cloudron/base:5.0.0@sha256:...
RUN mkdir -p /app/code
WORKDIR /app/code
COPY . /app/code/
RUN ln -sf /run/app/config.json /app/code/config.json
RUN chmod +x /app/code/start.sh
CMD [ "/app/code/start.sh" ]
```

### start.sh Conventions

- Drop privileges before the main process: `exec gosu cloudron:cloudron <cmd>`
- Fix ownership on each start because restores can reset it: `chown -R cloudron:cloudron /app/data`
- Use `exec` so SIGTERM reaches the app: `exec gosu cloudron:cloudron node /app/code/server.js`
- Gate first-run initialization with a marker file: `if [[ ! -f /app/data/.initialized ]]; then ...; touch /app/data/.initialized; fi`
- Log to stdout/stderr; fallback logs belong under `/run/<subdir>/*.log`
- For multi-process apps, use `supervisor` or `pm2`; see `cloudron-app-packaging.md` "start.sh Architecture"

## Manifest Essentials

```json
{
  "id": "com.example.myapp",
  "title": "My App",
  "author": "Jane Developer <jane@example.com>",
  "version": "1.0.0",
  "healthCheckPath": "/",
  "httpPort": 8000,
  "addons": { "localstorage": {} },
  "manifestVersion": 2
}
```

Full field reference: [manifest-ref.md](cloudron-app-packaging-skill/manifest-ref.md).

## Addons

| Addon | Provides | Key env var |
|-------|----------|-------------|
| `localstorage` | Writable `/app/data` with backup coverage | -- |
| `mysql` | MySQL 8.0 | `CLOUDRON_MYSQL_URL` |
| `postgresql` | PostgreSQL 14.9 | `CLOUDRON_POSTGRESQL_URL` |
| `mongodb` | MongoDB 8.0 | `CLOUDRON_MONGODB_URL` |
| `redis` | Redis 8.4 (persistent) | `CLOUDRON_REDIS_URL` |
| `ldap` / `oidc` | LDAP v3 / OpenID Connect auth | `CLOUDRON_LDAP_URL` / `CLOUDRON_OIDC_DISCOVERY_URL` |
| `sendmail` / `recvmail` | Outgoing SMTP / Incoming IMAP | `CLOUDRON_MAIL_SMTP_SERVER` / `CLOUDRON_MAIL_IMAP_SERVER` |
| `proxyauth` | Auth wall | -- |
| `scheduler` | Cron tasks | -- |
| `tls` | App certificate files | `/etc/certs/tls_cert.pem` |
| `docker` | Create containers (restricted) | `CLOUDRON_DOCKER_HOST` |

Full env vars and addon options: [addons-ref.md](cloudron-app-packaging-skill/addons-ref.md).

## Stack Notes

- **Apache** — Disable default sites, `Listen 8000`, send errors to stderr, `exec /usr/sbin/apache2 -DFOREGROUND`
- **Nginx** — Put temp paths under `/run/` (`client_body_temp_path`, `proxy_temp_path`); run with supervisor
- **PHP** — Symlink sessions into `/run/php/sessions`
- **Java** — Read the cgroup memory limit and set `-XX:MaxRAM`

## Debugging

```bash
cloudron logs [-f]       # view/follow logs
cloudron exec            # shell into app
cloudron debug           # pause app (read-write fs)
cloudron debug --disable # exit debug mode
```

## Reference Packages

All published apps are open source: https://git.cloudron.io/packages. Browse by framework: [PHP](https://git.cloudron.io/explore/projects?tag=php) | [Node](https://git.cloudron.io/explore/projects?tag=node) | [Python](https://git.cloudron.io/explore/projects?tag=python) | [Ruby/Rails](https://git.cloudron.io/explore/projects?tag=rails) | [Java](https://git.cloudron.io/explore/projects?tag=java) | [Go](https://git.cloudron.io/explore/projects?tag=go) | [Rust](https://git.cloudron.io/explore/projects?tag=rust)
