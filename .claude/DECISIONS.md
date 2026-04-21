# Architecture Decisions

Records of significant technical decisions for the Claude Code Environment Setup project.
Purpose: prevent revisiting settled decisions and provide context for future changes.

---

## Decision Log

### [DECISION-004] — Governance hook scripts live in `~/.claude/hooks/` (not inline in settings.json)

**Date**: 2026-04-21
**Status**: Accepted

**Context**
The Stop hook in `~/.claude/settings.json` previously had an inline `echo` command with nested escaped quotes. Attempting to extend it to cover all 5 governance files produced invalid JSON (quote-escaping hell). Inline commands are also hard to test and review.

**Decision**
Move the governance-check and staleness-check commands into standalone shell scripts at `~/.claude/hooks/governance-check.sh` and `~/.claude/hooks/governance-staleness.sh`. The JSON hooks just `bash /path/to/script.sh`.

**Consequences**
- Easier to edit and test the hook logic directly as shell scripts.
- JSON stays simple and valid.
- Scripts must be tracked separately and synced via `sync-setup.sh` for portability.

---

### [DECISION-003] — `sync-setup.sh` extracts from live `~/.claude/settings.json`

**Date**: 2026-04 (approximate)
**Status**: Accepted

**Context**
Maintaining the plugin/marketplace list by hand in `setup.sh` caused drift every time a plugin was added or removed via the Claude CLI.

**Decision**
`sync-setup.sh` reads the current state from `~/.claude/settings.json` (and related files) and rewrites the relevant sections of `setup.sh`. Run after any `~/.claude/` change.

**Consequences**
- Single source of truth: whatever's installed on the user's machine is what gets installed for others.
- Requires discipline: always run `sync-setup.sh` after changes, then commit + push.
- Encoded as the `feedback_always_sync_and_push` memory rule.

---

### [DECISION-002] — Cross-platform setup via runtime OS detection in one script

**Date**: 2026-04 (approximate)
**Status**: Accepted

**Context**
Separate macOS and Windows setup scripts would duplicate the marketplace/plugin/MCP lists and drift apart.

**Decision**
Keep `setup.sh` as a single bash script that detects OS at runtime and branches on platform-specific differences (python3 path, HTTPS URL handling, clipboard tool, etc.).

**Consequences**
- One source of truth for install steps.
- Windows users need `bash` (Git Bash or WSL) — documented in README.
- Platform branches add some complexity inside `setup.sh` but keep the artifact count at one.

---

### [DECISION-001] — 60-second timeout per plugin install with retry

**Date**: 2026-04 (approximate)
**Status**: Accepted

**Context**
Plugin installs occasionally hung indefinitely when the upstream marketplace clone was slow or unreachable, blocking the whole setup.

**Decision**
Wrap `claude plugin install "$plugin"` in `timeout 60` inside `add_plugin`, and retry once on failure. Log failures but continue with the rest of the install.

**Consequences**
- Setup script never hangs indefinitely.
- Failed plugins are visible at the end of the install, not silently missing.
- User can re-run `setup.sh` to retry individual failures (idempotent).

---

<!-- Add new decisions above this line, newest first -->
