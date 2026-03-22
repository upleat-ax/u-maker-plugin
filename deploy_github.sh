#!/usr/bin/env bash
# ============================================================
# deploy_github.sh — u-maker GitHub deployment (local build)
#
# Builds zip, pushes public repos, creates GitHub Releases.
# All done locally — no GitHub Actions dependency.
#
# Usage:
#   ./deploy_github.sh              # auto-bump patch (1.0.0 → 1.0.1)
#   ./deploy_github.sh 1.2.0        # deploy specific version
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
    log "Repo contents:"
    gh api "repos/${repo}/contents" --jq '.[].name' 2>/dev/null | sed 's/^/  /' || warn "Cannot list contents"
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

  local tag="v${version}"

  # ── Step 1: Update plugin.json version ──
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

  # ── Step 2: Push main to private repo ──
  log "Pushing main branch..."
  git push origin main
  ok "Main branch pushed"

  # ── Step 3: Create and push tag ──
  if git tag -l "$tag" | grep -q "$tag"; then
    warn "Tag ${tag} already exists locally, deleting..."
    git tag -d "$tag"
    git push origin ":refs/tags/${tag}" 2>/dev/null || true
  fi

  git tag -a "$tag" -m "Release ${tag}"
  git push origin "$tag"
  ok "Tag ${tag} created and pushed"

  # ── Step 4: Build zip ──
  log "Building plugin zip..."
  local zip_file="/tmp/u-maker-plugin-${tag}.zip"
  rm -f "$zip_file"

  (cd "$SCRIPT_DIR" && zip -r "$zip_file" \
    .claude-plugin/ \
    skills/ \
    agents/ \
    _refer/ \
    templates/ \
    scripts/ \
    lib/ \
    hooks/ \
    deploy_local.sh \
    deploy_local.bat \
    README.md \
    GET_STARTED.md \
    -x "*.DS_Store" "*__pycache__*" "*.pyc" \
  )
  local zip_size
  zip_size="$(du -h "$zip_file" | cut -f1 | tr -d ' ')"
  ok "Zip created: ${zip_file} (${zip_size})"

  # ── Step 5: Create Release on private repo ──
  log "Creating release on ${BOLD}${PRIVATE_REPO}${NC}..."
  gh release create "$tag" "$zip_file" \
    --title "u-maker ${tag}" \
    --notes "Release ${tag}" \
    --repo "$PRIVATE_REPO" 2>/dev/null || {
    warn "Release ${tag} may already exist on ${PRIVATE_REPO}, uploading asset..."
    gh release upload "$tag" "$zip_file" --clobber --repo "$PRIVATE_REPO" 2>/dev/null || true
  }
  ok "Release created on ${PRIVATE_REPO}"

  # ── Step 6: Push public repos (README + install scripts only) ──
  log "Pushing to public repos..."

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # Prepare public content
  cp "$SCRIPT_DIR/README.md" "$tmp_dir/README.md"
  cp "$SCRIPT_DIR/install.sh" "$tmp_dir/install.sh"
  cp "$SCRIPT_DIR/install.bat" "$tmp_dir/install.bat"
  cat > "$tmp_dir/.gitignore" << 'EOF'
.DS_Store
.u-maker/
.claude/
node_modules/
*.log
__pycache__
EOF

  # Init temp git repo and push to public repos
  (
    cd "$tmp_dir"
    git init -q
    git checkout -q -b main
    git add -A
    git commit -q -m "Release ${tag}"
    git tag -a "$tag" -m "Release ${tag}"

    # Get tokens from gh auth
    local public_token upleat_token
    public_token="$(gh auth token)"
    upleat_token="$(gh auth token)"

    # Push to thinoo-v2/u-maker-production
    git remote add public "https://x-access-token:${public_token}@github.com/${PUBLIC_REPO}.git"
    git push public main --force 2>/dev/null
    git push public "$tag" --force 2>/dev/null
    ok "Pushed to ${PUBLIC_REPO}"

    # Push to upleat-ax/u-maker-plugin
    git remote add upleat "https://x-access-token:${upleat_token}@github.com/${UPLEAT_REPO}.git"
    git push upleat main --force 2>/dev/null
    git push upleat "$tag" --force 2>/dev/null
    ok "Pushed to ${UPLEAT_REPO}"
  )

  rm -rf "$tmp_dir"

  # ── Step 7: Create Releases on public repos ──
  local release_notes
  release_notes="## u-maker ${tag}

### Install

**macOS / Linux:**
\`\`\`bash
curl -fsSL https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.sh | bash
\`\`\`

**Windows (PowerShell):**
\`\`\`powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -OutFile install.bat; .\\install.bat; Remove-Item install.bat
\`\`\`"

  for repo in "$PUBLIC_REPO" "$UPLEAT_REPO"; do
    log "Creating release on ${BOLD}${repo}${NC}..."
    gh release create "$tag" "$zip_file" \
      --title "u-maker ${tag}" \
      --notes "$release_notes" \
      --repo "$repo" 2>/dev/null || {
      warn "Release may exist, uploading asset..."
      gh release upload "$tag" "$zip_file" --clobber --repo "$repo" 2>/dev/null || true
    }
    ok "Release created on ${repo}"
  done

  # ── Step 8: Cleanup ──
  rm -f "$zip_file"

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  Deploy complete!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  Version: ${BOLD}${tag}${NC}"
  echo -e "  Private: https://github.com/${PRIVATE_REPO}"
  echo -e "  Public:  https://github.com/${PUBLIC_REPO}"
  echo -e "  Public:  https://github.com/${UPLEAT_REPO}"
  echo ""
  echo -e "  ${BOLD}Install (macOS/Linux):${NC}"
  echo -e "  curl -fsSL https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.sh | bash"
  echo ""
  echo -e "  ${BOLD}Install (Windows):${NC}"
  echo -e "  Invoke-WebRequest -Uri https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -OutFile install.bat; .\\install.bat"
  echo ""
}

# ============================================================
# Main
# ============================================================

case "${1:-}" in
  --check)
    cmd_check
    ;;
  --help|-h)
    echo "Usage:"
    echo "  ./deploy_github.sh              # auto-bump patch & deploy"
    echo "  ./deploy_github.sh 1.2.0        # deploy specific version"
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
