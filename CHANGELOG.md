# Changelog

All notable changes to u-maker-plugin.

## [4.0.0-alpha.14] — 2026-05-24

**Internal: CI/CD automation — Release + Vercel deploy GitHub Actions workflows.**

No user-facing plugin changes. Adds GitHub Actions to automate the release flow that previously required running `deploy_github.sh` + `deploy_vercel.sh` by hand. This is the first release executed end-to-end through the new pipeline.

### Added

- **`.github/workflows/release.yml`** — on `git push origin v*` (tag push): build `u-maker-plugin-${TAG}.zip` → GitHub Release on this repo (via `softprops/action-gh-release`) → force-sync README + HTML + install scripts to `upleat-ax/u-maker-plugin` → GitHub Release on the public repo with the same zip.
- **`.github/workflows/vercel-deploy.yml`** — on `main` push touching `README*.html` / `GET_STARTED.html` / `.claude-plugin/plugin.json` / the workflow file itself, plus manual `workflow_dispatch`: copy the 3 HTML docs + project link → `vercel pull` → `vercel deploy --prod` → curl-verify each public URL on `umaker.upleat.ai`.
- **`.github/AUTOMATION.md`** — maintainer guide covering both workflows, required secrets (`UPLEAT_PUBLISH_TOKEN`, `VERCEL_TOKEN`), the standard release flow after automation, the local fallback scripts, and what is still manual (CHANGELOG narrative, catalog table rows, SVG layer breakdown).

### Removed

- **`.github/workflows/publish.yml`** — superseded by `release.yml`. The old workflow only mirrored README + install scripts on tag push without building a zip or creating a Release.

### Notes

- Required secret `VERCEL_TOKEN` was added to repo settings; existing `UPLEAT_PUBLISH_TOKEN` is reused for the public-repo sync.
- Local scripts `deploy_github.sh` / `deploy_vercel.sh` remain as authoritative fallbacks; the workflows mirror their logic rather than extend it. Keep them in sync if you change the publishable file set.
- Post-automation standard release flow (see AUTOMATION.md):
  1. Edit `CHANGELOG.md` + bump `plugin.json` + sync README/HTML version strings.
  2. Open a PR, merge to main — `vercel-deploy.yml` refreshes `umaker.upleat.ai` automatically.
  3. `git tag -a vX.Y.Z` + `git push origin vX.Y.Z` — `release.yml` handles zip + both Releases + public-repo sync automatically.

## [4.0.0-alpha.13] — 2026-05-24

**Changed: 28-skill quality review fixes — sanitize, trigger hardening, progressive disclosure, Korean coverage, official-schema compliance.**

Comprehensive cleanup pass on all 28 skills following a multi-agent (5 reviewer) quality review. Touches every `skills/*/SKILL.md`, sanitizes `u-meeting-report/AGENTS.md`, and introduces 14 new `references/*.md` files for progressive disclosure. Plugin remains backward-compatible — no command renames, no behaviour changes; only documentation, frontmatter, and split-file organization.

### Fixed (Critical)

- **`skills/u-meeting-report/`** — frontmatter `name` was incorrectly `the-voice-meeting` (a separate system skill) → corrected to `u-meeting-report`. All 9 internal references to `~/.claude/skills/the-voice-meeting/...` (scripts, assets, `.env`) replaced with `${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/...`. Removed `/Users/thinoo/...` absolute path leak from `AGENTS.md`. The plugin's bundled `scripts/`, `assets/`, and `references/` for this skill are now actually consumed; the plugin is standalone-portable.
- **`skills/u-wireframe/SKILL.md`** — frontmatter `version: 3.2.0` → `4.0.0` (matches all peer phase skills).

### Changed (High)

