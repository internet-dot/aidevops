# t1744: Autoresearch Subagent — Autonomous Experiment Loop Runner

## Origin

- **Created:** 2026-04-01
- **Session:** claude-code:interactive
- **Created by:** marcusquinn (human) + AI (interactive)
- **Parent task:** t1741
- **Conversation context:** Core implementation of the autonomous experiment loop inspired by karpathy/autoresearch's program.md pattern and binary keep/discard decision model.

## What

Create `.agents/tools/autoresearch/autoresearch.md` — the subagent that runs the autonomous experiment loop. This is the engine that reads a research program, generates hypotheses, modifies code, measures results, and iterates within budget constraints.

## Why

This is the core deliverable of the autoresearch epic. Without it, the command doc (t1743) has nothing to dispatch to. The subagent closes the gap between existing analysis-only tools and autonomous optimization.

## How (Approach)

### The experiment loop

```
SETUP:
  1. Read research program file
  2. Create experiment worktree (experiment/{name})
  3. Recall cross-session memory for this research domain
  4. Read previous results.tsv if resuming
  5. Run baseline measurement (first iteration only)

LOOP (until budget exhausted):
  6. Generate hypothesis
     - Read current code state
     - Consider: what hasn't been tried, what worked in memory, program hints
     - Prioritize: high-expected-impact changes first, diminishing returns later
  7. Modify target files in worktree
  8. Run constraint checks (each constraint command must exit 0)
     - If constraint fails → revert, log "constraint_fail", skip to step 6
  9. Run metric command, extract numeric value
     - If measurement crashes → revert, log "crash", attempt diagnosis, skip to step 6
  10. Compare to current best
     - If improved (metric moves in desired direction) → git commit, update best, log "keep"
     - If equal or worse → git reset --hard, log "discard"
  11. Store finding in cross-session memory
  12. Check budget (wall clock, iteration count, goal condition)
     - If any budget exceeded → exit loop
  13. GOTO 6

COMPLETION:
  14. Write results summary (total iterations, improvement, best metric, key findings)
  15. Create PR from experiment branch with summary in body
  16. Store final learnings in memory
```

### Hypothesis generation strategy

The researcher model should follow a progression:
1. **Low-hanging fruit first** — obvious improvements from hints, memory recalls, code smells
2. **Systematic exploration** — vary one parameter at a time, measure effect
3. **Combination attempts** — combine two individually-successful changes
4. **Radical departures** — try fundamentally different approaches if incremental gains stall
5. **Simplification** — try removing things; equal-or-better with less code is a win (Karpathy principle)

### Crash recovery

- If the subagent session crashes mid-loop, the worktree and results.tsv persist
- On resume (`/autoresearch --resume`), read results.tsv to reconstruct state
- The current best is always the HEAD of the experiment branch
- Uncommitted changes on crash → `git reset --hard` to last known good state

### YAML frontmatter for subagent

```yaml
---
description: Autonomous experiment loop runner for code/agent/config optimization
mode: subagent
model: sonnet
tools:
  read: true
  write: true
  edit: true
  bash: true
  glob: true
  grep: true
  webfetch: false
  task: false
---
```

Reference: karpathy/autoresearch `program.md` for the loop design pattern.
Reference: `.agents/tools/build-agent/agent-testing.md` for measurement integration.

## Acceptance Criteria

- [ ] Subagent file exists at `.agents/tools/autoresearch/autoresearch.md`
  ```yaml
  verify:
    method: bash
    run: "test -f .agents/tools/autoresearch/autoresearch.md"
  ```
- [ ] Implements full loop: setup → hypothesis → modify → constrain → measure → keep/discard → log → repeat
  ```yaml
  verify:
    method: codebase
    pattern: "hypothesis|constraint|measure|keep|discard|revert"
    path: ".agents/tools/autoresearch/autoresearch.md"
  ```
- [ ] Creates experiment worktree using existing worktree workflow
  ```yaml
  verify:
    method: codebase
    pattern: "experiment/|worktree"
    path: ".agents/tools/autoresearch/autoresearch.md"
  ```
- [ ] Budget enforcement: wall-clock, iteration count, and goal-based termination
  ```yaml
  verify:
    method: codebase
    pattern: "timeout|max_iterations|budget"
    path: ".agents/tools/autoresearch/autoresearch.md"
  ```
- [ ] Results logged to results.tsv with: commit, metric, status, hypothesis, timestamp
- [ ] Creates PR on completion with results summary in body
- [ ] Crash recovery: resume from results.tsv + worktree state
- [ ] Cross-session memory integration (store and recall)
- [ ] Lint clean (markdownlint)

## Context & Decisions

- **Subagent, not a shell script**: the loop requires creative reasoning (hypothesis generation), code understanding (what to modify), and interpretation (why did the metric change). This is fundamentally an LLM task, not a deterministic script.
- **Git as state machine**: the experiment branch HEAD is always the best known state. `git commit` = keep, `git reset --hard` = discard. No separate state file needed for the experiment state — git IS the state.
- **Constraint checks before metric**: don't waste time measuring if tests are broken. Fail fast on constraint violations.
- **Simplification as a positive outcome**: removing code and getting equal or better results is explicitly encouraged. This aligns with aidevops's efficiency-drive aims.

## Relevant Files

- `.agents/scripts/commands/full-loop.md` — autonomous code work pattern
- `.agents/tools/build-agent/agent-review.md` — analysis pattern to extend
- `.agents/tools/build-agent/agent-testing.md` — measurement harness
- `.agents/workflows/git-workflow.md` — worktree creation conventions

## Dependencies

- **Blocked by:** t1742 (schema), t1743 (command doc)
- **Blocks:** t1745 (agent optimization needs this), t1747 (results tracking)

## Estimate Breakdown

| Phase | Time | Notes |
|-------|------|-------|
| Research/read | 30m | Review full-loop, agent-testing, git-workflow |
| Loop design | 1h | State machine, transitions, edge cases |
| Hypothesis strategy | 1h | Progression logic, memory integration |
| Crash recovery | 30m | Resume, state reconstruction |
| Write subagent | 1.5h | Full markdown with all sections |
| Review | 30m | Lint, cross-reference checks |
| **Total** | **~5h** | |
