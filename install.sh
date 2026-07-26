#!/usr/bin/env bash
# ============================================================
# install.sh — umaker plugin installer (macOS / Linux / WSL)
#
# Downloads the latest release from GitHub, extracts, installs,
# and cleans up temporary files.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/upleat-ax/umaker-plugin/main/install.sh | bash
#   # or
#   ./install.sh
#   ./install.sh --version 1.0.7    # install specific version
#   ./install.sh --uninstall        # remove plugin
# ============================================================
set -euo pipefail

# ============================================================
# Config
# ============================================================

REPO="${UMAKER_REPO:-upleat-ax/umaker-plugin}"
API_URL="https://api.github.com/repos/${REPO}/releases"
PLUGIN_NAME="umaker"
# Pre-rename plugin name (u-maker). Cleanup still targets these OLD-name
# artifacts so upgrades from a u-maker install leave nothing behind.
OLD_PLUGIN_NAME="u-maker"

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
# Helpers
# ============================================================

check_deps() {
  local missing=()
  for cmd in curl unzip python3; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    err "Missing required tools: ${missing[*]}"
    echo "  Install them and retry."
    exit 1
  fi
}

get_latest_version() {
  curl -fsSL "${API_URL}/latest" 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null \
    || { err "Failed to fetch latest release info from ${REPO}"; exit 1; }
}

get_download_url() {
  local tag="$1"
  curl -fsSL "${API_URL}/tags/${tag}" 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for asset in data.get('assets', []):
    if asset['name'].endswith('.zip'):
        print(asset['browser_download_url'])
        break
" 2>/dev/null \
    || { err "Failed to find zip asset for ${tag}"; exit 1; }
}

# ============================================================
# Install
# ============================================================

