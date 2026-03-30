#!/usr/bin/env bash
# =============================================================================
# sync-setup.sh — Auto-sync setup.sh with ALL current ~/.claude/ config
#
# Syncs: rules, CLAUDE.md, templates, commands, skills, MCP servers,
#        plugins, settings.json
#
# Runs automatically via SessionEnd hook. Can also be run manually.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export SCRIPT_DIR
SETUP_FILE="$SCRIPT_DIR/setup.sh"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETUP_FILE" ]; then
  echo "[sync-setup] setup.sh not found — skipping"
  exit 0
fi

# Detect python command (python3 on macOS/Linux, python on Windows)
if command -v python3 &>/dev/null; then
  PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
  PYTHON_CMD="python"
else
  echo "[sync-setup] Python not found — skipping"
  exit 0
fi

# ---------------------------------------------------------------------------
# Full sync via Python — handles rules, CLAUDE.md, templates, commands,
# skills, MCP, settings.json, and plugins in one pass
# ---------------------------------------------------------------------------

$PYTHON_CMD << 'PYEOF'
import json, re, os, sys, glob

SCRIPT_DIR = os.environ["SCRIPT_DIR"]
SETUP_FILE = os.path.join(SCRIPT_DIR, "setup.sh")
CLAUDE_DIR = os.path.expanduser("~/.claude")
SETTINGS_FILE = os.path.join(CLAUDE_DIR, "settings.json")

with open(SETUP_FILE) as f:
    content = f.read()

original = content
changes = []

# =========================================================================
# Helper: replace heredoc content between cat line and delimiter
# =========================================================================

def replace_heredoc(content, cat_pattern, delimiter, new_body):
    """Replace the body of a heredoc block in setup.sh."""
    delim_esc = re.escape(delimiter)
    # Match: cat line + newline + body + newline + delimiter
    pattern = rf'({cat_pattern}[^\n]*\n)(.*?)(\n{delim_esc}(?:\n|$))'
    m = re.search(pattern, content, re.DOTALL)
    if not m:
        return content, False
    old_body = m.group(2)
    if old_body.strip() == new_body.strip():
        return content, False
    return content[:m.start(2)] + new_body + content[m.end(2):m.start(3)] + m.group(3) + content[m.end(3):], True

def sync_file(content, source_path, cat_pattern, delimiter):
    """Read a source file and sync its content into the heredoc."""
    if not os.path.isfile(source_path):
        return content
    with open(source_path) as f:
        body = f.read().rstrip('\n')
    new_content, changed = replace_heredoc(content, cat_pattern, delimiter, body)
    if changed:
        changes.append(os.path.basename(source_path))
    return new_content

# =========================================================================
# 1. SYNC RULES
# =========================================================================

print("[sync-setup] Checking rules...")
rules = {
    "project-standards.md": r'cat > "\$CLAUDE_DIR/rules/project-standards\.md" << \'EOF\'',
    "maintenance.md":       r'cat > "\$CLAUDE_DIR/rules/maintenance\.md" << \'EOF\'',
    "workflow.md":          r'cat > "\$CLAUDE_DIR/rules/workflow\.md" << \'EOF\'',
    "code-quality.md":      r'cat > "\$CLAUDE_DIR/rules/code-quality\.md" << \'EOF\'',
    "project-onboarding.md": r'cat > "\$CLAUDE_DIR/rules/project-onboarding\.md" << \'EOF\'',
}
for filename, pattern in rules.items():
    content = sync_file(content, os.path.join(CLAUDE_DIR, "rules", filename), pattern, "EOF")

# =========================================================================
# 2. SYNC CLAUDE.MD (router)
# =========================================================================

print("[sync-setup] Checking CLAUDE.md...")
content = sync_file(content,
    os.path.join(CLAUDE_DIR, "CLAUDE.md"),
    r'cat > "\$CLAUDE_DIR/CLAUDE\.md" << \'EOF\'',
    "EOF")

# =========================================================================
# 3. SYNC TEMPLATES
# =========================================================================

print("[sync-setup] Checking templates...")
templates = ["CLAUDE.md", "PROJECT_SCOPE.md", "CHANGELOG.md", "DECISIONS.md", "KNOWN_ISSUES.md", "TASKLIST.md"]
for tmpl in templates:
    content = sync_file(content,
        os.path.join(CLAUDE_DIR, "templates", tmpl),
        rf'cat > "\$CLAUDE_DIR/templates/{re.escape(tmpl)}" << \'EOF\'',
        "EOF")

