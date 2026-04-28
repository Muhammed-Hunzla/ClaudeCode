# Architecture Decisions

Records of significant technical decisions for the Claude Code Environment Setup project.
Purpose: prevent revisiting settled decisions and provide context for future changes.

---

## Decision Log

### [DECISION-005] — Auto-bootstrap governance files from templates on SessionStart

**Date**: 2026-04-22
**Status**: Accepted

**Context**
Previously, if a project was missing `.claude/*.md` files, Claude could remember the rule but couldn't update files that didn't exist. The onboarding rule required asking the user first — but asking doesn't help if nothing exists to be updated during the session. Result: new projects stayed ungoverned until someone manually bootstrapped them.

**Decision**
Add a SessionStart hook (`~/.claude/hooks/project-bootstrap.sh`) that auto-copies all 6 governance templates (CLAUDE.md + 5 `.claude/*.md`) from `~/.claude/templates/` into any detected project directory (has `.git/` or a manifest file) when missing. Never overwrites existing files. Emits an `[ACTION REQUIRED]` notice telling Claude to populate the placeholders via the onboarding flow.

**Consequences**
- Every project now has the 6 files ready to be updated from day one.
- The onboarding rule ("ask the user first") still applies for POPULATING the files — not for their physical existence.
- Risk: template placeholders could be mistaken for real project state if the onboarding flow is skipped. Mitigated by the `[ACTION REQUIRED]` message and the staleness hook that continues to remind about updates.
- Bootstrap is idempotent — re-running adds nothing if files already exist.

---

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

### [DECISION-006] — Auto-graphify per project via SessionStart hook

**Date**: 2026-04-29
**Status**: Accepted

**Context**
User requested that `/gsd-graphify` be installed at user level and used "intelligently for every project automatically every time — do not forget to use the graphify for every project." The graphify command is gated on `.planning/config.json` having `graphify.enabled: true`, and only matters for GSD-managed projects. A pure rule (markdown) without enforcement would be forgotten across sessions, just like prior governance rules were before hooks.

**Decision**
Combine four mechanisms so the rule cannot be silently skipped:
1. `~/.claude/rules/graphify.md` — defines staleness criteria and required actions.
2. `~/.claude/hooks/graphify-check.sh` — SessionStart hook that detects `.planning/`, reads `config.json`, finds the latest graph file, and emits `[ACTION REQUIRED]` when missing or stale (>7d, planning-file changes, or 20+ source changes). Silent for non-GSD projects.
3. User-level `CLAUDE.md` router — links the rule and adds a quick-reference line.
4. Feedback memory — saved to project memory index so the rule persists in conversation context.

Staleness is computed by the hook (not Claude), so the trigger is consistent across sessions. The hook never invokes graphify itself — it only prompts Claude to run the slash command, preserving the user's control over heavyweight rebuilds.

**Consequences**
- Every GSD project session begins with an automatic graph-freshness check; missing/stale graphs cannot be silently ignored.
- Non-GSD projects pay zero cost (silent exit).
- Rule + hook + router + memory all sync into `setup.sh` so fresh installs inherit the behavior.
- Adds an 8th hook to the system — README and `sync-setup.sh` updated accordingly.

---

<!-- Add new decisions above this line, newest first -->
