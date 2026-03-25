---
description: Headless dispatch patterns for parallel AI agent execution via OpenCode
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

# Headless Dispatch

<!-- AI-CONTEXT-START -->

## Quick Reference

- **One-shot**: `opencode run "prompt"`
- **Warm server**: `opencode run --attach http://localhost:4096 "prompt"`
- **Server mode**: `opencode serve [--port 4096]`
- **SDK**: `npm install @opencode-ai/sdk`
- **Runner management**: `runner-helper.sh [create|run|status|list|stop|destroy]`
- **Runner directory**: `~/.aidevops/.agent-workspace/runners/`
- **ALWAYS use `headless-runtime-helper.sh run` for dispatch** — never bare `opencode run` (skips lifecycle reinforcement, GH#5096)

**When to use**: parallel tasks, scheduled/cron work, CI/CD integration, chat-triggered dispatch (Matrix/Discord/Slack via OpenClaw), background tasks.

**When NOT to use**: interactive development (use TUI), tasks requiring frequent human-in-the-loop decisions, single quick questions.

**Draft agents**: When parallel workers share domain-specific instructions, create a draft agent in `~/.aidevops/agents/draft/`. See `tools/build-agent/build-agent.md` "Agent Lifecycle Tiers".

**Remote dispatch**: For containers on remote hosts via SSH/Tailscale, see `tools/containers/remote-dispatch.md`.

<!-- AI-CONTEXT-END -->

## Dispatch Methods

### Method 1: Direct CLI

```bash
opencode run "Review src/auth.ts for security issues"
opencode run -m anthropic/claude-sonnet-4-6 "Generate unit tests for src/utils/"
opencode run --agent plan "Analyze the database schema"
opencode run --format json "List all exported functions in src/"
opencode run -f ./schema.sql "Generate types from this schema"
```

### Method 2: Warm Server (recommended for repeated tasks)

Avoids MCP cold boot on every dispatch.

```bash
opencode serve --port 4096                                      # Terminal 1
opencode run --attach http://localhost:4096 "Task"              # Terminal 2+
```

### Method 3: SDK (TypeScript)

```typescript
import { createOpencode, createOpencodeClient } from "@opencode-ai/sdk"

const { client, server } = await createOpencode({
  port: 4096,
  config: { model: "anthropic/claude-sonnet-4-6" },
})
// Or connect to existing: createOpencodeClient({ baseUrl: "http://localhost:4096" })
```

### Method 4: HTTP API

```bash
SESSION_ID=$(curl -sf -X POST "http://localhost:4096/session" \
  -H "Content-Type: application/json" \
  -d '{"title": "API task"}' | jq -r '.id')

# Sync (waits for response)
curl -sf -X POST "http://localhost:4096/session/$SESSION_ID/message" \
  -H "Content-Type: application/json" \
  -d '{"model": {"providerID": "anthropic", "modelID": "claude-sonnet-4-6"},
       "parts": [{"type": "text", "text": "Explain this codebase"}]}'

# Async (returns 204 immediately)
curl -sf -X POST "http://localhost:4096/session/$SESSION_ID/prompt_async" \
  -H "Content-Type: application/json" \
  -d '{"parts": [{"type": "text", "text": "Run tests in background"}]}'

curl -N "http://localhost:4096/event"  # Monitor via SSE
```

### Session Management

```bash
opencode run -c "Continue where we left off"          # Resume last session
opencode run -s ses_abc123 "Add error handling"       # Resume by ID
curl -sf -X POST "http://localhost:4096/session/$SESSION_ID/fork" \
  -H "Content-Type: application/json" -d '{"messageID": "msg-123"}'  # Fork
```

## Parallel Execution

### CLI Parallel (t1419 — Stagger Protection)

Stagger launches by 30s to avoid thundering herd (RAM exhaustion, API rate limits, MCP cold boot storms).

```bash
AGENTS_DIR="$(aidevops config get paths.agents_dir)"
HELPER="${AGENTS_DIR/#\~/$HOME}/scripts/headless-runtime-helper.sh"

for issue in 42 43 44 45; do
  $HELPER run --role worker --session-key "issue-${issue}" \
    --dir ~/Git/myproject --title "Issue #${issue}" \
    --prompt "/full-loop Implement issue #${issue}" &
  sleep 30
done
```

The pulse supervisor handles staggering automatically via `RAM_PER_WORKER_MB`/`MAX_WORKERS_CAP`. Manual dispatch bypasses these checks.

**Worker monitoring**: `worker-watchdog.sh --status` or install launchd service (`worker-watchdog.sh --install`) for automatic hung/idle worker detection and cleanup.

### Parallel vs Sequential

| Use parallel when | Use sequential when |
|-------------------|---------------------|
| Tasks are independent (read-only analysis) | Tasks depend on each other |
| Tasks have separate outputs | Tasks modify the same files |
| Speed matters (3×2min = 2min vs 6min) | Output of one feeds the next |

**Decision table**:

| Scenario | Pattern |
|----------|---------|
| PR review (security + quality + style) | Parallel |
| Bug fix + tests | Sequential |
| Multi-page SEO audit | Parallel |
| Refactor + update docs | Sequential |
| Generate tests for 5 modules | Parallel |
| Plan → implement → verify | Sequential |
| Decomposed subtasks (same parent) | `batch-strategy-helper.sh` |

## Runners

Named, persistent agent instances with their own identity and instructions.

```bash
runner-helper.sh create code-reviewer \
  --description "Reviews code for security and quality" \
  --model anthropic/claude-sonnet-4-6
runner-helper.sh run code-reviewer "Review src/auth/ for vulnerabilities"
runner-helper.sh run code-reviewer "Review src/auth/" --attach http://localhost:4096
runner-helper.sh status code-reviewer
runner-helper.sh list
runner-helper.sh destroy code-reviewer
```

**Runner directory**: `~/.aidevops/.agent-workspace/runners/<name>/AGENTS.md` (personality), `config.json`, `memory.db` (optional).

**Memory**: `memory-helper.sh store/recall --namespace "code-reviewer"`

**Mailbox**: `mail-helper.sh send --to "code-reviewer" --type "task_dispatch" --payload "..."`

## Custom Agents

Place in `.opencode/agents/<name>.md` (project-level) or `opencode.json` (global):

```markdown
---
description: Security-focused code reviewer
mode: subagent
model: anthropic/claude-sonnet-4-6
tools:
  write: false
  edit: false
  bash: false
permission:
  bash:
    "git diff*": allow
    "grep *": allow
    "*": deny
---
```

```bash
opencode run --agent security-reviewer "Audit the auth module"
```

## Model Provider Flexibility

```bash
opencode auth login                                              # Interactive provider selection
opencode run -m openrouter/anthropic/claude-sonnet-4-6 "Task"
opencode run -m groq/llama-4-scout-17b-16e-instruct "Quick task"
```

### OAuth-Aware Dispatch Routing (t1163)

When `SUPERVISOR_PREFER_OAUTH=true` (default), the supervisor routes Anthropic model requests through Claude CLI OAuth (subscription billing) when available, falling back to `opencode` CLI (token billing). Non-Anthropic models always use `opencode`.

```bash
export SUPERVISOR_PREFER_OAUTH=true   # default
export SUPERVISOR_CLI=opencode        # force specific CLI
```

## Security

1. **Network**: Use `--hostname 127.0.0.1` (default) for local-only access
2. **Auth**: Set `OPENCODE_SERVER_PASSWORD` when exposing to network
3. **Permissions**: `OPENCODE_PERMISSION='{"*":"allow"}'` for CI/CD autonomous mode
4. **Credentials**: Never pass secrets in prompts — use environment variables
5. **Cleanup**: Delete sessions after use to prevent data leakage
6. **Scoped tokens** (t1412.2): Workers get minimal-permission GitHub tokens (`contents:write`, `pull_requests:write`, `issues:write`) scoped to the target repo. Disable: `WORKER_SCOPED_TOKENS=false`. CLI: `worker-token-helper.sh [status|create|validate|cleanup]`.
7. **Worker sandbox** (t1412.1): Headless workers run with an isolated HOME (no SSH keys, no gopass, no cloud tokens). `WORKER_SANDBOX_ENABLED=true` (default). Base: `WORKER_SANDBOX_BASE=/tmp/aidevops-worker`. Stale cleanup: `worker-sandbox-helper.sh cleanup-stale`.
8. **Network tiering** (t1412.3): Tier 5 domains (exfiltration indicators: `requestbin.com`, `ngrok.io`, raw IPs) denied. Tier 4 (unknown) flagged for review. Enable: `sandbox-exec-helper.sh run --network-tiering --worker-id <id>`. Config: `configs/network-tiers.conf`.

**GitHub App setup for enforced token scoping** (t1412.2):
1. Create App at `https://github.com/settings/apps/new` (Contents R&W, Pull requests R&W, Issues R&W)
2. Install on account/org, generate private key
3. Write `~/.config/aidevops/github-app.json` with `app_id`, `private_key_path`, `installation_id` (chmod 600)

## Worker Uncertainty Framework

### Decision Tree

```text
Encounter ambiguity
├── Can I infer intent from context + codebase conventions?
│   ├── YES → Proceed, document decision in commit message
│   └── NO ↓
├── Would getting this wrong cause irreversible damage?
│   ├── YES → Exit cleanly with specific explanation
│   └── NO ↓
├── Does this affect only my task scope?
│   ├── YES → Proceed with simplest valid approach
│   └── NO → Exit (cross-task architectural decisions need human input)
```

**Proceed autonomously** (document in commit message):

| Situation | Action |
|-----------|--------|
| Multiple valid approaches, all achieve the goal | Pick the simplest |
| Style/naming ambiguity | Follow existing codebase conventions |
| Slightly vague task, clear intent | Interpret reasonably |
| Choosing between equivalent patterns | Match project precedent |
| Minor adjacent issue | Stay focused, note in PR body |

**Exit cleanly** (specific BLOCKED message):

| Situation | Why |
|-----------|-----|
| Task contradicts codebase state | May be stale or misdirected |
| Requires breaking public API changes | Cross-cutting impact |
| Task already done or obsolete | Avoid duplicate work |
| Missing dependencies/credentials | Cannot be inferred safely |
| Architectural decisions affecting other tasks | Needs human coordination |
| Create vs modify ambiguity with data loss risk | Irreversible |

```text
BLOCKED: Task says 'update the auth endpoint' but there are 3 auth endpoints
(JWT in src/auth/jwt.ts, OAuth in src/auth/oauth.ts, API key in src/auth/apikey.ts).
Need clarification on which one(s) to update.
```

**Supervisor integration**: BLOCKED exits → supervisor reads explanation, clarifies or creates prerequisite task. Unclear exits → supervisor dispatches diagnostic worker (`-diag-N` suffix).

## Lineage Context for Subtask Workers

When dispatching a worker for a subtask (task ID contains a dot, e.g., `t1408.3`), include a lineage block to prevent scope drift across parallel workers.

**Include when**: task ID has a dot AND parent/sibling tasks exist AND multiple siblings may run in parallel.

### Lineage Block Format

```text
TASK LINEAGE:
  0. [parent] Build a CRM with contacts, deals, and email (t1408)
    1. Implement contact management module (t1408.1)
    2. Implement deal pipeline module (t1408.2)  <-- THIS TASK
    3. Implement email integration module (t1408.3)

LINEAGE RULES:
- Focus ONLY on your specific task (marked with "<-- THIS TASK").
- Do NOT duplicate work that sibling tasks would handle.
- Define stubs for cross-sibling dependencies; document in PR body.
- If blocked by a sibling task, exit with BLOCKED and specify which sibling.
```

### Dispatch Template

```bash
AGENTS_DIR="$(aidevops config get paths.agents_dir)"
HELPER="${AGENTS_DIR/#\~/$HOME}/scripts/headless-runtime-helper.sh"

# Standard dispatch (top-level task)
$HELPER run \
  --role worker \
  --session-key "issue-<number>" \
  --dir <path> \
  --title "Issue #<number>: <title>" \
  --prompt "/full-loop Implement issue #<number> (<url>) -- <brief description>" &
sleep 2

# Subtask dispatch (append lineage block to prompt)
$HELPER run \
  --role worker \
  --session-key "issue-<number>" \
  --dir <path> \
  --title "Issue #<number>: <title>" \
  --prompt "/full-loop Implement issue #<number> (<url>) -- <brief description>

${LINEAGE_BLOCK}" &
sleep 2
```

**Assemble lineage from TODO.md**:

```bash
TASK_ID="t1408.3"; PARENT_ID="${TASK_ID%.*}"
PARENT_DESC=$(grep -E "^- \[.\] ${PARENT_ID} " TODO.md | head -1 \
  | sed -E 's/^- \[.\] [^ ]+ //' | cut -c1-120)
SIBLINGS=$(grep -E "^  - \[.\] ${PARENT_ID}\.[0-9]+" TODO.md \
  | sed -E 's/^  - \[.\] ([^ ]+) (.*)/\1: \2/' | cut -c1-120)
```

**Worker rules with lineage**: read lineage at session start, check sibling descriptions before implementing, create stub interfaces for cross-sibling dependencies, include "Task Lineage" section in PR body, exit with BLOCKED on hard sibling dependencies.

## Pre-Dispatch Task Decomposition (t1408.2)

Before dispatching, classify tasks as **atomic** (execute directly) or **composite** (split into subtasks).

```bash
# Classify (~$0.001, haiku tier)
task-decompose-helper.sh classify "Build auth with login and OAuth" --depth 0
# → {"kind": "composite", "confidence": 0.9, "reasoning": "..."}

# Decompose into subtasks with dependency edges
task-decompose-helper.sh decompose "Build auth with login and OAuth" --max-subtasks 5

# Format lineage block for a subtask
task-decompose-helper.sh format-lineage --parent "Build auth" \
  --children '[{"description": "login"}, {"description": "OAuth"}]' --current 1

# Check if already decomposed
task-decompose-helper.sh has-subtasks t1408 --todo-file ./TODO.md
```

**Configuration**: `DECOMPOSE_MAX_DEPTH=3`, `DECOMPOSE_MODEL=haiku`, `DECOMPOSE_ENABLED=true`

**Integration points**:

| Entry point | Mode | Behaviour |
|-------------|------|-----------|
| `/full-loop` (Step 0.45) | Interactive | Show tree, ask Y/n/edit |
| `/full-loop` (headless) | Headless | Auto-decompose, exit with DECOMPOSED |
| `/pulse` (Step 3) | Headless | Auto-classify before dispatch |
| `/new-task` | Interactive | Classify at creation |

**Principles**: When in doubt, atomic. Decompose into 2-5 subtasks only. Reuse `claim-task-id.sh` + `blocked-by:` + standard briefs. Skip already-decomposed tasks.

**Batch strategies** (t1408.4): `batch-strategy-helper.sh next-batch --strategy [depth-first|breadth-first]` controls dispatch order for decomposed tasks. Respects `blocked_by:` dependencies.

## Worker Efficiency Protocol

Workers are injected with this protocol via the supervisor dispatch prompt.

1. **TodoWrite decomposition** — Break task into 3-7 subtasks at session start. Last subtask must always be "Push and create PR".
2. **Commit early, commit often** — After EACH implementation subtask: `git add -A && git commit`. After FIRST commit: `git push -u origin HEAD && gh pr create --draft`.
3. **ShellCheck gate before push** (t234) — If any `.sh` files changed, run `shellcheck -x -S warning` and fix violations before pushing.
4. **Research offloading** — Spawn Task sub-agents for heavy codebase exploration (500+ line files, cross-file patterns). Sub-agents return concise summaries.
5. **Parallel sub-work (MANDATORY)** — Use Task tool for independent operations concurrently. Parallelise: reading multiple files, independent quality checks, generating tests for separate modules. Do NOT parallelise: writes to same files, sequential dependencies, git operations.
6. **Checkpoint after each subtask** — `session-checkpoint-helper.sh save` after each subtask for compaction resilience.
7. **Fail fast** — Verify assumptions before writing code: read target files, check dependencies exist, confirm task isn't already done.
8. **Token minimisation** — Read file ranges (not entire files), concise commit messages, exit with BLOCKED after one failed retry.

**ROI**: Protocol adds ~300-500 tokens/session. A single avoided context-exhaustion failure saves 10,000-50,000 tokens (20-100× ROI).

## Related

- `tools/ai-assistants/opencode-server.md` — Full server API reference
- `tools/ai-assistants/overview.md` — AI assistant comparison
- `tools/ai-assistants/runners/` — Example runner templates
- `scripts/runner-helper.sh` — Runner management CLI
- `scripts/cron-dispatch.sh` — Cron-triggered dispatch
- `scripts/matrix-dispatch-helper.sh` — Matrix chat-triggered dispatch
- `services/communications/matrix-bot.md` — Matrix bot setup
- `scripts/commands/pulse.md` — Pulse supervisor (multi-agent coordination)
- `scripts/mail-helper.sh` — Inter-agent mailbox
- `scripts/worker-token-helper.sh` — Scoped GitHub token lifecycle (t1412.2)
- `scripts/network-tier-helper.sh` — Network domain tiering (t1412.3)
- `scripts/sandbox-exec-helper.sh` — Execution sandbox
- `configs/network-tiers.conf` — Domain classification database
- `tools/security/prompt-injection-defender.md` — Prompt injection defense
- `memory/README.md` — Memory system (supports namespaces)
