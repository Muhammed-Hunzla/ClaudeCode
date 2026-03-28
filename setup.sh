#!/usr/bin/env bash
# =============================================================================
# Claude Code Full Setup Script (macOS + Windows)
# Run this on any new machine to restore the complete Claude Code environment.
#
# Usage:
#   macOS:   chmod +x setup.sh && ./setup.sh
#   Windows: Open Git Bash, then: bash setup.sh
#
# Requirements:
#   macOS  — Terminal (bash/zsh)
#   Windows — Git Bash (comes with Git for Windows)
#
# What this installs:
#   1.  System dependencies (Homebrew/winget, Node.js, uv, TypeScript LSP)
#   2.  Claude Code CLI
#   3.  Custom personal skills (explain-code, debug-helper, test-writer)
#   4.  8 plugin marketplaces
#   5.  123+ plugins across all categories
#   6.  CLAUDE.md (user-level config router)
#   7.  4 rule modules (rules/)
#   8.  5 project templates (templates/)
#   9.  2 custom commands (/bootstrap, /release)
#   10. Memory files (preferences & feedback)
#   11. Autopilot plugin (multi-agent orchestrator)
#   12. 2 third-party orchestration plugins (cloned from GitHub)
#   13. Model router (auto Haiku/Sonnet/Opus routing)
#   14. CodexBar (menu bar usage monitor — macOS only)
#   15. 40+ MCP servers (.mcp.json — CRM, sales, outreach, automation)
#   16. settings.json (hooks, permissions, plugins, MCP config)
# =============================================================================

set -e

# =============================================================================
# OS DETECTION
# =============================================================================
OS="unknown"
case "$(uname -s)" in
  Darwin*)  OS="mac" ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT*) OS="windows" ;;
  Linux*)   OS="linux" ;;
esac

if [ "$OS" = "unknown" ]; then
  echo "Unsupported OS: $(uname -s)"
  exit 1
fi

ROUTER_MODE="${1:-node}"
CLAUDE_DIR="$HOME/.claude"
ROUTER_DIR="$CLAUDE_DIR/model-router"
LOCAL_PLUGINS="$CLAUDE_DIR/plugins/local"

if [ "$OS" = "mac" ]; then
  LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
fi

# Detect python command (python3 on macOS/Linux, python on Windows)
if command -v python3 &>/dev/null; then
  PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
  PYTHON_CMD="python"
else
  echo "Python not found — install Python 3 before running this script."
  exit 1
fi

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
RED="\033[0;31m"
RESET="\033[0m"

