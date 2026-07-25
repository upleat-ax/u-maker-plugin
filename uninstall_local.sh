#!/usr/bin/env bash
# ============================================================
# uninstall_local.sh — umaker local plugin uninstaller
#
# Removes all umaker plugin artifacts (including legacy u-maker
# artifacts from pre-rename installs) from Claude Code,
# Codex CLI, and Gemini CLI.
#
# Usage:
#   ./uninstall_local.sh          # uninstall with confirmation
#   ./uninstall_local.sh --force  # skip confirmation prompt
# ============================================================
set -euo pipefail

# ============================================================
# 0. Constants
# ============================================================

PLUGIN_NAME="umaker"
# Pre-rename plugin name (u-maker). Old-name artifacts are still
# inventoried and removed so upgrades from u-maker installs get cleaned.
OLD_PLUGIN_NAME="u-maker"
PLUGIN_NAMES=("$OLD_PLUGIN_NAME" "$PLUGIN_NAME")

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[umaker]${NC} $*"; }
ok()   { echo -e "${GREEN}  [OK]${NC} $*"; }
warn() { echo -e "${YELLOW}  [WARN]${NC} $*"; }
err()  { echo -e "${RED}  [ERR]${NC} $*"; }

# ============================================================
# 1. Detect OS & set homes
# ============================================================

detect_os() {
  case "$(uname -s)" in
    Darwin)
      OS="macos"
      CLAUDE_HOME="$HOME/.claude"
      CODEX_HOME="$HOME/.codex"
      GEMINI_HOME="$HOME/.gemini"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="wsl"
        WIN_HOME="$(wslpath "$(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")"
        if [[ -n "$WIN_HOME" && -d "$WIN_HOME/.claude" ]]; then
          CLAUDE_HOME="$WIN_HOME/.claude"
          CODEX_HOME="$WIN_HOME/.codex"
          GEMINI_HOME="$WIN_HOME/.gemini"
        else
          CLAUDE_HOME="$HOME/.claude"
          CODEX_HOME="$HOME/.codex"
          GEMINI_HOME="$HOME/.gemini"
        fi
      else
        OS="linux"
        CLAUDE_HOME="$HOME/.claude"
        CODEX_HOME="$HOME/.codex"
        GEMINI_HOME="$HOME/.gemini"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      OS="windows"
      CLAUDE_HOME="$USERPROFILE/.claude"
      CODEX_HOME="$USERPROFILE/.codex"
      GEMINI_HOME="$USERPROFILE/.gemini"
      ;;
    *)
      OS="unknown"
      CLAUDE_HOME="$HOME/.claude"
      CODEX_HOME="$HOME/.codex"
      GEMINI_HOME="$HOME/.gemini"
      ;;
  esac

  PLUGINS_DIR="$CLAUDE_HOME/plugins"
  MARKETPLACES_DIR="$PLUGINS_DIR/marketplaces"
  CACHE_DIR="$PLUGINS_DIR/cache"
  KNOWN_MP="$PLUGINS_DIR/known_marketplaces.json"
  INSTALLED_PL="$PLUGINS_DIR/installed_plugins.json"
}

# ============================================================
# 2. Inventory — count what will be removed (old + new names)
# ============================================================

