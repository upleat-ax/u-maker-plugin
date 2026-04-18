---
name: u-plan
description: "This skill should be used when the user asks to 'plan', 'create SRS', 'generate IA', 'add requirements', '/u-plan', or wants to produce Plan phase documents (SRS + IA) from an already-prepared digest."
version: 4.0.0
triggers:
  - "/u-plan"
  - "plan phase"
  - "SRS"
  - "IA"
  - "requirements"
---

# u-plan — Plan Phase (SRS + IA Generation)

`/u-plan [--auto] [--loop] [--app {name}]`

Plan phase: consume `data/digest/` (already populated by `/u-prepare` or `/u-analyze`) and produce `docs/{app}/plan/srs.md+json` and `docs/{app}/plan/ia.md+json`. This skill covers the **Plan.Plan** sub-phase of the PBGD workflow (v4.0); the preceding Preparation sub-phase is handled by `/u-prepare`.

**Primary Agent:** u-agent-plan
**Engine Dependencies:** doc-engine, dep-engine
**PBGD Phase:** Plan.Plan

> **Migration note (v3.x → v4.0):** The old Steps 1–2 of this skill (dropzone scan + digest generation) have been extracted into `/u-analyze` under the Preparation sub-phase. `/u-plan` now starts from a populated digest. If `data/digest/` is empty, `/u-plan` errors with instructions to run `/u-prepare` first.

## Preconditions

- `data/digest/` is populated (at least one `.digest.json` file).
- `data/digest/_index.json` has no `pending` or `processing` entries.
- (Optional) `data/digest/_clarifications.json` from 요구사항 협의.

If preconditions are not met → fail fast with: `"Run /u-prepare (or /u-analyze) first to populate data/digest/."`

## Execution Flow

### Step 1: Generate SRS

1. Load all digest files from `data/digest/` and `_clarifications.json` (if present).
2. Aggregate: functional requirements, non-functional requirements, stakeholders, constraints, glossary — applying the rules in `skills/u-analyze/references/analysis-rules.md` §3.
3. Apply ID 10-increment rule (FR-010, NFR-010, US-010, FT-010) — remap digest-level temporary IDs.
4. Build traceability chains: FR→US→FT.
5. Render `_meta/templates/srs.template.md` → `docs/{app}/plan/srs.md`.
6. Generate `docs/{app}/plan/srs.json` (doc-companion schema, `phase: "plan"`, `subPhase: "plan"`).
7. Update `data/links.json` with `derives` edges from digest nodes → SRS item nodes.

### Step 2: Generate IA

1. Load SRS (screens, navigation references) and any screen descriptions from the digest.
2. Derive site map, page inventory, navigation structure, user flows.
3. Apply ID 10-increment (IA-010, IA-020, …).
4. Render `_meta/templates/ia.template.md` → `docs/{app}/plan/ia.md`.
5. Generate `docs/{app}/plan/ia.json` (doc-companion schema, `phase: "plan"`, `subPhase: "plan"`).
6. Update `data/links.json` with `references` edges IA→SRS.

### Step 3: Prompt for wireframe (interactive only)

After Plan docs are saved, prompt:

```
Plan docs saved. Wireframe generation (/u-wireframe) can take 10-30+ min.
Run it now? [y/N]
```

- Yes → delegate to `/u-wireframe --app {app}`.
- No → print: `"Skipped. Run /u-wireframe --app {app} later when ready."`

Skipped when `--auto` is set (unless `--auto --wireframe` is passed).

### Step 4: Gatekeeper (if `--loop`)

1. Invoke u-agent-gatekeeper on Plan documents (srs.md, ia.md).
2. If avg score < 95 → receive improvement list → re-execute Steps 1–2 with the feedback.
3. Max 3 retries.
4. On final fail → write gate report and surface to the user; do **not** auto-proceed to Build.

## Reference Files

- **`references/srs-spec.md`** — SRS structure rules, 4-tier hierarchy (FR→US→FT), ID conventions.
- **`references/ia-spec.md`** — IA structure rules, site map generation, user flow patterns.
- **`references/figma-analysis.md`** — Figma-specific planning content consumption (when digests carry Figma extraction).

## Related Commands

- `/u-prepare` — Upstream umbrella that populates `data/digest/` before `/u-plan` can run.
- `/u-analyze` — Upstream discrete analysis command (same role within `/u-prepare`).
- `/u-wireframe` — Downstream, prompted after `/u-plan` completes.
- `/u-build` — Next phase after Plan (orchestrates `/u-design` ↔ `/u-dev`).
