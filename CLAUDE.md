# Claude Code Environment Setup — Claude Configuration

## Rules

This project follows user-level rules defined at `~/.claude/CLAUDE.md`.

| Category | File |
|---|---|
| Project Standards | `~/.claude/rules/project-standards.md` |
| Maintenance Protocol | `~/.claude/rules/maintenance.md` |
| Development Workflow | `~/.claude/rules/workflow.md` |
| Code Quality | `~/.claude/rules/code-quality.md` |
| Project Onboarding | `~/.claude/rules/project-onboarding.md` |

**ALL 5 governance files in `.claude/` must be reviewed and updated after every task** — CHANGELOG, PROJECT_SCOPE, TASKLIST, DECISIONS, KNOWN_ISSUES. Enforced via `~/.claude/hooks/governance-check.sh` (Stop) and `~/.claude/hooks/governance-staleness.sh` (PostToolUse).

---

## Project Context

**Stack**: Bash, Python 3, Claude CLI, git — reproducible setup tooling (no application runtime).
**Purpose**: One-command reproducible bootstrap for a Claude Code environment (plugins, marketplaces, MCPs, skills, rules, hooks, templates) on macOS and Windows.

---

## Required Maintenance Files

- `.claude/PROJECT_SCOPE.md` — current state, in-progress features, next priorities
- `.claude/CHANGELOG.md` — all changes under `[Unreleased]`, timestamped
- `.claude/TASKLIST.md` — task tracker with completion status
- `.claude/DECISIONS.md` — architecture decisions and their rationale
- `.claude/KNOWN_ISSUES.md` — active bugs, limitations, technical debt

**Always read `PROJECT_SCOPE.md` and `CHANGELOG.md` at session start before making any changes.**

---

## Project-Specific Rules

### Single Source of Truth Locations

| Thing | Location |
|---|---|
| Reproducible install script | `setup.sh` (root) |
| Settings → setup sync logic | `sync-setup.sh` (root) |
| Project governance | `.claude/` directory |
| User rules (referenced, not duplicated) | `~/.claude/rules/` |
| User templates (synced into `setup.sh`) | `~/.claude/templates/` |
| User hooks (synced into `setup.sh`) | `~/.claude/hooks/` |
| User-level Claude settings | `~/.claude/settings.json` |

### Critical Workflow Rules (project-specific)

1. **Never hand-edit `setup.sh` sections that `sync-setup.sh` owns.** If a plugin/marketplace/MCP/skill/hook/rule/template is added or removed, run `sync-setup.sh` — don't edit `setup.sh` directly.
2. **After ANY change to `~/.claude/` — sync, commit, and push.** Per memory rule `feedback_always_sync_and_push`: run `bash sync-setup.sh`, then `git add && git commit && git push`.
3. **README stays in sync with `setup.sh`.** Counts (marketplaces, plugins, MCPs, skills) must match. Auto-updated via file-change hook; verify after manual edits.
4. **Governance hook scripts are NEW** — not yet referenced in `setup.sh`. When `sync-setup.sh` is next extended, include `~/.claude/hooks/governance-check.sh` and `~/.claude/hooks/governance-staleness.sh`.

### Notes

- This project IS the tooling itself — "progress" here is evolution of `setup.sh` + its inputs.
- Verification is manual: run `setup.sh` on a clean macOS or Windows environment; confirm counts match README.
- No test suite — be extra careful with changes to `setup.sh`.