- **Generic trigger hijack mitigation (6 skills)** — replaced overly-broad triggers that intercepted unrelated input with `u-maker`/`Turborepo` prefix qualifiers:
  - `u-qa`: `"QA"` → `"u-maker QA"`, `"u-qa runtime QA"`
  - `u-init`: `"initialize"` → `"u-maker init"`, `"u-maker initialize project"`
  - `u-check`: `"check phase"` → `"u-maker check"`, `"u-maker gatekeeping check"`
  - `u-createproject`: Korean generic `"프로젝트 생성"`/`"새 프로젝트"`/`"모노레포 생성"` → `"u-maker 프로젝트 생성"`/`"Turborepo 모노레포 스캐폴드"` etc.
  - `u-loop`: `"auto loop"`/`"full pipeline"` → `"u-maker auto loop"`/`"u-maker full pipeline"`
  - `u-tools-browser`: added missing `"playwright"`, `"agent-browser"`, `"screenshot"`, `"visual regression"`, `"a11y audit"`, `"figma parity"` so DS verify / capture flows match correctly.
- **`skills/u-engine/SKILL.md`** — description rewritten as internal-only (`INTERNAL INFRASTRUCTURE — not directly invoked by users`) to prevent LLM auto-invocation. 50-line `HTML Generation Protocol` body collapsed into pointer to existing `references/html-engine.md`. 110 → 68 lines.
- **Progressive disclosure refactor (6 large skills → 14 new `references/*.md`)** — total 2,050 → 1,339 lines (-35%):

  | Skill | Before | After | Δ | new refs |
  |---|---:|---:|---:|---:|
  | `u-tools-browser` | 501 | 305 | -39% | 4 (`backend-detection`, `visual-verify-ds`, `visual-verify-components`, `failure-handling`) |
  | `u-prepare-foldertree` | 285 | 126 | -56% | 2 (`foldertree-layout`, `migration-rules`) |
  | `u-output` | 286 | 175 | -39% | 2 (`screens-rendering`, `erd-rendering`) — folder newly created |
  | `u-tools-jenkins-deploy` | 365 | 309 | -15% | 3 (`credentials`, `nginx-tls`, `jenkins-gotchas`) |
  | `u-tools-git-pr` | 301 | 189 | -37% | 2 (`classification-rules`, `confirmation-ux`) |
  | `u-wireframe` | 312 | 235 | -25% | 1 (`wireframe-rendering-rules`) |

### Added

- **Korean trigger coverage** — 22 skills enriched. 26/28 skills are now Korean-searchable in addition to English (e.g., `"u-maker 기획"`, `"와이어프레임 생성"`, `"u-maker 배포"`, `"피그마 분석"`). `u-engine` is internal-only by design; `u-meeting-report` is covered via description-only Korean keywords.

### Changed (Frontmatter standardization)

- **All 26 skills** with a non-standard `triggers:` array migrated to the **official Claude Code schema** (`name`/`description`/`version` only). Every trigger keyword (English + Korean) was preserved by integrating them into `description` as quoted strings, matching the convention of all 5 official `plugin-dev/*` skills. Max resulting description length: 637 chars (`u-tools-browser`). This guarantees skill matching works even if the runtime ignores the non-spec `triggers:` field. `u-engine` and `u-meeting-report` were already description-only.

### Notes

- File stats: 43 files changed in PR #85, +1,118 / −1,019.
- Smoke test (manual, post-merge): in a fresh Claude Code session, type `/u-` to confirm all 28 skills autocomplete without duplicates, and try Korean phrases (`"u-maker 기획"`, `"와이어프레임 생성"`, `"회의록 작성"`) to confirm description-only matching.
- No migration required for existing projects — only documentation/frontmatter changed; no command renames or behavior changes.

## [4.0.0-alpha.12] — 2026-05-23

**Added: `.u-maker/.env` credential file + `/u-tools-jenkins-deploy` skill.**

Introduces a project-local credential file at `.u-maker/.env` (gitignored) for skills that need to authenticate to external systems, and ports the `u-tools-jenkins-deploy` skill into the plugin as the inaugural consumer.

### Added