log()     { echo -e "${BOLD}${BLUE}  -->${RESET} $1"; }
success() { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
fail()    { echo -e "  ${RED}✘${RESET}  $1"; }
step()    { echo -e "\n${BOLD}${BLUE}$1${RESET}"; }

echo -e "${BOLD}Detected OS: ${GREEN}${OS}${RESET}"

# =============================================================================
# 1. SYSTEM DEPENDENCIES
# =============================================================================
step "1/16  System Dependencies"

if [ "$OS" = "mac" ]; then
  # Homebrew (macOS)
  if ! command -v brew &>/dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    success "Homebrew installed"
  else
    success "Homebrew: $(brew --version | head -1)"
  fi

  # Node.js
  if ! command -v node &>/dev/null; then
    log "Installing Node.js..."
    brew install node
    success "Node.js installed"
  else
    success "Node.js: $(node --version)"
  fi

  # uv
  if ! command -v uv &>/dev/null; then
    log "Installing uv..."
    brew install uv
    success "uv installed"
  else
    success "uv: $(uv --version)"
  fi

elif [ "$OS" = "windows" ]; then
  # Check for winget
  if command -v winget &>/dev/null; then
    success "winget: available"
  else
    warn "winget not found — install App Installer from Microsoft Store"
  fi

  # Node.js
  if ! command -v node &>/dev/null; then
    log "Installing Node.js via winget..."
    winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements 2>/dev/null \
      && success "Node.js installed (restart Git Bash to use)" \
      || warn "Failed — install Node.js manually from https://nodejs.org"
  else
    success "Node.js: $(node --version)"
  fi

  # uv
  if ! command -v uv &>/dev/null; then
    log "Installing uv..."
    if command -v winget &>/dev/null; then
      winget install astral-sh.uv --accept-package-agreements --accept-source-agreements 2>/dev/null \
        && success "uv installed (restart Git Bash to use)" \
        || warn "Failed — install uv manually: https://docs.astral.sh/uv/getting-started/installation/"
    else
      curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null \
        && success "uv installed" \
        || warn "Failed — install uv manually: https://docs.astral.sh/uv/getting-started/installation/"
    fi
  else
    success "uv: $(uv --version)"
  fi
fi

# TypeScript Language Server (cross-platform)
if ! command -v typescript-language-server &>/dev/null; then
  log "Installing TypeScript Language Server..."
  npm install -g typescript-language-server typescript 2>/dev/null \
    && success "TypeScript Language Server installed" \
    || warn "Failed — run manually: npm install -g typescript-language-server typescript"
else
  success "TypeScript Language Server: already installed"
fi

# =============================================================================
# 2. CLAUDE CODE CLI
# =============================================================================
step "2/16  Claude Code CLI"

if ! command -v claude &>/dev/null; then
  log "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code
  success "Claude Code installed"
else
  success "Claude Code: $(claude --version 2>/dev/null | head -1 || echo 'installed')"
fi

# Create required directories
mkdir -p ~/.claude/skills/explain-code
mkdir -p ~/.claude/skills/debug-helper
mkdir -p ~/.claude/skills/test-writer
mkdir -p ~/.claude/memory

# =============================================================================
# 3. CUSTOM PERSONAL SKILLS
# =============================================================================
step "3/16  Custom Personal Skills"

cat > ~/.claude/skills/explain-code/SKILL.md << 'SKILL'
---
name: explain-code
description: Explain code clearly with analogies and diagrams. Use when a user asks to explain, understand, or walk through how code works.
allowed-tools: Read, Grep, Glob
---

When explaining code, structure your response as:

1. **One-line summary** — what this code does in plain English
2. **Analogy** — compare it to something from everyday life
3. **Flow diagram** — ASCII art showing the data/control flow
4. **Step-by-step walkthrough** — go through the key parts line by line
5. **Common gotchas** — one thing that trips people up about this code

Keep explanations concise. Tailor depth to what was asked.

If $ARGUMENTS is provided, focus explanation on: $ARGUMENTS
SKILL
success "explain-code"

cat > ~/.claude/skills/debug-helper/SKILL.md << 'SKILL'
---
name: debug-helper
description: Systematically debug errors, crashes, or unexpected behavior. Use when a user reports a bug, error message, or something not working as expected.
allowed-tools: Read, Grep, Glob, Bash
---

Debug systematically using this approach:

1. **Reproduce** — identify the exact steps/conditions that trigger the issue
2. **Isolate** — narrow down which component/file/function is responsible
3. **Hypothesize** — list 2-3 possible root causes, ranked by likelihood
4. **Verify** — check the most likely cause first (read relevant files, grep for patterns)
5. **Fix** — propose the minimal change that resolves the root cause
6. **Verify fix** — explain how to confirm the fix works

Focus on root causes, not symptoms. Never mask errors with try/catch without understanding them.

Issue to debug: $ARGUMENTS
SKILL
success "debug-helper"

cat > ~/.claude/skills/test-writer/SKILL.md << 'SKILL'
---
name: test-writer
description: Write comprehensive tests for code. Use when asked to add tests, improve test coverage, or write unit/integration tests.
allowed-tools: Read, Grep, Glob, Bash
---

Write tests following these principles:

1. **Read the code first** — understand what the function/module actually does
2. **Identify test cases**:
   - Happy path (normal inputs → expected outputs)
   - Edge cases (empty, null, zero, max values)
   - Error cases (invalid inputs, network failures, etc.)
3. **Use the project's existing test framework** — check for jest, pytest, vitest, go test, etc.
4. **Follow existing test patterns** — match the style of existing tests in the codebase
5. **Write descriptive test names** — test name should read like a specification
6. **Keep tests independent** — each test should set up its own state

Target: $ARGUMENTS
SKILL
success "test-writer"

# =============================================================================
# 4. CLAUDE.MD (user-level config router)
# =============================================================================
step "4/16  CLAUDE.md"

cat > "$CLAUDE_DIR/CLAUDE.md" << 'EOF'
# Claude Code — User-Level Configuration Router

This file is a **router only**. All rules live in categorized files under `~/.claude/rules/`.
Do not define rules here — link to them.

---

## Rule Modules

| Category | File | Purpose |
|---|---|---|
| Project Standards | [rules/project-standards.md](rules/project-standards.md) | Required files, structure, bootstrapping |
| Maintenance | [rules/maintenance.md](rules/maintenance.md) | CHANGELOG + PROJECT_SCOPE update protocol |
| Workflow | [rules/workflow.md](rules/workflow.md) | Pre/post task checklist, feature implementation flow |
| Code Quality | [rules/code-quality.md](rules/code-quality.md) | Single source of truth, naming, DRY principles |

---

## Quick Reference

- **Start of every session**: Read `.claude/PROJECT_SCOPE.md` and `.claude/CHANGELOG.md` before doing anything.
- **End of every task**: Verify changes work, then update `.claude/CHANGELOG.md` and `.claude/PROJECT_SCOPE.md` before responding as done.
- **New project**: Bootstrap required files from `~/.claude/templates/` into the project's `.claude/` directory if they don't exist.
- **One source of truth**: Never duplicate constants, configs, or state. Define once, reference everywhere.
- **Always verify**: Never claim a task is done without running the verification command and reading the output.

---

## Templates

Starter templates for required project files: `~/.claude/templates/`
EOF
success "CLAUDE.md"

# =============================================================================
# 5. RULES
# =============================================================================
step "5/16  Rules"

mkdir -p "$CLAUDE_DIR/rules"

cat > "$CLAUDE_DIR/rules/project-standards.md" << 'EOF'
# Project Standards

## Required Files

Every project must contain these files inside a `.claude/` subdirectory. If any are missing at the start of a session, create them from `~/.claude/templates/` before proceeding.

| File | Purpose |
|---|---|
| `CLAUDE.md` | Project-level router → links back to user rules + project-specific rules (lives in project root) |
| `.claude/CHANGELOG.md` | Auto-maintained log of all changes, organized by version/date |
| `.claude/PROJECT_SCOPE.md` | Living document: current state, in-progress features, next priorities |
| `.claude/DECISIONS.md` | Architecture Decision Records — what was decided and why |
| `.claude/KNOWN_ISSUES.md` | Active bugs, limitations, and technical debt |

## Project CLAUDE.md Structure

Every project's `CLAUDE.md` must:
1. Import user-level rules (reference `~/.claude/CLAUDE.md`)
2. Define project-specific overrides or additions
3. Specify the tech stack
4. Point to `.claude/PROJECT_SCOPE.md` and `.claude/CHANGELOG.md`

Use `~/.claude/templates/CLAUDE.md` as the starting point.

## Bootstrapping a New Project

When starting work in a directory that lacks required files:
1. Announce: "This project is missing required files. Creating them now."
2. Create `.claude/` directory in the project root
3. Create `CLAUDE.md` in project root from template — fill in project name and stack
4. Create `.claude/PROJECT_SCOPE.md` from template — fill in initial state
5. Create `.claude/CHANGELOG.md` from template
6. Create `.claude/DECISIONS.md` from template
7. Create `.claude/KNOWN_ISSUES.md` from template
8. Commit them as the first commit if the project is a git repo

## Continuing a Project Mid-Way (MANDATORY)

When joining or resuming work on an existing project:
1. **Audit the entire project** — read directory structure, key files, configs, and recent git history
2. **Check all governance files exist** — if any of the 5 required files are missing, create them by analyzing the project's current state (not from blank templates)
3. **Update `.claude/PROJECT_SCOPE.md`** — analyze the full project and write an accurate current state, not a guess
4. **Update `.claude/KNOWN_ISSUES.md`** — scan for bugs, TODOs, broken tests, deprecation warnings, linting errors, and document them all
5. **Update `.claude/DECISIONS.md`** — review architecture choices already made in the codebase and document them
6. **Update `.claude/CHANGELOG.md`** — ensure it reflects the actual history of the project
7. Only after all governance files are accurate: begin the requested work

## Directory Organization Principle

- Config: one place (e.g., `config/`, `.env`, `constants.ts`)
- Types/interfaces: one place (e.g., `types/`, `models/`)
- Utilities: one place (e.g., `utils/`, `lib/`)
- Never scatter constants, feature flags, or environment references across files
EOF
success "project-standards.md"

cat > "$CLAUDE_DIR/rules/maintenance.md" << 'EOF'
# Maintenance — CHANGELOG & PROJECT_SCOPE Protocol

## The Two Required Updates

After completing **any task** (feature, fix, refactor, config change), before declaring done:

### 1. Update .claude/CHANGELOG.md

Format: `## [Unreleased]` section at the top, entries under these categories:
- `### Added` — new features
- `### Changed` — changes to existing features
- `### Fixed` — bug fixes
- `### Removed` — removed features
- `### Security` — security fixes

Each entry: one line with timestamp prefix `[YYYY-MM-DD hh:MM AM/PM]`, imperative tense. Example:
```
### Added
- [2026-03-26 02:30 PM] User authentication via JWT tokens

### Fixed
- [2026-03-26 03:45 PM] Login redirect loop when session expires
```

When a version is released, move `[Unreleased]` entries under a `## [x.y.z] - YYYY-MM-DD` heading.

### 2. Update .claude/PROJECT_SCOPE.md

Update these sections as they change:
- **Current State** — what is fully working right now
- **In Progress** — what is actively being built (update every session)
- **Known Issues** — bugs or limitations discovered while working
- **Next Priorities** — what comes after current work
- **Decisions** — architectural decisions made and why (prevents revisiting them)

## Rules

- Never say a task is done without updating **ALL FOUR** governance files (CHANGELOG, PROJECT_SCOPE, DECISIONS, KNOWN_ISSUES)
- Every task completion requires reviewing and updating each file:
  - `CHANGELOG.md` — log what changed
  - `PROJECT_SCOPE.md` — update current state, in-progress, priorities
  - `DECISIONS.md` — log any architectural or design decisions made during the task
  - `KNOWN_ISSUES.md` — add any new issues discovered, remove any that were fixed
- If a task touches an existing feature, update its description in PROJECT_SCOPE.md
- If a task introduces a new dependency or integration, note it in PROJECT_SCOPE.md under the relevant feature
- Keep CHANGELOG entries brief — one line per change
- Keep PROJECT_SCOPE.md accurate, not aspirational — it must reflect current reality
- If a governance file has no changes needed, still verify it is accurate — do not skip the check

## Single Source of Truth Enforcement

Before adding a new constant, config value, or type:
1. Search the project for an existing definition
2. If found: use it, do not duplicate
3. If not found: create it in the canonical location (see project-standards.md)
4. Update .claude/PROJECT_SCOPE.md if it affects architecture
EOF
success "maintenance.md"

cat > "$CLAUDE_DIR/rules/workflow.md" << 'EOF'
# Development Workflow

## Session Start Checklist

At the start of every conversation (before reading any other code):
1. Read `.claude/PROJECT_SCOPE.md` — understand current state and what's in progress
2. Read `.claude/CHANGELOG.md` (Unreleased section) — understand what changed recently
3. If either file is missing, create it from `~/.claude/templates/` first

This prevents implementing something that conflicts with or duplicates existing work.

## Before Implementing a Feature

1. Check PROJECT_SCOPE.md: is this feature already in progress or done?
2. Check if the feature touches any "In Progress" items — if yes, coordinate or warn
3. Identify all files that will be affected — read them before changing them
4. Identify any constants, types, or configs needed — locate the single source of truth
5. If architecture decisions are needed, add them to `.claude/DECISIONS.md` (and summarize in PROJECT_SCOPE.md) before coding

## During Implementation

- One concern at a time — do not refactor unrelated code while implementing
- If you discover a bug while implementing: add it to `.claude/KNOWN_ISSUES.md` and summarize in PROJECT_SCOPE.md, do not fix inline unless trivial
- If you need to change something that other features depend on: warn the user before proceeding
- Never rename or move a function/file without checking what imports it

## Brainstorming Before Building (MANDATORY)

Before creating, building, or implementing **anything** (feature, component, page, button, API, etc.):

1. **Use the brainstorming skill** — discuss requirements, explore options, show alternatives
2. **Present options to the user** — show mockups/previews in the browser when applicable
3. **Get explicit user approval** on the chosen approach
4. **Create a plan with steps** — then implement step by step
5. Never jump straight to code — always discuss first, even for small features

This applies to ALL creation work: UI components, backend features, configs, integrations — everything.

## Verifying Changes with Playwright

**MANDATORY**: When verifying any UI or web change, always use Playwright in **headed mode** (real visible browser window) — never headless.

- Launch with `headless: false` so the actual browser window opens
- Interact with the page as a human would — click, scroll, fill forms
- Only confirm a task is complete after visually verifying it in the opened window
- Do not mark something done based on code inspection alone when a browser test is possible

## Screenshot & Test Artifact Organization

**Never place screenshots or test artifacts in the project root directory.**

- Screenshots go in the relevant plugin/tool folder (e.g., `playwright-mcp/screenshots/`, `tests/screenshots/`)
- Test reports go in the tool's output directory (e.g., `playwright-mcp/reports/`)
- Maintain corporate-level directory structure — no loose files in root
- If a dedicated folder doesn't exist, create one inside the relevant plugin/tool directory before saving

## Verification Before Completion (MANDATORY)

Before claiming ANY task is done, fixed, or working:

1. **Identify** the verification command (test suite, build, lint, browser check)
2. **Run** the command — fresh, complete, not a previous run
3. **Read** the full output — check exit code, count failures
4. **Test the actual functionality** — run the code, open in browser, execute the feature
5. **Only then** claim the result with evidence

Never say "it's fixed", "should work", or "done" without running verification first. If there's no automated test, manually verify by running the code or checking in the browser. Evidence before assertions — always. **No exceptions.**

## After Completing a Task

1. Update `.claude/CHANGELOG.md` under `## [Unreleased]`
2. Update `.claude/PROJECT_SCOPE.md`:
   - Move completed items from "In Progress" to "Current State"
   - Update "Known Issues" if anything was fixed
   - Update "Next Priorities" if the task changes what comes next
3. If new dependencies were added, note them
4. Only then: declare the task done

## Feature Flags & Incremental Work

- If a feature is partially done, mark it in PROJECT_SCOPE.md as `[partial]` with what works and what doesn't
- Never leave the project in a broken state — if mid-feature, ensure existing features still work
- If a session ends mid-task, update PROJECT_SCOPE.md `## In Progress` with exactly where you stopped

## Dependency Awareness

Before modifying a shared utility, type, or config:
1. Run a search to find all usages
2. List the affected files to the user
3. Get confirmation if the blast radius is large
EOF
success "workflow.md"

cat > "$CLAUDE_DIR/rules/code-quality.md" << 'EOF'
# Code Quality Rules

## Single Source of Truth

The most important rule: **define once, reference everywhere**.

- Constants → one file (e.g., `constants.ts`, `config.py`, `config/index.js`)
- Types/interfaces → one directory (e.g., `types/`, `models/`)
- Environment variables → accessed through one wrapper, not `process.env.X` scattered everywhere
- API endpoints → one place (e.g., `api/endpoints.ts`)
- Feature flags → one place (e.g., `config/features.ts`)

If you need to use the same value in two places: find where it's defined and import it. Never copy-paste a constant.

## Minimal Changes

- Only change what the task requires
- Do not refactor unrelated code while fixing a bug
- Do not add docstrings, comments, or types to code you didn't change
- Do not add error handling for scenarios that cannot happen
- Three similar lines of code is better than a premature abstraction
- No feature flags or backwards-compatibility shims — just change the code

## No Over-Engineering

- Don't design for hypothetical future requirements
- Don't create helpers for one-time operations
- Don't add configurability that isn't needed now
- The right complexity is the minimum needed for the current task

## Security Baseline

- Never commit secrets, tokens, or passwords — use environment variables
- Validate all external inputs (user input, API responses, file reads)
- Trust internal code — don't add defensive checks on values you just set
- No SQL injection, no command injection, no XSS

## Naming

- Names must be accurate and reflect current behavior — rename if the behavior changes
- Don't leave stale names like `newX`, `oldX`, `tempX`, `X2` in production code
- Boolean names: `isX`, `hasX`, `canX` — never just `flag` or `status`

## Clean Code Enforcement (MANDATORY)

Code must be clean at all times. No messy or useless code sitting in the project.

- **Remove dead code** — unused functions, variables, imports, commented-out blocks. Delete them, don't leave them "just in case"
- **Remove debug artifacts** — console.log, print statements, debugger keywords, test data left inline
- **Remove stale comments** — outdated TODOs, commented-out alternatives, "temporary" notes that are now permanent
- **Clean up after yourself** — if you refactor or replace something, delete the old version completely
- **No orphan files** — if a file is no longer imported or used anywhere, delete it
- **No placeholder code** — no empty functions, no `// TODO: implement`, no pass-through wrappers that do nothing
- After every task, review the changed files and their surroundings — clean anything messy you see

## Before Submitting

- Read the diff — does it do exactly what was asked, nothing more?
- Are there any leftover debug statements or TODO comments?
- Is anything duplicated that shouldn't be?
- Is there any dead code, unused imports, or orphan files? Remove them.
EOF
success "code-quality.md"

# =============================================================================
# 6. TEMPLATES
# =============================================================================
step "6/16  Templates"

mkdir -p "$CLAUDE_DIR/templates"

cat > "$CLAUDE_DIR/templates/CLAUDE.md" << 'EOF'
# [PROJECT NAME] — Claude Configuration

## Rules

This project follows user-level rules defined at `~/.claude/CLAUDE.md`.

| Category | File |
|---|---|
| Project Standards | `~/.claude/rules/project-standards.md` |
| Maintenance Protocol | `~/.claude/rules/maintenance.md` |
| Development Workflow | `~/.claude/rules/workflow.md` |
| Code Quality | `~/.claude/rules/code-quality.md` |

---

## Project Context

**Stack**: [e.g., Next.js, TypeScript, PostgreSQL, Prisma]
**Purpose**: [One sentence describing what this project does]

---

## Required Maintenance Files

- `PROJECT_SCOPE.md` — current state, in-progress features, next priorities
- `CHANGELOG.md` — all changes, auto-updated after every task
- `DECISIONS.md` — architecture decisions and their rationale
- `KNOWN_ISSUES.md` — active bugs, limitations, technical debt

**Always read PROJECT_SCOPE.md and CHANGELOG.md at session start before making any changes.**

---

## Project-Specific Rules

<!-- Add any project-specific overrides or additions below -->

### Source of Truth Locations

| Thing | Location |
|---|---|
| Constants | `[path]` |
| Types | `[path]` |
| API endpoints | `[path]` |
| Environment config | `[path]` |

### Notes

<!-- Any specific patterns, gotchas, or decisions for this project -->
EOF
success "CLAUDE.md template"

cat > "$CLAUDE_DIR/templates/PROJECT_SCOPE.md" << 'EOF'
# Project Scope

> Living document. Updated automatically after every task. Reflects current reality, not aspirations.

---

## Current State

<!-- What is fully working right now -->
- [ ] Initial setup

---

## In Progress

<!-- What is actively being built this session. Format: `[feature] — where we left off` -->
_Nothing in progress._

---

## Known Issues

<!-- Summary only — details in KNOWN_ISSUES.md -->
_None known. See KNOWN_ISSUES.md for full tracking._

---

## Next Priorities

<!-- What comes after current work, in order -->
1. _TBD_

---

## Features

<!-- Brief description of each shipped feature and its current status -->
| Feature | Status | Notes |
|---|---|---|
| — | — | — |

---

## Architecture Decisions

<!-- Decisions made and why — prevents revisiting them -->
| Decision | Reason | Date |
|---|---|---|
| — | — | — |

---

## Dependencies & Integrations

<!-- External services, APIs, packages that are load-bearing -->
| Dependency | Purpose | Notes |
|---|---|---|
| — | — | — |

---

_Last updated: [date]_
EOF
success "PROJECT_SCOPE.md template"

cat > "$CLAUDE_DIR/templates/CHANGELOG.md" << 'EOF'
# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- [YYYY-MM-DD HH:MM] Initial project setup

---

<!-- When releasing a version, move [Unreleased] items here:

## [x.y.z] - YYYY-MM-DD

### Added
-

### Changed
-

### Fixed
-

### Removed
-

-->
EOF
success "CHANGELOG.md template"

cat > "$CLAUDE_DIR/templates/DECISIONS.md" << 'EOF'
# Architecture Decisions

Records of significant technical decisions made in this project.
Purpose: prevent revisiting settled decisions and provide context for future changes.

---

## Decision Log

### [DECISION-001] — [Short title]

**Date**: YYYY-MM-DD
**Status**: Accepted | Superseded by DECISION-XXX | Deprecated

**Context**
What situation or problem required a decision?

**Decision**
What was decided?

**Consequences**
What are the trade-offs? What becomes easier or harder as a result?

---

<!-- Add new decisions above this line, newest first -->
EOF
success "DECISIONS.md template"

cat > "$CLAUDE_DIR/templates/KNOWN_ISSUES.md" << 'EOF'
# Known Issues

Active bugs, limitations, and technical debt tracked here.
Keeps PROJECT_SCOPE.md clean — this file holds the detail.

---

## Active Bugs

| ID | Severity | Description | Workaround | Reported |
|---|---|---|---|---|
| — | — | — | — | — |

---

## Limitations

Things the project intentionally doesn't do yet, or can't do well.

- —

---

## Technical Debt

Code that works but needs improvement before it becomes a real problem.

| Area | Issue | Priority |
|---|---|---|
| — | — | — |

---

## Resolved

| ID | Description | Fixed in |
|---|---|---|
| — | — | — |

---

_Last updated: [date]_
EOF
success "KNOWN_ISSUES.md template"

# =============================================================================
# 7. COMMANDS
# =============================================================================
step "7/16  Commands"

mkdir -p "$CLAUDE_DIR/commands"

cat > "$CLAUDE_DIR/commands/bootstrap.md" << 'EOF'
Bootstrap all required project files for this project.

Follow these steps exactly:

1. Read the current directory name and any existing files (package.json, pyproject.toml, README.md, etc.) to infer the project name, tech stack, and purpose.

2. Create the `.claude/` directory in the project root if it doesn't exist.

3. Check which required files already exist:
   - `CLAUDE.md` (project root)
   - `.claude/CHANGELOG.md`
   - `.claude/PROJECT_SCOPE.md`
   - `.claude/DECISIONS.md`
   - `.claude/KNOWN_ISSUES.md`

4. For each missing file, create it from the corresponding template at ~/.claude/templates/, filling in:
   - Project name (from directory name or package.json)
   - Tech stack (inferred from files present)
   - Purpose (inferred from README or package.json description)
   - Today's date where needed

5. `CLAUDE.md` goes in the project root. All other governance files go in `.claude/`.

6. If CLAUDE.md already exists but doesn't reference ~/.claude/CLAUDE.md, add the user-level rules import section to the top.

7. After creating all files, print a summary of what was created vs already existed.

8. If this is a git repo with no commits yet, suggest committing the bootstrap files as the first commit.

Do not ask for confirmation — just do it and show what was created.
EOF
success "/bootstrap"

cat > "$CLAUDE_DIR/commands/release.md" << 'EOF'
Cut a release for this project.

Follow these steps:

1. Read CHANGELOG.md and find everything under `## [Unreleased]`. If it's empty or only has the initial setup entry, warn and ask if the user still wants to proceed.

2. Read PROJECT_SCOPE.md to understand the current state.

3. Determine the next version number:
   - Check the most recent version in CHANGELOG.md (e.g. `## [1.2.0] - ...`)
   - If no versions exist yet, start at `0.1.0`
   - If the [Unreleased] section has breaking changes → bump major
   - If it has new features (Added section) → bump minor
   - If only fixes/changes → bump patch
   - Show the user the proposed version and ask to confirm or override

4. Once version is confirmed:
   a. In CHANGELOG.md: rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD` (today's date) and add a fresh empty `## [Unreleased]` section above it
   b. In PROJECT_SCOPE.md: update the version/release info if there's a relevant section

5. If this is a git repo:
   - Stage CHANGELOG.md and PROJECT_SCOPE.md
   - Show the user the proposed commit message: `chore: release vX.Y.Z`
   - Ask if they want to also create a git tag `vX.Y.Z`
   - Wait for confirmation before committing or tagging

6. Print the final release summary: version, date, what was included.
EOF
success "/release"

# =============================================================================
# 8. MEMORY
# =============================================================================
step "8/16  Memory"

mkdir -p "$CLAUDE_DIR/memory"

cat > "$CLAUDE_DIR/memory/MEMORY.md" << 'EOF'
# Memory Index

## Feedback
- [feedback_playwright_headed.md](feedback_playwright_headed.md) — Always use Playwright headed mode (real browser window)
- [feedback_autopilot_workflow.md](feedback_autopilot_workflow.md) — User wants autonomous multi-agent workflow with reporting
EOF
success "MEMORY.md"

cat > "$CLAUDE_DIR/memory/feedback_playwright_headed.md" << 'EOF'
---
name: playwright_headed_mode
description: Always use Playwright in headed mode (real browser window) to visually verify changes
type: feedback
---
Always launch Playwright with `headless: false`. Verify changes visually before marking done.
**Why:** User wants human-like visual verification, not silent headless testing.
EOF
success "feedback_playwright_headed.md"

cat > "$CLAUDE_DIR/memory/feedback_autopilot_workflow.md" << 'EOF'
---
name: autopilot_workflow_preference
description: User wants autonomous multi-agent development with parallel agents, browser testing, and timestamped reports
type: feedback
---
Preferred workflow: Understand → Plan → Parallel implement → Browser test (headed) → Report to .reports/
**Why:** Maximum automation with full visibility. Reports stay in project folder.
EOF
success "feedback_autopilot_workflow.md"

# =============================================================================
# 9. AUTOPILOT PLUGIN
# =============================================================================
step "9/16  Autopilot Plugin"

AUTOPILOT="$LOCAL_PLUGINS/autopilot"
mkdir -p "$AUTOPILOT/.claude-plugin" "$AUTOPILOT/agents" "$AUTOPILOT/commands" "$AUTOPILOT/skills/autopilot-workflow"

cat > "$AUTOPILOT/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "autopilot",
  "description": "Multi-agent development autopilot: understand, plan, parallel implement, browser test, timestamped report",
  "version": "1.0.0",
  "author": {"name": "Hunzla"},
  "keywords": ["automation", "multi-agent", "orchestration", "parallel", "testing", "reporting"]
}
EOF
success "plugin.json"

