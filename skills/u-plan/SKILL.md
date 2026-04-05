---
name: u-plan
description: "This skill should be used when the user asks to 'plan', 'ingest data', 'create SRS', 'generate IA', 'add requirements', '/u-plan', or wants to analyze raw data and produce Plan phase documents (SRS + IA)."
version: 4.0.0
triggers:
  - "/u-plan"
  - "plan phase"
  - "SRS"
  - "ingest"
  - "requirements"
---

# u-plan — Plan Phase

`/u-plan [--auto] [--loop] [--app {name}]`

Plan phase: analyze raw data from `data/dropzone/`, generate refined `data/digest/`, then produce `docs/{app}/plan/srs.md+json` and `docs/{app}/plan/ia.md+json`.

**Primary Agent:** u-agent-plan
**Engine Dependencies:** doc-engine, digest-engine, dep-engine

## Execution Flow

### Step 1: Scan Dropzone

1. Scan `data/dropzone/` for all files recursively
2. Compare against `data/digest/_index.json` hashes
3. Identify new/changed files requiring (re-)analysis
4. If no changes and existing digest → skip to Step 3

### Step 2: Generate Digest

For each new/changed file:

1. Read source file from `data/dropzone/{path}`
2. Analyze content: extract requirements, constraints, stakeholders, domain terms, workflows, pain points
3. Generate `data/digest/{mirror-path}/{filename}.digest.json` per `_meta/schemas/digest.schema.json`
4. Compute SHA-256 hash, store in `_index.json`
5. Mark status as `done` with `analyzedAt` timestamp

### Step 3: Generate SRS

1. Load all digest files from `data/digest/`
2. Aggregate: functional requirements, non-functional requirements, stakeholders, constraints, glossary
3. Apply ID 10-increment rule (FR-010, NFR-010, US-010, FT-010)
4. Build traceability chains: FR→US→FT
5. Render `_meta/templates/srs.template.md` → `docs/{app}/plan/srs.md`
6. Generate `docs/{app}/plan/srs.json` (doc-companion schema)
7. Update `data/links.json`

### Step 4: Generate IA

1. Load SRS (screens, navigation references)
2. Derive site map, page inventory, navigation structure, user flows
3. Apply ID 10-increment (IA-010, IA-020...)
4. Render `_meta/templates/ia.template.md` → `docs/{app}/plan/ia.md`
5. Generate `docs/{app}/plan/ia.json`
6. Update `data/links.json`

### Step 5: Gatekeeper (if --loop)

1. Invoke u-agent-gatekeeper on plan documents
2. If avg score < 95 → receive improvement list → re-execute Steps 3-4
3. Max 3 retries

## Reference Files

- **`references/ingest-flow.md`** — Dropzone scanning, digest generation details
- **`references/srs-spec.md`** — SRS structure rules, 4-tier hierarchy (FR→US→FT), ID conventions
- **`references/ia-spec.md`** — IA structure rules, site map generation, user flow patterns
