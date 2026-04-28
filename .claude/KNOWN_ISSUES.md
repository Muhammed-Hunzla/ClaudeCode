# Known Issues

Active bugs, limitations, and technical debt for Claude Code Environment Setup.

---

## Active Bugs

| ID | Severity | Description | Workaround | Reported |
|---|---|---|---|---|
| — | — | — | — | — |

_No active bugs as of 2026-04-29._

---

## Limitations

- **No automated test suite**: `setup.sh` is verified manually by running on a clean macOS or Windows install. A regression in setup logic would not be caught until the next install attempt.
- **Windows requires bash**: Users must have Git Bash or WSL — PowerShell-native setup is not provided.
- **Plugin install failures are non-fatal**: By design (so setup completes), but a silently failed plugin won't re-attempt until the user re-runs `setup.sh`.
- **Governance files (`.claude/`) are NOT bootstrapped automatically in target projects** by `setup.sh`. They are only seeded per-project via the onboarding flow defined in `~/.claude/rules/project-onboarding.md`. A future step could add an opt-in project-bootstrap command.
- **`sync-setup.sh` is manual**: It runs on `SessionEnd` via hook, but not on every `~/.claude/` change. If the session doesn't end cleanly, changes may not be synced.

---

## Technical Debt

| Area | Issue | Priority |
|---|---|---|
| `setup.sh` | 2296 lines in a single file — approaching unwieldy | Low |
| `setup.sh` | No verification step at end (no "health check" showing what actually installed) | Medium |
| README.md | Doesn't document the new `governance-check.sh` and `governance-staleness.sh` hooks | Medium |
| setup.sh sync | New governance hook scripts not yet referenced in `setup.sh` | High |
| graphify-check | Hook is bash + `find` based; on very large repos the staleness scan may take 100ms+ — acceptable but worth profiling later | Low |
| tooling-recommender | Keyword detection is heuristic — false positives possible (e.g. `sqlalchemy` matched `alchemy` before fix); coverage of niche stacks (Elixir, Clojure, Haskell, etc.) is incomplete | Low |

---

## Resolved

| ID | Description | Fixed in |
|---|---|---|
| — | Missing `claude-plugins-official` marketplace caused 15 plugins to fail on clean Mac install | Commit 3fbbaa3 (2026-04-17) |
| — | README showed 198 plugins (wrong count) | Commit 2043cd5 (2026-04-17) |
| — | README showed 8 marketplaces after adding 9th | Commit 89d2f1c (2026-04-17) |
| — | Plugin install could hang indefinitely on unreachable marketplace | Commit d4c1208 (60s timeout added) |
| — | Windows compatibility: HTTPS marketplaces, python3 JSON write | Commit cc6fbd2 + 1757146 |
| — | Project-level governance files not being updated (root cause: `.claude/` didn't exist) | Bootstrap 2026-04-21 |
| — | Stop hook only reminded about 2 of 5 governance files | 2026-04-21 (this session) |
| — | No SessionStart enforcement of `/gsd-graphify` — graph could go stale unnoticed across sessions | 2026-04-29 (graphify-check.sh added) |
| — | Installed skills/plugins/MCPs going unused — Claude wrote inline custom code instead of leveraging the toolbox | 2026-04-29 (tooling-recommender.sh added) |

---

_Last updated: 2026-04-29_
