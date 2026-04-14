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
DOC_SYNC_FILES=(
  "$SCRIPT_DIR/README.ko.html"
  "$SCRIPT_DIR/README.en.html"
  "$SCRIPT_DIR/GET_STARTED.html"
)

PRIVATE_REPO="upleat-ax/u-maker-plugin"
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

refresh_docs() {
  local version="$1"

  log "Refreshing README* / GET_STARTED* docs for ${BOLD}${version}${NC}..."

  python3 - "$SCRIPT_DIR" "$version" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
version = sys.argv[2]

skills = sorted(root.joinpath("skills").glob("*/SKILL.md"))
skills_total = len(skills)
agents = len(list(root.joinpath("agents").glob("*.md")))
phases = 5
parts = 13

def apply(path_str, replacements):
    path = root / path_str
    if not path.exists():
        return
    text = path.read_text(encoding="utf-8")
    original = text
    for pattern, repl in replacements:
        text = re.sub(pattern, repl, text, flags=re.MULTILINE)
    if text != original:
        path.write_text(text, encoding="utf-8")

shared_readme_html = [
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">Skills</div></div>)', rf"\g<1>{skills_total}\g<2>"),
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">Agents</div></div>)', rf"\g<1>{agents}\g<2>"),
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">PDCA Phases</div></div>)', rf"\g<1>{phases}\g<2>"),
]

apply("README.ko.html", shared_readme_html)

apply("README.en.html", shared_readme_html + [
    (r">\d+ cross-cutting engines\.", f">{skills_total} cross-cutting engines."),
])

apply("GET_STARTED.html", [
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">Commands</div></div>)', rf"\g<1>{skills_total}\g<2>"),
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">AI Agents</div></div>)', rf"\g<1>{agents}\g<2>"),
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">PDCA Phases</div></div>)', rf"\g<1>{phases}\g<2>"),
    (r'(<div class="stat"><div class="stat-val">)\d+(</div><div class="stat-label">Parts</div></div>)', rf"\g<1>{parts}\g<2>"),
])
PY

  if ! git diff --quiet -- "${DOC_SYNC_FILES[@]}"; then
    git add "${DOC_SYNC_FILES[@]}"
    git commit -m "docs: refresh README and GET_STARTED artifacts"
    ok "README* / GET_STARTED* docs refreshed"
  else
    ok "README* / GET_STARTED* docs already up to date"
  fi
}

# ============================================================
# Commands
# ============================================================

cmd_check() {
  ensure_gh

  for repo in "$UPLEAT_REPO"; do
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
  log "Install (Windows CMD):"
  echo -e "  ${BOLD}curl -fsSL --ssl-no-revoke https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -o install.bat && install.bat && del install.bat${NC}"
  echo ""
  log "Install (Windows PowerShell):"
  echo -e "  ${BOLD}curl.exe -fsSL --ssl-no-revoke https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -o install.bat; .\\install.bat; del install.bat${NC}"
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

  # ── Step 0: Refresh docs before deploy ──
  refresh_docs "$version"

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
    hooks/ \
    _meta/ \
    deploy_local.sh \
    deploy_local.bat \
    install.sh \
    install.bat \
    install.ps1 \
    uninstall_local.sh \
    README.ko.html \
    README.en.html \
    GET_STARTED.html \
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
  cp "$SCRIPT_DIR/README.md" "$tmp_dir/README.md" 2>/dev/null || true
  cp "$SCRIPT_DIR/README.ko.html" "$tmp_dir/README.ko.html"
  cp "$SCRIPT_DIR/README.en.html" "$tmp_dir/README.en.html"
  cp "$SCRIPT_DIR/GET_STARTED.html" "$tmp_dir/GET_STARTED.html"
  cp "$SCRIPT_DIR/install.sh" "$tmp_dir/install.sh"
  cp "$SCRIPT_DIR/install.bat" "$tmp_dir/install.bat"
  cp "$SCRIPT_DIR/install.ps1" "$tmp_dir/install.ps1"
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

    # Get token for upleat repo (use UPLEAT_TOKEN env var, fallback to gh auth)
    local upleat_token
    upleat_token="${UPLEAT_TOKEN:-$(gh auth token)}"

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

**Windows (CMD):**
\`\`\`cmd
curl -fsSL --ssl-no-revoke https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -o install.bat && install.bat && del install.bat
\`\`\`

**Windows (PowerShell):**
\`\`\`powershell
curl.exe -fsSL --ssl-no-revoke https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -o install.bat; .\\install.bat; del install.bat
\`\`\`"

  for repo in "$UPLEAT_REPO"; do
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

  # ── Step 9: Clean local deployment ──
  log "Cleaning local deployment..."
  local deploy_local="$SCRIPT_DIR/deploy_local.sh"
  if [[ -x "$deploy_local" ]]; then
    bash "$deploy_local" --clean
    ok "Local deployment cleaned"
  else
    warn "deploy_local.sh not found, skipping local clean"
  fi

  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${GREEN}${BOLD}  Deploy complete!${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo -e "  Version: ${BOLD}${tag}${NC}"
  echo -e "  Private: https://github.com/${PRIVATE_REPO}"
  echo -e "  Public:  https://github.com/${UPLEAT_REPO}"
  echo -e "  Local:   ${GREEN}cleaned (use deploy_local.sh to reinstall)${NC}"
  echo ""
  echo -e "  ${BOLD}Install (macOS/Linux):${NC}"
  echo -e "  curl -fsSL https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.sh | bash"
  echo ""
  echo -e "  ${BOLD}Install (Windows CMD):${NC}"
  echo -e "  curl -fsSL --ssl-no-revoke https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -o install.bat && install.bat && del install.bat"
  echo ""
  echo -e "  ${BOLD}Install (Windows PowerShell):${NC}"
  echo -e "  curl.exe -fsSL --ssl-no-revoke https://raw.githubusercontent.com/${UPLEAT_REPO}/main/install.bat -o install.bat; .\\install.bat; del install.bat"
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
