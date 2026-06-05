# Scope Analysis — extracting roadmap scope from code + git

Always scan source code and git directly (do not depend on `.u-maker` SSoT). The goal: turn a repo into a **track list** (rows of the Gantt) plus, per track, a **scope estimate** (how much is done vs remaining) and **status signals** that feed estimation and risk.

The reference report (`roadmap-hjw-fsms-grigolife-0811.html`) is the worked example — every number in it (278 routes, 226 mock markers, MR `!1355`, "주간 +19.5화면") came from one of the signals below. Reproduce that depth.

## Step A — Determine repo shape → track granularity

Tracks adapt to the repo:

| Repo shape | Track = | How to detect |
|---|---|---|
| Monorepo (multi-app) | one track per app **or** per feature-area within large apps | `apps/*`, `packages/*`, `pnpm-workspace.yaml`, `turbo.json`, `bun` workspaces |
| Single app | one track per feature-area / route group / domain module | top-level route groups, `src/features/*`, `src/modules/*`, domain folders |
| Library/service | one track per public surface / subsystem | exported entrypoints, service boundaries |

Group related tracks by a **color hue family** (see `html-template.md` palette): e.g. all app-A tracks → `blue*`, app-B → `green*`, cross-cutting → `common`. Always add a final **`common` track** for cross-repo BE dependency, SSoT/docs currency, and integration QA (the reference's "공통" track) — these absorb effort that per-feature tracks hide.

## Step B — Per-track scope signals (grep/glob)

Count and locate, per track scope:

```bash
# Routes / screens (Next.js app router, pages, RN screens)
find <scope> -regex '.*/(page|route|layout)\.\(t\|j\)sx\?' | wc -l
find <scope> -name '*.tsx' -path '*screens*' | wc -l

# Implemented vs stub/mock — the core "done vs remaining" signal
grep -rIn 'TODO(backend)\|TODO: *backend\|FIXME\|@ts-nocheck' <scope> | wc -l
grep -rIln 'mock\|MOCK\|mockData\|__mocks__\|stub\|placeholder\|href="#"' <scope> | wc -l
grep -rIn 'NotImplemented\|throw new Error(.\?not impl' <scope>

# BE wiring presence — real API calls vs none
grep -rIn 'fetch(\|axios\|useQuery\|useMutation\|repository\|/v1/\|/api/' <scope> | wc -l

# Feature-module maturity (Clean Architecture layers present?)
find <scope> -type d -regex '.*/(features|domain|data|hooks)$'
```

Interpret: a track with many routes but high mock/TODO(backend) density and few real API calls = **UI-exists / BE-pending** (muted "도착 대기" bar + wiring phases), exactly like the reference's `hjwAccounting` (37 routes, 25 UI-only/12 mock-only).

## Step C — Activity & momentum signals (git)

```bash
# Throughput per area since a date (feeds velocity in estimation-model.md)
git log --since='8 weeks ago' --pretty='%ad' --date=short -- <scope> | sort | uniq -c
git log --since='8 weeks ago' --oneline -- <scope> | wc -l

# Recent completed work → "완료" highlights + done releases
git log --since='6 weeks ago' --pretty='%s' --no-merges -- <scope> | grep -iE 'feat|완료|merge'

# In-flight: open branches / MR-MR numbers mentioned in messages
git branch -a --sort=-committerdate | head -40
git log --since='4 weeks ago' --pretty='%s' | grep -oE '!\\d+|MR ?!?\\d+|#\\d+'   # MR/issue refs

# Churn-prone files (risk signal) — most-touched files
git log --since='8 weeks ago' --name-only --pretty='' -- <scope> | sort | uniq -c | sort -rn | head -20

# Parked/stale branches (drift risk) — diverged but not merged
git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short) %(committerdate:short)'
```

Branch names often encode screen/feature IDs (reference: `feat/...만족도조사전체CRUD_S7611`) — mine them for completed/in-flight scope labels and MR numbers for the "이번 구간 핵심" highlights.

## Step D — Dated targets (the strongest estimation anchor)

Look for any **explicit measured rate or ETA** already in the codebase/docs — these beat any synthetic formula:

```bash
grep -rIn '주간 *+\|per week\|velocity\|ETA\|화면/주\|screens/week' . --include='*.md'
grep -rIn 'spec-sync\|srs\.md\|design.*규모\|화면목록' . --include='*.md'
```

The reference's only dated milestone (`설계규모 310화면 ETA 7/26`) came from `srs.md §126` (measured +19.5 screens/week). If such a number exists, anchor on it and cite the source. Note denominator ambiguity when two screen-count bases disagree (reference: 310 vs 577) and state which basis the report uses.

## Output of scope analysis

Produce, per track, a compact record to carry into estimation + rendering:

```
trackId, group(hue), title, subtitle
scope:   {routes, screensTotal, implemented, mockOnly, uiOnly, realApiCalls}
status:  done[] (labels+commits/MR), inFlight[] (labels+MR), remaining[]
signals: {weeklyThroughput, churnFiles[], parkedBranches[], beDependency:bool, staleSpec:bool}
datedTargets: [{label, date, source}]
```

This record maps directly onto `DEFAULT_TRACKS`, `DEFAULT_PHASES`, and `DEFAULT_DETAILS` in the template, and feeds `estimation-model.md` and `risk-analysis.md`.
