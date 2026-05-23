---
name: u-prepare-foldertree
description: "This skill should be used when the user asks to scaffold or migrate the .u-maker folder structure, via '/u-prepare-foldertree' (or as a sub-step of /u-prepare). Granular folder/state initialization only — no ingest or analysis."
version: 4.0.0
triggers:
  - "/u-prepare-foldertree"
  - "scaffold .u-maker"
  - "migrate .u-maker"
  - "initialize project structure"
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

Create the v4 folder structure:

```
.u-maker/
├── u-maker.config.json          # Project config (from config.schema.json)
├── .env.example                 # Credential template (committed, no secrets)
├── .env                         # Local credentials (NEVER committed)
├── data/
│   ├── dropzone/                # Raw file drop zone
│   ├── digest/                  # Analyzed digest JSONs
│   │   └── _index.json          # Hash index for change detection
│   ├── assumptions/             # Assumption tracking
│   ├── backlog/                 # Backlog items
│   └── links.json               # Traceability graph
├── docs/
│   ├── common/                  # Cross-app shared docs
│   └── {app}/                   # Per-app SSoT documents
│       ├── plan/                # srs.md+json, ia.md+json
│       ├── design/              # erd, api, screens, design-system
│       └── check/               # testcases, test-results
├── output/
│   ├── index.html               # Output root index (all apps listing)
│   └── {app}/                   # Generated HTML output
│       └── index.html           # Per-app navigation portal
├── reports/                     # Generated reports (daily, gate, summary)
│   └── index.html               # Reports index (chronological listing)
├── index.html                   # Root navigation hub
└── .state/
    ├── sessions/                # Session state files
    └── loop-state.json          # Auto-loop runtime state
```

#### 1.1 Create directories

Create all directories listed above. Replace `{app}` with the provided `app-name`.

#### 1.2 Write `u-maker.config.json`

```json
{
  "version": "4.0",
  "project": {
    "name": "{app-name}",
    "description": "",
    "apps": ["{app-name}"]
  },
  "workflow": {
    "phases": ["plan", "build", "gatekeeping", "deploy"]
  },
  "defaults": {
    "auto": true,
    "loop": false,
    "loopMaxRetries": 3,
    "gatekeeperThreshold": 95,
    "deployThreshold": 98
  }
}
```

#### 1.3 Write `data/links.json`

```json
{
  "version": "1.0.0",
  "lastUpdated": "{ISO-8601 now}",
  "nodes": [],
  "edges": []
}
```

#### 1.4 Write `data/digest/_index.json`

```json
{
  "version": "1.0.0",
  "files": {}
}
```

#### 1.5 Write `.state/loop-state.json`

```json
{
  "phase": null,
  "iteration": 0,
  "lastRun": null,
  "gateScores": {}
}
```

#### 1.5.1 Write `.env.example` and bootstrap `.env`

Copy `_meta/templates/u-maker-env.template` to **`.u-maker/.env.example`** verbatim (no rendering — placeholders stay blank so the user fills them in).

If `.u-maker/.env` does **not** already exist, also copy the same template to `.u-maker/.env`. This gives the user an immediately-editable starter file. If `.u-maker/.env` already exists, leave it untouched — never overwrite real credentials.

The template enumerates credential keys consumed by skills that need them (Jenkins via `/u-tools-jenkins-deploy`, Docker Hub, Git PAT, deploy-target SSH). Skills load it with `set -a; . .u-maker/.env; set +a` and prefer those values over interactive prompts.

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

When a legacy `.u-maker/` is detected, migrate to v4 structure. **Never delete data — only move and restructure.**

#### 2.0 Pre-migration backup

```
cp -r .u-maker/ .u-maker.bak-{YYYYMMDD-HHmmss}/
```

Print: `Backup created at .u-maker.bak-{timestamp}/`

#### 2.1 Version-specific migration rules

##### From v2 (has `u-ssot.config.json`)

| Legacy Path | New Path | Action |
|-------------|----------|--------|
| `.u-maker/u-ssot.config.json` | `.u-maker/u-maker.config.json` | Rename + rewrite to v4 schema |
| `.u-maker/_dropzone/` | `.u-maker/data/dropzone/` | Move contents |
| `.u-maker/_input/` | `.u-maker/data/digest/` | Move contents (re-analyze recommended) |
| `.u-maker/_classified/` | (discard structure) | Extract items → re-ingest via /u-plan |
| `.u-maker/apps/{app}/docs/` | `.u-maker/docs/{app}/` | Move contents |
| `.u-maker/apps/{app}/output/` | `.u-maker/output/{app}/` | Move contents |
| `.u-maker/_backlog/` | `.u-maker/data/backlog/` | Move contents |
| `.u-maker/_state/` | `.u-maker/.state/` | Move contents |

##### From v3.0 (has `_dropzone/` at `.u-maker/` root, no `data/`)

| Legacy Path | New Path | Action |
|-------------|----------|--------|
| `.u-maker/_dropzone/` | `.u-maker/data/dropzone/` | Move contents |
| `.u-maker/_input/` | `.u-maker/data/digest/` | Move contents |
| `.u-maker/_classified/` | (discard structure) | Note for re-ingest |
| `.u-maker/_backlog/` | `.u-maker/data/backlog/` | Move contents |
| `.u-maker/_state/` | `.u-maker/.state/` | Move contents |
| `.u-maker/apps/{app}/` | `.u-maker/docs/{app}/` + `.u-maker/output/{app}/` | Split docs vs output |
| `.u-maker/links.json` | `.u-maker/data/links.json` | Move |

##### From v3.1 (has `data/` but config `version: "3.x"`)

| Legacy Path | New Path | Action |
|-------------|----------|--------|
| `.u-maker/u-maker.config.json` | (in-place update) | Update `"version"` to `"4.0"` |
| `.u-maker/data/input/` | `.u-maker/data/digest/` | Rename if exists |
| `.u-maker/data/classified/` | (discard) | Note for re-ingest |
| `.u-maker/out/browse/` | `.u-maker/output/` | Move contents |
| `.u-maker/out/reports/` | `.u-maker/reports/` | Move contents |

#### 2.2 Create missing directories

After moving files, ensure all v4 directories exist (same as Step 1.1), including `reports/`.

#### 2.3 Ensure required files exist

Create `data/links.json`, `data/digest/_index.json`, `.state/loop-state.json` if they don't exist (same as Steps 1.3–1.5). Also run Step 1.5.1 to write `.env.example` and bootstrap `.env` (existing `.env` is never overwritten), and Step 1.7 to ensure `.u-maker/.env` is in the project `.gitignore`.

#### 2.3.1 Generate missing index files

If any of the 3 root index files are missing, generate them (same as Step 1.6). Scan existing `output/` and `reports/` directories for actual content and populate index data accordingly.

#### 2.4 Clean empty legacy directories

Remove now-empty legacy directories:

```
_dropzone/ _input/ _classified/ _backlog/ _state/ apps/ out/
```

Only remove if **empty**. If files remain, warn user.

#### 2.5 Remove backup if clean

If migration completed without errors, ask user: "Migration complete. Remove backup `.u-maker.bak-{timestamp}/`? (y/n)"

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
