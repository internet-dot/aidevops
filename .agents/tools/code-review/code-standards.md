---
description: Documented code quality standards for compliance checking
mode: subagent
tools:
  read: true
  write: false
  edit: false
  bash: true
  glob: true
  grep: true
  webfetch: false
  task: true
---

# Code Standards - Quality Rules Reference

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Purpose**: Reference documentation for code quality standards
- **Platforms**: SonarCloud, CodeFactor, Codacy, ShellCheck
- **Target**: A-grade across all platforms, zero critical violations

**Critical Rules (Zero Tolerance)**:

| Rule | Description | Pattern |
|------|-------------|---------|
| S7682 | Explicit return statements | `return 0` or `return 1` in every function |
| S7679 | No direct positional params | `local param="$1"` not `$1` directly |
| S1192 | Constants for repeated strings | `readonly MSG="text"` for 3+ uses |
| S1481 | No unused variables | Remove or use declared variables |
| ShellCheck | Zero violations | All scripts pass `shellcheck` |

**Validation Commands**:

```bash
# Run local linting
~/.aidevops/agents/scripts/linters-local.sh

# Check specific rules
grep -L "return [01]" .agents/scripts/*.sh  # S7682
grep -n '\$[1-9]' .agents/scripts/*.sh | grep -v 'local.*=.*\$[1-9]'  # S7679
```

**Workflow Position**: Reference during development, validated by `/linters-local`

<!-- AI-CONTEXT-END -->

## Critical Standards (Zero Tolerance)

### S7682 - Return Statements

Every function MUST have an explicit `return 0` or `return 1`.

```bash
# CORRECT
function_name() {
    local param="$1"
    # logic
    return 0
}
```

### S7679 - Positional Parameters

NEVER use positional parameters directly. Always assign to local variables first.

```bash
# CORRECT
main() {
    local command="${1:-help}"
    local account_name="$2"
    case "$command" in
        "list") list_items "$account_name" ;;
    esac
    return 0
}
```

### S1192 - String Literals

Define constants for strings used 3 or more times.

```bash
readonly ERROR_ACCOUNT_REQUIRED="Account name is required"
print_error "$ERROR_ACCOUNT_REQUIRED"
```

### S1481 - Unused Variables

Only declare variables that are actually used. Remove unused declarations.

### ShellCheck Compliance

```bash
find .agents/scripts/ -name "*.sh" -exec shellcheck {} \;
```

## Security Hotspots (Acceptable Patterns)

SonarCloud flags these patterns. They are acceptable when documented with a `# SONAR:` comment.

| Pattern | Rule | When acceptable |
|---------|------|-----------------|
| `startswith("http://")` | S5332 | URL detection for security audit |
| `http://$domain` | S5332 | Local dev without SSL (intentional) |
| `curl ... \| bash` | S4423 | Official installers from verified HTTPS sources |

**Suppress vs fix**: Suppress for official installers (bun, nvm, rustup), localhost dev, URL detection. Fix for actual HTTP in production or unverified installer sources.

## Platform Targets

### SonarCloud

| Metric | Target |
|--------|--------|
| Quality Gate | Passed |
| Bugs | 0 |
| Vulnerabilities | 0 |
| Code Smells | <50 |
| Technical Debt | <400 minutes |
| Security Rating | A |
| Reliability Rating | A |
| Maintainability Rating | A |

### CodeFactor

| Metric | Target |
|--------|--------|
| Overall Grade | A |
| A-grade Files | >85% |
| Critical Issues | 0 |

### Codacy

| Metric | Target |
|--------|--------|
| Grade | A |
| Security Issues | 0 |
| Error Prone | 0 |

## Markdown Standards

All markdown files must pass markdownlint with zero violations.

| Rule | Requirement |
|------|-------------|
| MD022 | Blank lines before AND after headings |
| MD025 | Single H1 per document |
| MD012 | No multiple consecutive blank lines |
| MD031 | Blank lines before AND after fenced code blocks |

```bash
# Lint all markdown
npx markdownlint-cli2 "**/*.md" --ignore node_modules

# Auto-fix
npx markdownlint-cli2 "**/*.md" --fix
```

## Pre-Commit Checklist

```bash
# 1. Run local linting
~/.aidevops/agents/scripts/linters-local.sh

# 2. Check return statements
grep -L "return [01]" .agents/scripts/*.sh

# 3. Check positional parameters
grep -n '\$[1-9]' .agents/scripts/*.sh | grep -v 'local.*=.*\$[1-9]'

# 4. Run ShellCheck
find .agents/scripts/ -name "*.sh" -exec shellcheck {} \;

# 5. Check for secrets
~/.aidevops/agents/scripts/secretlint-helper.sh scan

# 6. Lint markdown files
npx markdownlint-cli2 "**/*.md" --ignore node_modules
```

## Quality Scripts

| Script | Purpose |
|--------|---------|
| `linters-local.sh` | Run all local quality checks |
| `quality-fix.sh` | Auto-fix common issues |
| `pre-commit-hook.sh` | Git pre-commit validation |
| `secretlint-helper.sh` | Secret detection |

## Python Projects

### Worktrees and Virtual Environments

Gitignored artifacts (`.venv/`, `__pycache__/`, build dirs) do not transfer between worktrees.

| Situation | Correct action |
|-----------|----------------|
| Project has `.venv/` in canonical repo | Create fresh `.venv/` inside worktree, or activate canonical venv by absolute path without `pip install -e` from worktree |
| Project has `pyproject.toml` but no `.venv/` | `python3 -m venv .venv && pip install -e ".[dev]"` inside worktree |
| Verifying package install | Throwaway venv inside worktree — never modify canonical repo's venv from worktree |

### Editable Installs

**Never run `pip install -e` from a worktree using a venv outside the worktree.** It writes the worktree's absolute path into a `.pth` file; when the worktree is removed, imports break silently.

```bash
# SAFE — throwaway venv inside worktree
python3 -m venv .venv && source .venv/bin/activate
pip install -e shared/project/
```

### Installation Scope

Never install to user-local or system scope. Verify: `pip --version` must show a path inside the project's `.venv/`.

```bash
# SAFE
source .venv/bin/activate && pip install crawl4ai
# or
.venv/bin/pip install crawl4ai
```

### Requirements File Discipline

| File | When to use |
|------|-------------|
| `pyproject.toml` (preferred) | New projects, PEP 517/518 compliant |
| `requirements.txt` | Legacy projects or simple scripts |
| `requirements-dev.txt` | Dev-only deps (pytest, mypy, ruff) |

A venv that cannot be recreated from committed files is a defect. After installing any package, update the dependency file.

### Development Environment Section

When working on a Python project lacking a "Development Environment" section in its `AGENTS.md`, add one:

```markdown
## Development Environment

- **Python**: 3.x (specify version)
- **Venv**: `python3 -m venv .venv && source .venv/bin/activate`
- **Install**: `pip install -e ".[dev]"` (or `pip install -r requirements.txt`)
- **Tests**: `pytest` (or project-specific command)
- **Do NOT**: install globally, run `pip install -e` from a worktree using the canonical venv
```

## Related Documentation

- **Local linting**: `scripts/linters-local.sh`
- **Remote auditing**: `workflows/code-audit-remote.md`
- **Unified PR review**: `workflows/pr.md`
- **Automation guide**: `tools/code-review/automation.md`
- **Best practices**: `tools/code-review/best-practices.md`