cat > "$AUTOPILOT/agents/implementation-agent.md" << 'EOF'
---
name: implementation-agent
description: Focused single-task implementation agent for the autopilot workflow
model: sonnet
tools: [Read, Write, Edit, Glob, Grep, Bash]
---
You implement ONE specific task. Stay within scope. Return structured summary with status, files modified, changes made.
EOF
success "implementation-agent"

cat > "$AUTOPILOT/agents/browser-tester.md" << 'EOF'
---
name: browser-tester
description: Tests changes in a REAL headed browser window using Playwright
model: sonnet
tools:
  - Read
  - Bash
  - Glob
  - Grep
  - mcp__plugin_playwright_playwright__browser_navigate
  - mcp__plugin_playwright_playwright__browser_snapshot
  - mcp__plugin_playwright_playwright__browser_click
  - mcp__plugin_playwright_playwright__browser_fill_form
  - mcp__plugin_playwright_playwright__browser_type
  - mcp__plugin_playwright_playwright__browser_take_screenshot
  - mcp__plugin_playwright_playwright__browser_console_messages
  - mcp__plugin_playwright_playwright__browser_hover
  - mcp__plugin_playwright_playwright__browser_wait_for
  - mcp__plugin_playwright_playwright__browser_evaluate
  - mcp__plugin_playwright_playwright__browser_close
