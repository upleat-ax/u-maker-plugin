# foldertree-layout — v4 .u-maker Folder Layout + Initial Files

Reference for Step 1 (Fresh Initialization) of `u-prepare-foldertree`. Defines the v4 directory tree and the contents of all 5 bootstrap files.

## v4 Folder Tree

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

Create all directories; replace `{app}` with the provided `app-name`.

## Initial File Contents

### `u-maker.config.json` (Step 1.2)

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

### `data/links.json` (Step 1.3)

```json
{
  "version": "1.0.0",
  "lastUpdated": "{ISO-8601 now}",
  "nodes": [],
  "edges": []
}
```

### `data/digest/_index.json` (Step 1.4)

```json
{
  "version": "1.0.0",
  "files": {}
}
```

### `.state/loop-state.json` (Step 1.5)

```json
{
  "phase": null,
  "iteration": 0,
  "lastRun": null,
  "gateScores": {}
}
```

### `.env.example` and `.env` bootstrap (Step 1.5.1)

Copy `_meta/templates/u-maker-env.template` to **`.u-maker/.env.example`** verbatim (no rendering — placeholders stay blank so the user fills them in).

If `.u-maker/.env` does **not** already exist, also copy the same template to `.u-maker/.env`. This gives the user an immediately-editable starter file. If `.u-maker/.env` already exists, leave it untouched — never overwrite real credentials.

The template enumerates credential keys consumed by skills that need them (Jenkins via `/u-tools-jenkins-deploy`, Docker Hub, Git PAT, deploy-target SSH). Skills load it with `set -a; . .u-maker/.env; set +a` and prefer those values over interactive prompts.
