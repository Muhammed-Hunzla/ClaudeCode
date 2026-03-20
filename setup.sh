#!/usr/bin/env bash
# =============================================================================
# Claude Code Full Setup Script
# Run this on any new machine to restore the complete Claude Code environment.
#
# Usage:
#   chmod +x ~/.claude/setup.sh && ~/.claude/setup.sh
#   chmod +x ~/.claude/setup.sh && ~/.claude/setup.sh python   # Python model router
#
# What this installs:
#   1.  System dependencies (Homebrew, Node.js, uv, TypeScript LSP)
#   2.  Claude Code CLI
#   3.  Custom personal skills (explain-code, debug-helper, test-writer)
#   4.  6 plugin marketplaces
#   5.  59+ plugins across all categories
#   6.  CLAUDE.md (user-level config router)
#   7.  4 rule modules (rules/)
#   8.  5 project templates (templates/)
#   9.  2 custom commands (/bootstrap, /release)
#   10. Memory files (preferences & feedback)
#   11. Autopilot plugin (multi-agent orchestrator)
#   12. 2 third-party orchestration plugins (cloned from GitHub)
#   13. Model router (auto Haiku/Sonnet/Opus routing)
#   14. CodexBar (menu bar usage monitor)
#   15. settings.json (hooks, permissions, plugins, MCP config)
# =============================================================================

set -e

ROUTER_MODE="${1:-node}"
CLAUDE_DIR="$HOME/.claude"
ROUTER_DIR="$CLAUDE_DIR/model-router"
LOCAL_PLUGINS="$CLAUDE_DIR/plugins/local"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"

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

# =============================================================================
# 1. SYSTEM DEPENDENCIES
# =============================================================================
step "1/15  System Dependencies"

# Homebrew (macOS)
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  success "Homebrew installed"
else
  success "Homebrew: $(brew --version | head -1)"
fi

# Node.js — required for context7, playwright MCP servers
if ! command -v node &>/dev/null; then
  log "Installing Node.js..."
  brew install node
  success "Node.js installed"
else
  success "Node.js: $(node --version)"
fi

# uv — required for Serena MCP server
if ! command -v uv &>/dev/null; then
  log "Installing uv..."
  brew install uv
  success "uv installed"
else
  success "uv: $(uv --version)"
fi

# TypeScript Language Server — for typescript-lsp plugin
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
step "2/15  Claude Code CLI"

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
step "3/15  Custom Personal Skills"

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
step "4/15  CLAUDE.md"

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

- **Start of every session**: Read `PROJECT_SCOPE.md` and `CHANGELOG.md` before doing anything.
- **End of every task**: Update `CHANGELOG.md` and `PROJECT_SCOPE.md` before responding as done.
- **New project**: Bootstrap required files from `~/.claude/templates/` if they don't exist.
- **One source of truth**: Never duplicate constants, configs, or state. Define once, reference everywhere.

---

## Templates

Starter templates for required project files: `~/.claude/templates/`
EOF
success "CLAUDE.md"

# =============================================================================
# 5. RULES
# =============================================================================
step "5/15  Rules"

mkdir -p "$CLAUDE_DIR/rules"

cat > "$CLAUDE_DIR/rules/project-standards.md" << 'EOF'
# Project Standards

## Required Files

Every project must contain these files. If any are missing at the start of a session, create them from `~/.claude/templates/` before proceeding.

| File | Purpose |
|---|---|
| `CLAUDE.md` | Project-level router → links back to user rules + project-specific rules |
| `CHANGELOG.md` | Auto-maintained log of all changes, organized by version/date |
| `PROJECT_SCOPE.md` | Living document: current state, in-progress features, next priorities |
| `DECISIONS.md` | Architecture Decision Records — what was decided and why |
| `KNOWN_ISSUES.md` | Active bugs, limitations, and technical debt |

## Project CLAUDE.md Structure

Every project's `CLAUDE.md` must:
1. Import user-level rules (reference `~/.claude/CLAUDE.md`)
2. Define project-specific overrides or additions
3. Specify the tech stack
4. Point to `PROJECT_SCOPE.md` and `CHANGELOG.md`

## Bootstrapping a New Project