---
**ALWAYS use headed mode.** Navigate, interact like a human, take screenshots, check console errors. Return structured test results.
EOF
success "browser-tester"

cat > "$AUTOPILOT/agents/report-generator.md" << 'EOF'
---
name: report-generator
description: Generates timestamped execution reports in .reports/
model: haiku
tools: [Read, Write, Bash, Glob]
---
Compile all autopilot phase data into `.reports/YYYY-MM-DD_HH-MM_<task-slug>.md`. Include all timestamps, files modified, test results.
EOF
success "report-generator"

cat > "$AUTOPILOT/commands/autopilot.md" << 'EOF'
---
name: autopilot
description: Launch autonomous multi-agent development with browser testing and reporting
user_invocable: true
arguments:
  - name: task
    description: The task or feature to implement
    required: true
---
Use the autopilot-workflow skill. 5 phases: Requirement Analysis → Plan (get approval) → Parallel Implementation → Browser Testing (headed) → Report (.reports/). Task: {{ task }}
EOF
success "/autopilot"

cat > "$AUTOPILOT/commands/quick-autopilot.md" << 'EOF'
---
name: quick-autopilot
description: Fast autopilot — skip plan approval, go straight to implementation
user_invocable: true
arguments:
  - name: task
    description: The task or feature to implement
    required: true
---
Same as /autopilot but skip user approval. Go straight from planning to implementation. Still test in browser. Still generate report. Task: {{ task }}
EOF
success "/quick-autopilot"

cat > "$AUTOPILOT/skills/autopilot-workflow/SKILL.md" << 'EOF'
---
name: autopilot-workflow
description: Use when the user wants autonomous multi-agent development — understands requirements, plans, implements with parallel agents, tests in a real browser window, and writes a timestamped report to .reports/
---

# Autopilot Workflow

5-phase autonomous development orchestrator.

## Phase 1: Requirement Analysis
Read project state, identify affected files, list acceptance criteria. Timestamp.

## Phase 2: Implementation Plan
Decompose into independent (parallel) and dependent (sequential) tasks. Get user approval. Timestamp.

## Phase 3: Parallel Implementation
Dispatch one Agent per independent task in the same message. After agents return, check for conflicts, run dependent tasks. Timestamp each dispatch/completion.

## Phase 4: Browser Testing (MANDATORY)
ALWAYS use Playwright headed mode. Navigate, interact as human, take screenshots, verify. If tests fail, go back to Phase 3. Timestamp.

## Phase 5: Execution Report
Write to `.reports/YYYY-MM-DD_HH-MM_<task-slug>.md`. Include all phases with timestamps, task breakdown, agent results, test results, files modified. Update CHANGELOG.md and PROJECT_SCOPE.md.
EOF
success "autopilot-workflow skill"

# =============================================================================
# 10. THIRD-PARTY ORCHESTRATION PLUGINS
# =============================================================================
step "10/16  Orchestration Plugins"

if [ ! -d "$LOCAL_PLUGINS/claude-orchestration/.git" ]; then
  log "Cloning mbruhler/claude-orchestration..."
  git clone --quiet https://github.com/mbruhler/claude-orchestration.git "$LOCAL_PLUGINS/claude-orchestration" 2>&1 | tail -1
  success "claude-orchestration"
else
  log "claude-orchestration exists, pulling..."
  git -C "$LOCAL_PLUGINS/claude-orchestration" pull --quiet 2>/dev/null || true
  success "claude-orchestration (updated)"
fi

if [ ! -d "$LOCAL_PLUGINS/claude-code-workflow-orchestration/.git" ]; then
  log "Cloning barkain/claude-code-workflow-orchestration..."
  git clone --quiet https://github.com/barkain/claude-code-workflow-orchestration.git "$LOCAL_PLUGINS/claude-code-workflow-orchestration" 2>&1 | tail -1
  success "claude-code-workflow-orchestration"
else
  log "claude-code-workflow-orchestration exists, pulling..."
  git -C "$LOCAL_PLUGINS/claude-code-workflow-orchestration" pull --quiet 2>/dev/null || true
  success "claude-code-workflow-orchestration (updated)"
fi

# =============================================================================
# 11. MODEL ROUTER
# =============================================================================
step "11/16  Model Router"

mkdir -p "$ROUTER_DIR"

cat > "$ROUTER_DIR/config.json" << 'EOF'
{
  "port": 3131,
  "anthropicBaseUrl": "https://api.anthropic.com",
  "models": {
    "haiku":  "claude-haiku-4-5-20251001",
    "sonnet": "claude-sonnet-4-6",
    "opus":   "claude-opus-4-6"
  },
  "routing": {
    "haiku": {
      "maxTokens": 120,
      "keywords": ["rename","typo","spelling","what is","what does","format this","add comment","delete this","quick fix","just change"]
    },
    "opus": {
      "minTokens": 600,
      "keywords": ["architect","design system","refactor the entire","refactor all","analyze","plan the","strategy","think carefully","comprehensive","thorough","security audit","performance optimization","implement from scratch","system design","end to end"]
    }
  },
  "logging": true
}
EOF
success "config.json"

cat > "$ROUTER_DIR/package.json" << 'EOF'
{"name":"claude-model-router","version":"1.0.0","main":"router.js","scripts":{"start":"node router.js"}}
EOF

# Router JS (compact)
cat > "$ROUTER_DIR/router.js" << 'ROUTERJS'
#!/usr/bin/env node
const http=require('http'),https=require('https'),{URL}=require('url'),fs=require('fs'),path=require('path');
const C=JSON.parse(fs.readFileSync(path.join(__dirname,'config.json'),'utf8'));
const{port,anthropicBaseUrl,models,routing,logging}=C;
function lastUser(m){if(!Array.isArray(m))return'';for(let i=m.length-1;i>=0;i--){let g=m[i];if(g.role!=='user')continue;if(typeof g.content==='string')return g.content;if(Array.isArray(g.content))return g.content.filter(c=>c.type==='text').map(c=>c.text).join(' ')}return''}
function route(body){let t=lastUser(body.messages||'').toLowerCase(),n=Math.ceil(t.length/4),ok=routing.opus.keywords.some(k=>t.includes(k)),hk=routing.haiku.keywords.some(k=>t.includes(k));if(ok||n>=routing.opus.minTokens)return{model:models.opus,tier:'opus'};if(hk&&n<=routing.haiku.maxTokens)return{model:models.haiku,tier:'haiku'};return{model:models.sonnet,tier:'sonnet'}}
function fwd(h,k){return{'content-type':'application/json','anthropic-version':h['anthropic-version']||'2023-06-01','x-api-key':k,...(h['anthropic-beta']?{'anthropic-beta':h['anthropic-beta']}:{})}}
function proxy(o,b){return new Promise((r,j)=>{let u=new URL(anthropicBaseUrl),p=(u.protocol==='https:'?https:http).request({hostname:u.hostname,port:u.port||443,path:o.path,method:o.method,headers:o.headers},r);p.on('error',j);if(b)p.write(b);p.end()})}
http.createServer(async(req,res)=>{try{let chunks=[];await new Promise(r=>{req.on('data',c=>chunks.push(c));req.on('end',r)});let raw=Buffer.concat(chunks),key=(req.headers['x-api-key']||req.headers['authorization']||'').replace(/^Bearer /,'');if(req.method==='POST'&&req.url==='/v1/messages'){let body=JSON.parse(raw.toString()),{model,tier}=route(body);if(logging)console.log(`[${new Date().toISOString().slice(11,19)}] ${body.model||'?'} → ${tier.toUpperCase()}`);body.model=model;let m=Buffer.from(JSON.stringify(body)),h=fwd(req.headers,key);h['content-length']=m.length;let u=await proxy({path:req.url,method:req.method,headers:h},m);res.writeHead(u.statusCode,u.headers);u.pipe(res)}else{let h=fwd(req.headers,key);if(raw.length)h['content-length']=raw.length;let u=await proxy({path:req.url,method:req.method,headers:h},raw.length?raw:null);res.writeHead(u.statusCode,u.headers);u.pipe(res)}}catch(e){res.writeHead(502,{'content-type':'application/json'});res.end(JSON.stringify({error:{message:e.message}}))}}).listen(port,'127.0.0.1',()=>console.log(`Model Router on http://127.0.0.1:${port}`));
ROUTERJS
chmod +x "$ROUTER_DIR/router.js" 2>/dev/null || true
success "router.js"

