# Changelog

All notable changes to the Claude Code Environment Setup project.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- [2026-04-21 11:30 PM] Bootstrap `.claude/` directory with all 6 governance files (CLAUDE.md + PROJECT_SCOPE, CHANGELOG, TASKLIST, DECISIONS, KNOWN_ISSUES) — project was previously missing these.
- [2026-04-21 11:30 PM] `~/.claude/hooks/governance-check.sh` — Stop hook that lists all 5 governance files and warns if any are missing.
- [2026-04-21 11:30 PM] `~/.claude/hooks/governance-staleness.sh` — PostToolUse hook that warns when code is edited but governance files haven't been touched.

### Changed
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
