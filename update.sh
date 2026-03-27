#!/usr/bin/env bash
# ============================================================
# update.sh — u-maker plugin updater (macOS / Linux / WSL)
#
# Removes the existing installation completely, then installs
# the latest (or specified) version fresh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/update.sh | bash
#   # or
#   ./update.sh                     # update to latest
#   ./update.sh --version 2.1.0     # update to specific version
#   ./update.sh --check             # show current vs latest version
# ============================================================
set -euo pipefail

REPO="${UMAKER_REPO:-upleat-ax/u-maker-plugin}"
API_URL="https://api.github.com/repos/${REPO}/releases"
PLUGIN_NAME="u-maker"

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
    exit 1
  fi
}

get_current_version() {
  local claude_home="$HOME/.claude"
  local cache_dir="$claude_home/plugins/cache/$PLUGIN_NAME"

  # Find plugin.json in cache
  local plugin_json
  plugin_json="$(find "$cache_dir" -name "plugin.json" -path "*/.claude-plugin/*" 2>/dev/null | head -1)"

  if [[ -n "$plugin_json" && -f "$plugin_json" ]]; then
    python3 -c "import json; print(json.load(open('$plugin_json'))['version'])" 2>/dev/null || echo "unknown"
  else
    echo "not installed"
  fi
}

get_latest_version() {
  curl -fsSL "${API_URL}/latest" 2>/dev/null \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null \
    || { err "Failed to fetch latest release"; exit 1; }
}

# ============================================================
# Check (--check)
# ============================================================

do_check() {
  check_deps

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-maker Version Check${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""

  local current latest
  current="$(get_current_version)"
  latest="$(get_latest_version)"

  echo -e "  Current:  ${BOLD}${current}${NC}"
  echo -e "  Latest:   ${BOLD}${latest}${NC}"
  echo ""

  if [[ "$current" == "not installed" ]]; then
    echo -e "  ${YELLOW}u-maker is not installed.${NC}"
    echo -e "  Run: ${BOLD}curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash${NC}"
  elif [[ "v${current}" == "${latest}" || "${current}" == "${latest}" ]]; then
    echo -e "  ${GREEN}Already up to date!${NC}"
  else
    echo -e "  ${YELLOW}Update available!${NC}"
    echo -e "  Run: ${BOLD}curl -fsSL https://raw.githubusercontent.com/${REPO}/main/update.sh | bash${NC}"
  fi
  echo ""
}

# ============================================================
# Update (clean reinstall)
# ============================================================

do_update() {
  local version="$1"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-maker Plugin Updater${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""

  check_deps

  local current
  current="$(get_current_version)"
  echo -e "  Current version: ${BOLD}${current}${NC}"

  # Determine target version
  if [[ -z "$version" ]]; then
    log "Fetching latest release..."
    version="$(get_latest_version)"
  fi
  echo -e "  Target version:  ${BOLD}${version}${NC}"
  echo ""

  # ── Step 1: Download install.sh from the target release ──
  log "Downloading installer..."
  local install_url="https://raw.githubusercontent.com/${REPO}/${version}/install.sh"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local install_script="${tmp_dir}/install.sh"

  # Try tag URL first, fallback to main
  if ! curl -fsSL "$install_url" -o "$install_script" 2>/dev/null; then
    install_url="https://raw.githubusercontent.com/${REPO}/main/install.sh"
    curl -fsSL "$install_url" -o "$install_script" || {
      err "Failed to download installer"
      rm -rf "$tmp_dir"
      exit 1
    }
  fi
  ok "Installer downloaded"

  # ── Step 2: Run install.sh (which does clean + install) ──
  log "Running clean install..."
  chmod +x "$install_script"
  bash "$install_script" --version "${version#v}" || {
    err "Update failed"
    rm -rf "$tmp_dir"
    exit 1
  }

  rm -rf "$tmp_dir"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  u-maker updated!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  ${BOLD}${current}${NC} → ${BOLD}${version}${NC}"
  echo ""
  echo -e "  ${YELLOW}All previous data was removed and reinstalled fresh.${NC}"
  echo -e "  Restart Claude Code to apply changes."
  echo ""
}

# ============================================================
# Main
# ============================================================

case "${1:-}" in
  --check)
    do_check
    ;;
  --version)
    if [[ -z "${2:-}" ]]; then
      err "Usage: update.sh --version <version>"
      exit 1
    fi
    do_update "v${2#v}"
    ;;
  --help|-h)
    echo "Usage:"
    echo "  ./update.sh                  # update to latest (clean reinstall)"
    echo "  ./update.sh --version 2.1.0  # update to specific version"
    echo "  ./update.sh --check          # show current vs latest version"
    echo "  ./update.sh --help           # show this help"
    echo ""
    echo "Environment:"
    echo "  UMAKER_REPO=owner/repo  # override GitHub repo (default: upleat-ax/u-maker-plugin)"
    ;;
  *)
    do_update "${1:-}"
    ;;
esac
