# Task List

> Auto-maintained task tracker. Updated after every task completion.
> Source: Code analysis of `setup.sh`, `README.md`, and git history as of 2026-04-21.

---

## Summary

| Status | Count |
|---|---|
| Completed | 14 |
| In Progress | 1 |
| Pending | 3 |
| Blocked | 0 |

---

## Completed Tasks

- [x] Initial `setup.sh` for full Claude Code environment bootstrap (completed 2026-03)
- [x] Add cross-platform support (macOS + Windows) to setup script (completed 2026-04)
- [x] Add 40+ MCP servers for CRM, sales, outreach & automation (completed 2026-04)
- [x] Fix Windows compatibility: HTTPS marketplaces, plugin timeout, python detection (completed 2026-04)
- [x] Upgrade `sync-setup.sh` to sync all config sections, not just plugins (completed 2026-04)
- [x] Add 60s timeout to `add_marketplace` to prevent hanging on clone failures (completed 2026-04)
- [x] Add project onboarding rule + TASKLIST template (completed 2026-04-17)
- [x] Add 12 new tools: GSD, Claude Mem, UI/UX Pro Max, Obsidian CLI, n8n MCP, and 7 awesome-claude-code marketplaces (completed 2026-04-17)
- [x] Fix: Add missing `claude-plugins-official` marketplace (completed 2026-04-17)
- [x] Update README: 8 → 9 marketplaces (completed 2026-04-17)
- [x] Fix README: correct plugin count (123 not 198) (completed 2026-04-17)
- [x] Configure auto-update README on file changes via hook (completed 2026-04-17)
- [x] Strengthen Stop hook — cover all 5 governance files via `governance-check.sh` (completed 2026-04-21)
- [x] Add PostToolUse staleness-check hook via `governance-staleness.sh` (completed 2026-04-21)

---

## In Progress

- [ ] Bootstrap `.claude/` directory for this project with all 6 files [high] — nearly done, finalizing DECISIONS + KNOWN_ISSUES + root CLAUDE.md

---

## Pending Tasks

### High Priority

- [ ] Sync new governance hooks (`governance-check.sh`, `governance-staleness.sh`) into `setup.sh` via `sync-setup.sh` so they propagate to new installs
- [ ] Update README.md to document the governance-check and governance-staleness hooks under a new Hooks section

### Medium Priority

- [ ] Add `setup.sh` verification step: after install, print a "health check" showing counts of installed marketplaces/plugins/MCPs

### Low Priority

_None_

---

## Blocked Tasks

_None_

---

## Notes

- Task list generated from: code analysis + git history + user memory (no user-provided PRD).
- Last full review: 2026-04-21
- This project is unusual — it IS the setup tooling, so "progress" here means evolution of `setup.sh` and companion files.

---

_Last updated: 2026-04-21_
