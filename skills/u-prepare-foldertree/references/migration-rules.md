# migration-rules — Legacy `.u-maker/` → v4 Migration Matrices

Reference for Step 2 (Migration) of `u-prepare-foldertree`. Defines the path-mapping matrices for each detected legacy version (v2, v3.0, v3.1). Always preserves data — only moves and restructures.

## Pre-migration Backup (Step 2.0)

```
cp -r .u-maker/ .u-maker.bak-{YYYYMMDD-HHmmss}/
```

Print: `Backup created at .u-maker.bak-{timestamp}/`

## Version-specific Migration Rules (Step 2.1)

### From v2 (has `u-ssot.config.json`)

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

### From v3.0 (has `_dropzone/` at `.u-maker/` root, no `data/`)

| Legacy Path | New Path | Action |
|-------------|----------|--------|
| `.u-maker/_dropzone/` | `.u-maker/data/dropzone/` | Move contents |
| `.u-maker/_input/` | `.u-maker/data/digest/` | Move contents |
| `.u-maker/_classified/` | (discard structure) | Note for re-ingest |
| `.u-maker/_backlog/` | `.u-maker/data/backlog/` | Move contents |
| `.u-maker/_state/` | `.u-maker/.state/` | Move contents |
| `.u-maker/apps/{app}/` | `.u-maker/docs/{app}/` + `.u-maker/output/{app}/` | Split docs vs output |
| `.u-maker/links.json` | `.u-maker/data/links.json` | Move |

### From v3.1 (has `data/` but config `version: "3.x"`)

| Legacy Path | New Path | Action |
|-------------|----------|--------|
| `.u-maker/u-maker.config.json` | (in-place update) | Update `"version"` to `"4.0"` |
| `.u-maker/data/input/` | `.u-maker/data/digest/` | Rename if exists |
| `.u-maker/data/classified/` | (discard) | Note for re-ingest |
| `.u-maker/out/browse/` | `.u-maker/output/` | Move contents |
| `.u-maker/out/reports/` | `.u-maker/reports/` | Move contents |

## Post-move Steps

### Step 2.2 — Create missing directories

After moving files, ensure all v4 directories exist (per `foldertree-layout.md` § v4 Folder Tree), including `reports/`.

### Step 2.3 — Ensure required files exist

Create `data/links.json`, `data/digest/_index.json`, `.state/loop-state.json` if they don't exist (per `foldertree-layout.md` § Initial File Contents). Also run Step 1.5.1 to write `.env.example` and bootstrap `.env` (existing `.env` is never overwritten), and Step 1.7 to ensure `.u-maker/.env` is in the project `.gitignore`.

### Step 2.3.1 — Generate missing index files

If any of the 3 root index files are missing, generate them (per main SKILL.md Step 1.6). Scan existing `output/` and `reports/` directories for actual content and populate index data accordingly.

### Step 2.4 — Clean empty legacy directories

Remove now-empty legacy directories:

```
_dropzone/ _input/ _classified/ _backlog/ _state/ apps/ out/
```

Only remove if **empty**. If files remain, warn user.

### Step 2.5 — Remove backup if clean

If migration completed without errors, ask user: "Migration complete. Remove backup `.u-maker.bak-{timestamp}/`? (y/n)"
