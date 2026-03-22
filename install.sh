#!/usr/bin/env bash
# ============================================================
# install.sh — u-maker plugin installer (macOS / Linux / WSL)
#
# Downloads the latest release from GitHub, extracts, installs,
# and cleans up temporary files.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/upleat-ax/u-maker-plugin/main/install.sh | bash
#   # or
#   ./install.sh
#   ./install.sh --version 1.0.7    # install specific version
#   ./install.sh --uninstall        # remove plugin
# ============================================================
set -euo pipefail

# ============================================================
# Config
# ============================================================

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

do_install() {
  local version="$1"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-maker Plugin Installer${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""

  check_deps

  # Determine version
  if [[ -z "$version" ]]; then
    log "Fetching latest release..."
    version="$(get_latest_version)"
  fi
  ok "Version: ${BOLD}${version}${NC}"

  # Get download URL
  log "Finding download URL..."
  local url
  url="$(get_download_url "$version")"
  if [[ -z "$url" ]]; then
    err "No zip asset found for ${version}"
    exit 1
  fi
  ok "URL: ${url}"

  # Create temp directory
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local zip_file="${tmp_dir}/u-maker-plugin.zip"

  # Download
  log "Downloading..."
  curl -fsSL "$url" -o "$zip_file" || {
    err "Download failed"
    rm -rf "$tmp_dir"
    exit 1
  }
  local size
  size="$(du -h "$zip_file" | cut -f1 | tr -d ' ')"
  ok "Downloaded (${size})"

  # Extract
  log "Extracting..."
  unzip -qo "$zip_file" -d "${tmp_dir}/plugin" || {
    err "Extraction failed"
    rm -rf "$tmp_dir"
    exit 1
  }
  ok "Extracted"

  # Find deploy_local.sh in extracted files
  local deploy_script
  deploy_script="$(find "${tmp_dir}/plugin" -name "deploy_local.sh" -type f | head -1)"
  if [[ -z "$deploy_script" ]]; then
    err "deploy_local.sh not found in archive"
    rm -rf "$tmp_dir"
    exit 1
  fi

  # Install
  log "Installing..."
  chmod +x "$deploy_script"
  bash "$deploy_script" || {
    err "Installation failed"
    rm -rf "$tmp_dir"
    exit 1
  }

  # Clean up
  log "Cleaning up temporary files..."
  rm -rf "$tmp_dir"
  ok "Temporary files removed"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  u-maker ${version} installed!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo -e "  Restart Claude Code to start using u-maker."
  echo -e "  Then run: ${BOLD}/u-skill-help${NC}"
  echo ""
}

# ============================================================
# Uninstall
# ============================================================

do_uninstall() {
  echo ""
  log "Uninstalling u-maker..."

  local claude_home="$HOME/.claude"
  local cache_dir="$claude_home/plugins/cache/${PLUGIN_NAME}"

  # Find deploy_local.sh in cache
  local deploy_script
  deploy_script="$(find "$cache_dir" -name "deploy_local.sh" -type f 2>/dev/null | head -1)"

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
    echo "  UMAKER_REPO=owner/repo  # override GitHub repo (default: upleat-ax/u-maker-plugin)"
    ;;
  *)
    do_install "${1:-}"
    ;;
esac
