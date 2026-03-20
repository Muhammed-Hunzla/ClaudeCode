#!/usr/bin/env bash
# =============================================================================
# sync-setup.sh — Auto-sync setup.sh with current ~/.claude/settings.json
#
# Reads the live settings.json, regenerates plugin sections in setup.sh,
# then commits and pushes to GitHub if there are changes.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETUP_FILE="$SCRIPT_DIR/setup.sh"
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ] || [ ! -f "$SETUP_FILE" ]; then
  echo "[sync-setup] Missing settings.json or setup.sh — skipping"
  exit 0
fi

# ---------------------------------------------------------------------------
# Run the full sync via Python (single script, no temp files)
# ---------------------------------------------------------------------------

set +e  # Python uses exit 42 for "changes made"
python3 << 'PYEOF'
import json, re, os, sys

SETTINGS = os.path.expanduser("~/.claude/settings.json")
SETUP_FILE = os.path.join(os.environ.get("SCRIPT_DIR", "."), "setup.sh")

with open(SETTINGS) as f:
    settings = json.load(f)

with open(SETUP_FILE) as f:
    content = f.read()

plugins = {k: v for k, v in settings.get("enabledPlugins", {}).items() if v}
marketplaces = settings.get("extraKnownMarketplaces", {})

# --- 1. Group plugins by marketplace ---
groups = {}
for pid in sorted(plugins.keys()):
    parts = pid.rsplit("@", 1)
    name = parts[0]
    mkt = parts[1] if len(parts) == 2 else "unknown"
    groups.setdefault(mkt, []).append(pid)

mkt_labels = {
    "claude-plugins-official": "Official Anthropic",
    "superpowers-dev": "Superpowers (TDD · Debugging · Agent Patterns)",
    "claude-skills": "Skills Marketplace (Frontend · ML · AI)",
    "python-backend-plugins": "Python Core (ruff · mypy · pytest · SOLID)",
    "ando-marketplace": "Python Dev Stack & Autonomous Workflows",
    "daviguides": "Python Philosophy",
    "daymade-skills": "Daymade Skills",
    "local": "Local Plugins",
}

# --- 2. Generate install commands ---
install_lines = []
for mkt in ["claude-plugins-official", "superpowers-dev", "claude-skills",
             "python-backend-plugins", "ando-marketplace", "daviguides",
             "daymade-skills"] + sorted(set(groups.keys()) - set(mkt_labels.keys())):
    if mkt not in groups or mkt == "local":
        continue
    label = mkt_labels.get(mkt, mkt)
    install_lines.append(f'echo ""')
    install_lines.append(f'echo "  {label}"')
    for pid in sorted(groups[mkt]):
        install_lines.append(f'install_plugin "{pid}"')

install_block = "\n".join(install_lines)

# --- 3. Generate enabledPlugins JSON ---
enabled_items = []
sorted_keys = sorted(plugins.keys())
for i, k in enumerate(sorted_keys):
    comma = "," if i < len(sorted_keys) - 1 else ""
    enabled_items.append(f'    "{k}": true{comma}')
enabled_json = "\n".join(enabled_items)

# --- 4. Generate extraKnownMarketplaces JSON ---
mkt_items = []
sorted_mkts = sorted(marketplaces.keys())
for i, name in enumerate(sorted_mkts):
    repo = marketplaces[name].get("source", {}).get("repo", "")
    comma = "," if i < len(sorted_mkts) - 1 else ""
    mkt_items.append(f'    "{name}": {{')
    mkt_items.append(f'      "source": {{ "source": "github", "repo": "{repo}" }}')
    mkt_items.append(f'    }}{comma}')
mkt_json = "\n".join(mkt_items)

# --- 5. Generate marketplace add commands ---
mkt_add_lines = []
for name in sorted(marketplaces.keys()):
    repo = marketplaces[name].get("source", {}).get("repo", "")
    if repo:
        padded = f'"{repo}"'.ljust(55)
        mkt_add_lines.append(f'add_marketplace {padded}"{name}"')
mkt_add_block = "\n".join(mkt_add_lines)

# --- 6. Counts ---
non_local = [k for k in plugins if not k.endswith("@local")]
plugin_count = len(non_local)
mkt_count = len(marketplaces)

changed = False

# --- Replace plugin install commands section ---
pattern = r'(# =+\n# 5\. PLUGINS.*?\nstep "14/15  Installing Plugins"\n\ninstall_plugin\(\) \{.*?\}\n)(.*?)((?:\n# =+\n# 6\. SETTINGS))'
m = re.search(pattern, content, re.DOTALL)
if m:
    new_section = m.group(1) + "\n" + install_block + "\n" + m.group(3)
    content = content[:m.start()] + new_section + content[m.end():]
    changed = True

# --- Replace enabledPlugins block ---
pattern = r'("enabledPlugins": \{)\n.*?(\n  \})'
m = re.search(pattern, content, re.DOTALL)
if m:
    # Check this is actually the enabledPlugins and not extraKnownMarketplaces
    new_block = m.group(1) + "\n" + enabled_json + m.group(2)
    content = content[:m.start()] + new_block + content[m.end():]
    changed = True

# --- Replace extraKnownMarketplaces block ---
pattern = r'("extraKnownMarketplaces": \{)\n.*?(\n  \})'
m = re.search(pattern, content, re.DOTALL)
if m:
    new_block = m.group(1) + "\n" + mkt_json + m.group(2)
    content = content[:m.start()] + new_block + content[m.end():]
    changed = True

# --- Replace marketplace add commands ---
pattern = r'(add_marketplace [^\n]+\n)+'
m = re.search(pattern, content)
if m:
    content = content[:m.start()] + mkt_add_block + "\n" + content[m.end():]
    changed = True

# --- Update counts ---
for old, new in [
    (r'#   5\.\s+\d+\+ plugins across all categories',
     f'#   5.  {plugin_count}+ plugins across all categories'),
    (r'# 5\. PLUGINS \(\d+ total\)',
     f'# 5. PLUGINS ({plugin_count} total)'),
    (r'Plugins\s+: \d+\+ marketplace',
     f'Plugins      : {plugin_count}+ marketplace'),
    (r'Marketplaces : \d+',
     f'Marketplaces : {mkt_count}'),
]:
    c2 = re.sub(old, new, content)
    if c2 != content:
        content = c2
        changed = True

if changed:
    with open(SETUP_FILE, "w") as f:
        f.write(content)
    print("[sync-setup] setup.sh updated")
else:
    print("[sync-setup] setup.sh already up to date")

sys.exit(0 if not changed else 42)  # 42 = changes were made
PYEOF

SYNC_EXIT=$?
set -e

# ---------------------------------------------------------------------------
# Commit and push if there were changes (exit code 42)
# ---------------------------------------------------------------------------

cd "$SCRIPT_DIR"

if [ $SYNC_EXIT -eq 42 ]; then
  git add setup.sh sync-setup.sh 2>/dev/null
  git commit -m "Auto-sync: update plugins/skills from settings.json" 2>/dev/null
  git push origin main 2>/dev/null \
    && echo "[sync-setup] Pushed to GitHub" \
    || echo "[sync-setup] Push failed — will retry next sync"
elif [ $SYNC_EXIT -eq 0 ]; then
  echo "[sync-setup] No changes to push"
else
  echo "[sync-setup] Sync failed"
  exit 1
fi