clean_existing() {
  local claude_home="$HOME/.claude"
  local plugins_dir="$claude_home/plugins"
  local cache_dir="$plugins_dir/cache"
  local marketplaces_dir="$plugins_dir/marketplaces"
  local skills_root="$claude_home/skills"
  local agents_root="$claude_home/agents"
  local known_mp="$plugins_dir/known_marketplaces.json"
  local installed_pl="$plugins_dir/installed_plugins.json"
  local settings_file="$claude_home/settings.json"

  log "Removing existing umaker installation (incl. legacy u-maker artifacts)..."

  # Clean both the OLD (u-maker) and NEW (umaker) name variants.
  local name
  for name in "$OLD_PLUGIN_NAME" "$PLUGIN_NAME"; do

    # 1. Remove skill symlinks (<name>__*)
    if [[ -d "$skills_root" ]]; then
      local scount=0
      for link in "$skills_root"/${name}__*; do
        if [[ -L "$link" ]]; then
          rm "$link"
          scount=$((scount + 1))
        fi
      done
      [[ $scount -gt 0 ]] && ok "Removed $scount skill symlinks (${name}__*)"
    fi

    # 2. Remove agent symlinks (<name>__*)
    if [[ -d "$agents_root" ]]; then
      local acount=0
      for link in "$agents_root"/${name}__*; do
        if [[ -L "$link" ]]; then
          rm "$link"
          acount=$((acount + 1))
        fi
      done
      [[ $acount -gt 0 ]] && ok "Removed $acount agent symlinks (${name}__*)"
    fi

    # 3. Remove marketplace symlink
    if [[ -L "$marketplaces_dir/${name}-marketplace" ]]; then
      rm "$marketplaces_dir/${name}-marketplace"
      ok "Marketplace symlink removed (${name}-marketplace)"
    fi

    # 4. Remove plugin cache (all versions)
    if [[ -d "$cache_dir/$name" ]]; then
      rm -rf "$cache_dir/$name"
      ok "Cache directory removed (all $name versions)"
    fi

    # 5. Clean known_marketplaces.json
    if [[ -f "$known_mp" ]]; then
      python3 -c "
import json
with open('$known_mp', 'r') as f:
    data = json.load(f)
data.pop('$name', None)
with open('$known_mp', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null && ok "known_marketplaces.json cleaned ($name)"
    fi

    # 6. Clean installed_plugins.json
    if [[ -f "$installed_pl" ]]; then
      python3 -c "
import json
with open('$installed_pl', 'r') as f:
    data = json.load(f)
data.get('plugins', {}).pop('${name}@${name}', None)
with open('$installed_pl', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null && ok "installed_plugins.json cleaned (${name}@${name})"
    fi

    # 7. Clean settings.json enabledPlugins (write back only if changed)
    if [[ -f "$settings_file" ]]; then
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
" 2>/dev/null && ok "settings.json enabledPlugins cleaned (${name}@${name})"
    fi

  done

  # 7. Remove Codex symlinks
  local codex_home="$HOME/.codex"
  if [[ -d "$codex_home" ]]; then
    for link in plugins agents skills; do
      if [[ -L "$codex_home/$link" ]]; then
        rm "$codex_home/$link"
      fi
    done
    ok "Codex symlinks removed"
  fi

  # 8. Remove Gemini symlinks
  local gemini_home="$HOME/.gemini"
  if [[ -d "$gemini_home" ]]; then
    for link in plugins agents skills; do
      if [[ -L "$gemini_home/$link" ]]; then
        rm "$gemini_home/$link"
      fi
    done
    ok "Gemini symlinks removed"
  fi

  ok "Clean complete"
}

do_install() {
  local version="$1"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  umaker Plugin Installer${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""

  check_deps

  # Determine version
  if [[ -z "$version" ]]; then
    log "Fetching latest release..."
    version="$(get_latest_version)"
  fi
  ok "Version: ${BOLD}${version}${NC}"

  # ── Step 1: Clean existing installation ──
  log "Step 1/4: Cleaning existing installation..."
  clean_existing
  echo ""

  # ── Step 2: Download ──
  log "Step 2/4: Downloading..."
  local url
  url="$(get_download_url "$version")"
  if [[ -z "$url" ]]; then
    err "No zip asset found for ${version}"
    exit 1
  fi
  ok "URL: ${url}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local zip_file="${tmp_dir}/umaker-plugin.zip"

  curl -fsSL "$url" -o "$zip_file" || {
    err "Download failed"
    rm -rf "$tmp_dir"
    exit 1
  }
  local size
  size="$(du -h "$zip_file" | cut -f1 | tr -d ' ')"
  ok "Downloaded (${size})"

  # ── Step 3: Extract ──
  log "Step 3/4: Extracting..."
  unzip -qo "$zip_file" -d "${tmp_dir}/plugin" || {
    err "Extraction failed"
    rm -rf "$tmp_dir"
    exit 1
  }
  ok "Extracted"

  # ── Step 4: Install (clean) ──
  log "Step 4/4: Installing..."
  local deploy_script
  deploy_script="$(find "${tmp_dir}/plugin" -name "deploy_local.sh" -type f | head -1)"
  if [[ -z "$deploy_script" ]]; then
    err "deploy_local.sh not found in archive"
    rm -rf "$tmp_dir"
    exit 1
  fi

  chmod +x "$deploy_script"
  bash "$deploy_script" || {
    err "Installation failed"
    rm -rf "$tmp_dir"
    exit 1
  }

  # Clean up temp files
  rm -rf "$tmp_dir"

  # Warn about existing .u-maker/ projects (v4.0 is a breaking change from v3.x)
  log "Checking for existing .u-maker/ projects..."
  local found_count=0
  for umaker_dir in "$HOME"/*/".u-maker" "$HOME"/*/*/".u-maker" "$PWD"/".u-maker"; do
    if [[ -d "$umaker_dir" ]]; then
      found_count=$((found_count + 1))
      warn "Found: $umaker_dir"
    fi
  done
  if [[ $found_count -gt 0 ]]; then
    echo ""
    warn "WARNING: v4.0+ is not compatible with v3.x .u-maker/ folders. Please re-initialize with /um-plan."
    echo ""
  else
    ok "No existing .u-maker/ projects found"
  fi

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  umaker ${version} installed! (clean)${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo -e "  ${YELLOW}All previous data was removed and reinstalled fresh.${NC}"
  echo -e "  Restart Claude Code to start using umaker."
  echo -e "  Then run: ${BOLD}/um-plan${NC}"
  echo -e "  Note: um-* skill bodies are served by the u-maker terminal app — keep it running."
  echo ""
}

# ============================================================
# Uninstall
# ============================================================

do_uninstall() {
  echo ""
  log "Uninstalling umaker..."

  local claude_home="$HOME/.claude"
  local cache_dir="$claude_home/plugins/cache/${PLUGIN_NAME}"
  local old_cache_dir="$claude_home/plugins/cache/${OLD_PLUGIN_NAME}"

  # Find deploy_local.sh in cache (new name first, then legacy u-maker cache)
  local deploy_script
  deploy_script="$(find "$cache_dir" -name "deploy_local.sh" -type f 2>/dev/null | head -1)"
  if [[ -z "$deploy_script" ]]; then
    deploy_script="$(find "$old_cache_dir" -name "deploy_local.sh" -type f 2>/dev/null | head -1)"
  fi

  if [[ -n "$deploy_script" ]]; then
    bash "$deploy_script" --clean
  else
    warn "Cache not found. Manual cleanup may be needed."
    warn "Check ~/.claude/plugins/ and ~/.claude/skills/"
  fi

  ok "Uninstall complete. Restart Claude Code."
  echo ""
}

# ============================================================
# Main
# ============================================================

case "${1:-}" in
  --uninstall|--clean)
    do_uninstall
    ;;
  --version)
    if [[ -z "${2:-}" ]]; then
      err "Usage: install.sh --version <version>"
      exit 1
    fi
    do_install "v${2#v}"
    ;;
  --help|-h)
    echo "Usage:"
    echo "  ./install.sh                  # install latest version"
    echo "  ./install.sh --version 1.0.7  # install specific version"
    echo "  ./install.sh --uninstall      # remove plugin"
    echo "  ./install.sh --help           # show this help"
    echo ""
    echo "Environment:"
    echo "  UMAKER_REPO=owner/repo  # override GitHub repo (default: upleat-ax/umaker-plugin)"
    ;;
  *)
    do_install "${1:-}"
    ;;
esac
