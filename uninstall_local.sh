#!/usr/bin/env bash
# ============================================================
# uninstall_local.sh — u-maker local plugin uninstaller
#
# Removes all u-maker plugin artifacts from Claude Code,
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

PLUGIN_NAME="u-maker"
MARKETPLACE_NAME="${PLUGIN_NAME}-marketplace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[u-maker]${NC} $*"; }
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
# 2. Inventory — count what will be removed
# ============================================================

inventory() {
  local items=0

  # Skill symlinks
  SKILL_COUNT=0
  if [[ -d "$CLAUDE_HOME/skills" ]]; then
    for link in "$CLAUDE_HOME/skills"/${PLUGIN_NAME}__*; do
      [[ -L "$link" ]] && SKILL_COUNT=$((SKILL_COUNT + 1))
    done
  fi
  items=$((items + SKILL_COUNT))

  # Agent symlinks
  AGENT_COUNT=0
  if [[ -d "$CLAUDE_HOME/agents" ]]; then
    for link in "$CLAUDE_HOME/agents"/${PLUGIN_NAME}__*; do
      [[ -L "$link" ]] && AGENT_COUNT=$((AGENT_COUNT + 1))
    done
  fi
  items=$((items + AGENT_COUNT))

  # Marketplace symlink
  HAS_MARKETPLACE=false
  [[ -L "$MARKETPLACES_DIR/$MARKETPLACE_NAME" ]] && HAS_MARKETPLACE=true && items=$((items + 1))

  # Cache
  HAS_CACHE=false
  [[ -d "$CACHE_DIR/$PLUGIN_NAME" ]] && HAS_CACHE=true && items=$((items + 1))

  # JSON entries
  HAS_KNOWN_MP=false
  if [[ -f "$KNOWN_MP" ]]; then
    python3 -c "import json; d=json.load(open('$KNOWN_MP')); exit(0 if '$PLUGIN_NAME' in d else 1)" 2>/dev/null && HAS_KNOWN_MP=true && items=$((items + 1))
  fi

  HAS_INSTALLED_PL=false
  if [[ -f "$INSTALLED_PL" ]]; then
    python3 -c "import json; d=json.load(open('$INSTALLED_PL')); exit(0 if '${PLUGIN_NAME}@${PLUGIN_NAME}' in d.get('plugins',{}) else 1)" 2>/dev/null && HAS_INSTALLED_PL=true && items=$((items + 1))
  fi

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
  echo -e "${BOLD}  u-maker Uninstaller${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  OS:      $OS"
  echo -e "  Claude:  $CLAUDE_HOME"
  echo -e "${BOLD}----------------------------------------${NC}"
  echo ""

  if [[ $TOTAL_ITEMS -eq 0 ]]; then
    ok "No u-maker artifacts found. Nothing to remove."
    echo ""
    exit 0
  fi

  log "Found the following artifacts:"
  echo ""
  [[ $SKILL_COUNT -gt 0 ]]  && echo -e "  ${CYAN}$SKILL_COUNT${NC} skill symlinks   (~/.claude/skills/${PLUGIN_NAME}__*)"
  [[ $AGENT_COUNT -gt 0 ]]  && echo -e "  ${CYAN}$AGENT_COUNT${NC} agent symlinks   (~/.claude/agents/${PLUGIN_NAME}__*)"
  $HAS_MARKETPLACE           && echo -e "  ${CYAN}1${NC} marketplace symlink"
  $HAS_CACHE                 && echo -e "  ${CYAN}1${NC} cache directory     (~/.claude/plugins/cache/$PLUGIN_NAME/)"
  $HAS_KNOWN_MP              && echo -e "  ${CYAN}1${NC} known_marketplaces.json entry"
  $HAS_INSTALLED_PL          && echo -e "  ${CYAN}1${NC} installed_plugins.json entry"
  [[ $CODEX_LINKS -gt 0 ]]  && echo -e "  ${CYAN}$CODEX_LINKS${NC} Codex symlinks"
  [[ $GEMINI_LINKS -gt 0 ]] && echo -e "  ${CYAN}$GEMINI_LINKS${NC} Gemini symlinks"
  echo ""
}

# ============================================================
# 4. Uninstall
# ============================================================

uninstall() {
  echo -e "${BOLD}Removing...${NC}"
  echo ""

  # 1. Skill symlinks
  if [[ $SKILL_COUNT -gt 0 ]]; then
    local count=0
    for link in "$CLAUDE_HOME/skills"/${PLUGIN_NAME}__*; do
      if [[ -L "$link" ]]; then
        rm "$link"
        count=$((count + 1))
      fi
    done
    ok "Removed $count skill symlinks"
  fi

  # 2. Agent symlinks
  if [[ $AGENT_COUNT -gt 0 ]]; then
    local count=0
    for link in "$CLAUDE_HOME/agents"/${PLUGIN_NAME}__*; do
      if [[ -L "$link" ]]; then
        rm "$link"
        count=$((count + 1))
      fi
    done
    ok "Removed $count agent symlinks"
  fi

  # 3. Marketplace symlink
  if $HAS_MARKETPLACE; then
    rm "$MARKETPLACES_DIR/$MARKETPLACE_NAME"
    ok "Marketplace symlink removed"
  fi

  # 4. Cache
  if $HAS_CACHE; then
    rm -rf "$CACHE_DIR/$PLUGIN_NAME"
    ok "Cache directory removed"
  fi

  # 5. known_marketplaces.json
  if $HAS_KNOWN_MP; then
    python3 -c "
import json
with open('$KNOWN_MP', 'r') as f:
    data = json.load(f)
data.pop('$PLUGIN_NAME', None)
with open('$KNOWN_MP', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null
    ok "known_marketplaces.json entry removed"
  fi

  # 6. installed_plugins.json
  if $HAS_INSTALLED_PL; then
    python3 -c "
import json
with open('$INSTALLED_PL', 'r') as f:
    data = json.load(f)
data.get('plugins', {}).pop('${PLUGIN_NAME}@${PLUGIN_NAME}', None)
with open('$INSTALLED_PL', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null
    ok "installed_plugins.json entry removed"
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
  echo -e "${GREEN}${BOLD}  u-maker uninstalled.${NC}"
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
