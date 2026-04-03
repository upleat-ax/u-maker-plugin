#!/usr/bin/env bash
# ============================================================
# deploy_vercel.sh — Deploy u-maker docs to umaker.upleat.ai
#
# Builds a static site from README*.html + GET_STARTED.html
# and deploys to Vercel (umaker.upleat.ai).
#
# Usage:
#   ./deploy_vercel.sh              # deploy to production
#   ./deploy_vercel.sh --preview    # deploy preview only
#   ./deploy_vercel.sh --check      # verify deployment
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

DOMAIN="umaker.upleat.ai"
PROJECT_NAME="u-maker-docs"

# ============================================================
# Helpers
# ============================================================

ensure_vercel() {
  if ! command -v vercel &>/dev/null; then
    err "Vercel CLI required. Install: npm i -g vercel@latest"
    exit 1
  fi
}

get_version() {
  python3 -c "import json; print(json.load(open('$SCRIPT_DIR/.claude-plugin/plugin.json'))['version'])"
}

# ============================================================
# Build static site
# ============================================================

build_site() {
  local out_dir="$1"
  local version
  version="$(get_version)"

  log "Building static site (v${version})..."

  rm -rf "$out_dir"
  mkdir -p "$out_dir"

  # Copy HTML docs
  cp "$SCRIPT_DIR/README.ko.html" "$out_dir/README.ko.html"
  cp "$SCRIPT_DIR/README.en.html" "$out_dir/README.en.html"
  cp "$SCRIPT_DIR/GET_STARTED.html" "$out_dir/GET_STARTED.html"

  # index.html → serve README.ko.html content directly
  cp "$SCRIPT_DIR/README.ko.html" "$out_dir/index.html"

  ok "Site built: 4 files (v${version})"
}

# ============================================================
# Deploy
# ============================================================

cmd_deploy() {
  local prod="${1:-true}"
  local version
  version="$(get_version)"

  ensure_vercel

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}  u-maker Vercel Deploy${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  Version: ${CYAN}v${version}${NC}"
  echo -e "  Domain:  ${BOLD}${DOMAIN}${NC}"
  echo -e "  Mode:    $([ "$prod" = "true" ] && echo "Production" || echo "Preview")"
  echo -e "${BOLD}----------------------------------------${NC}"
  echo ""

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local site_dir="$tmp_dir/site"

  # Step 1: Build
  build_site "$site_dir"

  # Step 2: Write vercel.json
  cat > "$site_dir/vercel.json" << 'VJSON'
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=3600, s-maxage=86400" },
        { "key": "X-Content-Type-Options", "value": "nosniff" }
      ]
    }
  ],
  "cleanUrls": true
}
VJSON
  ok "vercel.json written"

  # Step 3: Deploy
  log "Deploying to Vercel..."

  local deploy_args=("--yes")
  if [[ "$prod" == "true" ]]; then
    deploy_args+=("--prod")
  fi

  local deploy_url
  deploy_url="$(cd "$site_dir" && vercel "${deploy_args[@]}" 2>&1)" || {
    err "Deploy failed:"
    echo "$deploy_url"
    rm -rf "$tmp_dir"
    exit 1
  }
  ok "Deployed: ${deploy_url}"

  # Cleanup
  rm -rf "$tmp_dir"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  Deploy complete!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  URL:     ${BOLD}${deploy_url}${NC}"
  if [[ "$prod" == "true" ]]; then
    echo -e "  Domain:  ${BOLD}https://${DOMAIN}${NC}"
  fi
  echo ""
  echo -e "  Pages:"
  echo -e "    https://${DOMAIN}/                    (README.ko.html)"
  echo -e "    https://${DOMAIN}/README.ko.html"
  echo -e "    https://${DOMAIN}/README.en.html"
  echo -e "    https://${DOMAIN}/GET_STARTED.html"
  echo ""
}

# ============================================================
# Check
# ============================================================

cmd_check() {
  ensure_vercel

  echo ""
  log "Checking deployment status..."
  echo ""

  local urls=(
    "https://${DOMAIN}/"
    "https://${DOMAIN}/README.ko.html"
    "https://${DOMAIN}/README.en.html"
    "https://${DOMAIN}/GET_STARTED.html"
  )

  local all_ok=true
  for url in "${urls[@]}"; do
    local status
    status="$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || echo "000")"
    if [[ "$status" == "200" ]]; then
      ok "$url → ${status}"
    else
      err "$url → ${status}"
      all_ok=false
    fi
  done

  echo ""
  if $all_ok; then
    echo -e "  ${GREEN}${BOLD}All pages accessible.${NC}"
  else
    echo -e "  ${YELLOW}${BOLD}Some pages failed. Redeploy with ./deploy_vercel.sh${NC}"
  fi
  echo ""
}

# ============================================================
# Main
# ============================================================

case "${1:-}" in
  --preview)
    cmd_deploy "false"
    ;;
  --check)
    cmd_check
    ;;
  --help|-h)
    echo "Usage:"
    echo "  ./deploy_vercel.sh              # deploy to production"
    echo "  ./deploy_vercel.sh --preview    # deploy preview only"
    echo "  ./deploy_vercel.sh --check      # verify deployment"
    echo "  ./deploy_vercel.sh --help       # show this help"
    ;;
  *)
    cmd_deploy "true"
    ;;
esac
