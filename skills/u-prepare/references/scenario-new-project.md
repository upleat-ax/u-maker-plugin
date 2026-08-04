# Scenario A — New Project

> Detailed flow for `/u-prepare` when starting from an empty directory with no existing source code. PBGD Plan.Prepare, v4.0.

## 1. Precondition check

| Check | Expected |
|-------|----------|
| Project root has no recognizable source manifest (package.json, pom.xml, go.mod, pyproject.toml, Cargo.toml, etc.) | ✓ |
| `.u-maker/` is absent or empty | ✓ |
| User has a rough idea of what they want to build | ✓ |

If the project root **does** contain source code but the user explicitly wants to plan from scratch (ignoring existing code), pass `--scenario A` to override.

## 2. Flow

```
┌─ Step 1. /u-prepare-foldertree {app-name}
│    creates .u-maker/ with fresh v4 schema
│
├─ Step 2. Prompt user to populate dropzone
│    "Drop files (PDFs, Word, Figma links, notes) into
│     .u-maker/data/dropzone/, then reply 'done'."
│
├─ Step 3. /u-analyze --app {app-name}
│    hashes, extracts, writes data/digest/*.json
│
├─ Step 4. 요구사항 협의 (gap analysis Q&A)
│    writes data/digest/_clarifications.json
│
└─ Step 5. Print Preparation summary
```

## 3. Typical inputs

- **RFP / proposal PDFs** — richest source for requirements
- **Meeting notes** (.md, .docx) — stakeholder intent, pain points
- **Figma links** — screen-planning content (기업용 시스템)
- **Spreadsheets** — requirement/stakeholder matrices
- **Drafts of user stories** — for direct consumption into SRS

## 4. Minimum viable preparation

You can proceed to `/u-plan` after Step 4 even if the digest is sparse — but the resulting SRS will be short. Aim for at least:

- 1 source document with a clear problem statement
- ≥ 5 extractable requirements
- ≥ 2 stakeholders with distinct roles

If these minima are not met, `/u-prepare` should warn but not block.

## 5. Hand-off

Final state hands off to `/u-plan` via `data/digest/` and `data/digest/_clarifications.json`. No further action needed from the user before `/u-plan`.