- **`_meta/templates/u-maker-env.template`** — `.env.example` content. Enumerates credential keys consumed by skills: Jenkins (`JENKINS_URL`/`JENKINS_USER`/`JENKINS_TOKEN`, plus optional `JENKINS_SSH_*`), Docker Hub (`DOCKERHUB_NAMESPACE`/`DOCKERHUB_USER`/`DOCKERHUB_TOKEN`), Git host PAT (`GIT_HOST_USER`/`GIT_HOST_PAT`), and deploy-target SSH (`DEPLOY_TARGET_HOST`/`DEPLOY_TARGET_USER`/`DEPLOY_TARGET_PASS`/`DEPLOY_TARGET_PORT`). Empty values mean "ask interactively when needed."
- **`/u-prepare-foldertree` Step 1.5.1** — On fresh init, writes `.u-maker/.env.example` and bootstraps `.u-maker/.env` from the template (never overwrites an existing `.env`). Migration path (Step 2.3) does the same for legacy projects.
- **`/u-prepare-foldertree` Step 1.7** — Adds `.u-maker/.env` to the project `.gitignore` so secrets never land in git. `.env.example` is committed.
- **`skills/u-tools-jenkins-deploy/`** (new) — Jenkins CI/CD setup skill ported from `~/.claude/skills/u-maker__u-tools-jenkins-deploy/`. Same Phase 1–8 pipeline (Jenkinsfile generation → credential registration → job creation → nginx + TLS → webhook/polling → first build) plus a new **Phase 0** that loads `.u-maker/.env` and resolves Jenkins/Docker Hub/Git/target-SSH credentials before prompting. Precedence: CLI flag → `.u-maker/.env` → interactive prompt. Templates (`Jenkinsfile`, `Dockerfile`, `Dockerfile.dockerignore`, `nginx-server-block`) ship under `templates/`.

### Why

Without `.u-maker/.env`, every Jenkins / Docker Hub / SSH setup forced the user to paste tokens and passwords directly into chat — captured in transcripts, easily leaked, and re-asked on every session. A project-local, gitignored env file lets users set credentials once and have skills consume them on demand. The `/u-tools-jenkins-deploy` skill is the first consumer; subsequent skills can extend the same file rather than each inventing their own location.

### Notes

- `.u-maker/.env.example` is committed verbatim from `_meta/templates/u-maker-env.template`. Adding a new key for another skill = edit the template; future `/u-prepare-foldertree` runs propagate it to new projects.
- Existing projects pick up the file on the next `/u-prepare-foldertree --migrate` (or any rerun — Step 2.3 is idempotent).

## [4.0.0-alpha.5] — 2026-04-19

**Changed: Figma parity is now a mandatory hard gate.**

When a Design System originated from Figma (extracted via `/u-tools-figma-ds` or registered with `dsFileKey` in `data/figma/manifest.json`) and is implemented as HTML/CSS, the browser MUST verify identity with Figma. Previously this was an opt-in pixel diff; now it is a non-skippable parity check that blocks `/u-design` and `/u-dev` from completing on failure.

### Changed

- `/u-tools-browser` Step 6e (DS HTML Verification) — added sub-step **6e.8 Figma parity check (mandatory)**:
  - Pulls Figma reference screenshots via `mcp__plugin_figma_figma__get_screenshot` and Variable defs via `get_variable_defs`.
  - Token parity: every Figma Variable mapped to a CSS variable must match (color ΔE < 1 in OKLCH; dimensions ±0.5 px).
  - Per-frame screenshot diff: SSIM ≥ 0.95 AND pixel diff ≤ 5 %.
  - Coverage parity: every Figma component ↔ every `CMP-{nnn}` in the HTML.
  - Unauthenticated Figma session → HALT (never silent skip). Override with `--no-figma-parity` (logged).
  - `result` rules tightened: any parity failure forces top-level `result == "fail"` (cannot be downgraded to `partial`).
- `/u-tools-browser` Step 6f (Component Verification) — Figma diff promoted from "optional" to **mandatory** when `components[*].figmaKey` is set:
  - Per-variant / per-state pixel diff (SSIM ≥ 0.95, pixel diff ≤ 5 %, bounds ±2 px).
  - Token resolution parity against Figma Variable bindings.
  - Same HALT-on-unauthenticated rule as Step 6e.
