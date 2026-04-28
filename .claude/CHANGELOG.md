# Changelog

All notable changes to the Claude Code Environment Setup project.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- [2026-04-29 03:25 AM] `~/.claude/rules/tooling-awareness.md` — User-level rule: at every session start, audit installed skills/plugins/MCPs/agents against the project stack and prefer them over writing from scratch. Documents per-domain tool reach-list (React, Vue, FastAPI, Django, ML, LLM, Web3, Testing, GSD, Universal).
- [2026-04-29 03:25 AM] `~/.claude/hooks/tooling-recommender.sh` — SessionStart hook that detects project stack from manifests (package.json, pyproject.toml, requirements.txt, Cargo.toml, go.mod, Pipfile, Package.swift, *.xcodeproj, build.gradle, pom.xml) + dependency keywords (react, next, vue, tailwind, fastapi, django, torch, langchain, anthropic, solana, web3, ethers, viem, jito, helius, prisma, playwright, vitest, jest, expo) and prints a `[TOOLING AUDIT]` block with specific skill/plugin/MCP/agent recommendations.
- [2026-04-29 03:25 AM] `tooling-recommender.sh` registered as 5th `SessionStart` hook in `~/.claude/settings.json` and in `setup.sh`-generated settings.
- [2026-04-29 03:25 AM] User-level CLAUDE.md router: linked `rules/tooling-awareness.md` and added quick-reference line.
- [2026-04-29 03:25 AM] `setup.sh`: tooling-awareness rule heredoc + tooling-recommender hook heredoc + 3rd SessionStart entry. `sync-setup.sh`: added to rules map and governance hooks list.
- [2026-04-29 03:00 AM] `~/.claude/rules/graphify.md` — User-level rule: every GSD project (with `.planning/`) must keep its knowledge graph current via `/gsd-graphify build`; defines staleness criteria and hook-driven workflow.
- [2026-04-29 03:00 AM] `~/.claude/hooks/graphify-check.sh` — SessionStart hook that detects `.planning/`, reads `.planning/config.json`, and emits `[ACTION REQUIRED]` notice when graphify graph is missing or stale (>7d, planning-file changes, or 20+ source-file changes since last build). Silent for non-GSD projects.
- [2026-04-29 03:00 AM] `graphify-check.sh` registered as 4th `SessionStart` hook in `~/.claude/settings.json`.
- [2026-04-29 03:00 AM] User-level CLAUDE.md router: linked `rules/graphify.md` and added quick-reference line for GSD projects.
- [2026-04-29 03:00 AM] `setup.sh`: graphify rule heredoc, graphify-check hook heredoc, `SessionStart` registration in generated `settings.json` (project-bootstrap + graphify-check) — fresh installs now register both hooks.
- [2026-04-29 03:00 AM] `sync-setup.sh`: added `graphify.md` to rules sync map and `graphify-check.sh` to governance-hook sync list.
- [2026-04-22 12:55 AM] `~/.claude/hooks/project-bootstrap.sh` — SessionStart hook that auto-creates `.claude/` + 6 governance files from `~/.claude/templates/` when missing in any project directory (detects via `.git/` or common manifest files). Never overwrites.
- [2026-04-22 12:55 AM] Auto-bootstrap hook registered in `~/.claude/settings.json` SessionStart.
- [2026-04-22 12:55 AM] `setup.sh` section "7b. GOVERNANCE HOOKS" — installs all 3 governance hook scripts (`governance-check.sh`, `governance-staleness.sh`, `project-bootstrap.sh`) into `~/.claude/hooks/` on fresh setups.
- [2026-04-22 12:55 AM] `sync-setup.sh` extended with Section 5b — syncs governance hook scripts from `~/.claude/hooks/` back into `setup.sh` heredocs.
- [2026-04-21 11:30 PM] Bootstrap `.claude/` directory with all 6 governance files (CLAUDE.md + PROJECT_SCOPE, CHANGELOG, TASKLIST, DECISIONS, KNOWN_ISSUES) — project was previously missing these.
- [2026-04-21 11:30 PM] `~/.claude/hooks/governance-check.sh` — Stop hook that lists all 5 governance files and warns if any are missing.
- [2026-04-21 11:30 PM] `~/.claude/hooks/governance-staleness.sh` — PostToolUse hook that warns when code is edited but governance files haven't been touched.

### Changed
- [2026-04-29 03:25 AM] README.md section "13. Hooks" updated from 8 → 9 hooks; added tooling-recommender row and tooling awareness paragraph.
- [2026-04-29 03:00 AM] README.md section "13. Hooks" updated from 7 → 8 hooks; added graphify-check row and graphify enforcement paragraph.
- [2026-04-22 12:55 AM] README.md section "13. Hooks" expanded from 4 → 7 hooks with governance enforcement table + rationale paragraph.
- [2026-04-21 11:30 PM] Stop hook in `~/.claude/settings.json` now calls `governance-check.sh` instead of an inline two-file reminder (was only mentioning CHANGELOG + PROJECT_SCOPE; now covers all 5).
- [2026-04-21 11:30 PM] Added new PostToolUse matcher `Write|Edit|MultiEdit` that runs the staleness check after file modifications.

---

## [0.9.0] - 2026-04-17

### Added
- Added `anthropics/claude-plugins-official` marketplace to `setup.sh` (was missing — caused 15 plugins to fail on clean Mac install).
- Added 12 new tools: GSD, Claude Mem, UI/UX Pro Max, Obsidian CLI, n8n MCP, and 7 awesome-claude-code marketplaces.
- Added Auto-update README hook — README stays in sync with `setup.sh` after every change.
- Added project onboarding rule (`rules/project-onboarding.md`) + `TASKLIST.md` template.

### Fixed
- README marketplace count corrected from 8 → 9.
- README plugin count corrected from 198 → 123 (actual count).
- Windows compatibility: HTTPS marketplaces, plugin timeout, python3 detection.

### Changed
- `sync-setup.sh` now syncs all config sections (rules, templates, hooks, plugins, marketplaces, MCPs, skills), not just plugins.

---

## [0.8.0] - 2026-04 (approximate)

### Added
- 40+ MCP servers (CRM, sales, outreach, automation).
- Cross-platform support (macOS + Windows) in `setup.sh`.
- 60s timeout to `add_marketplace` to prevent hanging on clone failures.

---

## [0.7.0] - Initial

### Added
- Initial commit: Claude Code full setup script (`setup.sh`).

---

<!-- When releasing a version, move [Unreleased] items here under ## [x.y.z] - YYYY-MM-DD -->
