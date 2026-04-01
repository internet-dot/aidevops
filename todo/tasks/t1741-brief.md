# t1741: Autoresearch — Autonomous Experiment Loop

## Origin

- **Created:** 2026-04-01
- **Session:** claude-code:interactive
- **Created by:** marcusquinn (human) + AI (interactive)
- **Conversation context:** User researched karpathy/autoresearch and hyperspaceai/agi repos, discussed how autonomous experiment loops could fit into aidevops for code optimization, agent instruction tuning, and standalone research sandboxes.

## What

A `/autoresearch` command and subagent that runs autonomous experiment loops: modify code/config → test → measure metric → keep if improved, discard if not → repeat within budget constraints. Three operating modes:

1. **In-repo** — experiment worktree in the target repo (optimizing that repo's code/config/agents)
2. **Cross-repo** — target a different managed repo from any session
3. **Standalone** — scaffold a new `autoresearch-{name}` repo with `aidevops init` for topics without an existing codebase

Interactive setup interview when invoked without complete arguments, with context-aware defaults and suggestions.

## Why

Current optimization tools (agent-review, code-simplifier, agent-testing) are **analysis-only and human-gated**. They identify improvements but don't close the loop. Autoresearch adds the autonomous iteration cycle: propose → test → measure → decide → repeat. This enables overnight optimization runs (like Karpathy's ~100 experiments while you sleep) on any measurable dimension — agent token usage, build performance, test coverage, prompt quality.

Direct ROI: agents optimized by autoresearch use fewer tokens for the same quality = lower cost per task. Code optimized by autoresearch runs faster/smaller without manual iteration.

## How (Approach)

### Prior art patterns to adopt

**From karpathy/autoresearch:**
- `program.md` as the human-written research instructions → maps to research program schema
- Single metric, binary keep/discard decision → metric-gated commit/revert
- Git branch per experiment run, commit per hypothesis → existing worktree workflow
- `results.tsv` for structured logging → new results tracking
- "NEVER STOP" autonomous loop within time budget → budget-controlled loop