- `/u-tools-browser` Options — added `--no-figma-parity`, `--figma-diff-threshold {pct}` (default 5), `--figma-ssim-threshold {0..1}` (default 0.95).
- `/u-tools-browser` Anti-patterns — explicit prohibitions: silently skipping parity, downgrading parity failure to `partial`, try/catch-ing the parity check away.
- `/u-design` Step 4a.10 — promoted to **hard gate**. On parity `fail`, re-runs Steps 4a.3–9 (max 3 retries); never proceeds to Step 4b without parity pass. `partial` allowed only for non-parity issues.
- `/u-dev` Step 1.5 — promoted to **hard gate**. On parity `fail`, re-runs Step 1 for failing components only (max 3 retries); never proceeds to Step 2 (BE) without parity pass.

### Rationale

When the user describes the workflow as "extract DS from Figma → implement in HTML/CSS → verify identical", the browser is the only authority that can confirm "identical". Anything weaker (token-only diff, manual review) misses CSS specificity, browser rendering quirks, and unbound hardcoded values. Making the gate mandatory ensures the implemented DS cannot ship with silent visual drift from its Figma source.

### Added

- `--no-figma-parity` flag for explicit, audited overrides (e.g., when intentionally diverging).
- Per-component diff PNG triplets (figma / impl / diff) under `.u-maker/.state/visual-verify/diffs/`.

## [4.0.0-alpha.4] — 2026-04-19

**Added: Browser-driven visual verification for HTML-first DS and implemented components.**

After `/u-design` Step 4a writes `out/{app}/design/design-system.html` and after `/u-dev` Step 1 generates FE components, the browser now verifies them automatically — no manual "open the file and look" loop.

### Added

- `/u-tools-browser` Step 6e — **Design System HTML Verification**. Opens the static `design-system.html` via `file://`, samples every `:root` CSS variable, asserts every `CMP-{nnn}` showcase + variant + state selector is present, toggles `[data-theme="dark"]`, runs a Lighthouse / axe-core a11y audit, and captures full-page light + dark screenshots. Result persisted at `.u-maker/.state/visual-verify/{app}-design-system.json`.
- `/u-tools-browser` Step 6f — **Component Implementation Verification**. Renders each `CMP-{nnn}` in Storybook (preferred) or the app, samples computed styles, asserts variant/state selectors, optionally pixel-diffs against the linked Figma component (when `figmaKey` is set), runs per-subtree a11y audit. Result at `.u-maker/.state/visual-verify/{app}-components.json`.

### Wired

- `/u-design` Step 4a.10 — auto-delegates to `/u-tools-browser` Step 6e after `design-system.html` is written. On `result == "fail"` (missing tokens, broken dark mode, WCAG-AA contrast violation), re-runs Steps 4a.3–9 with the diff as improvement list (max 3 retries).
- `/u-dev` Step 1.5 — auto-delegates to `/u-tools-browser` Step 6f after FE components are generated. On `result == "fail"`, re-runs Step 1 for failing components only (max 3 retries). Skipped when `--only be|db` or zero FE files changed.
- `/u-tools-browser` Consumer Integration Table — two new rows for the 6e / 6f entries.

### Notes

- Both verifications are **mandatory** under default mode (`--auto` runs them headless). The `--no-screenshot` flag suppresses captures but still runs the assertions.
- The Figma diff sub-step in 6f is **opt-in** — only runs when `mcp__plugin_figma_figma__get_screenshot` is reachable AND `components[*].figmaKey` is populated by `/u-tools-figma-ds`.

## [4.0.0-alpha.3] — 2026-04-19

**Added: Figma writer skills.**

Adds two new write-side skills under the `u-tools-*` namespace, complementing the existing read-only `/u-tools-figma` analyzer. Both delegate Figma mutations to the `figma` plugin (`figma:figma-generate-design`, `figma:figma-generate-library`) so u-maker stays as the orchestration layer.

### Added

