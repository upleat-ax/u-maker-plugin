# Changelog

All notable changes to u-maker-plugin.

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
- `u-agent-build` — Build-phase orchestrator agent.
- `u-agent-deploy` — Deploy-phase agent.
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