**From hyperspaceai/agi:**
- Cross-pollination (agents adopt peers' discoveries) → cross-session memory recall
- Multi-domain research (ML, search, finance, skills) → configurable research programs
- 3-layer collaboration stack → memory (fast) + git (durable) + PR (human-readable)

### Architecture

```
/autoresearch [args]
    ↓
scripts/commands/autoresearch.md    # command doc (interactive setup)
    ↓
tools/autoresearch/autoresearch.md  # subagent (loop runner)
    ↓
templates/research-program-template.md  # program file format
```

### Key files to create/modify

- `.agents/tools/autoresearch/autoresearch.md` — subagent (the loop runner)
- `.agents/scripts/commands/autoresearch.md` — slash command doc
- `.agents/templates/research-program-template.md` — program file schema/template
- `.agents/configs/` — any default configs
- `AGENTS.md` — add autoresearch to domain index and capabilities
- `subagent-index.toon` — register new subagent

### Three model roles

| Role | Purpose | Default tier |
|---|---|---|
| Researcher | Generates hypotheses, modifies code, interprets results | sonnet |
| Evaluator | Judges qualitative output when metric isn't purely numeric | haiku |
| Target | Model under test (agent optimization only) | sonnet |

### Budget controls (any stops the loop)

| Control | Default | Override |
|---|---|---|
| Wall-clock | 2h | `--budget 4h` |
| Iterations | 50 | `--iterations 100` |
| Goal-based | none | `--until "pass rate >= 95%"` |

### Interactive setup flow

When invoked without complete args, the command asks for:
1. What are you researching? (with context-aware suggestion)
2. Where does the work happen? (this repo / another / new standalone)
3. What's the success metric? (with suggested metrics based on repo type)
4. Budget? (with sensible defaults)
5. Which models? (with tier recommendations)

Each question includes a default that can be accepted with Enter.

## Acceptance Criteria

- [ ] `/autoresearch` command runs interactive setup when invoked without args
  ```yaml
  verify:
    method: codebase
    pattern: "## Interactive Setup"
    path: ".agents/scripts/commands/autoresearch.md"
  ```
- [ ] Research program template exists with all required fields (target, metric, constraints, models, budget)
  ```yaml
  verify:
    method: codebase
    pattern: "metric|direction|budget|models"
    path: ".agents/templates/research-program-template.md"
  ```
- [ ] Subagent implements the full experiment loop (modify → test → measure → keep/discard → log → repeat)
  ```yaml
  verify:
    method: codebase
    pattern: "keep.*discard|revert.*commit"
    path: ".agents/tools/autoresearch/autoresearch.md"
  ```
- [ ] Three modes work: in-repo (worktree), cross-repo (--repo), standalone (init)
  ```yaml
  verify:
    method: codebase
    pattern: "autoresearch init|--repo"
    path: ".agents/scripts/commands/autoresearch.md"
  ```
- [ ] Agent optimization mode integrates with agent-test-helper.sh
  ```yaml
  verify:
    method: codebase
    pattern: "agent-test-helper"
    path: ".agents/tools/autoresearch/"
  ```
- [ ] Results logged to results.tsv with structured format
- [ ] Cross-session memory stores findings for future sessions
- [ ] Standalone init runs `aidevops init` and registers in repos.json
- [ ] Lint clean (shellcheck for any scripts, markdownlint for .md files)

## Context & Decisions

- **Worktree, not new repo** for in-repo/cross-repo modes: the code being optimized lives in its repo, creating a separate repo adds cross-repo file management complexity. Both Karpathy and Hyperspace work within the same repo on experiment branches.
- **New repo for standalone mode**: research without an existing codebase needs a home. `aidevops init` ensures it's managed (task tracking, memory, pulse visibility). Prefix `autoresearch-` for discoverability.
- **Binary keep/discard** (not gradual): Karpathy's key insight — if the metric improved, keep the commit; if not, revert. No partial credit. This keeps the loop simple and the git history clean.
- **Token budget matters**: unlike Karpathy (GPU time is fixed cost), each autoresearch iteration costs API tokens. Total budget controls are essential, not optional.
- **Agent optimization is the proof case**: all measurement infrastructure exists (agent-test-helper.sh). Build this integration first, generalize second.
- **P2P/distributed features explicitly excluded**: Hyperspace's gossip, CRDT leaderboards, and points system are for multi-agent distributed research. aidevops is single-user; cross-session memory serves the same learning-persistence function without network infrastructure.

## Relevant Files

- `.agents/tools/build-agent/agent-review.md` — existing analysis-only agent review (pattern to extend)
- `.agents/tools/build-agent/agent-testing.md` — existing test framework (measurement harness)
- `.agents/scripts/commands/full-loop.md` — existing autonomous code work command (pattern to follow)
- `.agents/configs/simplification-state.json` — hash registry for tracking what's changed
- `.agents/templates/brief-template.md` — template format reference

## Dependencies

- **Blocked by:** nothing (can start immediately)
- **Blocks:** nothing external
- **External:** none — uses existing aidevops infrastructure

## Estimate Breakdown

| Phase | Time | Notes |
|-------|------|-------|
| Research/read | 1h | Review agent-testing, full-loop, and simplification patterns |
| t1742: Schema + template | 2h | Research program format definition |
| t1743: Command doc | 3h | Interactive setup, context detection, 3 modes |
| t1744: Subagent | 5h | Core loop, crash recovery, PR creation |
| t1745: Agent optimization | 3h | agent-test-helper integration, metrics |
| t1746: Standalone init | 2h | Repo scaffolding, aidevops init, repos.json |
| t1747: Results + memory | 2h | TSV logging, memory integration, summaries |
| Testing | 2h | End-to-end validation of all modes |
| **Total** | **~20h** | |
