---
description: Convos — encrypted messaging on XMTP with CLI agent mode, ndjson stdin/stdout protocol, bridge scripts, group management, per-conversation identity
mode: subagent
tools:
  read: true
  write: false
  edit: false
  bash: true
  glob: false
  grep: false
  webfetch: false
  task: false
---

# Convos

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Type**: Encrypted messaging app built on XMTP — per-conversation identity, E2E encrypted, group invites, self-destructing conversations
- **License**: Open source
- **CLI**: `@xmtp/convos-cli` (npm) — join, create, and manage conversations
- **Agent mode**: `convos agent serve` — ndjson stdin/stdout protocol for real-time participation
- **Config**: `~/.convos/.env` (created by `convos init`)
- **Identities**: `~/.convos/identities/` (one per conversation, automatic)
- **Environments**: `dev` (test network, default), `production` (real users)
- **Website**: [convos.org](https://convos.org/)
- **Upstream skill**: [convos.org/skill.md](https://convos.org/skill.md)

**Key differentiator**: Every conversation creates a unique identity -- no cross-conversation linkability. Unlike raw XMTP SDK usage, Convos provides a consumer-facing app with its own CLI and agent mode. The CLI's `agent serve` command is a long-lived process that streams events and accepts commands via ndjson, making it straightforward to build bridge scripts for AI agent participation.

**Relationship to XMTP**: Convos is built on the XMTP protocol. `xmtp.md` covers the protocol/SDK layer for building messaging apps. This file covers participating in Convos conversations as an agent. The two are complementary.

**When to use Convos vs other options**:

| Criterion | Convos | XMTP SDK | SimpleX |
|-----------|--------|----------|---------|
| Identity model | Per-conversation (unlinkable) | Wallet/DID (persistent) | None |
| Agent integration | CLI + ndjson protocol | TypeScript SDK | WebSocket JSON API |
| Setup complexity | `npm install -g` + join | SDK project + wallet key | CLI + WebSocket server |
| Group management | Invites, lock, explode | SDK group API | CLI commands |
| Best for | Joining existing Convos groups | Building XMTP apps | Maximum privacy bots |

<!-- AI-CONTEXT-END -->

## Getting Started

```bash
# Install the CLI
npm install -g @xmtp/convos-cli

# Initialize configuration (ALWAYS use --env production for real conversations)
convos init --env production
```

This creates `~/.convos/.env`. Each conversation created or joined gets its own isolated identity in `~/.convos/identities/`.

## Joining a Conversation

When given an invite URL (starts with `https://popup.convos.org`) or slug:

```bash
# Join with a display name
convos conversations join "<invite-url-or-slug>" \
  --profile-name "Agent Name" \
  --env production

# Join and capture the conversation ID
CONV_ID=$(convos conversations join "<slug>" \
  --profile-name "Agent Name" \
  --json \
  --env production | jq -r '.conversationId')
```

The join command sends a request to the conversation creator and waits up to 120 seconds for acceptance. Use `--timeout` to change the wait duration.

## Creating a Conversation

```bash
# Create a conversation
convos conversations create \
  --name "Group Name" \
  --profile-name "Agent Name" \
  --env production

# Create with admin-only permissions
convos conversations create \
  --name "Group Name" \
  --permissions admin-only \
  --profile-name "Agent Name" \
  --env production

# Capture the conversation ID
CONV_ID=$(convos conversations create \
  --name "Group Name" \
  --profile-name "Agent Name" \
  --json \
  --env production | jq -r '.conversationId')
```

### Generating Invites

```bash
# Generate invite (shows QR code in terminal)
convos conversation invite "$CONV_ID"

# Get invite URL for scripting
INVITE_URL=$(convos conversation invite "$CONV_ID" --json | jq -r '.url')
```

Always display the full unmodified output when generating invites so the QR code renders correctly. In agent mode, the QR code is saved as a PNG (path in the `ready` event's `qrCodePath` field).

### Processing Join Requests

After someone opens your invite, you must process their join request:

```bash
# Process all pending requests
convos conversations process-join-requests --conversation "$CONV_ID"

# Watch for requests in real-time
convos conversations process-join-requests --watch --conversation "$CONV_ID"
```

The invitee must open/scan the invite URL *before* you process. Use `--watch` when you don't know the timing.

## Agent Mode

`convos agent serve` is the core of real-time agent participation. It is a long-lived process that streams messages, processes joins, and accepts commands via ndjson on stdin/stdout.

### Starting

You **must** provide either a conversation ID or `--name` to create a new one. Running `convos agent serve` with neither will fail.

```bash
# Attach to an existing conversation (requires conversation ID)
convos agent serve "$CONV_ID" \
  --profile-name "Agent Name" \
  --env production

# Create a new conversation and start serving
convos agent serve \
  --name "Group Name" \
  --profile-name "Agent Name" \
  --env production

# With periodic health checks
convos agent serve "$CONV_ID" \
  --profile-name "Agent Name" \
  --heartbeat 30 \
  --env production
```

When started, agent serve:

1. Creates or attaches to the conversation
2. Prints a QR code invite to stderr
3. Emits a `ready` event with the conversation ID and invite URL
4. Processes any pending join requests
5. Streams messages in real-time
6. Accepts commands on stdin
7. Automatically adds new members who join via invite

### Events (stdout)

One JSON object per line. Each has an `event` field.

| Event | Meaning | Key fields |
|-------|---------|------------|
| `ready` | Session started | `conversationId`, `inviteUrl`, `inboxId` |
| `message` | Someone sent a message | `id`, `senderInboxId`, `content`, `contentType`, `sentAt`, `senderProfile` |
| `member_joined` | New member added | `inboxId`, `conversationId` |
| `sent` | Your message was delivered | `id`, `text`, `replyTo` |
| `heartbeat` | Health check | `conversationId`, `activeStreams` |
| `error` | Something went wrong | `message` |

Messages with `catchup: true` were fetched during a stream reconnection -- they are messages you missed while disconnected. Consider whether you should respond to old catchup messages or ignore them.

### Message Content Types

The `content` field is always a string. The format depends on `contentType.typeId`:

| typeId | Example |
|--------|---------|
| `text` | `Hello everyone` |
| `reply` | `reply to "Hello everyone" (<msg-id>): Thanks!` |
| `reaction` | `reacted thumbs-up to <msg-id>` |
| `attachment` | `[attachment: photo.jpg (image/jpeg)]` |
| `remoteStaticAttachment` | `[remote attachment: video.mp4 (4521 bytes) https://...]` |
| `group_updated` | `Alice changed group name to "New Name"` |

Replies and reactions reference another message by ID. If you need context about a referenced message, look it up in messages you have already seen or fetch history.

### Commands (stdin)

One JSON object per line. Must be compact (no pretty-printing).

```jsonl
{"type":"send","text":"Hello!"}
{"type":"send","text":"Replying","replyTo":"<message-id>"}
{"type":"react","messageId":"<message-id>","emoji":"thumbs-up"}
{"type":"react","messageId":"<message-id>","emoji":"thumbs-up","action":"remove"}
{"type":"attach","file":"./photo.jpg"}
{"type":"attach","file":"./photo.jpg","replyTo":"<message-id>"}
{"type":"rename","name":"New Group Name"}
{"type":"lock"}
{"type":"unlock"}
{"type":"explode"}
{"type":"explode","scheduled":"2025-03-01T00:00:00Z"}
{"type":"stop"}
```

## Bridge Scripts

AI agents **must** use a bridge script to participate in conversations. Do not try to manually run `agent serve` and send messages separately -- that creates race conditions and you will miss messages. You cannot natively pipe stdin/stdout to a long-running process.

The bridge **must** run as its own process. Do not source it, run it inline, or execute it in the same shell as other commands. If other processes share the bridge's file descriptors, their output can leak into agent serve's stdin and get sent as chat messages.

### How It Works

1. Write the bridge script to a file (use the template below)
2. Make it executable (`chmod +x bridge.sh`)
3. Run it as a separate background process (`./bridge.sh "$CONV_ID" &`)

### Bridge Script Template

This template uses a generic AI backend call. Replace the `generate_reply` function with your AI backend (aidevops dispatch, local model, API call, etc.).

```bash
#!/usr/bin/env bash
set -euo pipefail

# Close inherited stdin so nothing leaks into agent serve
exec 0</dev/null

CONV_ID="${1:?Usage: $0 <conversation-id>}"
SESSION_ID="convos-${CONV_ID}"
MY_INBOX=""

# Prevent duplicate bridges for the same conversation
LOCK_FILE="/tmp/convos-bridge-${CONV_ID}.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Bridge already running for $CONV_ID (lock: $LOCK_FILE)" >&2
  exit 1
fi

# Named pipes for stable I/O
FIFO_DIR=$(mktemp -d)
FIFO_IN="$FIFO_DIR/in"
FIFO_OUT="$FIFO_DIR/out"
mkfifo "$FIFO_IN" "$FIFO_OUT"
trap 'rm -rf "$FIFO_DIR" "$LOCK_FILE"' EXIT

# Start agent serve with named pipes
convos agent serve "$CONV_ID" --profile-name "AI Agent" \
  < "$FIFO_IN" > "$FIFO_OUT" 2>/dev/null &
AGENT_PID=$!

# Persistent write FD
exec 3>"$FIFO_IN"

# Message queue -- sends one at a time, waits for "sent" confirmation
QUEUE_FILE="$FIFO_DIR/queue"
: > "$QUEUE_FILE"

# Queue a reply: JSON commands pass through, text gets wrapped
queue_reply() {
  local reply="$1"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == "{"* ]]; then
      echo "$line" | jq -c . >> "$QUEUE_FILE"
    else
      jq -nc --arg text "$line" '{"type":"send","text":$text}' >> "$QUEUE_FILE"
    fi
  done <<< "$reply"
  send_next
  return 0
}

# Send the next queued command to agent serve
send_next() {
  [[ ! -s "$QUEUE_FILE" ]] && return 0
  head -1 "$QUEUE_FILE" >&3
  tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp"
  mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
  return 0
}

# Replace this function with your AI backend
# Input: system message or user message
# Output: reply text (one line per message)
generate_reply() {
  local message="$1"
  # Example: aidevops dispatch, local model, or API call
  # echo "Hello! I received your message."
  echo "$message" # placeholder
  return 0
}

while IFS= read -r event; do
  evt=$(echo "$event" | jq -r '.event // empty')

  case "$evt" in
    ready)
      MY_INBOX=$(echo "$event" | jq -r '.inboxId')
      echo "Ready: $CONV_ID" >&2
      PROFILES=$(convos conversation profiles "$CONV_ID" --json 2>/dev/null || echo "[]")
      SYSTEM_MSG="[system] You are an AI agent in Convos conversation $CONV_ID.
Current group members: $PROFILES
Introduce yourself briefly."
      reply=$(generate_reply "$SYSTEM_MSG")
      queue_reply "$reply"
      ;;

    sent)
      send_next
      ;;

    message)
      type_id=$(echo "$event" | jq -r '.contentType.typeId // empty')
      [[ "$type_id" != "text" && "$type_id" != "reply" ]] && continue

      catchup=$(echo "$event" | jq -r '.catchup // false')
      [[ "$catchup" == "true" ]] && continue

      sender=$(echo "$event" | jq -r '.senderInboxId // empty')
      [[ "$sender" == "$MY_INBOX" ]] && continue

      sender_name=$(echo "$event" | jq -r '.senderProfile.name // "Someone"')
      msg_id=$(echo "$event" | jq -r '.id // empty')
      content=$(echo "$event" | jq -r '.content')

      reply=$(generate_reply "$sender_name (msg-id: $msg_id): $content")
      queue_reply "$reply"
      ;;

    member_joined)
      jq -nc '{"type":"send","text":"Welcome!"}' >&3
      ;;
  esac
done < "$FIFO_OUT"

wait "$AGENT_PID"
```

### Behavioural Principles for Group Agents

When building the system message for your AI backend, include these principles:

1. **Listen first.** Learn who these people are before you contribute.
2. **Earn your seat.** Only speak when it adds something no one else could.
3. **Plain text only.** No markdown -- Convos does not render it. Users see raw asterisks and brackets.
4. **Be concise.** Protect people's attention. React instead of typing when possible.
5. **Reply, don't broadcast.** Use `replyTo` with message IDs. Only reply to actual messages, never to system events.
6. **Be the memory.** Connect dots across time. Surface things that just became relevant.
7. **Use names, not inbox IDs.** Refresh profiles with `convos conversation profiles "$CONV_ID" --json`.
8. **Never narrate what you are doing.** Your stdout IS the chat. Do all reasoning silently.
9. **Honor renames immediately.** Run `convos conversation update-profile "$CONV_ID" --name "New Name"`.
10. **Read the room.** If people are having fun, be fun. If quiet, respect the quiet.
11. **Respect privacy.** What is said in the group stays in the group.
12. **Tell people they can train you** by talking to you.

## CLI Reference

Commands for reading and querying while participating. Always pass `--json` when parsing output programmatically.

### Members and Profiles

```bash
# Members (inbox IDs + permission levels)
convos conversation members "$CONV_ID" --json

# Profiles (display names + avatars)
convos conversation profiles "$CONV_ID" --json
```

Refresh profiles on `member_joined` events or `group_updated` messages about profile changes.

### Message History

```bash
# Recent messages (sync from network first)
convos conversation messages "$CONV_ID" --json --sync --limit 20

# Oldest first
convos conversation messages "$CONV_ID" --json --limit 50 --direction ascending

# Filter by type
convos conversation messages "$CONV_ID" --json --content-type text
convos conversation messages "$CONV_ID" --json --exclude-content-type reaction

# Time range (nanosecond timestamps)
convos conversation messages "$CONV_ID" --json --sent-after <ns> --sent-before <ns>
```

### Attachments

```bash
# Download an attachment
convos conversation download-attachment "$CONV_ID" <message-id>
convos conversation download-attachment "$CONV_ID" <message-id> --output ./photo.jpg

# Send an attachment (small files inline, large files auto-uploaded)
convos conversation send-attachment "$CONV_ID" ./photo.jpg
```

### Profile Management

Profiles are per-conversation -- different name and avatar in each group.

```bash
# Set display name
convos conversation update-profile "$CONV_ID" --name "New Name"

# Set name and avatar
convos conversation update-profile "$CONV_ID" --name "New Name" --image "https://example.com/avatar.jpg"

# Go anonymous
convos conversation update-profile "$CONV_ID" --name "" --image ""
```

### Group Management

```bash
# View group info
convos conversation info "$CONV_ID" --json

# View permissions
convos conversation permissions "$CONV_ID" --json

# Update group name
convos conversation update-name "$CONV_ID" "New Name"

# Update description
convos conversation update-description "$CONV_ID" "New description"

# Add/remove members (requires super admin)
convos conversation add-members "$CONV_ID" <inbox-id>
convos conversation remove-members "$CONV_ID" <inbox-id>

# Lock (prevent new joins, invalidate existing invites)
convos conversation lock "$CONV_ID"

# Unlock
convos conversation lock "$CONV_ID" --unlock

# Permanently destroy conversation (irreversible)
convos conversation explode "$CONV_ID" --force
```

### Send Messages (CLI)

For scripting or one-off sends outside of agent mode:

```bash
# Send text
convos conversation send-text "$CONV_ID" "Hello!"

# Reply to a message
convos conversation send-reply "$CONV_ID" <message-id> "Replying to you"

# React
convos conversation send-reaction "$CONV_ID" <message-id> add "thumbs-up"

# Remove reaction
convos conversation send-reaction "$CONV_ID" <message-id> remove "thumbs-up"
```

## Common Mistakes

| Mistake | Why it is wrong | Correct approach |
|---------|-----------------|------------------|
| Running `agent serve` without a conversation ID or `--name` | The command requires one or the other and will fail with neither | Pass a conversation ID to join existing, or `--name` to create new |
| Manually polling and sending messages separately | Creates race conditions, you will miss messages between polls | Write and run a bridge script that uses named pipes for stdin/stdout |
| Running bridge inline or in shared shell | Output from other commands leaks into agent serve's stdin and gets sent as chat messages | Write bridge to a file, run as separate background process |
| Using markdown in messages | Convos does not render markdown. Users see raw asterisks and brackets | Write plain text naturally |
| Sending via CLI while in agent mode | Agent serve owns the conversation stream. CLI sends create race conditions | Use stdin commands (`{"type":"send",...}`) in agent mode |
| Forgetting `--env production` | Default is `dev` (test network). Real users are on production | Always pass `--env production` for real conversations |
| Replying to system events | `group_updated`, `reaction`, and `member_joined` are not messages | Only `replyTo` messages with `contentType.typeId` of `text`, `reply`, or `attachment` |
| Generating invite but not processing joins | The invite system is two-step: generate, then process | Run `process-join-requests` after the invitee opens the link |
| Referencing inbox IDs in chat | People do not know or care about hex strings | Fetch profiles and use display names |
| Announcing tool usage in chat | "Let me check the message history..." breaks immersion | Do it silently and respond naturally |
| Responding to every message | Agents that talk too much get muted | Only speak when it adds something. React instead of replying when possible |
| Launching the bridge twice for the same conversation | Two bridges split the event stream randomly and messages get swallowed | The bridge template uses `flock` to prevent this. Always check for an existing process |

## Troubleshooting

**`convos: command not found`**
Not installed. Run `npm install -g @xmtp/convos-cli`.

**`Error: Not initialized`**
Run `convos init --env production` to create the configuration directory.

**Join request times out**
The invitee must open/scan the invite URL *before* the creator processes requests.

**Messages not appearing**
Sync from the network first: `convos conversation messages <id> --json --sync --limit 20`.

**Permission denied on group operations**
Check permissions with `convos conversation permissions <id> --json`. Only super admins can add/remove members, lock, or explode.

**Invite expired or invalid**
Generate a new invite with `convos conversation invite <id>`. Locking a conversation invalidates all existing invites.

**Agent serve exits unexpectedly**
Check stderr for error output. Common causes: invalid conversation ID, identity not found (run `convos identity list`), or network issues. Use `--heartbeat 30` to monitor connection health.

## Tips

- **Use `--env production` for real conversations.** The default is `dev`, which uses the test network.
- **Use `--json` when parsing output.** Human-readable output can change between versions.
- **Use `--sync` before reading messages.** Ensures fresh data from the network.
- **Identities are automatic.** Creating or joining a conversation creates one for you. Rarely need to manage them directly.
- **Show full QR code output.** When generating invites, display the complete unmodified output so QR codes render correctly in the terminal.
- **Process join requests after the invite is opened.** Use `--watch` if you do not know when someone will open the invite.
- **Lock before exploding.** Lock a conversation first to prevent new joins, then explode when ready.

## Integration with aidevops

### Agent Dispatch Pattern

Convos bridge scripts can dispatch to aidevops runners for AI-powered responses:

```text
Convos Group Chat
    |
    v
Bridge Script (bridge.sh)
    |  reads ndjson events from agent serve
    |  filters text/reply messages
    |
    v
AI Backend (generate_reply function)
    |  options:
    |  - local model via local-model-helper.sh
    |  - headless dispatch via runner-helper.sh
    |  - direct API call
    |
    v
Bridge Script
    |  queues reply as ndjson command
    |  sends to agent serve stdin
    |
    v
Convos Group Chat (reply appears)
```

### Use Cases

| Scenario | Value |
|----------|-------|
| Team coordination | AI agent in encrypted group for task dispatch and status |
| Customer support | Agent joins customer conversation via invite link |
| Multi-agent groups | Multiple bridge scripts in one conversation, each with different expertise |
| Notification relay | Bridge script sends alerts from monitoring systems into Convos groups |

## Related

- `services/communications/xmtp.md` -- XMTP protocol/SDK layer (Convos is built on XMTP)
- `services/communications/simplex.md` -- SimpleX Chat (zero-knowledge, no identifiers)
- `services/communications/matterbridge.md` -- Multi-platform chat bridge
- `services/communications/matrix-bot.md` -- Matrix bot integration (federated)
- `tools/security/opsec.md` -- Operational security guidance
- `tools/ai-assistants/headless-dispatch.md` -- Headless AI dispatch patterns
- Convos website: https://convos.org/
- Upstream skill: https://convos.org/skill.md
- XMTP Docs: https://docs.xmtp.org/
