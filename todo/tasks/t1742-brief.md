# t1742: Research Program Schema and Template

## Origin

- **Created:** 2026-04-01
- **Session:** claude-code:interactive
- **Created by:** marcusquinn (human) + AI (interactive)
- **Parent task:** t1741
- **Conversation context:** Designing the data format that defines what an autoresearch session optimizes, how it measures success, and what constraints apply.

## What

Define the research program file format and create a reusable template. A research program is a markdown file (at `todo/research/{name}.md` or provided via `--program`) that fully specifies an autoresearch session: what to optimize, how to measure, what models to use, and when to stop.

Deliverables:
1. `.agents/templates/research-program-template.md` — the template with all fields documented
2. Schema documentation within the template (inline, not a separate spec file)
3. 2-3 example programs inline (agent optimization, build performance, standalone ML)

## Why

The research program is the contract between the human (who defines what to optimize) and the subagent (who runs the loop). Without a clear schema, the interactive setup can't generate valid programs, and the subagent can't parse them reliably. This is the foundational piece that t1743 and t1744 depend on.

## How (Approach)

Design the schema as structured markdown with YAML frontmatter for machine-readable fields and prose sections for human context. Pattern follows existing `brief-template.md`.

### Proposed schema

```markdown
---
name: optimize-build-time
mode: in-repo          # in-repo | cross-repo | standalone
target_repo: .         # path or "." for current
---
# Research: {title}

## Target
files: src/**/*.ts, webpack.config.js    # glob patterns of modifiable files
branch: experiment/{name}                 # auto-generated worktree branch

## Metric
command: npm run build 2>&1 | grep 'Time:' | awk '{print $2}'
name: build_time_seconds
direction: lower          # lower | higher
baseline: null            # populated on first run

## Constraints
- Tests must pass: npm test
- No new dependencies
- Keep public API unchanged
- Max file changes per iteration: 5

## Models
researcher: sonnet        # runs the loop
evaluator: haiku          # scores qualitative output (optional)
target: sonnet            # model under test (agent optimization only, optional)

## Budget
timeout: 7200             # total wall-clock seconds (2h)
max_iterations: 50        # max experiment count
per_experiment: 300       # max seconds per single experiment run
goal: null                # optional goal-based termination (e.g., "< 3.0")

## Hints
- Tree-shaking opportunities in utils/
- Barrel exports may prevent dead-code elimination
```

### Key design decisions

- **YAML frontmatter** for mode/repo (machine-parsed by command doc)
- **Markdown sections** for everything else (readable by both human and LLM)
- **`Constraints` as a bullet list** — the subagent runs each as a pre-check before measuring
- **`Hints` section** — optional human guidance for the researcher model's hypothesis generation
- **`baseline: null`** — auto-populated on first run, never manually set

Reference: `.agents/templates/brief-template.md:1-108` for template conventions.

## Acceptance Criteria

- [ ] Template exists at `.agents/templates/research-program-template.md`
  ```yaml
  verify:
    method: bash
    run: "test -f .agents/templates/research-program-template.md"
  ```
- [ ] All required fields present: target files, metric (command, name, direction), constraints, models, budget
  ```yaml
  verify:
    method: codebase
    pattern: "## Target|## Metric|## Constraints|## Models|## Budget"
    path: ".agents/templates/research-program-template.md"
  ```
- [ ] YAML frontmatter includes mode and target_repo
  ```yaml
  verify:
    method: codebase
    pattern: "mode:.*in-repo|cross-repo|standalone"
    path: ".agents/templates/research-program-template.md"
  ```
- [ ] At least 2 example programs included (inline or as separate example files)
- [ ] Schema is parseable by the subagent (sections extractable via grep/awk)
- [ ] Lint clean (markdownlint)

## Context & Decisions

- Markdown over YAML/JSON: research programs should be human-readable and editable. The subagent can parse markdown sections. Pure YAML would be more rigid but less approachable.
- `baseline: null` auto-populated: prevents the human from having to run the baseline manually. The first iteration of the loop establishes baseline.
- Constraints as executable commands: each constraint is a shell command that must exit 0. This makes constraint checking deterministic.

## Relevant Files

- `.agents/templates/brief-template.md` — template format conventions
- `.agents/tools/build-agent/agent-testing.md:36-63` — test suite JSON format (parallel structured format)
- `program.md` from karpathy/autoresearch — the original "skill file" pattern

## Dependencies

- **Blocked by:** nothing
- **Blocks:** t1743, t1744

## Estimate Breakdown

| Phase | Time | Notes |
|-------|------|-------|
| Research/read | 20m | Review brief-template, agent-testing format |
| Design | 40m | Schema fields, section structure |
| Write template | 40m | Template + inline examples |
| Review | 20m | Lint, verify parsability |
| **Total** | **~2h** | |