When starting work in a directory that lacks required files:
1. Announce: "This project is missing required files. Creating them now."
2. Create all required files from `~/.claude/templates/`
3. Commit them as the first commit if the project is a git repo

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

### 1. Update CHANGELOG.md
Format: `## [Unreleased]` section at the top, entries under: Added, Changed, Fixed, Removed, Security.

### 2. Update PROJECT_SCOPE.md
Update: Current State, In Progress, Known Issues, Next Priorities, Decisions.

## Rules
- Never say a task is done without updating both files
- Keep CHANGELOG entries brief — one line per change
- Keep PROJECT_SCOPE.md accurate, not aspirational
EOF
success "maintenance.md"

cat > "$CLAUDE_DIR/rules/workflow.md" << 'EOF'
# Development Workflow

## Session Start Checklist
1. Read `PROJECT_SCOPE.md` — understand current state
2. Read `CHANGELOG.md` (Unreleased section) — understand recent changes
3. If either is missing, create from `~/.claude/templates/`

## Verifying Changes with Playwright
**MANDATORY**: Always use Playwright in **headed mode** (real visible browser window) — never headless.
- Launch with `headless: false` so the actual browser window opens
- Interact with the page as a human would — click, scroll, fill forms
- Only confirm a task is complete after visually verifying it in the opened window

## After Completing a Task
1. Update `CHANGELOG.md` under `## [Unreleased]`
2. Update `PROJECT_SCOPE.md`
3. Only then: declare the task done

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
Define once, reference everywhere. Constants, types, env vars, API endpoints — one canonical location each.

## Minimal Changes
Only change what the task requires. No unrelated refactors, no extra docstrings, no over-engineering.

## Security Baseline
Never commit secrets. Validate external inputs. No SQL/command injection or XSS.

## Naming
Names must be accurate. Booleans: `isX`, `hasX`, `canX`. No stale names.
EOF
success "code-quality.md"

# =============================================================================
# 6. TEMPLATES
# =============================================================================
step "6/15  Templates"

mkdir -p "$CLAUDE_DIR/templates"

cat > "$CLAUDE_DIR/templates/CLAUDE.md" << 'EOF'
# [PROJECT NAME] — Claude Configuration

## Rules
This project follows user-level rules at `~/.claude/CLAUDE.md`.

## Project Context
**Stack**: [e.g., Next.js, TypeScript, PostgreSQL]
**Purpose**: [One sentence]

## Required Files
- `PROJECT_SCOPE.md` · `CHANGELOG.md` · `DECISIONS.md` · `KNOWN_ISSUES.md`
EOF
success "CLAUDE.md template"

cat > "$CLAUDE_DIR/templates/PROJECT_SCOPE.md" << 'EOF'
# Project Scope
> Living document. Updated after every task.

## Current State
- [ ] Initial setup

## In Progress
_Nothing in progress._

## Known Issues
_None. See KNOWN_ISSUES.md._

## Next Priorities
1. _TBD_
EOF
success "PROJECT_SCOPE.md template"

cat > "$CLAUDE_DIR/templates/CHANGELOG.md" << 'EOF'
# Changelog
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Initial project setup
EOF
success "CHANGELOG.md template"

cat > "$CLAUDE_DIR/templates/DECISIONS.md" << 'EOF'
# Architecture Decisions
Records of significant technical decisions. Prevents revisiting settled decisions.

## Decision Log
<!-- Add decisions here, newest first -->
EOF
success "DECISIONS.md template"

cat > "$CLAUDE_DIR/templates/KNOWN_ISSUES.md" << 'EOF'
# Known Issues
Active bugs, limitations, and technical debt.

## Active Bugs
| ID | Severity | Description | Workaround | Reported |
|---|---|---|---|---|

## Technical Debt
| Area | Issue | Priority |
|---|---|---|
EOF
success "KNOWN_ISSUES.md template"

# =============================================================================
# 7. COMMANDS
# =============================================================================
step "7/15  Commands"

mkdir -p "$CLAUDE_DIR/commands"

cat > "$CLAUDE_DIR/commands/bootstrap.md" << 'EOF'
Bootstrap all required project files. Read the directory to infer project name, stack, and purpose. Create missing files from ~/.claude/templates/. Do not ask for confirmation.
EOF
success "/bootstrap"