# =========================================================================
# 4. SYNC COMMANDS
# =========================================================================

print("[sync-setup] Checking commands...")
for cmd in ["bootstrap", "release"]:
    content = sync_file(content,
        os.path.join(CLAUDE_DIR, "commands", f"{cmd}.md"),
        rf'cat > "\$CLAUDE_DIR/commands/{cmd}\.md" << \'EOF\'',
        "EOF")

# =========================================================================
# 5. SYNC CUSTOM SKILLS
# =========================================================================

print("[sync-setup] Checking custom skills...")
skills_dir = os.path.join(CLAUDE_DIR, "skills")
if os.path.isdir(skills_dir):
    for skill_name in sorted(os.listdir(skills_dir)):
        skill_file = os.path.join(skills_dir, skill_name, "SKILL.md")
        if os.path.isfile(skill_file):
            content = sync_file(content, skill_file,
                rf'cat > ~/\.claude/skills/{re.escape(skill_name)}/SKILL\.md << \'SKILL\'',
                "SKILL")

# =========================================================================
# 6. SYNC MCP SERVERS (.mcp.json)
# =========================================================================

print("[sync-setup] Checking MCP servers...")
mcp_file = os.path.join(CLAUDE_DIR, ".mcp.json")
if os.path.isfile(mcp_file):
    content = sync_file(content, mcp_file,
        r'cat > "\$CLAUDE_DIR/\.mcp\.json" << \'MCPEOF\'',
        "MCPEOF")

# =========================================================================
# 7. SYNC SETTINGS.JSON + PLUGIN COUNTS
# =========================================================================

print("[sync-setup] Checking settings.json & plugins...")
if os.path.isfile(SETTINGS_FILE):
    with open(SETTINGS_FILE) as f:
        settings = json.load(f)

    # Replace settings.json heredoc
    settings_formatted = json.dumps(settings, indent=2)
    pattern = r"cat > ~/\.claude/settings\.json << 'JSON'\n.*?\nJSON"
    m = re.search(pattern, content, re.DOTALL)
    if m:
        new_block = "cat > ~/.claude/settings.json << 'JSON'\n" + settings_formatted + "\nJSON"
        if m.group(0) != new_block:
            content = content[:m.start()] + new_block + content[m.end():]
            changes.append("settings.json")

    # Update plugin counts
    plugins = {k: v for k, v in settings.get("enabledPlugins", {}).items() if v}
    non_local = [k for k in plugins if not k.endswith("@local")]
    plugin_count = len(non_local)
    mkt_count = len(settings.get("extraKnownMarketplaces", {}))

    for old, new in [
        (r'#   5\.\s+\d+\+ plugins across all categories',
         f'#   5.  {plugin_count}+ plugins across all categories'),
        (r'Plugins\s+: \d+\+ marketplace',
         f'Plugins      : {plugin_count}+ marketplace'),
        (r'Marketplaces : \d+',
         f'Marketplaces : {mkt_count}'),
    ]:
        content = re.sub(old, new, content)

# =========================================================================
# WRITE IF CHANGED
# =========================================================================

if content != original:
    with open(SETUP_FILE, "w") as f:
        f.write(content)
    print(f"[sync-setup] Updated: {', '.join(changes) if changes else 'formatting'}")
    sys.exit(42)  # Signal: changes were made
else:
    print("[sync-setup] setup.sh already up to date")
    sys.exit(0)
PYEOF

SYNC_EXIT=$?

# ---------------------------------------------------------------------------
# Commit and push if changes were made (exit 42)
# ---------------------------------------------------------------------------

if [ $SYNC_EXIT -ne 42 ]; then
  exit 0
fi

cd "$SCRIPT_DIR"

if git diff --quiet setup.sh sync-setup.sh 2>/dev/null; then
  echo "[sync-setup] No git changes detected"
  exit 0
fi

echo "[sync-setup] Committing and pushing..."

git add setup.sh sync-setup.sh 2>/dev/null
git commit -m "Auto-sync: update plugins/skills from settings.json" 2>/dev/null || {
  echo "[sync-setup] Nothing new to commit"
  exit 0
}
git push origin main 2>/dev/null \
  && echo "[sync-setup] Pushed to GitHub" \
  || echo "[sync-setup] Push failed — will retry next sync"
