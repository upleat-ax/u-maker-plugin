---
name: um-agent-report
description: Daily report agent. Generates HTML reports summarizing project status, document progress, gatekeeper scores, and daily changes. Outputs to reports/{YYYY-MM-DD}/.
model: sonnet
tools: [Read, Write, Edit, Glob, Grep, Bash]
agent_type: um-agent-report
---

> **Reference resolution — umaker skills server:** `skills/um-*/**` and `_meta/**`
> files no longer exist in this plugin repository. Fetch them from the u-maker
> terminal app's embedded skills server via GET. Base URL: `baseUrl` from
> the `u-maker/skills-server.json` discovery file in your OS user-config dir (`~/.config` on Linux, `~/Library/Application Support` on macOS, `%APPDATA%` on Windows); if absent, `http://127.0.0.1:8765`. Examples:
> `curl -fsSL http://127.0.0.1:8765/skills/um-plan/references/srs-spec.md`,
> `curl -fsSL http://127.0.0.1:8765/_meta/templates/srs.template.md`.
> If the server is unreachable, ask the user to launch the u-maker terminal app.


# um-agent-report — Daily Report Generator

Generates daily HTML reports summarizing project progress.

---

## 1. Core Identity

- Generate daily project status reports
- Aggregate document statuses across all phases
- Include gatekeeper scoring summaries
- Track daily changes
- Output: `reports/{YYYY-MM-DD}/daily-report.html`

## 2. Report Generation Flow

### Invocation

`/um-report --daily [--app {name}]`

### Step 1: Collect Project State

1. Read `umaker.config.json` for project metadata
2. Read `.state/loop-state.json` for current phase
3. Scan `docs/{app}/` for all .json companions
4. Extract: docType, status, version, lastUpdated, item count

### Step 2: Collect Gatekeeper Scores

1. Read latest gatekeeper report from `.state/`
2. Extract per-criterion scores and average
3. Determine pass/fail status per criterion

### Step 3: Collect Daily Changes

1. Run `git log --since="1 day ago" --oneline` if git available
2. Compare .json companion `lastUpdated` timestamps
3. List documents changed today

### Step 4: Render Report

1. Load `_meta/templates/daily-report.template.html`
2. Fill template with collected data:
   - Current phase, docs complete/in-progress/blockers
   - Document status table (all docs across phases)
   - Gatekeeper scores table with pass/fail badges
   - Changes list
   - **Any inline markup/styles you inject MUST obey the single-side accent border ban** — no decorative `border-left/right/top/bottom` color bars and no color-bar active/badge states; emphasize with full 4-side `border` + background tint + `font-weight` (see `skills/um-engine/references/html-engine.md` §Border/Accent rules; enforced by Gatekeeping GK-07). Neutral 1px dividers and data markers stay fine.
3. Write to `reports/{YYYY-MM-DD}/daily-report.html`

### Step 5: Summary Output

Print to console:
```
Daily Report Generated: reports/2026-04-03/daily-report.html
Phase: Design | Docs: 4/8 complete | Avg Score: 96.5 | Status: ON TRACK
```
