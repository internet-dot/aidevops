---
description: GitHub Actions CI/CD workflow setup and management
mode: subagent
tools:
  read: true
  write: true
  edit: true
  bash: true
  glob: true
  grep: true
  webfetch: true
  task: true
---

# GitHub Actions Setup Guide

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Workflow**: `.github/workflows/code-quality.yml`
- **Triggers**: push to `main`/`develop`; pull requests to `main`
- **Jobs**: Framework Validation, SonarCloud Analysis, Codacy Analysis
- **Secrets**: `SONAR_TOKEN` configured; `CODACY_API_TOKEN` needs setup; `GITHUB_TOKEN` auto-provided
- **Dashboards**: [SonarCloud](https://sonarcloud.io/project/overview?id=marcusquinn_aidevops) · [Codacy](https://app.codacy.com/gh/marcusquinn/aidevops) · [Actions](https://github.com/marcusquinn/aidevops/actions)
- **Secret management**: Repository Settings → Secrets and variables → Actions

<!-- AI-CONTEXT-END -->

## Concurrent Push Patterns

Always `git pull --rebase` before `git push`. Keep `|| true` on pull so empty-repo/no-op failures don't abort. Exit non-zero after retries so the workflow surfaces push failures.

| Scenario | Pattern |
|----------|---------|
| Pushing to external repo | Full retry |
| Auto-fix commits to same repo | Simple |
| Wiki sync | Full retry |
| Release workflows | Simple |

**Full retry** (external repos, wiki sync):

```yaml
for i in 1 2 3; do
  git pull --rebase origin main || true
  if git push; then exit 0; fi
  sleep $((i * 5))  # exponential backoff: 5s, 10s, 15s
done
exit 1
```

**Simple** (auto-fix, release):

```yaml
git pull --rebase origin main || true
git push
```

## Secrets

| Secret | Status | Source |
|--------|--------|--------|
| `SONAR_TOKEN` | Configured | https://sonarcloud.io/account/security |
| `CODACY_API_TOKEN` | Needs setup | https://app.codacy.com/account/api-tokens |
| `GITHUB_TOKEN` | Auto-provided | GitHub |

**Add `CODACY_API_TOKEN`:** Settings → Secrets and variables → Actions → New repository secret → Name: `CODACY_API_TOKEN`, Value: token from secure local storage.

## Workflow Behavior

- Push to `main` or `develop` → full analysis.
- Pull requests to `main` → full analysis.
- `Codacy Analysis` conditional on token presence.
