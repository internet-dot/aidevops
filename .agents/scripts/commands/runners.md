---
description: Dispatch workers for tasks, PRs, or issues via opencode run
agent: Build+
mode: subagent
---

Dispatch workers by type: **Code changes** (repo edits, tests, PRs) -> `/full-loop`; **Operational work** (reports, audits) -> direct command.

Arguments: $ARGUMENTS

## Scope & Rules

**`/runners` is a targeted dispatcher, not a supervisor.** It resolves items, launches workers, and stops. It does NOT run supervisor phases or auto-pickup. Use `/pulse` for unattended slot-filling.

- **Isolation**: Workers stay isolated; `/runners` never touches source code or branches.
- **Dispatch Path**: `headless-runtime-helper.sh run` is the **ONLY** valid path. NEVER use bare `opencode run` (GH#5096).
- **Detach**: Use `--detach` for agent-to-agent dispatch to avoid blocking.
- **Directory**: `--dir ~/Git/<repo-name>` must match the target repo.
- **Agent**: Omit `--agent` for code tasks (Build+ default).
- **Model**: Do NOT add `--model` unless escalation is required by policy.

## Step 1: Resolve Items

Resolve inputs to descriptions:
- `GH#\d+` / `Issue URL`: `gh issue view <id> --json number,title,url`
- `t\d+`: `grep -E "^- \[ \] <id> " TODO.md`
- `#\d+` / `PR URL`: `gh pr view <id> --json number,title,headRefName,url`

## Step 2: Dispatch Workers

```bash
AGENTS_DIR="$(aidevops config get paths.agents_dir)"
HELPER="${AGENTS_DIR/#\~/$HOME}/scripts/headless-runtime-helper.sh"

# Code task (Build+ default)
$HELPER run --detach --role worker --session-key "task-t083" \
  --dir ~/Git/<repo> --title "t083: <desc>" --prompt "/full-loop t083 -- <desc>"
```

### Legacy Redirection (no --detach)

`$HELPER run ... </dev/null >>/tmp/worker-${session_key}.log 2>&1 &`

## Step 3: Show Dispatch Table

Show launched items then stop:

| # | Item | Worker |
|---|------|--------|
| 1 | GH#267: `<title>` | dispatched |