# --- Start the model router (platform-specific) ---
if [ "$OS" = "mac" ]; then
  # macOS: use launchd
  NODE_BIN=$(which node 2>/dev/null || echo "/opt/homebrew/bin/node")
  cat > "$ROUTER_DIR/com.claude.model-router-node.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.claude.model-router-node</string>
  <key>ProgramArguments</key><array><string>${NODE_BIN}</string><string>${ROUTER_DIR}/router.js</string></array>
  <key>WorkingDirectory</key><string>${ROUTER_DIR}</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>${ROUTER_DIR}/router.log</string>
  <key>StandardErrorPath</key><string>${ROUTER_DIR}/router.log</string>
  <key>EnvironmentVariables</key><dict><key>PATH</key><string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string></dict>
</dict></plist>
PLIST
  success "launchd plist"

  if lsof -ti:3131 &>/dev/null; then
    log "Stopping existing process on port 3131..."
    kill $(lsof -ti:3131) 2>/dev/null || true
    sleep 1
  fi
  for label in com.claude.model-router-node com.claude.model-router-python; do
    launchctl unload "$LAUNCH_AGENTS/$label.plist" 2>/dev/null || true
    rm -f "$LAUNCH_AGENTS/$label.plist"
  done
  mkdir -p "$LAUNCH_AGENTS"
  cp "$ROUTER_DIR/com.claude.model-router-node.plist" "$LAUNCH_AGENTS/"
  launchctl load "$LAUNCH_AGENTS/com.claude.model-router-node.plist"
  sleep 2
  if lsof -ti:3131 &>/dev/null; then
    success "Router running on http://localhost:3131"
  else
    warn "Router failed to start. Check: $ROUTER_DIR/router.log"
  fi

elif [ "$OS" = "windows" ]; then
  # Windows: use a startup VBS script (runs node in background, no console window)
  NODE_BIN=$(which node 2>/dev/null || echo "node")
  # Convert Git Bash paths to Windows paths for the VBS script
  WIN_ROUTER_DIR=$(cygpath -w "$ROUTER_DIR" 2>/dev/null || echo "$ROUTER_DIR")
  WIN_NODE_BIN=$(cygpath -w "$NODE_BIN" 2>/dev/null || echo "$NODE_BIN")
  WIN_STARTUP="$(cygpath -u "$APPDATA/Microsoft/Windows/Start Menu/Programs/Startup" 2>/dev/null)"

  cat > "$ROUTER_DIR/start-router.vbs" << VBSCRIPT
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """${WIN_NODE_BIN}"" ""${WIN_ROUTER_DIR}\\router.js""", 0, False
VBSCRIPT
  success "startup VBS script"

  # Stop any existing router on port 3131
  if netstat -ano 2>/dev/null | grep -q ":3131 "; then
    log "Stopping existing process on port 3131..."
    PID=$(netstat -ano 2>/dev/null | grep ":3131 " | grep "LISTENING" | awk '{print $5}' | head -1)
    if [ -n "$PID" ] && [ "$PID" != "0" ]; then
      taskkill //PID "$PID" //F 2>/dev/null || true
      sleep 1
    fi
  fi

  # Copy to Windows Startup folder
  if [ -n "$WIN_STARTUP" ] && [ -d "$WIN_STARTUP" ]; then
    cp "$ROUTER_DIR/start-router.vbs" "$WIN_STARTUP/claude-model-router.vbs"
    success "Added to Windows Startup folder"
  else
    warn "Could not find Startup folder — copy start-router.vbs manually"
  fi

  # Start the router now (detached so it survives Git Bash closing)
  WIN_NODE=$(cygpath -w "$(which node 2>/dev/null || echo node)" 2>/dev/null || echo "node")
  WIN_ROUTER_JS=$(cygpath -w "$ROUTER_DIR/router.js" 2>/dev/null || echo "$ROUTER_DIR/router.js")
  cmd //c start //B "" "$WIN_NODE" "$WIN_ROUTER_JS" >NUL 2>&1
  sleep 2
  if netstat -ano 2>/dev/null | grep -q ":3131.*LISTENING"; then
    success "Router running on http://localhost:3131"
  else
    warn "Router failed to start. Run manually: node $ROUTER_DIR/router.js"
  fi
fi

# =============================================================================
# 12. CODEXBAR (macOS only)
# =============================================================================
step "12/16  CodexBar"

if [ "$OS" = "mac" ]; then
  if command -v brew &>/dev/null; then
    if ! brew list --cask codexbar &>/dev/null 2>&1; then
      log "Installing CodexBar..."
      brew tap steipete/tap 2>/dev/null || true
      brew install --cask steipete/tap/codexbar 2>&1 | tail -2
      success "CodexBar installed"
    else
      success "CodexBar already installed"
    fi
    [ -d "/Applications/CodexBar.app" ] && open /Applications/CodexBar.app 2>/dev/null || true
  else
    warn "Homebrew not found — install CodexBar manually: brew install --cask steipete/tap/codexbar"
  fi
else
  warn "CodexBar is macOS-only — skipped on $OS"
fi

# =============================================================================
# 13. PLUGIN MARKETPLACES
# =============================================================================
step "13/16  Plugin Marketplaces"

add_marketplace() {
  local repo="$1"
  local label="$2"
  log "Adding marketplace: $label ($repo)"
  # Use full HTTPS URL to avoid SSH auth issues on machines without SSH keys
  claude plugin marketplace add "https://github.com/${repo}.git" 2>&1 | grep -E "Successfully|already|Failed" | head -1 \
    && success "$label" || fail "$label"
}

add_marketplace "agiprolabs/claude-trading-skills"                     "agiprolabs-claude-trading-skills"
add_marketplace "kivilaid/plugin-marketplace"                          "ando-marketplace"
add_marketplace "jeremylongshore/claude-code-plugins-plus-skills"      "claude-code-plugins-plus"
add_marketplace "secondsky/claude-skills"                              "claude-skills"
add_marketplace "daviguides/claude-marketplace"                        "daviguides"
add_marketplace "daymade/claude-code-skills"                           "daymade-skills"
add_marketplace "ruslan-korneev/python-backend-claude-plugins"         "python-backend-plugins"
add_marketplace "obra/superpowers"                                     "superpowers-dev"

# Wait for marketplaces to sync before installing plugins
log "Waiting for marketplaces to sync..."
sleep 5

# =============================================================================
# 14. PLUGINS (198+ total)
# =============================================================================
step "14/16  Installing Plugins"

install_plugin() {
  local plugin="$1"
  local timeout_sec=30
  local attempt=1
  local max_attempts=2
  while [ $attempt -le $max_attempts ]; do
    # Use timeout to prevent hanging on unavailable marketplaces
    if command -v timeout &>/dev/null; then
      output=$(timeout "$timeout_sec" claude plugin install "$plugin" 2>&1)
    else
      output=$(claude plugin install "$plugin" 2>&1)
    fi
    local exit_code=$?
    if echo "$output" | grep -qi "success"; then
      success "$plugin"
      return
    elif echo "$output" | grep -qi "already installed"; then
      success "$plugin (already installed)"
      return
    fi
    # Exit code 124 = timeout killed the process
    if [ "$exit_code" -eq 124 ]; then
      fail "$plugin — timed out after ${timeout_sec}s"
      return
    fi
    if [ $attempt -lt $max_attempts ]; then
      sleep 2
    fi
    attempt=$((attempt + 1))
  done
  fail "$plugin — $(echo "$output" | grep -v '^$' | tail -1)"
}

