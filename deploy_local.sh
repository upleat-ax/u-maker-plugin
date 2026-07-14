#!/usr/bin/env bash
# ============================================================
# deploy_local.sh — u-maker local plugin deployment
#
# Deploys the u-maker plugin to Claude Code, Codex CLI, and Gemini CLI.
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
CODEX_PLUGIN_JSON="$SCRIPT_DIR/.codex-plugin/plugin.json"

PLUGIN_NAME="$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['name'])")"
PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])")"
MARKETPLACE_NAME="${PLUGIN_NAME}-marketplace"
CODEX_MARKETPLACE_NAME="$(python3 -c "import json; print(json.load(open('$MARKETPLACE_JSON'))['name'])")"

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
# 1. Detect OS & set CLAUDE_HOME / CODEX_HOME
# ============================================================

detect_os() {
  case "$(uname -s)" in
    Darwin)
      OS="macos"
      CLAUDE_HOME="$HOME/.claude"
      CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
      GEMINI_HOME="$HOME/.gemini"
      ;;
    Linux)
      # Could be native Linux or WSL
      if grep -qi microsoft /proc/version 2>/dev/null; then
        OS="wsl"
        # WSL: use Windows user home for Claude/Codex/Gemini
        WIN_HOME="$(wslpath "$(cmd.exe /C 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null || echo "")"
        if [[ -n "$WIN_HOME" && -d "$WIN_HOME/.claude" ]]; then
          CLAUDE_HOME="$WIN_HOME/.claude"
          CODEX_HOME="${CODEX_HOME:-$WIN_HOME/.codex}"
          GEMINI_HOME="$WIN_HOME/.gemini"
        else
          CLAUDE_HOME="$HOME/.claude"
          CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
          GEMINI_HOME="$HOME/.gemini"
        fi
      else
        OS="linux"
        CLAUDE_HOME="$HOME/.claude"
        CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
        GEMINI_HOME="$HOME/.gemini"
      fi
      ;;
    MINGW*|MSYS*|CYGWIN*)
      OS="windows"
      CLAUDE_HOME="$USERPROFILE/.claude"
      CODEX_HOME="${CODEX_HOME:-$USERPROFILE/.codex}"
      GEMINI_HOME="$USERPROFILE/.gemini"
      ;;
    *)
      OS="unknown"
      CLAUDE_HOME="$HOME/.claude"
      CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
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
    rsync -a --delete --delete-excluded "${excludes[@]}" "$SCRIPT_DIR/" "$dest/"
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
cache_path = '$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION'
install_loc = '$MARKETPLACES_DIR/$MARKETPLACE_NAME'

with open(mp_file, 'r') as f:
    data = json.load(f)