inventory() {
  local items=0
  local name

  # Skill symlinks
  SKILL_COUNT=0
  if [[ -d "$CLAUDE_HOME/skills" ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      for link in "$CLAUDE_HOME/skills"/${name}__*; do
        [[ -L "$link" ]] && SKILL_COUNT=$((SKILL_COUNT + 1))
      done
    done
  fi
  items=$((items + SKILL_COUNT))

  # Agent symlinks
  AGENT_COUNT=0
  if [[ -d "$CLAUDE_HOME/agents" ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      for link in "$CLAUDE_HOME/agents"/${name}__*; do
        [[ -L "$link" ]] && AGENT_COUNT=$((AGENT_COUNT + 1))
      done
    done
  fi
  items=$((items + AGENT_COUNT))

  # Marketplace symlinks
  MARKETPLACE_COUNT=0
  for name in "${PLUGIN_NAMES[@]}"; do
    [[ -L "$MARKETPLACES_DIR/${name}-marketplace" ]] && MARKETPLACE_COUNT=$((MARKETPLACE_COUNT + 1))
  done
  items=$((items + MARKETPLACE_COUNT))

  # Caches
  CACHE_COUNT=0
  for name in "${PLUGIN_NAMES[@]}"; do
    [[ -d "$CACHE_DIR/$name" ]] && CACHE_COUNT=$((CACHE_COUNT + 1))
  done
  items=$((items + CACHE_COUNT))

  # JSON entries
  KNOWN_MP_COUNT=0
  if [[ -f "$KNOWN_MP" ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      python3 -c "import json; d=json.load(open('$KNOWN_MP')); exit(0 if '$name' in d else 1)" 2>/dev/null && KNOWN_MP_COUNT=$((KNOWN_MP_COUNT + 1))
    done
  fi
  items=$((items + KNOWN_MP_COUNT))

  INSTALLED_PL_COUNT=0
  if [[ -f "$INSTALLED_PL" ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      python3 -c "import json; d=json.load(open('$INSTALLED_PL')); exit(0 if '${name}@${name}' in d.get('plugins',{}) else 1)" 2>/dev/null && INSTALLED_PL_COUNT=$((INSTALLED_PL_COUNT + 1))
    done
  fi
  items=$((items + INSTALLED_PL_COUNT))

  # settings.json enabledPlugins entries
  ENABLED_COUNT=0
  local settings_file="$CLAUDE_HOME/settings.json"
  if [[ -f "$settings_file" ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      python3 -c "import json; d=json.load(open('$settings_file')); exit(0 if '${name}@${name}' in d.get('enabledPlugins',{}) else 1)" 2>/dev/null && ENABLED_COUNT=$((ENABLED_COUNT + 1))
    done
  fi
  items=$((items + ENABLED_COUNT))

  # Codex symlinks
  CODEX_LINKS=0
  if [[ -d "$CODEX_HOME" ]]; then
    for link in plugins agents skills; do
      [[ -L "$CODEX_HOME/$link" ]] && CODEX_LINKS=$((CODEX_LINKS + 1))
    done
  fi
  items=$((items + CODEX_LINKS))

  # Gemini symlinks
  GEMINI_LINKS=0
  if [[ -d "$GEMINI_HOME" ]]; then
    for link in plugins agents skills; do
      [[ -L "$GEMINI_HOME/$link" ]] && GEMINI_LINKS=$((GEMINI_LINKS + 1))
    done
  fi
  items=$((items + GEMINI_LINKS))

  TOTAL_ITEMS=$items
}

# ============================================================
# 3. Print summary before removal
# ============================================================

print_summary() {
  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  umaker Uninstaller${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  OS:      $OS"
  echo -e "  Claude:  $CLAUDE_HOME"
  echo -e "${BOLD}----------------------------------------${NC}"
  echo ""

  if [[ $TOTAL_ITEMS -eq 0 ]]; then
    ok "No umaker (or legacy u-maker) artifacts found. Nothing to remove."
    echo ""
    exit 0
  fi

  log "Found the following artifacts (umaker + legacy u-maker):"
  echo ""
  [[ $SKILL_COUNT -gt 0 ]]        && echo -e "  ${CYAN}$SKILL_COUNT${NC} skill symlinks   (~/.claude/skills/{umaker,u-maker}__*)"
  [[ $AGENT_COUNT -gt 0 ]]        && echo -e "  ${CYAN}$AGENT_COUNT${NC} agent symlinks   (~/.claude/agents/{umaker,u-maker}__*)"
  [[ $MARKETPLACE_COUNT -gt 0 ]]  && echo -e "  ${CYAN}$MARKETPLACE_COUNT${NC} marketplace symlinks"
  [[ $CACHE_COUNT -gt 0 ]]        && echo -e "  ${CYAN}$CACHE_COUNT${NC} cache directories   (~/.claude/plugins/cache/{umaker,u-maker}/)"
  [[ $KNOWN_MP_COUNT -gt 0 ]]     && echo -e "  ${CYAN}$KNOWN_MP_COUNT${NC} known_marketplaces.json entries"
  [[ $INSTALLED_PL_COUNT -gt 0 ]] && echo -e "  ${CYAN}$INSTALLED_PL_COUNT${NC} installed_plugins.json entries"
  [[ $ENABLED_COUNT -gt 0 ]]      && echo -e "  ${CYAN}$ENABLED_COUNT${NC} settings.json enabledPlugins entries"
  [[ $CODEX_LINKS -gt 0 ]]        && echo -e "  ${CYAN}$CODEX_LINKS${NC} Codex symlinks"
  [[ $GEMINI_LINKS -gt 0 ]]       && echo -e "  ${CYAN}$GEMINI_LINKS${NC} Gemini symlinks"
  echo ""
}

# ============================================================
# 4. Uninstall
# ============================================================

uninstall() {
  echo -e "${BOLD}Removing...${NC}"
  echo ""

  local name

  # 1. Skill symlinks
  if [[ $SKILL_COUNT -gt 0 ]]; then
    local count=0
    for name in "${PLUGIN_NAMES[@]}"; do
      for link in "$CLAUDE_HOME/skills"/${name}__*; do
        if [[ -L "$link" ]]; then
          rm "$link"
          count=$((count + 1))
        fi
      done
    done
    ok "Removed $count skill symlinks"
  fi

  # 2. Agent symlinks
  if [[ $AGENT_COUNT -gt 0 ]]; then
    local count=0
    for name in "${PLUGIN_NAMES[@]}"; do
      for link in "$CLAUDE_HOME/agents"/${name}__*; do
        if [[ -L "$link" ]]; then
          rm "$link"
          count=$((count + 1))
        fi
      done
    done
    ok "Removed $count agent symlinks"
  fi

  # 3. Marketplace symlinks
  if [[ $MARKETPLACE_COUNT -gt 0 ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      if [[ -L "$MARKETPLACES_DIR/${name}-marketplace" ]]; then
        rm "$MARKETPLACES_DIR/${name}-marketplace"
        ok "Marketplace symlink removed (${name}-marketplace)"
      fi
    done
  fi

  # 4. Caches
  if [[ $CACHE_COUNT -gt 0 ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      if [[ -d "$CACHE_DIR/$name" ]]; then
        rm -rf "$CACHE_DIR/$name"
        ok "Cache directory removed ($name)"
      fi
    done
  fi

  # 5. known_marketplaces.json
  if [[ $KNOWN_MP_COUNT -gt 0 ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      python3 -c "
import json
with open('$KNOWN_MP', 'r') as f:
    data = json.load(f)
data.pop('$name', None)
with open('$KNOWN_MP', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null
    done
    ok "known_marketplaces.json entries removed"
  fi

  # 6. installed_plugins.json
  if [[ $INSTALLED_PL_COUNT -gt 0 ]]; then
    for name in "${PLUGIN_NAMES[@]}"; do
      python3 -c "
import json
with open('$INSTALLED_PL', 'r') as f:
    data = json.load(f)
data.get('plugins', {}).pop('${name}@${name}', None)
with open('$INSTALLED_PL', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null
    done
    ok "installed_plugins.json entries removed"
  fi

  # 6b. settings.json enabledPlugins (umaker@umaker + legacy u-maker@u-maker)
  if [[ $ENABLED_COUNT -gt 0 ]]; then
    local settings_file="$CLAUDE_HOME/settings.json"
    for name in "${PLUGIN_NAMES[@]}"; do
      python3 -c "
import json
sf = '$settings_file'
key = '${name}@${name}'
with open(sf, 'r') as f:
    data = json.load(f)
ep = data.get('enabledPlugins', {})
if key in ep:
    del ep[key]
    with open(sf, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
" 2>/dev/null
    done
    ok "settings.json enabledPlugins entries removed"
  fi

  # 7. Codex symlinks
  if [[ $CODEX_LINKS -gt 0 ]]; then
    for link in plugins agents skills; do
      [[ -L "$CODEX_HOME/$link" ]] && rm "$CODEX_HOME/$link"
    done
    ok "Codex symlinks removed"
  fi

  # 8. Gemini symlinks
  if [[ $GEMINI_LINKS -gt 0 ]]; then
    for link in plugins agents skills; do
      [[ -L "$GEMINI_HOME/$link" ]] && rm "$GEMINI_HOME/$link"
    done
    ok "Gemini symlinks removed"
  fi

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  umaker uninstalled.${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo -e "  Restart Claude Code / Codex / Gemini CLI to apply."
  echo ""
  echo -e "  ${YELLOW}Note:${NC} .u-maker/ project directories in your repos"
  echo -e "  were NOT removed. Delete them manually if no longer needed."
  echo ""
}

# ============================================================
# Main
# ============================================================

detect_os
inventory

case "${1:-}" in
  --force|-f)
    print_summary
    uninstall
    ;;
  --help|-h)
    echo "Usage:"
    echo "  ./uninstall_local.sh          # uninstall with confirmation"
    echo "  ./uninstall_local.sh --force  # skip confirmation prompt"
    echo "  ./uninstall_local.sh --help   # show this help"
    ;;
  *)
    print_summary
    if [[ $TOTAL_ITEMS -gt 0 ]]; then
      echo -ne "  ${YELLOW}Proceed with uninstall?${NC} [y/N] "
      read -r answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo ""
        uninstall
      else
        echo ""
        log "Cancelled."
        echo ""
      fi
    fi
    ;;
esac
