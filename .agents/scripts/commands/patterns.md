---
description: Show success/failure patterns from memory to guide task approach and model routing
agent: Build+
mode: subagent
model: haiku
---

Show cross-session success/failure patterns relevant to the current task.

Arguments: `$ARGUMENTS`

## Instructions

Query all pattern types:

```bash
~/.aidevops/agents/scripts/memory-helper.sh recall "success pattern" --type SUCCESS_PATTERN --limit 20
~/.aidevops/agents/scripts/memory-helper.sh recall "failure pattern" --type FAILURE_PATTERN --limit 20
~/.aidevops/agents/scripts/memory-helper.sh recall "working solution" --type WORKING_SOLUTION --limit 10
~/.aidevops/agents/scripts/memory-helper.sh recall "failed approach" --type FAILED_APPROACH --limit 10
```

**Modes** (from `$ARGUMENTS`): `recommend` → model-tier recommendation from outcomes | `report` → full pattern summary | default → concise task-focused suggestions. Filter to task-relevant patterns when arguments are provided.

**Output order:** What works (repeated successes) → What fails (repeated failures/regressions) → Recommended tier (with rationale from evidence).

**No patterns fallback:**

```text
No patterns recorded yet. Patterns are recorded automatically by the pulse supervisor after observing outcomes, or manually with:

  /remember "SUCCESS: bugfix with sonnet — structured debugging found root cause quickly"
  /remember "FAILURE: architecture with sonnet — needed opus for cross-service trade-offs"

Available commands: /patterns suggest, /patterns recommend, /patterns report
```
