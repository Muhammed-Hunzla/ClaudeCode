# Task List

> Auto-maintained task tracker. Updated after every task completion.
> Source: Code analysis of `setup.sh`, `README.md`, and git history as of 2026-04-21.

---

## Summary

| Status | Count |
|---|---|
| Completed | 23 |
| In Progress | 0 |
| Pending | 1 |
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
- [x] Bootstrap `.claude/` directory for this project with all 6 files (completed 2026-04-21)
- [x] Add `~/.claude/hooks/project-bootstrap.sh` + SessionStart hook — auto-creates governance files in any project (completed 2026-04-22)
- [x] Sync all 3 governance hooks (check, staleness, bootstrap) into `setup.sh` as section "7b. GOVERNANCE HOOKS" (completed 2026-04-22)
- [x] Extend `sync-setup.sh` with Section 5b to sync hook scripts on future changes (completed 2026-04-22)
- [x] Update README.md Hooks section from 4 → 7 hooks with governance enforcement rationale (completed 2026-04-22)
- [x] Create `~/.claude/rules/graphify.md` — user-level rule for auto-using `/gsd-graphify` on every GSD project (completed 2026-04-29)
- [x] Create `~/.claude/hooks/graphify-check.sh` — SessionStart hook with intelligent staleness detection (>7d, planning changes, 20+ source changes) (completed 2026-04-29)
- [x] Register `graphify-check.sh` as 4th SessionStart hook in `~/.claude/settings.json`; link rule in user CLAUDE.md router (completed 2026-04-29)
- [x] Sync graphify rule + hook into `setup.sh` (placeholders + sync-setup.sh map updates) and add SessionStart entries to generated `settings.json` (completed 2026-04-29)
- [x] Update README.md Hooks section from 7 → 8 hooks; add graphify enforcement paragraph (completed 2026-04-29)

---

## In Progress

_Nothing in progress._

---

## Pending Tasks

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

_Last updated: 2026-04-29_