echo ""
echo "  Official Anthropic"
install_plugin "agent-sdk-dev@claude-plugins-official"
install_plugin "claude-code-setup@claude-plugins-official"
install_plugin "claude-md-management@claude-plugins-official"
install_plugin "code-review@claude-plugins-official"
install_plugin "code-simplifier@claude-plugins-official"
install_plugin "commit-commands@claude-plugins-official"
install_plugin "context7@claude-plugins-official"
install_plugin "feature-dev@claude-plugins-official"
install_plugin "frontend-design@claude-plugins-official"
install_plugin "github@claude-plugins-official"
install_plugin "hookify@claude-plugins-official"
install_plugin "playground@claude-plugins-official"
install_plugin "playwright@claude-plugins-official"
install_plugin "plugin-dev@claude-plugins-official"
install_plugin "pr-review-toolkit@claude-plugins-official"
install_plugin "pyright-lsp@claude-plugins-official"
install_plugin "ralph-loop@claude-plugins-official"
install_plugin "security-guidance@claude-plugins-official"
install_plugin "serena@claude-plugins-official"
install_plugin "skill-creator@claude-plugins-official"
install_plugin "typescript-lsp@claude-plugins-official"
install_plugin "swift-lsp@claude-plugins-official"
install_plugin "kotlin-lsp@claude-plugins-official"
install_plugin "gopls-lsp@claude-plugins-official"
echo ""
echo "  Superpowers (TDD · Debugging · Agent Patterns)"
install_plugin "superpowers@superpowers-dev"
echo ""
echo "  Skills Marketplace (Frontend · ML · AI)"
install_plugin "aceternity-ui@claude-skills"
install_plugin "claude-agent-sdk@claude-skills"
install_plugin "design-review@claude-skills"
install_plugin "design-system-creation@claude-skills"
install_plugin "frontend-design@claude-skills"
install_plugin "inspira-ui@claude-skills"
install_plugin "interaction-design@claude-skills"
install_plugin "ml-model-training@claude-skills"
install_plugin "ml-pipeline-automation@claude-skills"
install_plugin "mobile-first-design@claude-skills"
install_plugin "nextjs@claude-skills"
install_plugin "react-best-practices@claude-skills"
install_plugin "react-composition-patterns@claude-skills"
install_plugin "react-hook-form-zod@claude-skills"
install_plugin "responsive-web-design@claude-skills"
install_plugin "shadcn-vue@claude-skills"
install_plugin "tailwind-v4-shadcn@claude-skills"
echo ""
echo "  Python Core (ruff · mypy · pytest · SOLID)"
install_plugin "fastapi@python-backend-plugins"
install_plugin "python@python-backend-plugins"
install_plugin "tech-lead@python-backend-plugins"
echo ""
echo "  Python Dev Stack & Autonomous Workflows"
install_plugin "agent-orchestration@ando-marketplace"
install_plugin "backend-development@ando-marketplace"
install_plugin "code-refactoring@ando-marketplace"
install_plugin "code-review-ai@ando-marketplace"
install_plugin "context-management@ando-marketplace"
install_plugin "debugging-toolkit@ando-marketplace"
install_plugin "dependency-management@ando-marketplace"
install_plugin "engineering-workflow-tools@ando-marketplace"
install_plugin "error-debugging@ando-marketplace"
install_plugin "llm-application-dev@ando-marketplace"
install_plugin "machine-learning-ops@ando-marketplace"
install_plugin "python-development@ando-marketplace"
install_plugin "tdd-workflows@ando-marketplace"
install_plugin "unit-testing@ando-marketplace"
echo ""
echo "  Python Philosophy"
install_plugin "arche@daviguides"
install_plugin "shodo@daviguides"
install_plugin "zazen@daviguides"
echo ""
echo "  Trading & Crypto"
install_plugin "trading-skills@agiprolabs-claude-trading-skills"
install_plugin "arbitrage-opportunity-finder@claude-code-plugins-plus"
install_plugin "blockchain-explorer-cli@claude-code-plugins-plus"
install_plugin "cross-chain-bridge-monitor@claude-code-plugins-plus"
install_plugin "crypto-derivatives-tracker@claude-code-plugins-plus"
install_plugin "crypto-news-aggregator@claude-code-plugins-plus"
install_plugin "crypto-portfolio-tracker@claude-code-plugins-plus"
install_plugin "crypto-signal-generator@claude-code-plugins-plus"
install_plugin "crypto-tax-calculator@claude-code-plugins-plus"
install_plugin "defi-yield-optimizer@claude-code-plugins-plus"
install_plugin "dex-aggregator-router@claude-code-plugins-plus"
install_plugin "flash-loan-simulator@claude-code-plugins-plus"
install_plugin "gas-fee-optimizer@claude-code-plugins-plus"
install_plugin "liquidity-pool-analyzer@claude-code-plugins-plus"
install_plugin "market-movers-scanner@claude-code-plugins-plus"
install_plugin "market-price-tracker@claude-code-plugins-plus"
install_plugin "market-sentiment-analyzer@claude-code-plugins-plus"
install_plugin "mempool-analyzer@claude-code-plugins-plus"
install_plugin "nft-rarity-analyzer@claude-code-plugins-plus"
install_plugin "on-chain-analytics@claude-code-plugins-plus"
install_plugin "options-flow-analyzer@claude-code-plugins-plus"
install_plugin "staking-rewards-optimizer@claude-code-plugins-plus"
install_plugin "token-launch-tracker@claude-code-plugins-plus"
install_plugin "trading-strategy-backtester@claude-code-plugins-plus"
install_plugin "wallet-portfolio-tracker@claude-code-plugins-plus"
install_plugin "wallet-security-auditor@claude-code-plugins-plus"
install_plugin "whale-alert-monitor@claude-code-plugins-plus"
install_plugin "openbb-terminal@claude-code-plugins-plus"
echo ""
echo "  Design & UX"
install_plugin "wondelai-design-everyday-things@claude-code-plugins-plus"
install_plugin "wondelai-hooked-ux@claude-code-plugins-plus"
install_plugin "wondelai-ios-hig-design@claude-code-plugins-plus"
install_plugin "wondelai-refactoring-ui@claude-code-plugins-plus"
install_plugin "wondelai-top-design@claude-code-plugins-plus"
install_plugin "wondelai-ux-heuristics@claude-code-plugins-plus"
install_plugin "wondelai-web-typography@claude-code-plugins-plus"
echo ""
echo "  AI/ML & Data Science"
install_plugin "anomaly-detection-system@claude-code-plugins-plus"
install_plugin "time-series-forecaster@claude-code-plugins-plus"
install_plugin "sentiment-analysis-tool@claude-code-plugins-plus"
install_plugin "data-visualization-creator@claude-code-plugins-plus"
install_plugin "nlp-text-analyzer@claude-code-plugins-plus"
install_plugin "regression-analysis-tool@claude-code-plugins-plus"
echo ""
echo "  API & Backend"
install_plugin "rest-api-generator@claude-code-plugins-plus"
install_plugin "graphql-server-builder@claude-code-plugins-plus"
install_plugin "websocket-server-builder@claude-code-plugins-plus"
install_plugin "api-authentication-builder@claude-code-plugins-plus"
install_plugin "api-documentation-generator@claude-code-plugins-plus"
install_plugin "api-sdk-generator@claude-code-plugins-plus"
echo ""
echo "  Testing & Performance"
install_plugin "e2e-test-framework@claude-code-plugins-plus"
install_plugin "mobile-app-tester@claude-code-plugins-plus"
install_plugin "unit-test-generator@claude-code-plugins-plus"
install_plugin "api-test-automation@claude-code-plugins-plus"
install_plugin "test-coverage-analyzer@claude-code-plugins-plus"
install_plugin "bottleneck-detector@claude-code-plugins-plus"
install_plugin "database-query-profiler@claude-code-plugins-plus"
install_plugin "performance-optimization-advisor@claude-code-plugins-plus"
install_plugin "memory-leak-detector@claude-code-plugins-plus"
echo ""
echo "  Daymade Skills"
install_plugin "deep-research@daymade-skills"
install_plugin "financial-data-collector@daymade-skills"
install_plugin "iOS-APP-developer@daymade-skills"
install_plugin "ui-designer@daymade-skills"
install_plugin "competitors-analysis@daymade-skills"

# =============================================================================
# 15. MCP SERVERS (.mcp.json — 40+ servers)
# =============================================================================
step "15/16  MCP Servers (.mcp.json)"

log "Writing ~/.claude/.mcp.json with 40+ MCP servers..."