data[name] = {
    'source': {
        'source': 'directory',
        'path': cache_path
    },
    'installLocation': cache_path,
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
cache_path = '$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION'
version = '$PLUGIN_VERSION'

with open(ip_file, 'r') as f:
    data = json.load(f)

if 'plugins' not in data:
    data['plugins'] = {}

key = f'{plugin_name}@{plugin_name}'
now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S.000Z')

data['plugins'][key] = [{
    'scope': 'user',
    'installPath': cache_path,
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
# 5b. Update enabledPlugins in ~/.claude/settings.json
# ============================================================

update_enabled_plugins() {
  local settings_file="$CLAUDE_HOME/settings.json"

  if [[ ! -f "$settings_file" ]]; then
    warn "settings.json not found at $settings_file, skipping enabledPlugins toggle"
    return 0
  fi

  python3 -c "
import json
sf = '$settings_file'
key = '${PLUGIN_NAME}@${PLUGIN_NAME}'

with open(sf, 'r') as f:
    data = json.load(f)

ep = data.setdefault('enabledPlugins', {})
if ep.get(key) is True:
    print('already-on')
else:
    ep[key] = True
    with open(sf, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    print('toggled-on')
" >/dev/null
  ok "settings.json enabledPlugins → on ($PLUGIN_NAME@$PLUGIN_NAME)"
}

# ============================================================
# 6. Install the plugin with the Codex CLI
# ============================================================

setup_codex() {
  if ! command -v codex &>/dev/null; then
    warn "Codex CLI not found, skipping Codex setup"
    return 0
  fi

  if ! codex plugin --help &>/dev/null; then
    warn "This Codex CLI does not support plugins; update Codex and retry"
    return 0
  fi

  if [[ ! -f "$CODEX_PLUGIN_JSON" ]]; then
    err "Missing Codex manifest: $CODEX_PLUGIN_JSON"
    return 1
  fi

  # Older versions of this script shared Claude's entire plugin directory.
  # Codex now manages its own plugin cache and installation state.
  if [[ -L "$CODEX_HOME/plugins" && "$(readlink "$CODEX_HOME/plugins")" == "$PLUGINS_DIR" ]]; then
    rm "$CODEX_HOME/plugins"
    mkdir -p "$CODEX_HOME/plugins"
    ok "Replaced legacy Codex → Claude plugins symlink with a Codex directory"
  else
    mkdir -p "$CODEX_HOME/plugins"
  fi

  # Remove links created by the short-lived direct-skill workaround. The
  # installed plugin exposes these skills under the `u-maker:*` namespace.
  if [[ -d "$CODEX_HOME/skills" && ! -L "$CODEX_HOME/skills" ]]; then
    local legacy_skill_count=0
    local legacy_skill_link
    for legacy_skill_link in "$CODEX_HOME/skills"/${PLUGIN_NAME}-*; do
      [[ -L "$legacy_skill_link" ]] || continue
      rm "$legacy_skill_link"
      legacy_skill_count=$((legacy_skill_count + 1))
    done
    if [[ $legacy_skill_count -gt 0 ]]; then
      ok "Removed $legacy_skill_count legacy direct Codex skill links"
    fi
  fi

  log "Registering the local Codex marketplace..."
  local marketplace_root=""
  marketplace_root="$(codex plugin marketplace list 2>/dev/null \
    | awk -v name="$CODEX_MARKETPLACE_NAME" '$1 == name {$1=""; sub(/^[[:space:]]+/, ""); print; exit}')"

  if [[ -z "$marketplace_root" ]]; then
    codex plugin marketplace add "$SCRIPT_DIR" >/dev/null
    ok "Codex marketplace registered: $CODEX_MARKETPLACE_NAME"
  elif [[ "$marketplace_root" != "$SCRIPT_DIR" ]]; then
    err "Codex marketplace '$CODEX_MARKETPLACE_NAME' already points to $marketplace_root"
    err "Remove that marketplace or rename this local marketplace before deploying"
    return 1
  else
    ok "Codex marketplace already registered: $CODEX_MARKETPLACE_NAME"
  fi

  # Reinstall so repeated local deploys always refresh Codex's cached copy.
  codex plugin remove "$PLUGIN_NAME@$CODEX_MARKETPLACE_NAME" >/dev/null 2>&1 || true
  codex plugin add "$PLUGIN_NAME@$CODEX_MARKETPLACE_NAME" >/dev/null

  ok "Codex plugin installed and enabled: $PLUGIN_NAME@$CODEX_MARKETPLACE_NAME"
}

# ============================================================
# 6b. Setup Gemini symlinks
# ============================================================

setup_gemini() {
  if [[ ! -d "$GEMINI_HOME" ]]; then
    warn "Gemini home not found ($GEMINI_HOME), skipping Gemini setup"
    return 0
  fi

  log "Setting up Gemini symlinks..."

  # plugins -> Claude plugins
  make_link "$PLUGINS_DIR" "$GEMINI_HOME/plugins"

  # agents -> Claude agents (if Claude agents dir exists)
  if [[ -d "$CLAUDE_HOME/agents" ]]; then
    make_link "$CLAUDE_HOME/agents" "$GEMINI_HOME/agents"
  fi

  # skills -> Claude skills (if Claude skills dir exists)
  if [[ -d "$CLAUDE_HOME/skills" ]]; then
    make_link "$CLAUDE_HOME/skills" "$GEMINI_HOME/skills"
  fi

  ok "Gemini shares Claude plugin directories"
}

# ============================================================
# 6c. Register _meta symlinks (templates, schemas, etc.)
# ============================================================

register_meta_symlinks() {
  local cache_meta="$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION/_meta"

  if [[ ! -d "$cache_meta" ]]; then
    warn "No _meta directory in cache, skipping _meta symlinks"
    return 0
  fi

  # Register in each platform's home that exists
  for platform_home in "$CLAUDE_HOME" "$CODEX_HOME" "$GEMINI_HOME"; do
    [[ -d "$platform_home" ]] || continue

    local meta_dir="$platform_home/_meta"
    local link_path="$meta_dir/$PLUGIN_NAME"

    mkdir -p "$meta_dir"
    make_link "$cache_meta" "$link_path"
  done

  ok "Registered _meta symlinks (templates, schemas, session-protocols, tech-rules)"
}

# ============================================================
# 6e. Remove legacy ~/.claude/skills/${PLUGIN_NAME}__* symlinks
#
# These were registered by older versions of this script for cross-CLI
# (Codex/Gemini) discovery. They are now redundant — Claude Code's plugin
# system loads plugin skills natively under the `${PLUGIN_NAME}:skill`
# namespace, and Codex/Gemini share the plugin cache via the
# `setup_codex` / `setup_gemini` symlinks. Keeping both forms causes every
# skill to appear twice in `/plugin` and the skill picker.
# ============================================================

remove_legacy_skill_symlinks() {
  local skills_root="$CLAUDE_HOME/skills"
  [[ -d "$skills_root" ]] || { ok "No legacy skill symlinks to clean"; return 0; }

  local count=0
  for link in "$skills_root"/${PLUGIN_NAME}__*; do
    [[ -e "$link" || -L "$link" ]] || continue
    rm -rf "$link"
    count=$((count + 1))
  done

  if [[ $count -gt 0 ]]; then
    ok "Removed $count legacy skill symlinks (now loaded via plugin system)"
  else
    ok "No legacy skill symlinks to clean"
  fi
}

# ============================================================
# 6f. Remove legacy ~/.claude/agents/${PLUGIN_NAME}__* symlinks
# ============================================================

remove_legacy_agent_symlinks() {
  local agents_root="$CLAUDE_HOME/agents"
  [[ -d "$agents_root" ]] || { ok "No legacy agent symlinks to clean"; return 0; }

  local count=0
  for link in "$agents_root"/${PLUGIN_NAME}__*; do
    [[ -e "$link" || -L "$link" ]] || continue
    rm -rf "$link"
    count=$((count + 1))
  done

  if [[ $count -gt 0 ]]; then
    ok "Removed $count legacy agent symlinks (now loaded via plugin system)"
  else
    ok "No legacy agent symlinks to clean"
  fi
}

# ============================================================
# 7. Deploy
# ============================================================

deploy() {
  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-maker Local Deploy${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  Plugin:  ${CYAN}$PLUGIN_NAME${NC} v$PLUGIN_VERSION"
  echo -e "  Source:  $SCRIPT_DIR"
  echo -e "  OS:      $OS"
  echo -e "  Claude:  $CLAUDE_HOME"
  echo -e "  Codex:   $CODEX_HOME"
  echo -e "  Gemini:  $GEMINI_HOME"
  echo -e "${BOLD}----------------------------------------${NC}"
  echo ""

  # Ensure directories exist
  mkdir -p "$MARKETPLACES_DIR" "$CACHE_DIR"

  # Step 1: Cache sync (must run BEFORE symlink so the target exists)
  log "1/10  Cache sync"
  sync_to_cache

  # Step 2: Marketplace symlink (points to cache, not SCRIPT_DIR — survives temp dir cleanup)
  log "2/10  Marketplace symlink"
  local cache_dest="$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"
  make_link "$cache_dest" "$MARKETPLACES_DIR/$MARKETPLACE_NAME"

  # Step 3: known_marketplaces.json
  log "3/10  known_marketplaces.json"
  update_known_marketplaces

  # Step 4: installed_plugins.json
  log "4/10  installed_plugins.json"
  update_installed_plugins

  # Step 5: settings.json enabledPlugins toggle (otherwise Claude Code won't load the plugin)
  log "5/10  settings.json enabledPlugins"
  update_enabled_plugins

  # Step 6: Remove legacy duplicate symlinks
  # Claude Code's plugin system loads plugin skills/agents natively under the
  # `${PLUGIN_NAME}:skill` namespace. The old `${PLUGIN_NAME}__skill` symlinks
  # produced a second copy of every skill in /plugin — purge them.
  log "6/10  Remove legacy skill symlinks (${PLUGIN_NAME}__*)"
  remove_legacy_skill_symlinks

  log "7/10  Remove legacy agent symlinks (${PLUGIN_NAME}__*)"
  remove_legacy_agent_symlinks

  # Step 8: _meta symlinks (templates, schemas, etc.)
  log "8/10  _meta symlinks (templates, schemas)"
  register_meta_symlinks

  # Step 9: Codex
  log "9/10  Codex integration"
  setup_codex

  # Step 10: Gemini
  log "10/10 Gemini integration"
  setup_gemini

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  Deploy complete!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo -e "  Restart Claude Code / Codex / Gemini CLI to pick up changes."
  echo -e "  Codex CLI: run /skills or type \$${PLUGIN_NAME}:u-plan (skills are not /u-plan slash commands)."
  echo ""
}

# ============================================================
# 8. Clean (--clean)
# ============================================================

clean() {
  echo ""
  log "Cleaning u-maker deployment..."

  # Remove the Codex-managed plugin and its local marketplace registration.
  if command -v codex &>/dev/null && codex plugin --help &>/dev/null; then
    codex plugin remove "$PLUGIN_NAME@$CODEX_MARKETPLACE_NAME" >/dev/null 2>&1 || true
    codex plugin marketplace remove "$CODEX_MARKETPLACE_NAME" >/dev/null 2>&1 || true
    ok "Codex plugin and marketplace registration removed"
  fi

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

  # Remove from settings.json enabledPlugins
  local settings_file="$CLAUDE_HOME/settings.json"
  if [[ -f "$settings_file" ]]; then
    python3 -c "
import json
sf = '$settings_file'
key = '${PLUGIN_NAME}@${PLUGIN_NAME}'
with open(sf, 'r') as f:
    data = json.load(f)
ep = data.get('enabledPlugins', {})
if key in ep:
    del ep[key]
    with open(sf, 'w') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
"
    ok "settings.json enabledPlugins → off"
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

  # Remove agent symlinks
  local agents_root="$CLAUDE_HOME/agents"
  local acount=0
  for link in "$agents_root"/${PLUGIN_NAME}__*; do
    if [[ -L "$link" ]]; then
      rm "$link"
      acount=$((acount + 1))
    fi
  done
  if [[ $acount -gt 0 ]]; then
    ok "Removed $acount agent symlinks"
  fi

  # Remove _meta symlinks
  for platform_home in "$CLAUDE_HOME" "$CODEX_HOME" "$GEMINI_HOME"; do
    if [[ -L "$platform_home/_meta/$PLUGIN_NAME" ]]; then
      rm "$platform_home/_meta/$PLUGIN_NAME"
      ok "Removed _meta symlink from $(basename "$platform_home")"
    fi
  done

  # Remove Gemini symlinks
  if [[ -d "$GEMINI_HOME" ]]; then
    for link in plugins agents skills; do
      if [[ -L "$GEMINI_HOME/$link" ]]; then
        rm "$GEMINI_HOME/$link"
        ok "Gemini $link symlink removed"
      fi
    done
  fi

  echo ""
  ok "Clean complete. Restart Claude Code / Codex / Gemini CLI."
  echo ""
}

# ============================================================
# 9. Check (--check)
# ============================================================

check() {
  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-maker Deployment Status${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""

  local all_ok=true

  # Marketplace symlink
  if [[ -L "$MARKETPLACES_DIR/$MARKETPLACE_NAME" ]]; then
    local target
    target="$(readlink "$MARKETPLACES_DIR/$MARKETPLACE_NAME")"
    local expected_target="$CACHE_DIR/$PLUGIN_NAME/$PLUGIN_NAME/$PLUGIN_VERSION"
    if [[ "$target" == "$expected_target" || "$target" == "$SCRIPT_DIR" ]]; then
      ok "Marketplace symlink → $target"
    else
      warn "Marketplace symlink points to $target (expected $expected_target)"
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

  # settings.json enabledPlugins
  local settings_file="$CLAUDE_HOME/settings.json"
  if [[ -f "$settings_file" ]]; then
    local enabled
    enabled="$(python3 -c "import json; d=json.load(open('$settings_file')); print('yes' if d.get('enabledPlugins',{}).get('${PLUGIN_NAME}@${PLUGIN_NAME}') is True else 'no')")"
    if [[ "$enabled" == "yes" ]]; then
      ok "settings.json enabledPlugins → on"
    else
      err "settings.json enabledPlugins → off (plugin will not load)"
      all_ok=false
    fi
  else
    warn "settings.json not found at $settings_file"
  fi

  # _meta symlinks
  local meta_ok=true
  for platform_home in "$CLAUDE_HOME" "$CODEX_HOME" "$GEMINI_HOME"; do
    [[ -d "$platform_home" ]] || continue
    local pname
    pname="$(basename "$platform_home")"
    if [[ -L "$platform_home/_meta/$PLUGIN_NAME" ]]; then
      ok "$pname _meta → cache _meta"
    else
      warn "$pname _meta symlink missing"
      meta_ok=false
    fi
  done
  if ! $meta_ok; then
    all_ok=false
  fi

  # Codex
  if command -v codex &>/dev/null && codex plugin --help &>/dev/null; then
    local codex_plugin_status
    codex_plugin_status="$(codex plugin list 2>/dev/null \
      | awk -v selector="$PLUGIN_NAME@$CODEX_MARKETPLACE_NAME" '$1 == selector {print $0; exit}')"
    if [[ "$codex_plugin_status" == *"installed, enabled"* ]]; then
      ok "Codex plugin → $PLUGIN_NAME@$CODEX_MARKETPLACE_NAME installed, enabled"
    else
      err "Codex plugin → $PLUGIN_NAME@$CODEX_MARKETPLACE_NAME is not installed and enabled"
      all_ok=false
    fi
  else
    warn "Codex CLI plugin support not available (skipped)"
  fi

  # Gemini
  if [[ -d "$GEMINI_HOME" ]]; then
    if [[ -L "$GEMINI_HOME/plugins" ]]; then
      local gemini_target
      gemini_target="$(readlink "$GEMINI_HOME/plugins")"
      if [[ "$gemini_target" == "$PLUGINS_DIR" ]]; then
        ok "Gemini plugins → Claude plugins"
      else
        warn "Gemini plugins → $gemini_target (expected $PLUGINS_DIR)"
      fi
    else
      warn "Gemini plugins symlink missing"
    fi
  else
    warn "Gemini not installed (skipped)"
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
