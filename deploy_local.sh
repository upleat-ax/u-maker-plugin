#!/usr/bin/env bash
# ============================================================
# deploy_local.sh — u-ssot local plugin deployment
#
# Deploys the u-ssot plugin to Claude Code and Codex CLI.
#   - macOS:   ~/.claude/plugins/...
#   - Windows: %USERPROFILE%\.claude\plugins\... (Git Bash / WSL)
#
# Usage:
#   ./deploy_local.sh          # deploy (default)
#   ./deploy_local.sh --clean  # remove deployed artifacts
#   ./deploy_local.sh --check  # verify deployment status
# ============================================================
set -euo pipefail

# ============================================================
# 0. Constants
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_JSON="$SCRIPT_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$SCRIPT_DIR/.claude-plugin/marketplace.json"

PLUGIN_NAME="$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['name'])")"
PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])")"
MARKETPLACE_NAME="${PLUGIN_NAME}-marketplace"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[u-ssot]${NC} $*"; }
ok()   { echo -e "${GREEN}  [OK]${NC} $*"; }
warn() { echo -e "${YELLOW}  [WARN]${NC} $*"; }
err()  { echo -e "${RED}  [ERR]${NC} $*"; }

# ============================================================
# 1. Detect OS & set CLAUDE_HOME / CODEX_HOME
# ============================================================

detect_os() {
  case "$(uname -s)" in
    Darwin)
      OS="macos"
      CLAUDE_HOME="$HOME/.claude"
      CODEX_HOME="$HOME/.codex"
      ;;
    Linux)
      # Could be native Linux or WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="wsl"
        # WSL: use Windows user home for Claude/Codex
        WIN_HOME="$(wslpath "$(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")"
        if [[ -n "$WIN_HOME" && -d "$WIN_HOME/.claude" ]]; then
          CLAUDE_HOME="$WIN_HOME/.claude"
          CODEX_HOME="$WIN_HOME/.codex"
        else
          CLAUDE_HOME="$HOME/.claude"
          CODEX_HOME="$HOME/.codex"
        fi
      else
        OS="linux"
        CLAUDE_HOME="$HOME/.claude"
        CODEX_HOME="$HOME/.codex"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      OS="windows"
      CLAUDE_HOME="$USERPROFILE/.claude"
      CODEX_HOME="$USERPROFILE/.codex"
      ;;
    *)
      OS="unknown"
      CLAUDE_HOME="$HOME/.claude"
      CODEX_HOME="$HOME/.codex"
      ;;
  esac

  PLUGINS_DIR="$CLAUDE_HOME/plugins"
  MARKETPLACES_DIR="$PLUGINS_DIR/marketplaces"
  CACHE_DIR="$PLUGINS_DIR/cache"
  KNOWN_MP="$PLUGINS_DIR/known_marketplaces.json"
  INSTALLED_PL="$PLUGINS_DIR/installed_plugins.json"
}

# ============================================================
# 2. Create symlink (cross-platform)
# ============================================================

make_link() {
  local target="$1"
  local link_path="$2"

  if [[ -L "$link_path" ]]; then
    local current
    current="$(readlink "$link_path")"
    if [[ "$current" == "$target" ]]; then
      ok "Symlink already correct: $(basename "$link_path")"
      return 0
    fi
    rm "$link_path"
  elif [[ -e "$link_path" ]]; then
    warn "Removing existing non-symlink: $link_path"
    rm -rf "$link_path"
  fi

  if [[ "$OS" == "windows" ]]; then
    # Windows Git Bash: use MKLINK /J (junction) for directories
    local win_target win_link
    win_target="$(cygpath -w "$target" 2>/dev/null || echo "$target")"
    win_link="$(cygpath -w "$link_path" 2>/dev/null || echo "$link_path")"
    cmd.exe /C "mklink /J \"$win_link\" \"$win_target\"" >/dev/null 2>&1 || ln -s "$target" "$link_path"
  else
    ln -s "$target" "$link_path"
  fi

  ok "Symlink created: $(basename "$link_path") -> $target"
}