- `/u-tools-figma-screen` — Screen-spec writer. Inputs: (Figma URL │ `screens.{md,json}`) + (Figma DS URL │ `design-system.{md,json,tsx,css}`). Outputs: Figma frames, `screens.md+json`, or both. Source-resolution matrix, conflict log under `.u-maker/.state/figma-screen-conflicts.json`, idempotent `--rerun` via persisted bundles. References: `source-resolution.md`, `conflict-resolution.md`, `delegation-bundle.md`.
- `/u-tools-figma-ds` — Code → Figma design-system writer. Input: `.tsx + .json + .css` (W3C tokens / Style Dictionary / CSS custom properties / Tailwind config). Output: Figma Variables (3 layers, light/dark modes, 10 scales) + master components + variants. References: `token-extraction.md`, `component-extraction.md`, `delegation-bundle.md`.

### Wired

- `/u-plan` Step 2.5 — auto-delegates to `/u-tools-figma-screen --output md` when both a screen-plan source and a design-system source are detected after IA generation. Pre-populates `screens.{md,json}` so `/u-design` Step 3 verifies-and-finalises instead of generating from scratch.
- `/u-analyze` Step 2.4 — auto-delegates to `/u-tools-figma-ds` when DS-applied source code (token files, `packages/tokens`, `packages/ui-*`) is detected in dropzone. Falls back to `--dry-run` when Figma is unauthenticated; bundle persisted for later replay.
- `/u-design` Step 4.5 — opt-in outbound sync to Figma for both screens (`/u-tools-figma-screen --output figma --prefer md`) and DS (`/u-tools-figma-ds`). Doc completion never blocks on Figma availability.

### Changed

- `.claude-plugin/plugin.json` — version `4.0.0-alpha.2` → `4.0.0-alpha.3`; skill count 25 → 27; description updated to mention the writer skills.
- README.md, README.ko.html, README.en.html, GET_STARTED.html — `u-tools-*` tables expanded with the two new entries.

### Removed

- `u-maker__u-ocean-wireframe2figma` — separately-installed legacy skill removed from `~/.claude/skills/` (the new u-tools-figma-screen replaces it).

## [4.0.0-alpha.1] — 2026-04-18

**Breaking change: PDCA → PBGD workflow migration.**

The plugin has been restructured from a 5-phase PDCA pipeline (Plan / Design / Dev / Check / Ship) to a 4-phase PBGD pipeline (Plan / Build / Gatekeeping / Deploy). This is a breaking change; follow the migration steps below when upgrading a v3.x project.

### Phase restructuring

| v3.x (PDCA) | v4.0 (PBGD) | Notes |
|-------------|-------------|-------|
| Plan (Steps 1–2: dropzone + digest) | `Plan.Prepare` (new) | Extracted into `/u-prepare` umbrella and `/u-analyze` skill |
| Plan (Steps 3–5: SRS + IA) | `Plan.Plan` | `/u-plan` scope narrowed to SRS/IA generation |
| (implicit) Wireframe | `Build.UIDesign` companion | `/u-wireframe` now prompted explicitly post-Plan (time-consuming) |
| Design | `Build.UIDesign` | Same doc outputs; new phase metadata |
| Dev | `Build.Development` | Same code outputs; new phase metadata |
| (implicit) Ping-pong | `Build` (umbrella) | New `/u-build` orchestrator with design↔dev ping-pong |
| Check | `Gatekeeping` | Renamed; now explicitly covers doc scoring + runtime QA |
| Ship | `Deploy` (new, expanded) | New `/u-deploy` with interactive target + artifact selection |

### Added