cat > "$CLAUDE_DIR/commands/release.md" << 'EOF'
Cut a release. Read CHANGELOG.md [Unreleased], determine next version (semver), rename section to dated version, create fresh [Unreleased]. Optionally commit and tag.
EOF
success "/release"

# =============================================================================
# 8. MEMORY
# =============================================================================
step "8/15  Memory"

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
step "9/15  Autopilot Plugin"

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
step "10/15  Orchestration Plugins"

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
step "11/15  Model Router"

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
chmod +x "$ROUTER_DIR/router.js"
success "router.js"

# Launchd plist
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

# Start router
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

# =============================================================================
# 12. CODEXBAR
# =============================================================================
step "12/15  CodexBar"

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

# =============================================================================
# 13. PLUGIN MARKETPLACES
# =============================================================================
step "13/15  Plugin Marketplaces"

add_marketplace() {
  local repo="$1"
  local label="$2"
  log "Adding marketplace: $label ($repo)"
  claude plugin marketplace add "$repo" 2>&1 | grep -E "Successfully|already|Failed" | head -1 \
    && success "$label" || fail "$label"
}

add_marketplace "kivilaid/plugin-marketplace"                          "ando-marketplace"
add_marketplace "secondsky/claude-skills"                              "claude-skills"
add_marketplace "daviguides/claude-marketplace"                        "daviguides"
add_marketplace "daymade/claude-code-skills"                           "daymade-skills"
add_marketplace "ruslan-korneev/python-backend-claude-plugins"         "python-backend-plugins"
add_marketplace "obra/superpowers"                                     "superpowers-dev"

# =============================================================================
# 5. PLUGINS (59 total)
# =============================================================================
step "14/15  Installing Plugins"

