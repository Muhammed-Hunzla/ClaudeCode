# Project Scope

> Living document. Updated after every task. Reflects current reality, not aspirations.
> **Project**: Claude Code Environment Setup (reproducible full setup for macOS + Windows)

---

## Current State

- `setup.sh` (2296 lines) — reproducible bootstrap script for Claude Code environments (macOS + Windows)
- `sync-setup.sh` — extracts live config from `~/.claude/settings.json` and writes it back into `setup.sh` (auto-sync)
- `README.md` — documents the setup, counts marketplaces/plugins/MCPs
- Installs:
  - **9 plugin marketplaces** (claude-plugins-official, agiprolabs-claude-trading-skills, ando-marketplace, claude-code-plugins-plus, claude-skills, daviguides, daymade-skills, python-backend-plugins, superpowers-dev)
  - **123+ plugins** across those marketplaces
  - **40+ MCP servers** (CRM, sales, outreach, automation, scraping, ads, payments)
  - **Skills, agents, commands, hooks, rules, templates**
- User-level rules synced into `setup.sh`: `project-standards.md`, `maintenance.md`, `workflow.md`, `code-quality.md`, `project-onboarding.md`, `graphify.md`, `tooling-awareness.md`
- Templates synced: `CLAUDE.md`, `PROJECT_SCOPE.md`, `CHANGELOG.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `TASKLIST.md`
- Cross-platform support (Windows compatibility: HTTPS marketplaces, plugin timeout, python3 JSON writer)
- Auto-update README hook configured — README stays in sync with `setup.sh` after every change

---

## In Progress

_Nothing in progress. Tooling awareness is live — every project gets a `[TOOLING AUDIT]` recommendation block at SessionStart via `tooling-recommender.sh` (joins graphify auto-check + governance auto-bootstrap as the third per-project enforcement hook)._

---

## Known Issues

_Summary only — details in `.claude/KNOWN_ISSUES.md`._

- `setup.sh` does not currently include a step to bootstrap `.claude/` in newly cloned target projects (only installs user-level config; project-level governance files are created per-project on first session via the onboarding flow).
- No automated test suite for `setup.sh` — verification is manual (run on clean Mac/Windows).

---

## Next Priorities

1. Add a `setup.sh` verification step: print a "health check" of installed counts after install completes.
2. Consider a project-level `.claude/settings.json` that extends user-level hooks with project-specific enforcement.

---

## Features

| Feature | Status | Notes |
|---|---|---|
| Cross-platform setup (macOS + Windows) | Shipped | `setup.sh` detects OS and adjusts python/HTTPS handling |
| 9 plugin marketplaces | Shipped | Includes anthropics/claude-plugins-official (added Apr 17, 2026) |
| 123+ plugins | Shipped | Verified count — README corrected from 198 |
| 40+ MCP servers | Shipped | Written to `~/.claude/.mcp.json` |
| Auto-sync settings → setup.sh | Shipped | `sync-setup.sh` |
| Auto-update README hook | Shipped | README auto-updates on file changes |
| Plugin install retry + timeout | Shipped | 60s timeout per plugin, retry on fail |
| User-level rules (5 files) | Shipped | Synced into `setup.sh` |
| Templates (6 files) | Shipped | Synced into `setup.sh` |
| Governance enforcement hooks | Shipped | `governance-check.sh` (Stop), `governance-staleness.sh` (PostToolUse) |
| Graphify auto-check hook | Shipped | `graphify-check.sh` (SessionStart) — flags missing/stale `.planning/graphs/` for any GSD project |
| Tooling awareness hook | Shipped | `tooling-recommender.sh` (SessionStart) — detects project stack and recommends specific installed tools per session |
| Project-level `.claude/` for THIS repo | Shipped | Bootstrapped 2026-04-21 |

---

## Architecture Decisions

_Full records in `.claude/DECISIONS.md`._

| Decision | Reason | Date |
|---|---|---|
| `sync-setup.sh` extracts from `~/.claude/settings.json` (not manually maintained) | Prevent setup.sh drift when user adds/removes plugins | 2026-03 |
| Plugin install has 60s timeout + retry | Hanging clones on unreachable marketplaces blocked setup | 2026-04 |
| Cross-platform via runtime detection (not separate scripts) | Single source of truth for install steps | 2026-04 |
| Governance files enforced via hook scripts (not inline JSON) | JSON quote-escaping is fragile; scripts are easier to edit/test | 2026-04-21 |
| Graphify enforced via SessionStart hook (not slash command) | User wants automatic intelligent reminder per project; hook detects staleness without manual invocation | 2026-04-29 |
| Tooling awareness via stack-detection hook (not just rule) | Hundreds of installed skills/plugins/MCPs were unused; rule alone is forgotten across sessions | 2026-04-29 |

---

## Dependencies & Integrations

| Dependency | Purpose | Notes |
|---|---|---|
| `claude` CLI | Plugin marketplace + install | Required; setup.sh errors if missing |
| `git` | Clone marketplaces, project repo | Required |
| `python3` | JSON manipulation (Windows-safe) | Used instead of `jq` for portability |
| `bash` / `zsh` | Shell execution | macOS default zsh, setup.sh uses `#!/usr/bin/env bash` |
| `osascript` (macOS) | Desktop notifications in hooks | Optional, degrades gracefully |

---

_Last updated: 2026-04-29_
