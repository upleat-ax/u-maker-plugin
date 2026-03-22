#!/usr/bin/env bash
# ============================================================
# deploy_github.sh — u-maker GitHub deployment
#
# Creates a version tag and pushes it to trigger the GitHub Actions
# workflow that publishes to thinoo-v2/u-maker-production (public).
#
# Usage:
#   ./deploy_github.sh              # auto-bump patch (1.0.0 → 1.0.1)
#   ./deploy_github.sh 1.2.0        # deploy specific version
#   ./deploy_github.sh --status     # check latest workflow run
#   ./deploy_github.sh --check      # verify public repo state
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_JSON="$SCRIPT_DIR/.claude-plugin/plugin.json"

PRIVATE_REPO="thinoo-v2/u-maker-plugin"
PUBLIC_REPO="thinoo-v2/u-maker-production"
UPLEAT_REPO="upleat-ax/u-maker-plugin"

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

current_version() {
  python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])"
}

bump_patch() {
  local ver="$1"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$ver"
  echo "${major}.${minor}.$((patch + 1))"
}

ensure_clean() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    err "Working tree has uncommitted changes. Commit or stash first."
    exit 1
  fi
}

ensure_gh() {
  if ! command -v gh &>/dev/null; then
    err "GitHub CLI (gh) is required. Install: brew install gh"
    exit 1
  fi
}

# ============================================================
# Commands
# ============================================================

cmd_status() {
  ensure_gh
  log "Latest workflow run on ${BOLD}${PRIVATE_REPO}${NC}:"
  echo ""
  gh run list --repo "$PRIVATE_REPO" --workflow "publish.yml" --limit 5
}

cmd_check() {
  ensure_gh

  for repo in "$PUBLIC_REPO" "$UPLEAT_REPO"; do
    log "Public repo: ${BOLD}https://github.com/${repo}${NC}"
    echo ""

    local visibility
    visibility="$(gh repo view "$repo" --json visibility -q '.visibility' 2>/dev/null || echo "NOT_FOUND")"
    if [[ "$visibility" == "PUBLIC" ]]; then
      ok "Visibility: PUBLIC"
    else
      err "Visibility: $visibility"
    fi

    echo ""
    log "Latest tags:"
    gh api "repos/${repo}/tags" --jq '.[0:5][] | "  \(.name)"' 2>/dev/null || warn "No tags found"

    echo ""
    log "Latest release:"
    gh release view --repo "$repo" --json tagName,assets -q '"  Tag: \(.tagName)\n  Assets: \([.assets[].name] | join(", "))"' 2>/dev/null || warn "No releases found"
    echo ""
  done

  log "Install (macOS/Linux):"
  echo -e "  ${BOLD}curl -fsSL https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.sh | bash${NC}"
  echo ""
  log "Install (Windows):"
  echo -e "  ${BOLD}Invoke-WebRequest -Uri https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -OutFile install.bat; .\\install.bat${NC}"
}

cmd_deploy() {
  local version="$1"

  ensure_clean
  ensure_gh

  local current
  current="$(current_version)"

  if [[ -z "$version" ]]; then
    version="$(bump_patch "$current")"
    log "Auto-bumping: ${current} → ${BOLD}${version}${NC}"
  else
    log "Deploying version: ${BOLD}${version}${NC}"
  fi

  # Update plugin.json version
  if [[ "$version" != "$current" ]]; then
    python3 -c "
import json
with open('$PLUGIN_JSON', 'r') as f:
    data = json.load(f)
data['version'] = '$version'
with open('$PLUGIN_JSON', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
"
    git add "$PLUGIN_JSON"
    git commit -m "chore: bump version to ${version}"
    ok "Updated plugin.json: ${version}"
  fi

  # Push main first
  log "Pushing main branch..."
  git push origin main
  ok "Main branch pushed"

  # Create and push tag
  local tag="v${version}"

  if git tag -l "$tag" | grep -q "$tag"; then
    warn "Tag ${tag} already exists locally, deleting..."
    git tag -d "$tag"
    git push origin ":refs/tags/${tag}" 2>/dev/null || true
  fi

  git tag -a "$tag" -m "Release ${tag}"
  git push origin "$tag"
  ok "Tag ${tag} pushed — workflow triggered"

  echo ""
  log "Monitoring workflow..."
  echo ""

  local run_id
  for _ in 1 2 3 4 5; do
    run_id="$(gh run list --repo "$PRIVATE_REPO" --workflow "publish.yml" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || echo "")"
    [[ -n "$run_id" ]] && break
    sleep 2
  done

  if [[ -n "$run_id" ]]; then
    gh run watch "$run_id" --repo "$PRIVATE_REPO" --exit-status && {
      echo ""
      ok "Deploy complete! ${BOLD}v${version}${NC} → ${PUBLIC_REPO} + ${UPLEAT_REPO}"
      echo ""
      log "Install (macOS/Linux):"
      echo -e "  ${BOLD}curl -fsSL https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.sh | bash${NC}"
      echo ""
      log "Install (Windows):"
      echo -e "  ${BOLD}Invoke-WebRequest -Uri https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -OutFile install.bat; .\\install.bat${NC}"
    } || {
      echo ""
      err "Workflow failed. Check: gh run view ${run_id} --repo ${PRIVATE_REPO} --log"
      exit 1
    }
  else
    warn "Could not find workflow run. Check manually:"
    echo "  gh run list --repo ${PRIVATE_REPO}"
  fi
}

# ============================================================
# Main
# ============================================================

case "${1:-}" in
  --status)
    cmd_status
    ;;
  --check)
    cmd_check
    ;;
  --help|-h)
    echo "Usage:"
    echo "  ./deploy_github.sh              # auto-bump patch & deploy"
    echo "  ./deploy_github.sh 1.2.0        # deploy specific version"
    echo "  ./deploy_github.sh --status     # check workflow runs"
    echo "  ./deploy_github.sh --check      # verify public repo"
    echo "  ./deploy_github.sh --help       # show this help"
    ;;
  --*)
    err "Unknown option: $1"
    exit 1
    ;;
  *)
    cmd_deploy "${1:-}"
    ;;
esac