cat > "$CLAUDE_DIR/.mcp.json" << 'MCPEOF'
{
  "mcpServers": {

    "______________________________CLIENT_HUNTING______________________________": {},

    "apollo-io": {
      "command": "npx",
      "args": ["-y", "@chainscore/apollo-io-mcp"],
      "env": {
        "APOLLO_API_KEY": "YOUR_APOLLO_API_KEY_HERE"
      }
    },

    "hunter-io": {
      "command": "npx",
      "args": ["-y", "hunter-mcp"],
      "env": {
        "HUNTER_API_KEY": "YOUR_HUNTER_API_KEY_HERE"
      }
    },

    "lusha": {
      "command": "npx",
      "args": ["-y", "@lusha-oss/lusha-public-api-mcp"],
      "env": {
        "LUSHA_API_KEY": "YOUR_LUSHA_API_KEY_HERE"
      }
    },

    "explorium-prospecting": {
      "command": "npx",
      "args": ["-y", "@explorium/vibeprospecting-mcp"],
      "env": {
        "EXPLORIUM_API_KEY": "YOUR_EXPLORIUM_API_KEY_HERE"
      }
    },

    "smartlead": {
      "command": "npx",
      "args": ["-y", "@leadmagic/smartlead-mcp-server"],
      "env": {
        "SMARTLEAD_API_KEY": "YOUR_SMARTLEAD_API_KEY_HERE"
      }
    },

    "cold-mailer": {
      "command": "npx",
      "args": ["-y", "cold-mailer-mcp"],
      "env": {
        "EMAIL_USER": "YOUR_EMAIL_HERE",
        "EMAIL_PASS": "YOUR_EMAIL_APP_PASSWORD_HERE"
      }
    },

    "______________________________LINKEDIN______________________________": {},

    "linkedin-scraper": {
      "command": "npx",
      "args": ["-y", "linkedin-mcp-server"],
      "env": {
        "LINKEDIN_EMAIL": "YOUR_LINKEDIN_EMAIL_HERE",
        "LINKEDIN_PASSWORD": "YOUR_LINKEDIN_PASSWORD_HERE"
      }
    },

    "linkedin-content": {
      "command": "npx",
      "args": ["-y", "@southleft/linkedin-mcp"],
      "env": {
        "LINKEDIN_ACCESS_TOKEN": "YOUR_LINKEDIN_ACCESS_TOKEN_HERE"
      }
    },

    "______________________________WEB_SCRAPING______________________________": {},

    "google-maps-scraper": {
      "command": "npx",
      "args": ["-y", "google-maps-scraper-mcp"],
      "env": {}
    },

    "outscraper": {
      "command": "npx",
      "args": ["-y", "outscraper-mcp"],
      "env": {
        "OUTSCRAPER_API_KEY": "YOUR_OUTSCRAPER_API_KEY_HERE"
      }
    },

    "brightdata": {
      "command": "npx",
      "args": ["-y", "@brightdata/mcp"],
      "env": {
        "API_TOKEN": "YOUR_BRIGHTDATA_API_TOKEN_HERE",
        "BROWSER_AUTH": "YOUR_BRIGHTDATA_BROWSER_AUTH_HERE"
      }
    },

    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_KEY": "YOUR_FIRECRAWL_API_KEY_HERE"
      }
    },

    "apify": {
      "command": "npx",
      "args": ["-y", "@apify/mcp-server-rag-web-browser"],
      "env": {
        "APIFY_TOKEN": "YOUR_APIFY_TOKEN_HERE"
      }
    },

    "______________________________SOCIAL_OUTREACH______________________________": {},

    "twitter-x": {
      "command": "npx",
      "args": ["-y", "x-mcp"],
      "env": {
        "X_USERNAME": "YOUR_X_USERNAME_HERE",
        "X_PASSWORD": "YOUR_X_PASSWORD_HERE"
      }
    },

    "whatsapp": {
      "command": "npx",
      "args": ["-y", "whatsapp-mcp"],
      "env": {}
    },

    "telegram": {
      "command": "npx",
      "args": ["-y", "telegram-mcp"],
      "env": {
        "TELEGRAM_API_ID": "YOUR_TELEGRAM_API_ID_HERE",
        "TELEGRAM_API_HASH": "YOUR_TELEGRAM_API_HASH_HERE"
      }
    },

    "discord": {
      "command": "npx",
      "args": ["-y", "discord-mcp"],
      "env": {
        "DISCORD_TOKEN": "YOUR_DISCORD_BOT_TOKEN_HERE"
      }
    },

    "reddit-leads": {
      "command": "npx",
      "args": ["-y", "reddit-mcp-server"],
      "env": {}
    },

    "______________________________FREELANCE_PLATFORMS______________________________": {},

    "upwork": {
      "command": "npx",
      "args": ["-y", "@chinchillaenterprises/mcp-upwork"],
      "env": {
        "UPWORK_API_KEY": "YOUR_UPWORK_API_KEY_HERE",
        "UPWORK_API_SECRET": "YOUR_UPWORK_API_SECRET_HERE"
      }
    },

    "______________________________GHL______________________________": {},

    "gohighlevel-complete": {
      "command": "npx",
      "args": ["-y", "gohighlevel-mcp-complete"],
      "env": {
        "GHL_API_KEY": "YOUR_GHL_API_KEY_HERE",
        "GHL_LOCATION_ID": "YOUR_GHL_LOCATION_ID_HERE"
      }
    },

    "gohighlevel": {
      "command": "npx",
      "args": ["-y", "gohighlevel-mcp"],
      "env": {
        "GHL_API_KEY": "YOUR_GHL_API_KEY_HERE"
      }
    },

    "______________________________SALESFORCE______________________________": {},

    "salesforce-cli": {
      "command": "npx",
      "args": ["-y", "@salesforce/mcp"],
      "env": {}
    },

    "salesforce-api": {
      "command": "npx",
      "args": ["-y", "mcp-server-salesforce"],
      "env": {
        "SF_LOGIN_URL": "https://login.salesforce.com",
        "SF_USERNAME": "YOUR_SF_USERNAME_HERE",
        "SF_PASSWORD": "YOUR_SF_PASSWORD_HERE",
        "SF_SECURITY_TOKEN": "YOUR_SF_SECURITY_TOKEN_HERE"
      }
    },

    "______________________________CRM______________________________": {},

    "hubspot": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-hubspot"],
      "env": {
        "HUBSPOT_ACCESS_TOKEN": "YOUR_HUBSPOT_ACCESS_TOKEN_HERE"
      }
    },

    "pipedrive": {
      "command": "npx",
      "args": ["-y", "mcp-pipedrive"],
      "env": {
        "PIPEDRIVE_API_TOKEN": "YOUR_PIPEDRIVE_API_TOKEN_HERE"
      }
    },

    "zoho-crm": {
      "command": "npx",
      "args": ["-y", "zoho-crm-mcp"],
      "env": {
        "ZOHO_CLIENT_ID": "YOUR_ZOHO_CLIENT_ID_HERE",
        "ZOHO_CLIENT_SECRET": "YOUR_ZOHO_CLIENT_SECRET_HERE",
        "ZOHO_REFRESH_TOKEN": "YOUR_ZOHO_REFRESH_TOKEN_HERE"
      }
    },

    "______________________________AUTOMATION______________________________": {},

    "zapier": {
      "command": "npx",
      "args": ["-y", "zapier-mcp"],
      "env": {
        "ZAPIER_MCP_API_KEY": "YOUR_ZAPIER_MCP_API_KEY_HERE"
      }
    },

    "n8n-workflow-builder": {
      "command": "npx",
      "args": ["-y", "mcp-n8n-workflow-builder"],
      "env": {
        "N8N_BASE_URL": "YOUR_N8N_URL_HERE",
        "N8N_API_KEY": "YOUR_N8N_API_KEY_HERE"
      }
    },

    "n8n": {
      "command": "npx",
      "args": ["-y", "n8n-mcp-server"],
      "env": {
        "N8N_BASE_URL": "YOUR_N8N_URL_HERE",
        "N8N_API_KEY": "YOUR_N8N_API_KEY_HERE"
      }
    },

    "make-com": {
      "command": "npx",
      "args": ["-y", "@integromat/make-mcp-server"],
      "env": {
        "MAKE_API_TOKEN": "YOUR_MAKE_API_TOKEN_HERE"
      }
    },

    "______________________________MARKETING_ADS______________________________": {},

    "google-ads": {
      "command": "npx",
      "args": ["-y", "@googleads/google-ads-mcp"],
      "env": {
        "GOOGLE_ADS_DEVELOPER_TOKEN": "YOUR_GOOGLE_ADS_DEV_TOKEN_HERE",
        "GOOGLE_ADS_CLIENT_ID": "YOUR_GOOGLE_ADS_CLIENT_ID_HERE",
        "GOOGLE_ADS_CLIENT_SECRET": "YOUR_GOOGLE_ADS_CLIENT_SECRET_HERE",
        "GOOGLE_ADS_REFRESH_TOKEN": "YOUR_GOOGLE_ADS_REFRESH_TOKEN_HERE",
        "GOOGLE_ADS_CUSTOMER_ID": "YOUR_GOOGLE_ADS_CUSTOMER_ID_HERE"
      }
    },

    "meta-ads": {
      "command": "npx",
      "args": ["-y", "@pipeboard/meta-ads-mcp"],
      "env": {
        "META_ACCESS_TOKEN": "YOUR_META_ACCESS_TOKEN_HERE",
        "META_AD_ACCOUNT_ID": "YOUR_META_AD_ACCOUNT_ID_HERE"
      }
    },

    "mailchimp": {
      "command": "npx",
      "args": ["-y", "mailchimp-mcp-server"],
      "env": {
        "MAILCHIMP_API_KEY": "YOUR_MAILCHIMP_API_KEY_HERE"
      }
    },

    "sendgrid": {
      "command": "npx",
      "args": ["-y", "sendgrid-mcp"],
      "env": {
        "SENDGRID_API_KEY": "YOUR_SENDGRID_API_KEY_HERE"
      }
    },

    "______________________________COMMUNICATION______________________________": {},

    "twilio": {
      "command": "npx",
      "args": ["-y", "@twilio-labs/mcp"],
      "env": {
        "TWILIO_ACCOUNT_SID": "YOUR_TWILIO_ACCOUNT_SID_HERE",
        "TWILIO_AUTH_TOKEN": "YOUR_TWILIO_AUTH_TOKEN_HERE"
      }
    },

    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "YOUR_SLACK_BOT_TOKEN_HERE"
      }
    },

    "email-unified": {
      "command": "npx",
      "args": ["-y", "email-mcp"],
      "env": {
        "EMAIL_PROVIDER": "gmail",
        "EMAIL_ADDRESS": "YOUR_EMAIL_HERE",
        "EMAIL_PASSWORD": "YOUR_EMAIL_APP_PASSWORD_HERE"
      }
    },

    "______________________________PAYMENTS______________________________": {},

    "stripe": {
      "command": "npx",
      "args": ["-y", "@stripe/mcp"],
      "env": {
        "STRIPE_SECRET_KEY": "YOUR_STRIPE_SECRET_KEY_HERE"
      }
    },

    "______________________________PRODUCTIVITY______________________________": {},

    "notion": {
      "command": "npx",
      "args": ["-y", "@makenotion/notion-mcp-server"],
      "env": {
        "NOTION_API_KEY": "YOUR_NOTION_API_KEY_HERE"
      }
    }
  }
}
MCPEOF

success "~/.claude/.mcp.json written (40+ MCP servers)"

# =============================================================================
# 16. SETTINGS.JSON
# =============================================================================
step "16/16  Writing ~/.claude/settings.json"

# Write settings.json using a Python one-liner to guarantee valid JSON
# This avoids heredoc escaping issues with double quotes in notification commands
if [ "$OS" = "mac" ]; then
  NOTIFY_CMD="osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\" sound name \"Glass\"' 2>/dev/null || true"
  STOP_NOTIFY_CMD="osascript -e 'display notification \"Claude Code has finished\" with title \"Claude Code\" sound name \"Ping\"' 2>/dev/null || true"
  SYNC_CMD="bash $HOME/Documents/GitHub/ClaudeCode/sync-setup.sh 2>&1 | tail -3 || true"
elif [ "$OS" = "windows" ]; then
  NOTIFY_CMD="powershell -Command \"[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [void][System.Windows.Forms.MessageBox]::Show('Claude Code needs your attention','Claude Code')\" 2>/dev/null || true"
  STOP_NOTIFY_CMD="powershell -Command \"[void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [void][System.Windows.Forms.MessageBox]::Show('Claude Code has finished','Claude Code')\" 2>/dev/null || true"
  SYNC_CMD="bash $HOME/Documents/GitHub/ClaudeCode/sync-setup.sh 2>&1 | tail -3 || true"
else
  NOTIFY_CMD="echo Claude Code needs your attention"
  STOP_NOTIFY_CMD="echo Claude Code has finished"
  SYNC_CMD="echo [sync] SessionEnd sync not configured for this OS"
fi

$PYTHON_CMD -c "
import json, os, sys

notify = sys.argv[1]
stop_notify = sys.argv[2]
sync_cmd = sys.argv[3]

