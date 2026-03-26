# Claude Code Environment Setup

One-script setup that restores a complete Claude Code development environment on any machine. Installs the CLI, 198+ plugins across 8 marketplaces, a model router, custom skills, governance rules, project templates, hooks, and 40+ MCP servers for CRM, sales, outreach, and automation.

## Prerequisites

| Requirement | Why |
|---|---|
| **macOS, Windows (Git Bash), or Linux** | Cross-platform script |
| **Node.js + npm** | Claude Code CLI, TypeScript LSP, npm-based MCP servers |
| **Python 3 + [uv](https://docs.astral.sh/uv/)** | Model router, Python-based MCP servers |
| **[GitHub CLI](https://cli.github.com/) (`gh`)** | Orchestration plugin cloning, GitHub MCP |
| **Anthropic API Key** | Required for Claude Code to function |

> The script auto-installs Node.js, uv, and Homebrew (macOS) / winget (Windows) if missing.

## Quick Start

```bash
git clone https://github.com/Muhammed-Hunzla/ClaudeCode.git
cd ClaudeCode
chmod +x setup.sh
./setup.sh
```

On Windows, open **Git Bash** and run `bash setup.sh`.

## What Gets Installed

The setup runs 16 stages:

### 1. System Dependencies
- **macOS:** Homebrew, Node.js, uv
- **Windows:** winget, Node.js, uv
- **Both:** TypeScript Language Server

### 2. Claude Code CLI
Global install of `@anthropic-ai/claude-code`.

### 3. Custom Skills (3)
| Skill | Trigger |
|---|---|
| `explain-code` | "explain this code", "walk me through" |
| `debug-helper` | Bug reports, error messages, unexpected behavior |
| `test-writer` | "add tests", "write unit tests", "improve coverage" |

### 4. CLAUDE.md & Rules (4 modules)
A user-level config router (`~/.claude/CLAUDE.md`) that links to modular rule files:

| Module | Purpose |
|---|---|
| `project-standards.md` | Required files, bootstrapping, directory organization |
| `maintenance.md` | CHANGELOG + PROJECT_SCOPE update protocol |
| `workflow.md` | Session checklists, Playwright headed mode, feature flow |
| `code-quality.md` | Single source of truth, naming, DRY, security baseline |

### 5. Project Templates (5)
Auto-created for new projects via the `/bootstrap` command:
- `CLAUDE.md` -- Project-level config
- `PROJECT_SCOPE.md` -- Living state document
- `CHANGELOG.md` -- Keep-a-Changelog format
- `DECISIONS.md` -- Architecture Decision Records
- `KNOWN_ISSUES.md` -- Bugs and technical debt

### 6. Custom Commands (2)
| Command | Purpose |
|---|---|
| `/bootstrap` | Create all required project files from templates |
| `/release` | Cut a semver release from CHANGELOG |

### 7. Memory System
Persistent cross-session context stored in `~/.claude/memory/`. Tracks user preferences, feedback, and workflow patterns.

### 8. Autopilot Plugin
A local plugin providing 5-phase autonomous workflow:
1. Analyze requirements
2. Plan implementation
3. Parallel agent execution
4. Browser testing (Playwright, headed mode)
5. Report generation

Commands: `/autopilot`, `/quick-autopilot`

### 9. Orchestration Plugins (2)
Cloned from GitHub:
- [claude-orchestration](https://github.com/mbruhler/claude-orchestration) -- N8N-like workflow orchestration
- [claude-code-workflow-orchestration](https://github.com/barkain/claude-code-workflow-orchestration) -- Hook-based task delegation

### 10. Plugin Marketplaces (8) & 198+ Plugins

**Marketplaces added:**

| Marketplace | Focus |
|---|---|
| `claude-plugins-official` | Core Anthropic plugins |
| `superpowers-dev` | TDD, debugging, agent patterns |
| `claude-skills` | Frontend, ML, AI skills |
| `python-backend-plugins` | Ruff, mypy, pytest, SOLID |
| `ando-marketplace` | Python dev, orchestration, workflows |
| `daviguides` | Python philosophy (shodo, zazen, arche) |
| `agiprolabs-claude-trading-skills` | Crypto/trading strategies |
| `claude-code-plugins-plus` | APIs, testing, performance, DeFi, analytics |

**Plugin categories include:** code review, PR review, feature dev, security, frontend design, playground, LSPs (TypeScript, Pyright, Swift, Kotlin, Go), React, Tailwind, Next.js, ML, trading, crypto, DeFi, design/UX, API generators, testing, performance, and more.

### 11. MCP Servers (40+ in `.mcp.json`)

All MCP servers are configured in `~/.claude/.mcp.json` with placeholder API keys. Replace `YOUR_*_HERE` with real keys to activate.

#### Client Hunting & Lead Generation
| Server | What It Does |
|---|---|
| **Apollo.io** | 27+ tools: people/org search, enrichment, email sequences, deals |
| **Hunter.io** | Find & verify emails for any domain |
| **Lusha** | 100M+ contacts, 60M+ companies -- phone & email lookups |
| **Explorium** | 150M+ companies, 800M+ contacts, natural language prospecting |
| **SmartLead** | 113+ tools for cold email campaigns, deliverability, analytics |
| **Cold-Mailer** | Parse job postings, generate personalized emails, send |

#### LinkedIn
| Server | What It Does |
|---|---|
| **LinkedIn Scraper** | Scrape profiles, companies, jobs via persistent browser |
| **LinkedIn Content** | 83 tools -- analytics, content creation, engagement automation |

#### Web Scraping
| Server | What It Does |
|---|---|
| **Google Maps Scraper** | Scrape local businesses (no auth needed) |
| **Outscraper** | 25+ tools for Google Maps business data extraction |
| **Bright Data** | Enterprise scraping, anti-bot bypass, 195-country proxies |
| **Firecrawl** | Web scraping and search (free tier available) |
| **Apify** | 1000s of ready scrapers for any platform |

#### Social & Messaging Outreach
| Server | What It Does |
|---|---|
| **Twitter/X** | DM prospects, engage, scrape leads |
| **WhatsApp** | Search contacts, send messages (no auth needed) |
| **Telegram** | Group management, messaging, community outreach |
| **Discord** | Monitor communities for opportunities |
| **Reddit** | Find people asking for your services (no auth needed) |

#### Freelance Platforms
| Server | What It Does |
|---|---|
| **Upwork** | 12 tools -- job search, proposals, messages, contracts |

#### GoHighLevel (GHL)
| Server | What It Does |
|---|---|
| **GHL Complete** | 520+ tools across 40 categories -- full CRM + marketing |
| **GHL Standard** | Contacts, opportunities, calendars, workflows |

#### Salesforce
| Server | What It Does |
|---|---|
| **Salesforce CLI** | Official SF CLI integration (no auth needed) |
| **Salesforce API** | SOQL queries, metadata, CRUD operations |

#### CRM
| Server | What It Does |
|---|---|
| **HubSpot** | Contacts, companies, deals, tickets, pipeline |
| **Pipedrive** | Full Pipedrive CRM integration |
| **Zoho CRM** | Comprehensive Zoho with OAuth |

#### Automation Platforms
| Server | What It Does |
|---|---|
| **Zapier** | Connect to 8,000+ apps via natural language |
| **n8n Workflow Builder** | AI-powered workflow creation, 17 tools |
| **n8n** | Manage 1,239 automation nodes |
| **Make.com** | Trigger and interact with Make scenarios |

#### Marketing & Ads
| Server | What It Does |
|---|---|
| **Google Ads** | Campaign management from Claude |
| **Meta Ads** | Facebook/Instagram Ads monitoring & optimization |
| **Mailchimp** | Email marketing and automation |
| **SendGrid** | Contact lists, templates, sends, stats |

#### Communication
| Server | What It Does |
|---|---|
| **Twilio** | SMS, Voice, WhatsApp -- all Twilio APIs |
| **Slack** | Channels, messages, user search |
| **Email (unified)** | Multi-account email (Gmail, Outlook, IMAP) |

#### Payments & Productivity
| Server | What It Does |
|---|---|
| **Stripe** | Customers, products, payments, invoicing |
| **Notion** | Pages, databases, search |

> Additional plugin-managed MCPs: Context7, Playwright, Serena (code intelligence), GitHub, CoinGecko, CCXT.

> **Tip:** Don't enable more than 3-5 MCP servers simultaneously -- too many tool descriptions degrades Claude's reasoning. Swap based on current task.

### 12. Model Router
Intelligent model selector that auto-routes queries to the optimal Claude model:
- **Haiku** -- quick fixes, simple questions
- **Sonnet** -- moderate complexity
- **Opus** -- complex architecture, large features

Runs on `http://localhost:3131`. Supports both Node.js and Python implementations. Auto-starts via launchd (macOS) or VBS (Windows).

### 13. Hooks (4)
| Hook | Trigger | Action |
|---|---|---|
| `Notification` | Claude needs attention | macOS/Windows system notification |
| `Stop` | Session ending | Reminds to update CHANGELOG + PROJECT_SCOPE |
| `UserPromptSubmit` | Every prompt | Checks for PROJECT_SCOPE.md |
| `SessionEnd` | Session closes | Runs `sync-setup.sh` to keep setup.sh in sync |

### 14. CodexBar (macOS only)
Menu bar usage monitor installed via Homebrew.

### 15. MCP Servers Config
Writes `~/.claude/.mcp.json` with 40+ MCP server configurations.

### 16. settings.json
Central config with permissions, hooks, environment variables, and all enabled plugins.

## API Keys & Tokens

### Required

| Key | Where to Get | Where It's Stored |
|---|---|---|
| **Anthropic API Key** | [console.anthropic.com](https://console.anthropic.com/) | Shell environment (`ANTHROPIC_API_KEY`) |

### Recommended

| Key | Where to Get | Where It's Stored | What It Enables |
|---|---|---|---|
| **GitHub PAT** | [github.com/settings/tokens](https://github.com/settings/tokens?type=beta) | `~/.claude/settings.json` -> `env.GITHUB_PERSONAL_ACCESS_TOKEN` | `plugin:github:github` MCP server |

**Creating a GitHub PAT:**
1. Go to [GitHub Settings > Fine-grained tokens](https://github.com/settings/tokens?type=beta)
2. Click **Generate new token**
3. Name: `Claude Code MCP`
4. Expiration: 90 days (or your preference)
5. Repository access: **All repositories**
6. Permissions:
   - Contents: Read & Write
   - Issues: Read & Write
   - Pull requests: Read & Write
   - Metadata: Read (auto-selected)
7. Copy the token and add it to `~/.claude/settings.json`:
```json
{
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_YOUR_TOKEN_HERE"
  }
}
```

### Optional (MCP Server Keys)

All MCP servers in `~/.claude/.mcp.json` use placeholder keys (`YOUR_*_HERE`). Activate each by replacing with real API keys:

| Key | Where to Get | Free Tier? |
|---|---|---|
| **Apollo.io** | [apollo.io](https://www.apollo.io/) | Yes (50 credits/mo) |
| **Hunter.io** | [hunter.io](https://hunter.io/) | Yes (25 searches/mo) |
| **Firecrawl** | [firecrawl.dev](https://www.firecrawl.dev/) | Yes |
| **SmartLead** | [smartlead.ai](https://www.smartlead.ai/) | Trial |
| **GoHighLevel** | [gohighlevel.com](https://www.gohighlevel.com/) | Trial |
| **Zapier** | [zapier.com](https://zapier.com/) | Yes (limited) |
| **HubSpot** | [hubspot.com](https://www.hubspot.com/) | Yes (free CRM) |
| **Stripe** | [stripe.com](https://stripe.com/) | Yes (test mode) |
| **Twilio** | [twilio.com](https://www.twilio.com/) | Yes (trial credits) |

Servers requiring no API key: Google Maps Scraper, Salesforce CLI, WhatsApp, Reddit, and plugin-managed MCPs.

## Post-Install Verification

After setup, launch Claude Code and run:

```
/mcp
```

You should see servers listed as connected. If any show as failed, check:
- The npm package exists (run `npx -y <package-name> --help`)
- Required API keys are set in `~/.claude/.mcp.json`
- For Python-based servers: `uv` and `uvx` are available in your PATH

## Directory Structure

After running `setup.sh`, this is what gets created under `~/.claude/`:

```
~/.claude/
├── CLAUDE.md                          # User-level config router
├── settings.json                      # Central config (hooks, permissions, plugins)
├── .mcp.json                          # 40+ MCP server configurations
├── rules/                             # Governance modules
│   ├── project-standards.md
│   ├── maintenance.md
│   ├── workflow.md
│   └── code-quality.md
├── templates/                         # Project bootstrap templates
│   ├── CLAUDE.md
│   ├── PROJECT_SCOPE.md
│   ├── CHANGELOG.md
│   ├── DECISIONS.md
│   └── KNOWN_ISSUES.md
├── skills/                            # Custom skills
│   ├── explain-code/SKILL.md
│   ├── debug-helper/SKILL.md
│   └── test-writer/SKILL.md
├── commands/                          # Custom slash commands
│   ├── bootstrap.md
│   └── release.md
├── memory/                            # Persistent session memory
│   └── MEMORY.md
├── plugins/local/                     # Local plugins
│   ├── autopilot/
│   ├── claude-orchestration/
│   └── claude-code-workflow-orchestration/
└── model-router/                      # Intelligent model selector
    ├── config.json
    ├── router.js
    ├── router.py
    └── package.json
```

## Auto-Sync

The `sync-setup.sh` script keeps `setup.sh` in sync with your live `~/.claude/settings.json`:

- Runs automatically on every Claude Code session end (via the `SessionEnd` hook)
- Extracts current enabled plugins and marketplaces from settings.json
- Regenerates the plugin sections in setup.sh
- Commits and pushes changes to GitHub if anything changed

This means whenever you install or remove plugins in Claude Code, your setup script is automatically updated for future machine setups.

## Customization

**Add/remove plugins:**
```bash
claude plugin install <name>    # Install via CLI
claude plugin uninstall <name>  # Remove via CLI
```
Changes auto-sync to setup.sh on session end.

**Add MCP servers:**
Edit `~/.claude/.mcp.json` and add new server entries. Restart Claude Code for changes to take effect.

**Modify rules:**
Edit files in `~/.claude/rules/`. Changes apply to all future sessions immediately.

**Add new skills:**
Create a directory under `~/.claude/skills/<skill-name>/` with a `SKILL.md` file containing YAML frontmatter (name, description, allowed-tools) and the skill content.

**Add new commands:**
Create a `.md` file in `~/.claude/commands/` with the command template.

## Troubleshooting

| Issue | Fix |
|---|---|
| MCP server shows "failed" | Check if the npm package exists and API keys are set in `~/.claude/.mcp.json` |
| Model router not starting | Run `node ~/.claude/model-router/router.js` manually to see errors |
| Plugins not loading | Run `claude plugin list` to verify installation |
| Serena opens browser on start | This is normal -- it's the Serena code intelligence dashboard |
| Hooks not firing | Check `~/.claude/settings.json` hook syntax is valid JSON |
| Too many MCP tools slow Claude | Disable unused servers in `.mcp.json` (remove or comment out) |

## License

Personal environment setup. Fork and customize for your own workflow.