# ============================================================
# 3. Sync to cache (rsync or fallback cp)
# ============================================================

CACHE_EXCLUDES=(
  ".git"
  ".DS_Store"
  "node_modules"
  ".orphaned_at"
)

sync_to_cache() {
  local dest="$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"

  mkdir -p "$dest"

  if command -v rsync &>/dev/null; then
    local excludes=()
    for ex in "${CACHE_EXCLUDES[@]}"; do
      excludes+=(--exclude "$ex")
    done
    rsync -a --delete "${excludes[@]}" "$SCRIPT_DIR/" "$dest/"
  else
    # Fallback: rm + cp
    rm -rf "$dest"
    mkdir -p "$dest"
    # Copy everything, then remove excluded
    cp -R "$SCRIPT_DIR/." "$dest/"
    for ex in "${CACHE_EXCLUDES[@]}"; do
      rm -rf "$dest/$ex"
    done
  fi

  ok "Cache synced: cache/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"
}

# ============================================================
# 4. Update known_marketplaces.json
# ============================================================

update_known_marketplaces() {
  if [[ ! -f "$KNOWN_MP" ]]; then
    echo '{}' > "$KNOWN_MP"
  fi

  python3 -c "
import json, sys, os
from datetime import datetime, timezone

mp_file = '$KNOWN_MP'
name = '$PLUGIN_NAME'
source_path = '$SCRIPT_DIR'
install_loc = '$MARKETPLACES_DIR/$MARKETPLACE_NAME'

with open(mp_file, 'r') as f:
    data = json.load(f)

data[name] = {
    'source': {
        'source': 'directory',
        'path': source_path
    },
    'installLocation': source_path,
    'lastUpdated': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')
}

with open(mp_file, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  ok "known_marketplaces.json updated"
}

# ============================================================
# 5. Update installed_plugins.json
# ============================================================

update_installed_plugins() {
  if [[ ! -f "$INSTALLED_PL" ]]; then
    echo '{"plugins":{}}' > "$INSTALLED_PL"
  fi

  python3 -c "
import json
from datetime import datetime, timezone

ip_file = '$INSTALLED_PL'
plugin_name = '$PLUGIN_NAME'
source_path = '$SCRIPT_DIR'
version = '$PLUGIN_VERSION'

with open(ip_file, 'r') as f:
    data = json.load(f)

if 'plugins' not in data:
    data['plugins'] = {}

key = f'{plugin_name}@{plugin_name}'
now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')

data['plugins'][key] = [{
    'scope': 'user',
    'installPath': source_path,
    'version': version,
    'installedAt': now,
    'lastUpdated': now
}]

with open(ip_file, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
  ok "installed_plugins.json updated"
}

# ============================================================
# 6. Setup Codex symlinks
# ============================================================

setup_codex() {
  if [[ ! -d "$CODEX_HOME" ]]; then
    warn "Codex home not found ($CODEX_HOME), skipping Codex setup"
    return 0
  fi

  log "Setting up Codex symlinks..."

  # plugins -> Claude plugins
  make_link "$PLUGINS_DIR" "$CODEX_HOME/plugins"

  # agents -> Claude agents (if Claude agents dir exists)
  if [[ -d "$CLAUDE_HOME/agents" ]]; then
    make_link "$CLAUDE_HOME/agents" "$CODEX_HOME/agents"
  fi

  # skills -> Claude skills (if Claude skills dir exists)
  if [[ -d "$CLAUDE_HOME/skills" ]]; then
    make_link "$CLAUDE_HOME/skills" "$CODEX_HOME/skills"
  fi

  ok "Codex shares Claude plugin directories"
}

# ============================================================
# 6b. Register skill symlinks in ~/.claude/skills/
# ============================================================

register_skill_symlinks() {
  local skills_root="$CLAUDE_HOME/skills"
  local cache_skills="$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION/skills"

  mkdir -p "$skills_root"

  if [[ ! -d "$cache_skills" ]]; then
    warn "No skills directory in cache, skipping skill symlinks"
    return 0
  fi

  local count=0
  for skill_dir in "$cache_skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local link_name="${PLUGIN_NAME}__${skill_name}"
    local link_path="${skills_root}/${link_name}"

    if [[ -L "$link_path" ]]; then
      local current
      current="$(readlink "$link_path")"
      if [[ "$current" == "$skill_dir" ]]; then
        continue
      fi
      rm "$link_path"
    elif [[ -e "$link_path" ]]; then
      rm -rf "$link_path"
    fi

    ln -s "$skill_dir" "$link_path"
    count=$((count + 1))
  done

  if [[ $count -gt 0 ]]; then
    ok "Registered $count skill symlinks in ~/.claude/skills/"
  else
    ok "All skill symlinks up to date"
  fi
}

# ============================================================
# 7. Deploy
# ============================================================

deploy() {
  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-ssot Local Deploy${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  Plugin:  ${CYAN}$PLUGIN_NAME${NC} v$PLUGIN_VERSION"
  echo -e "  Source:  $SCRIPT_DIR"
  echo -e "  OS:      $OS"
  echo -e "  Claude:  $CLAUDE_HOME"
  echo -e "  Codex:   $CODEX_HOME"
  echo -e "${BOLD}----------------------------------------${NC}"
  echo ""

  # Ensure directories exist
  mkdir -p "$MARKETPLACES_DIR" "$CACHE_DIR"

  # Step 1: Marketplace symlink
  log "1/6  Marketplace symlink"
  make_link "$SCRIPT_DIR" "$MARKETPLACES_DIR/$MARKETPLACE_NAME"

  # Step 2: Cache sync
  log "2/6  Cache sync"
  sync_to_cache

  # Step 3: known_marketplaces.json
  log "3/6  known_marketplaces.json"
  update_known_marketplaces

  # Step 4: installed_plugins.json
  log "4/6  installed_plugins.json"
  update_installed_plugins

  # Step 5: Skill symlinks (for Codex compatibility)
  log "5/6  Skill symlinks"
  register_skill_symlinks

  # Step 6: Codex
  log "6/6  Codex integration"
  setup_codex

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  Deploy complete!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo -e "  Restart Claude Code / Codex to pick up changes."
  echo ""
}

# ============================================================
# 8. Clean (--clean)
# ============================================================

clean() {
  echo ""
  log "Cleaning u-ssot deployment..."

  # Remove marketplace symlink
  if [[ -L "$MARKETPLACES_DIR/$MARKETPLACE_NAME" ]]; then
    rm "$MARKETPLACES_DIR/$MARKETPLACE_NAME"
    ok "Marketplace symlink removed"
  fi

  # Remove cache
  if [[ -d "$CACHE_DIR/$PLUGIN_NAME" ]]; then
    rm -rf "$CACHE_DIR/$PLUGIN_NAME"
    ok "Cache removed"
  fi

  # Remove from known_marketplaces.json
  if [[ -f "$KNOWN_MP" ]]; then
    python3 -c "
import json
with open('$KNOWN_MP', 'r') as f:
    data = json.load(f)
data.pop('$PLUGIN_NAME', None)
with open('$KNOWN_MP', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
    ok "known_marketplaces.json cleaned"
  fi

  # Remove from installed_plugins.json
  if [[ -f "$INSTALLED_PL" ]]; then
    python3 -c "
import json
with open('$INSTALLED_PL', 'r') as f:
    data = json.load(f)
data.get('plugins', {}).pop('${PLUGIN_NAME}@${PLUGIN_NAME}', None)
with open('$INSTALLED_PL', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
    ok "installed_plugins.json cleaned"
  fi

  # Remove skill symlinks
  local skills_root="$CLAUDE_HOME/skills"
  local count=0
  for link in "$skills_root"/${PLUGIN_NAME}__*; do
    if [[ -L "$link" ]]; then
      rm "$link"
      count=$((count + 1))
    fi
  done
  if [[ $count -gt 0 ]]; then
    ok "Removed $count skill symlinks"
  fi

  echo ""
  ok "Clean complete. Restart Claude Code / Codex."
  echo ""
}

# ============================================================
# 9. Check (--check)
# ============================================================

check() {
  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-ssot Deployment Status${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""

  local all_ok=true

  # Marketplace symlink
  if [[ -L "$MARKETPLACES_DIR/$MARKETPLACE_NAME" ]]; then
    local target
    target="$(readlink "$MARKETPLACES_DIR/$MARKETPLACE_NAME")"
    if [[ "$target" == "$SCRIPT_DIR" ]]; then
      ok "Marketplace symlink → $target"
    else
      warn "Marketplace symlink points to $target (expected $SCRIPT_DIR)"
      all_ok=false
    fi
  else
    err "Marketplace symlink missing"
    all_ok=false
  fi

  # Cache
  local cache_path="$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"
  if [[ -d "$cache_path" ]]; then
    local src_count cache_count
    src_count="$(find "$SCRIPT_DIR" -type f -not -path '*/.git/*' | wc -l | tr -d ' ')"
    cache_count="$(find "$cache_path" -type f | wc -l | tr -d ' ')"
    ok "Cache exists ($cache_count files, source has $src_count)"
  else
    err "Cache missing at $cache_path"
    all_ok=false
  fi

  # known_marketplaces.json
  if [[ -f "$KNOWN_MP" ]]; then
    local has_entry
    has_entry="$(python3 -c "import json; d=json.load(open('$KNOWN_MP')); print('yes' if '$PLUGIN_NAME' in d else 'no')")"
    if [[ "$has_entry" == "yes" ]]; then
      ok "known_marketplaces.json has entry"
    else
      err "known_marketplaces.json missing entry"
      all_ok=false
    fi
  else
    err "known_marketplaces.json not found"
    all_ok=false
  fi

  # installed_plugins.json
  if [[ -f "$INSTALLED_PL" ]]; then
    local has_plugin
    has_plugin="$(python3 -c "import json; d=json.load(open('$INSTALLED_PL')); print('yes' if '${PLUGIN_NAME}@${PLUGIN_NAME}' in d.get('plugins',{}) else 'no')")"
    if [[ "$has_plugin" == "yes" ]]; then
      ok "installed_plugins.json has entry"
    else
      err "installed_plugins.json missing entry"
      all_ok=false
    fi
  else
    err "installed_plugins.json not found"
    all_ok=false
  fi

  # Codex
  if [[ -d "$CODEX_HOME" ]]; then
    if [[ -L "$CODEX_HOME/plugins" ]]; then
      local codex_target
      codex_target="$(readlink "$CODEX_HOME/plugins")"
      if [[ "$codex_target" == "$PLUGINS_DIR" ]]; then
        ok "Codex plugins → Claude plugins"
      else
        warn "Codex plugins → $codex_target (expected $PLUGINS_DIR)"
      fi
    else
      warn "Codex plugins symlink missing"
    fi
  else
    warn "Codex not installed (skipped)"
  fi

  echo ""
  if $all_ok; then
    echo -e "  ${GREEN}${BOLD}All checks passed.${NC}"
  else
    echo -e "  ${YELLOW}${BOLD}Issues found. Run ./deploy_local.sh to fix.${NC}"
  fi
  echo ""
}

# ============================================================
# Main
# ============================================================

detect_os

case "${1:-}" in
  --clean)  clean ;;
  --check)  check ;;
  *)        deploy ;;
esac