settings = {
  'env': {
    'ANTHROPIC_BASE_URL': 'http://localhost:3131'
  },
  'permissions': {
    'allow': ['Bash(*)', 'Read(*)', 'Write(*)', 'Edit(*)', 'Glob(*)', 'Grep(*)', 'Agent(*)'],
    'deny': []
  },
  'hooks': {
    'Notification': [{
      'matcher': '',
      'hooks': [{'type': 'command', 'command': notify}]
    }],
    'Stop': [{
      'matcher': '',
      'hooks': [
        {'type': 'command', 'command': stop_notify},
        {'type': 'command', 'command': \"echo '\\\\n[MAINTENANCE CHECK] Before this session ends:\\\\n  1. Was CHANGELOG.md updated under [Unreleased]?\\\\n  2. Was PROJECT_SCOPE.md updated (In Progress / Current State / Known Issues)?\\\\n  If not — do it now before responding as done.'\"}
      ]
    }],
    'UserPromptSubmit': [{
      'matcher': '',
      'hooks': [{'type': 'command', 'command': \"[ -f PROJECT_SCOPE.md ] && echo '[SESSION START] PROJECT_SCOPE.md found. Read it before starting.' || echo '[SESSION START] No PROJECT_SCOPE.md found. If this is a project, bootstrap required files from ~/.claude/templates/ first.'\"}]
    }],
    'SessionEnd': [{
      'matcher': '',
      'hooks': [{'type': 'command', 'command': sync_cmd}]
    }]
  },
  'enabledPlugins': {
    'commit-commands@claude-plugins-official': True,
    'code-review@claude-plugins-official': True,
    'pr-review-toolkit@claude-plugins-official': True,
    'feature-dev@claude-plugins-official': True,
    'security-guidance@claude-plugins-official': True,
    'frontend-design@claude-plugins-official': True,
    'agent-sdk-dev@claude-plugins-official': True,
    'claude-md-management@claude-plugins-official': True,
    'hookify@claude-plugins-official': True,
    'skill-creator@claude-plugins-official': True,
    'code-simplifier@claude-plugins-official': True,
    'playground@claude-plugins-official': True,
    'claude-code-setup@claude-plugins-official': True,
    'plugin-dev@claude-plugins-official': True,
    'ralph-loop@claude-plugins-official': True,
    'typescript-lsp@claude-plugins-official': True,
    'pyright-lsp@claude-plugins-official': True,
    'github@claude-plugins-official': True,
    'context7@claude-plugins-official': True,
    'playwright@claude-plugins-official': True,
    'serena@claude-plugins-official': True,
    'swift-lsp@claude-plugins-official': True,
    'kotlin-lsp@claude-plugins-official': True,
    'gopls-lsp@claude-plugins-official': True,
    'superpowers@superpowers-dev': True,
    'react-best-practices@claude-skills': True,
    'tailwind-v4-shadcn@claude-skills': True,
    'shadcn-vue@claude-skills': True,
    'nextjs@claude-skills': True,
    'mobile-first-design@claude-skills': True,
    'react-hook-form-zod@claude-skills': True,
    'aceternity-ui@claude-skills': True,
    'responsive-web-design@claude-skills': True,
    'design-system-creation@claude-skills': True,
    'react-composition-patterns@claude-skills': True,
    'design-review@claude-skills': True,
    'inspira-ui@claude-skills': True,
    'interaction-design@claude-skills': True,
    'frontend-design@claude-skills': True,
    'ml-model-training@claude-skills': True,
    'ml-pipeline-automation@claude-skills': True,
    'claude-agent-sdk@claude-skills': True,
    'tech-lead@python-backend-plugins': True,
    'python@python-backend-plugins': True,
    'fastapi@python-backend-plugins': True,
    'python-development@ando-marketplace': True,
    'unit-testing@ando-marketplace': True,
    'agent-orchestration@ando-marketplace': True,
    'llm-application-dev@ando-marketplace': True,
    'error-debugging@ando-marketplace': True,
    'debugging-toolkit@ando-marketplace': True,
    'backend-development@ando-marketplace': True,
    'code-refactoring@ando-marketplace': True,
    'tdd-workflows@ando-marketplace': True,
    'machine-learning-ops@ando-marketplace': True,
    'context-management@ando-marketplace': True,
    'engineering-workflow-tools@ando-marketplace': True,
    'dependency-management@ando-marketplace': True,
    'code-review-ai@ando-marketplace': True,
    'shodo@daviguides': True,
    'zazen@daviguides': True,
    'arche@daviguides': True,
    'trading-skills@agiprolabs-claude-trading-skills': True,
    'arbitrage-opportunity-finder@claude-code-plugins-plus': True,
    'blockchain-explorer-cli@claude-code-plugins-plus': True,
    'cross-chain-bridge-monitor@claude-code-plugins-plus': True,
    'crypto-derivatives-tracker@claude-code-plugins-plus': True,
    'crypto-news-aggregator@claude-code-plugins-plus': True,
    'crypto-portfolio-tracker@claude-code-plugins-plus': True,
    'crypto-signal-generator@claude-code-plugins-plus': True,
    'crypto-tax-calculator@claude-code-plugins-plus': True,
    'defi-yield-optimizer@claude-code-plugins-plus': True,
    'dex-aggregator-router@claude-code-plugins-plus': True,
    'flash-loan-simulator@claude-code-plugins-plus': True,
    'gas-fee-optimizer@claude-code-plugins-plus': True,
    'liquidity-pool-analyzer@claude-code-plugins-plus': True,
    'market-movers-scanner@claude-code-plugins-plus': True,
    'market-price-tracker@claude-code-plugins-plus': True,
    'market-sentiment-analyzer@claude-code-plugins-plus': True,
    'mempool-analyzer@claude-code-plugins-plus': True,
    'nft-rarity-analyzer@claude-code-plugins-plus': True,
    'on-chain-analytics@claude-code-plugins-plus': True,
    'options-flow-analyzer@claude-code-plugins-plus': True,
    'staking-rewards-optimizer@claude-code-plugins-plus': True,
    'token-launch-tracker@claude-code-plugins-plus': True,
    'trading-strategy-backtester@claude-code-plugins-plus': True,
    'wallet-portfolio-tracker@claude-code-plugins-plus': True,
    'wallet-security-auditor@claude-code-plugins-plus': True,
    'whale-alert-monitor@claude-code-plugins-plus': True,
    'openbb-terminal@claude-code-plugins-plus': True,
    'wondelai-design-everyday-things@claude-code-plugins-plus': True,
    'wondelai-hooked-ux@claude-code-plugins-plus': True,
    'wondelai-ios-hig-design@claude-code-plugins-plus': True,
    'wondelai-refactoring-ui@claude-code-plugins-plus': True,
    'wondelai-top-design@claude-code-plugins-plus': True,
    'wondelai-ux-heuristics@claude-code-plugins-plus': True,
    'wondelai-web-typography@claude-code-plugins-plus': True,
    'anomaly-detection-system@claude-code-plugins-plus': True,
    'time-series-forecaster@claude-code-plugins-plus': True,
    'sentiment-analysis-tool@claude-code-plugins-plus': True,
    'data-visualization-creator@claude-code-plugins-plus': True,
    'nlp-text-analyzer@claude-code-plugins-plus': True,
    'regression-analysis-tool@claude-code-plugins-plus': True,
    'rest-api-generator@claude-code-plugins-plus': True,
    'graphql-server-builder@claude-code-plugins-plus': True,
    'websocket-server-builder@claude-code-plugins-plus': True,
    'api-authentication-builder@claude-code-plugins-plus': True,
    'api-documentation-generator@claude-code-plugins-plus': True,
    'api-sdk-generator@claude-code-plugins-plus': True,
    'e2e-test-framework@claude-code-plugins-plus': True,
    'mobile-app-tester@claude-code-plugins-plus': True,
    'unit-test-generator@claude-code-plugins-plus': True,
    'api-test-automation@claude-code-plugins-plus': True,
    'test-coverage-analyzer@claude-code-plugins-plus': True,
    'bottleneck-detector@claude-code-plugins-plus': True,
    'database-query-profiler@claude-code-plugins-plus': True,
    'performance-optimization-advisor@claude-code-plugins-plus': True,
    'memory-leak-detector@claude-code-plugins-plus': True,
    'deep-research@daymade-skills': True,
    'financial-data-collector@daymade-skills': True,
    'iOS-APP-developer@daymade-skills': True,
    'ui-designer@daymade-skills': True,
    'competitors-analysis@daymade-skills': True,
    'autopilot@local': True,
    'orchestration@local': True,
    'workflow-orchestrator@local': True
  },
  'extraKnownMarketplaces': {
    'superpowers-dev': {'source': {'source': 'github', 'repo': 'obra/superpowers'}},
    'claude-skills': {'source': {'source': 'github', 'repo': 'secondsky/claude-skills'}},
    'ando-marketplace': {'source': {'source': 'github', 'repo': 'kivilaid/plugin-marketplace'}},
    'daymade-skills': {'source': {'source': 'github', 'repo': 'daymade/claude-code-skills'}},
    'daviguides': {'source': {'source': 'github', 'repo': 'daviguides/claude-marketplace'}},
    'python-backend-plugins': {'source': {'source': 'github', 'repo': 'ruslan-korneev/python-backend-claude-plugins'}},
    'agiprolabs-claude-trading-skills': {'source': {'source': 'github', 'repo': 'agiprolabs/claude-trading-skills'}},
    'claude-code-plugins-plus': {'source': {'source': 'github', 'repo': 'jeremylongshore/claude-code-plugins-plus-skills'}}
  },
  'voiceEnabled': True,
  'skipDangerousModePermissionPrompt': True
}

out = os.path.expanduser('~/.claude/settings.json')
with open(out, 'w') as f:
    json.dump(settings, f, indent=2)
" "$NOTIFY_CMD" "$STOP_NOTIFY_CMD" "$SYNC_CMD"

success "~/.claude/settings.json written"

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║         Claude Code Setup Complete!                  ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  OS           : ${BOLD}${OS}${RESET}"
echo -e "  Plugins      : 123+ marketplace + 3 local (autopilot, orchestration, workflow)"
echo -e "  Skills       : 3 custom (explain-code · debug-helper · test-writer)"
echo -e "  Marketplaces : 8"
echo -e "  MCP servers  : 40+ (CRM · sales · outreach · automation · scraping · ads · payments)"
echo -e "  Rules        : 4 modules (project-standards · maintenance · workflow · code-quality)"
echo -e "  Templates    : 5 (CLAUDE.md · PROJECT_SCOPE · CHANGELOG · DECISIONS · KNOWN_ISSUES)"
echo -e "  Commands     : /bootstrap · /release · /autopilot · /quick-autopilot"
echo -e "  Model router : Haiku/Sonnet/Opus on http://localhost:3131"
if [ "$OS" = "mac" ]; then
  echo -e "  CodexBar     : Menu bar usage monitor"
fi
echo ""
echo -e "${YELLOW}  Action required:${RESET}"
echo ""
if [ "$OS" = "mac" ]; then
  echo "  1. Add to ~/.zshrc for GitHub MCP:"
  echo "       export GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here"
elif [ "$OS" = "windows" ]; then
  echo "  1. Set environment variable for GitHub MCP:"
  echo "       setx GITHUB_PERSONAL_ACCESS_TOKEN your_token_here"
fi
echo ""
echo "  2. If you are NOT using a local API proxy, remove the"
echo "     \"env\": {\"ANTHROPIC_BASE_URL\": ...} block from ~/.claude/settings.json"
echo ""
echo "  3. Restart Claude Code to activate all plugins."
echo ""