- `/u-prepare` — Preparation umbrella (foldertree + dropzone + analyze/reverse + 요구사항 협의).
- `/u-analyze` — Discrete dropzone → digest analysis skill (extracted from `/u-plan` Steps 1–2).
- `/u-build` — Build-phase orchestrator (design ↔ dev ping-pong).
- `/u-deploy` — Deploy-phase skill (interactive target + artifact selection, ≥ 98 gate, continuous regeneration).
- `/u-tools-figma` — Comprehensive Figma analyzer skill (pages + variants + assets + components + comments, semantic extraction). Auto-delegated from `/u-prepare`, `/u-analyze`, `/u-reverse`, `/u-design` on Figma sources. **Note:** v4.0.0-alpha.1 ships the reduced extraction path; full 6-phase pipeline (schema-strict manifest + 4-source variant detection) scheduled for the first post-GA release. Downstream consumers must tolerate `source.pipeline == "reduced"` digests (see `agents/u-agent-figma.md` §10).
- `u-agent-build` — Build-phase orchestrator agent.
- `u-agent-deploy` — Deploy-phase agent.
- `u-agent-figma` — Figma analyzer agent (reduced path in alpha).
- `_meta/schemas/deploy-manifest.schema.json` — Deploy manifest authoritative schema.
- `_meta/templates/{deploy-runbook,ci-github-actions,ci-vercel,ci-docker,env,release-notes,smoke-test}` — Deploy-phase templates.
- `hooks/on-deploy-state.js` — Continuous regeneration: marks deploy artifacts stale on SSoT drift.
- `.state/deploy-readiness.json` — Written by Gatekeeping after every run; read by Deploy as gate input.
- Schema additions: `workflow.phases` in config, `deployThreshold: 98` in gate-rules, phase/sub-phase enums in doc-companion and links.

### Renamed

- `skills/u-init/` → `skills/u-prepare-foldertree/` (granular `.u-maker` scaffolding only).
- `skills/u-check/` → `skills/u-gatekeeping/` (covers doc scoring + runtime QA).
- Output path: `docs/{app}/check/` → `docs/{app}/gatekeeping/` (migration handled by `/u-prepare-foldertree --migrate`).

### Alias layer (backward-compat)

- `/u-init` is now an **alias** of `/u-prepare` (the umbrella).
- `/u-check` is now an **alias** of `/u-gatekeeping`.
- `/u-qa` is now an **alias** of `/u-gatekeeping --only qa`.

Alias SKILL.md files print a one-line forwarding notice and route to the canonical command.

### Changed

- `/u-plan` scope narrowed: dropzone scanning + digest generation moved to `/u-analyze`. `/u-plan` now requires `data/digest/` to be populated.
- `u-agent-plan` now owns both Preparation sub-phase (via `/u-prepare`) and Plan sub-phase (via `/u-plan`).
- `u-agent-qa` renamed scope: Runtime QA sub-phase of Gatekeeping (formerly Check phase).
- `u-agent-gatekeeper` now emits `.state/deploy-readiness.json` after every run with both `passThreshold` (95) and `deployThreshold` (98) status.
- `u-agent-pm` rewritten with PBGD state machine + transition guards + alias resolution table.
- `u-loop` rewritten for PBGD sequence (Prepare → Plan → Build → Gatekeeping → Deploy) with `--skip-deploy` option.
- `hooks/on-gate-result.js` emits deploy-readiness regardless of loopActive state.
- `.claude-plugin/plugin.json`: version bumped; description and keywords updated for PBGD.

### Removed / Deprecated

- `skills/u-plan/references/ingest-flow.md` deleted — content moved to `skills/u-analyze/references/digest-extraction.md` and `analysis-rules.md`.
- `x-deprecated-pdca` block in `gate-rules.json` documents the retired PDCA gate names (no runtime effect).

### Migration checklist for v3.x projects

1. Back up `.u-maker/` (automatic via `/u-prepare-foldertree --migrate`).
2. Run `/u-prepare-foldertree --migrate` on the project root to rename `docs/{app}/check/` → `docs/{app}/gatekeeping/` and update `u-maker.config.json` to v4.0 schema.
3. Re-run `/u-analyze` if your dropzone state was mid-analysis before the upgrade.
4. Any custom scripts referencing `/u-init`, `/u-check`, `/u-qa` continue to work (aliases). Update to canonical names at your leisure.
5. Any custom tooling referencing `docs/{app}/check/` must be updated to `docs/{app}/gatekeeping/`.

---

## [3.4.10] — 2026-04-18

Final PDCA release. See git history for details.