install_plugin() {
  local plugin="$1"
  output=$(claude plugin install "$plugin" 2>&1)
  if echo "$output" | grep -q "Successfully installed"; then
    success "$plugin"
  elif echo "$output" | grep -q "already installed"; then
    success "$plugin (already installed)"
  else
    fail "$plugin — $(echo "$output" | grep -v '^$' | tail -1)"
  fi
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

# =============================================================================
# 6. SETTINGS.JSON
# =============================================================================
step "15/15  Writing ~/.claude/settings.json"

# NOTE: ANTHROPIC_BASE_URL points to a local proxy (http://localhost:3131).
# If you are NOT using a local proxy/router, remove the "env" block below,
# or change the URL to https://api.anthropic.com
#
# GitHub MCP requires: export GITHUB_PERSONAL_ACCESS_TOKEN=your_token
# Add that line to your ~/.zshrc or ~/.bash_profile.

cat > ~/.claude/settings.json << 'JSON'
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:3131"
  },
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "Agent(*)"
    ],
    "deny": []
  },
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\" sound name \"Glass\"' 2>/dev/null || true"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code has finished\" with title \"Claude Code\" sound name \"Ping\"' 2>/dev/null || true"
          },
          {
            "type": "command",
            "command": "echo '\n[MAINTENANCE CHECK] Before this session ends:\n  1. Was CHANGELOG.md updated under [Unreleased]?\n  2. Was PROJECT_SCOPE.md updated (In Progress / Current State / Known Issues)?\n  If not — do it now before responding as done.'"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f PROJECT_SCOPE.md ] && echo '[SESSION START] PROJECT_SCOPE.md found. Read it before starting.' || echo '[SESSION START] No PROJECT_SCOPE.md found. If this is a project, bootstrap required files from ~/.claude/templates/ first.'"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "aceternity-ui@claude-skills": true,
    "agent-orchestration@ando-marketplace": true,
    "agent-sdk-dev@claude-plugins-official": true,
    "arche@daviguides": true,
    "autopilot@local": true,
    "backend-development@ando-marketplace": true,
    "claude-agent-sdk@claude-skills": true,
    "claude-code-setup@claude-plugins-official": true,
    "claude-md-management@claude-plugins-official": true,
    "code-refactoring@ando-marketplace": true,
    "code-review-ai@ando-marketplace": true,
    "code-review@claude-plugins-official": true,
    "code-simplifier@claude-plugins-official": true,
    "commit-commands@claude-plugins-official": true,
    "context-management@ando-marketplace": true,
    "context7@claude-plugins-official": true,
    "debugging-toolkit@ando-marketplace": true,
    "dependency-management@ando-marketplace": true,
    "design-review@claude-skills": true,
    "design-system-creation@claude-skills": true,
    "engineering-workflow-tools@ando-marketplace": true,
    "error-debugging@ando-marketplace": true,
    "fastapi@python-backend-plugins": true,
    "feature-dev@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "frontend-design@claude-skills": true,
    "github@claude-plugins-official": true,
    "hookify@claude-plugins-official": true,
    "inspira-ui@claude-skills": true,
    "interaction-design@claude-skills": true,
    "llm-application-dev@ando-marketplace": true,
    "machine-learning-ops@ando-marketplace": true,
    "ml-model-training@claude-skills": true,
    "ml-pipeline-automation@claude-skills": true,
    "mobile-first-design@claude-skills": true,
    "nextjs@claude-skills": true,
    "orchestration@local": true,
    "playground@claude-plugins-official": true,
    "playwright@claude-plugins-official": true,
    "plugin-dev@claude-plugins-official": true,
    "pr-review-toolkit@claude-plugins-official": true,
    "pyright-lsp@claude-plugins-official": true,
    "python-development@ando-marketplace": true,
    "python@python-backend-plugins": true,
    "ralph-loop@claude-plugins-official": true,
    "react-best-practices@claude-skills": true,
    "react-composition-patterns@claude-skills": true,
    "react-hook-form-zod@claude-skills": true,
    "responsive-web-design@claude-skills": true,
    "security-guidance@claude-plugins-official": true,
    "serena@claude-plugins-official": true,
    "shadcn-vue@claude-skills": true,
    "shodo@daviguides": true,
    "skill-creator@claude-plugins-official": true,
    "superpowers@superpowers-dev": true,
    "tailwind-v4-shadcn@claude-skills": true,
    "tdd-workflows@ando-marketplace": true,
    "tech-lead@python-backend-plugins": true,
    "typescript-lsp@claude-plugins-official": true,
    "unit-testing@ando-marketplace": true,
    "workflow-orchestrator@local": true,
    "zazen@daviguides": true
  },
  "extraKnownMarketplaces": {
    "ando-marketplace": {
      "source": { "source": "github", "repo": "kivilaid/plugin-marketplace" }
    },
    "claude-skills": {
      "source": { "source": "github", "repo": "secondsky/claude-skills" }
    },
    "daviguides": {
      "source": { "source": "github", "repo": "daviguides/claude-marketplace" }
    },
    "daymade-skills": {
      "source": { "source": "github", "repo": "daymade/claude-code-skills" }
    },
    "python-backend-plugins": {
      "source": { "source": "github", "repo": "ruslan-korneev/python-backend-claude-plugins" }
    },
    "superpowers-dev": {
      "source": { "source": "github", "repo": "obra/superpowers" }
    }
  },
  "voiceEnabled": true,
  "skipDangerousModePermissionPrompt": true,
  "model": "sonnet"
}
JSON

success "~/.claude/settings.json written"

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║         Claude Code Setup Complete!                  ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Plugins      : 59+ marketplace + 3 local (autopilot, orchestration, workflow)"
echo -e "  Skills       : 3 custom (explain-code · debug-helper · test-writer)"
echo -e "  Marketplaces : 6"
echo -e "  MCP servers  : context7 · playwright · serena · github"
echo -e "  Rules        : 4 modules (project-standards · maintenance · workflow · code-quality)"
echo -e "  Templates    : 5 (CLAUDE.md · PROJECT_SCOPE · CHANGELOG · DECISIONS · KNOWN_ISSUES)"
echo -e "  Commands     : /bootstrap · /release · /autopilot · /quick-autopilot"
echo -e "  Model router : Haiku/Sonnet/Opus on http://localhost:3131"
echo -e "  CodexBar     : Menu bar usage monitor"
echo ""
echo -e "${YELLOW}  Action required:${RESET}"
echo ""
echo "  1. Add to ~/.zshrc for GitHub MCP:"
echo "       export GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here"
echo ""
echo "  2. If you are NOT using a local API proxy, remove the"
echo "     \"env\": {\"ANTHROPIC_BASE_URL\": ...} block from ~/.claude/settings.json"
echo ""
echo "  3. Restart Claude Code to activate all plugins."
echo ""
