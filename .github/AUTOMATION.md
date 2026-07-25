# Release Automation

This repo now ships two GitHub Actions workflows that automate the release flow that previously required running `deploy_github.sh` + `deploy_vercel.sh` locally.

## Workflows

| File | Trigger | What it does |
|---|---|---|
| `.github/workflows/release.yml` | `git push origin v*` (tag push) | Builds `umaker-plugin-${TAG}.zip` → creates GitHub Release on this repo → force-syncs README/HTML/install scripts to `upleat-ax/umaker-plugin` → creates Release on the public repo |
| `.github/workflows/vercel-deploy.yml` | push to `main` touching `README*.html`, `GET_STARTED.html`, `.claude-plugin/plugin.json`, or this workflow itself · `workflow_dispatch` manual run | Deploys the 3 HTML docs to `umaker.upleat.ai` via Vercel CLI (production), then curls each page to verify 200 |

## Required GitHub Secrets

Set under **Settings → Secrets and variables → Actions** for this repo (`thinoo-v2/umaker-plugin`).

| Secret | Used by | How to obtain |
|---|---|---|
| `UPLEAT_PUBLISH_TOKEN` | `release.yml` | Personal Access Token (classic) with `repo` scope, on an account that can push to `upleat-ax/umaker-plugin`. Already configured. |
| `VERCEL_TOKEN` | `vercel-deploy.yml` | https://vercel.com/account/tokens → "Create Token" → scope it to the project's team. **Needs to be added manually.** |

Vercel `orgId` / `projectId` do not need to be secrets — they are committed in `.vercel/project.json` and read by `vercel pull` at job runtime.

## Standard Release Flow (post-automation)

```bash
# 1. Pull latest main, bump plugin.json version (or let deploy_github.sh do it)
git checkout main && git pull

# 2. Update CHANGELOG.md with a new entry for the version (narrative — keep doing this by hand)

# 3. Update README*.html / GET_STARTED.html if any user-facing changes need to land
#    (catalog rows, SVG breakdown, etc.) — manual for now

# 4. Open a PR with the docs + CHANGELOG, merge to main
#    → vercel-deploy.yml automatically refreshes umaker.upleat.ai

# 5. Tag and push:
VERSION="4.0.0-alpha.14"   # whatever
git tag -a "v${VERSION}" -m "Release v${VERSION}"
git push origin "v${VERSION}"
#    → release.yml automatically:
#      - builds zip
#      - creates Release on this repo
#      - syncs to upleat-ax/umaker-plugin
#      - creates Release on the public repo
```

## Local Fallback

The two original scripts (`deploy_github.sh`, `deploy_vercel.sh`) still work and remain the authoritative local fallback if Actions are disabled or you need to deploy from a workstation. They contain logic that the workflows mirror, not extend — keep them in sync if you change the publishable file set.

## Verification

- After a tag push, check **Actions → Release** for green status, and verify:
  - https://github.com/thinoo-v2/umaker-plugin/releases (new tag with zip asset)
  - https://github.com/upleat-ax/umaker-plugin/releases (mirrored)
  - https://raw.githubusercontent.com/upleat-ax/umaker-plugin/main/install.sh (up-to-date)
- After a main push to docs, check **Actions → Vercel Deploy** for green status, and verify https://umaker.upleat.ai/ shows the new version.

## What's still manual

- **`CHANGELOG.md` entry** — automation can pull commits, but the narrative ("why this change matters") needs a human. Keep editing the file before tag push.
- **Catalog table rows for new skills** in `README.md` and the 3 HTML pages. Adding a skill = adding a row.
- **SVG layer breakdown in `GET_STARTED.html`** (`Plan(N) + Build(M) + ...`) when a skill is added/moved.

If those become tedious, consider opening an issue to add a `release_prep.sh` generator that reads `skills/*/SKILL.md` frontmatter to auto-generate catalog rows.
