---
name: u-prepare-foldertree
description: "This skill should be used when the user asks to '/u-prepare-foldertree', 'scaffold .u-maker', 'migrate .u-maker', 'initialize project structure', 'u-maker 폴더 생성', 'u-maker 폴더트리', '.u-maker 마이그레이션', or as a sub-step of /u-prepare. Granular folder/state initialization only — no ingest or analysis."
version: 4.0.0
---

# u-prepare-foldertree — .u-maker Folder/State Scaffolding

`/u-prepare-foldertree [--app {name}] [--loop] [--migrate]`

Create or migrate the `.u-maker/` folder tree for a project. This is the **foldertree-only** granular step within the Preparation sub-phase of the PBGD workflow (v4.0). Invoked automatically as the first step of `/u-prepare`, or directly by the user when only the scaffolding is needed.

**Primary Agent:** u-agent-pm
**Engine Dependencies:** (none — this is a bootstrap command)
**PBGD Phase:** Plan.Prepare (granular)
**Parent umbrella:** `/u-prepare` (use `/u-init` as alias)

> **Note:** In v3.x this skill was named `u-init`. In v4.0 (PBGD) the name was changed to make its granular purpose explicit. `/u-init` now aliases to `/u-prepare` (the umbrella), not to this skill.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--app {name}` | No | App scope / default app name. Positional `app-name` also accepted. If omitted, ask user. |
| `--loop` | No | No-op for this command (no scoreable output). Accepted for cross-command parameter consistency; ignored silently. |
| `--migrate` | No | Force migration mode even if `.u-maker/` already exists |

## Execution Flow

### Step 0: Detect Existing Structure

Scan project root for known `.u-maker/` layouts:

| Detected | Version | Action |
|----------|---------|--------|
| No `.u-maker/` found | — | Fresh init (Step 1) |
| `.u-maker/u-maker.config.json` with `"version": "4.0"` | v4 (current) | Already initialized. Print status and exit. |
| `.u-maker/u-maker.config.json` with `"version": "3.x"` | v3.1 | Migrate (Step 2) |
| `.u-maker/u-ssot.config.json` | v2 | Migrate (Step 2) |
| `.u-maker/_dropzone/` or `.u-maker/_input/` (no config) | v3.0 | Migrate (Step 2) |
| `.u-maker/apps/` directory exists | v3.0-early | Migrate (Step 2) |

### Step 1: Fresh Initialization

#### 1.1–1.5.1 Create v4 folder tree + bootstrap files

Create the v4 directory tree and write the 5 bootstrap files (`u-maker.config.json`, `data/links.json`, `data/digest/_index.json`, `.state/loop-state.json`, `.env.example` + `.env`).

Full tree + initial file contents → **see `references/foldertree-layout.md`**.

#### 1.6 Generate Initial Index Files

Render the three root index HTML files from their templates with empty/initial data:

1. **`.u-maker/index.html`** — from `_meta/templates/root-index.template.html`
   - `projectName` = app-name, `projectDescription` = "", `apps` = [{name: app-name, docCount: 0}], all counts = 0
2. **`.u-maker/output/index.html`** — from `_meta/templates/output-root-index.template.html`
   - `projectName` = app-name, `apps` = [{name: app-name, initial: first char uppercase, planCount/designCount/checkCount: 0, planDocs/designDocs/checkDocs: []}]
3. **`.u-maker/output/{app}/index.html`** — from `_meta/templates/output-index.template.html`
   - `appName` = app-name, all item arrays empty, all counts = 0
4. **`.u-maker/reports/index.html`** — from `_meta/templates/reports-index.template.html`
   - `projectName` = app-name, `reportCount` = 0, `reports` = []

#### 1.7 Update `.gitignore`

Append these lines to the project root `.gitignore` (create if absent, skip lines that already exist):

```
# u-maker runtime
.u-maker/.state/
.u-maker/output/
.u-maker/reports/
.u-maker/.env
```

`.u-maker/.env.example` is committed; only the real `.env` (with secrets) is ignored.

#### 1.8 Print summary

```
u-maker foldertree ready.
  App:    {app-name}
  Root:   .u-maker/
  Next:   Run /u-prepare --app {app-name} to ingest files/links and analyze
          (or drop files into .u-maker/data/dropzone/ and run /u-analyze directly)
```

### Step 2: Migration from Legacy Structures

When a legacy `.u-maker/` is detected, migrate to v4. **Never delete data — only move and restructure.**

Steps 2.0–2.5: pre-migration backup → version-specific path-mapping matrix (v2 / v3.0 / v3.1) → recreate missing dirs + files → clean empty legacy → ask about backup removal.

Full migration matrices + post-move steps → **see `references/migration-rules.md`**.

#### 2.6 Print migration summary

```
u-maker migrated from {detected-version} → v4.
  Moved:    {N} files
  Created:  {N} new directories
  Skipped:  {list of non-empty legacy dirs, if any}
  Backup:   .u-maker.bak-{timestamp}/ (kept/removed)
  Next:     Run /u-prepare --app {app} to resume ingest+analysis
            (or /u-plan --app {app} if digest is already populated)
```

## Error Handling

| Condition | Action |
|-----------|--------|
| `.u-maker/` already v4 and no `--migrate` | Print "Already initialized (v4). Use --migrate to force re-migration." |
| No write permission | Error: "Cannot write to project root. Check permissions." |
| Backup creation fails | Abort migration. Do not modify any files. |
| File move conflict (target exists) | Keep newer file. Log both paths for user review. |

## Reference Files

- **`_meta/schemas/config.schema.json`** — Config file schema (version, project, defaults)
- **`_meta/templates/u-maker-env.template`** — `.u-maker/.env.example` content (credential keys consumed by skills)
- **`skills/u-engine/references/dep-engine.md`** — links.json initialization spec
