---
mode: subagent
---
# t15049: simplification: tighten agent doc Code Reviewer

## Origin

- **Created:** 2026-04-02
- **Session:** opencode:gemini-3-flash
- **Created by:** ai-supervisor
- **Conversation context:** Automated scan flagged `.agents/tools/ai-assistants/runners-code-reviewer.md` for simplification.

## What

Tighten and restructure the agent doc `.agents/tools/ai-assistants/runners-code-reviewer.md` to reduce its size while preserving all institutional knowledge.

## Why

The file is currently 98 lines. Reducing its size improves token efficiency and makes it easier for LLMs to process.

## How (Approach)

- Tighten prose and remove redundancy.
- Reorder by importance (Rules, Mindset, Checklist, Output Format).
- Use search patterns instead of line numbers.
- Verify content preservation.

## Acceptance Criteria

- [x] Prose is tightened and redundant information removed.
- [x] All institutional knowledge (checklists, rules, mindset) is preserved.
- [x] File size is reduced (target: <70 lines).
  ```yaml
  verify:
    method: bash
    run: "[[ $(wc -l < .agents/tools/ai-assistants/runners-code-reviewer.md) -lt 70 ]]"
  ```
- [x] Markdown linting passes.
  ```yaml
  verify:
    method: bash
    run: "markdownlint-cli2 .agents/tools/ai-assistants/runners-code-reviewer.md"
  ```

## Relevant Files

- `.agents/tools/ai-assistants/runners-code-reviewer.md` — main file to simplify.

## Estimate Breakdown

| Phase | Time | Notes |
|-------|------|-------|
| Research/read | 5m | Read original file |
| Implementation | 15m | Tighten prose |
| Testing | 5m | Lint and verify |
| **Total** | **25m** | |
