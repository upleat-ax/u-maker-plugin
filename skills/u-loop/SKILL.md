---
name: u-loop
description: "Unattended PBGD auto-execution loop. Runs Prepare → Plan → Build → Gatekeeping → Deploy sequentially with gatekeeper validation at each phase. Use when automating the full project pipeline or resuming from a specific phase."
version: 4.0.0
triggers:
  - "/u-loop"
  - "auto loop"
  - "run all phases"
  - "full pipeline"
  - "unattended"
---

# u-loop — Unattended PBGD Auto-Execution Loop

`/u-loop [--app {name}] [--from {phase}] [--to {phase}] [--dry-run] [--max-retries {n}] [--criteria {n}] [--skip-deploy]`

Run all PBGD phases (Prepare → Plan → Build → Gatekeeping → Deploy) sequentially. Each phase executes with `--loop` enabled so `u-agent-gatekeeper` validates and retries until doc quality passes (avg ≥ 95) or max retries are exhausted. Deploy additionally requires avg ≥ 98.

**Engine Dependencies:** All engines (doc, html, digest, dep, router)
**State:** `.state/loop-state.json`
**PBGD Phase:** cross-phase orchestrator

> **Migration note (v3.x → v4.0):** In PDCA this loop ran `plan → design → dev → check → ship`. In PBGD it runs `prepare → plan → build → gatekeeping → deploy`. `/u-build` internally orchestrates the UI Design ↔ Development ping-pong. `/u-gatekeeping` covers what was formerly the Check phase. `/u-deploy` replaces Ship and is opt-in.

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | required | Target app name |
| `--from {phase}` | `prepare` | Start from this phase (prepare/plan/build/gatekeeping/deploy) |
| `--to {phase}` | `deploy` | Stop after this phase |
| `--dry-run` | OFF | Show execution plan without running |
| `--max-retries {n}` | `3` | Max gatekeeper retries per phase |
| `--criteria {n}` | `5` | Number of gatekeeper criteria to validate (1–11). Passed as `--loop {n}` |
| `--skip-deploy` | OFF | Run through Gatekeeping only; stop before Deploy |

## PBGD Phase Sequence

```
Phase 1: PREPARE      → /u-prepare --auto --app {name}
Phase 2: PLAN         → /u-plan --auto --loop {criteria} --app {name}
Phase 3: BUILD        → /u-build --auto --loop {criteria} --app {name}
Phase 4: GATEKEEPING  → /u-gatekeeping --auto --loop {criteria} --app {name}
Phase 5: DEPLOY       → /u-deploy --auto --app {name}  (requires avg ≥ 98; skipped if --skip-deploy)
```

Each phase (except Prepare and Deploy) must pass its gatekeeper gate (avg ≥ 95) before advancing. Deploy requires avg ≥ 98.

## Execution Flow

### Step 0: Initialize Loop State

1. Read or create `.state/loop-state.json`.
2. Determine starting phase (from `--from` or last incomplete phase).
3. Validate `--app` parameter exists.
4. If `--dry-run` → print execution plan and exit.

**loop-state.json schema (v4.0):**

```json
{
  "app": "myapp",
  "startedAt": "…",
  "currentPhase": "prepare",
  "currentSubPhase": null,
  "maxRetries": 3,
  "phases": {
    "prepare":     { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "plan":        { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "build":       { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "gatekeeping": { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "deploy":      { "status": "pending", "attempts": 0, "score": null, "completedAt": null }
  },
  "history": [],
  "deployReady": false
}
```

### Step 1: Execute Phase

For the current phase:

1. Set `phases[phase].status = "running"`.
2. Save loop-state.
3. Invoke the phase skill:

| Phase | Skill | What it produces |
|-------|-------|------------------|
| prepare | `/u-prepare` | `.u-maker/` scaffolded + `data/digest/` populated + `_clarifications.json` |
| plan | `/u-plan` | SRS + IA (md+json) |
| build | `/u-build` | Design docs (ERD, API, Screens, Design System) + FE/BE/DB code |
| gatekeeping | `/u-gatekeeping` | testcases + test-results (md+json) + `deploy-readiness.json` |
| deploy | `/u-deploy` | CI/CD artifacts + `data/deploy/manifest.json` |

### Step 2: Gatekeeper Validation

For Plan / Build / Gatekeeping, the phase skill's `--loop {N}` flag invokes `u-agent-gatekeeper` automatically:

1. Gatekeeper scores top N criteria.
2. Calculate avg.
3. If avg ≥ 95 → **PASS**; set `phases[phase].status = "passed"`; record score and completedAt; advance.
4. If avg < 95 → **FAIL**; increment `phases[phase].attempts`; record improvement items; if attempts < maxRetries → re-execute; else → ESCALATE (halt, notify user).

For Prepare: no gate (phase is interactive or digest-complete-check).
For Deploy: gate is `deployReady: true` (avg ≥ 98) from `.state/deploy-readiness.json`. If false → skip Deploy (or abort if Deploy was the `--to` target).

### Step 3: Phase Transition

On PASS:

1. Log transition in `history[]`.
2. Update `currentPhase` to next PBGD phase.
3. Save loop-state.
4. If current phase ≤ `--to` phase → goto Step 1.
5. If all phases complete → goto Step 4.

On FAIL (max retries):

1. Set `phases[phase].status = "failed"`.
2. Log failure with accumulated improvement items.
3. Print escalation message (see below).
4. Exit loop.

### Step 4: Completion

When all targeted phases pass:

```
========================================
  u-loop Complete: {app}
========================================
  Phase         | Score  | Attempts | Time
  --------------|--------|----------|--------
  Prepare       | n/a    | 1        | 0m 40s
  Plan          | 97.2   | 1        | 2m 15s
  Build         | 96.8   | 2        | 6m 30s
  Gatekeeping   | 98.5   | 1        | 1m 50s
  Deploy        | n/a    | 1        | 0m 35s
  --------------|--------|----------|--------
  Overall       | 97.5   | 6 total  | 11m 50s
========================================
  Status: ALL PHASES PASSED · deployReady: true
========================================
```

## Resume Support

If a loop was interrupted, `/u-loop --app {name}` auto-detects existing loop-state and resumes from the first phase with `status != "passed"`. Previous phase results are preserved.

To force restart: delete `.state/loop-state.json` or use `--from prepare`.

## Phase Dependencies

```
prepare ──► plan ──► build ──► gatekeeping ──► deploy
 digest     SRS+IA   ERD+API    testcases      CI/CD
                     Screens    results        artifacts
                     DS+Code                   manifest
```

Each phase reads outputs of all previous phases. If an upstream SSoT changes (e.g., SRS updated), the dep-engine (`data/links.json`) marks downstream docs stale and `hooks/on-deploy-state.js` marks deploy artifacts stale.

## Dry Run Output

`/u-loop --app myapp --dry-run` prints a phase-by-phase plan with inputs, outputs, and gates for each PBGD phase.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Missing `--app` | Error: `--app is required for /u-loop` |
| Missing dropzone + no source | Prepare stops at scenario-decision prompt; `/u-loop --auto` uses default resolution (see `skills/u-prepare/references/scenario-decision.md` §4) |
| Phase skill not found | Error: `Skill u-{phase} not found` |
| Gatekeeper unavailable | Retry once, then halt with warning |
| Deploy blocked (avg < 98) | Skip Deploy with notice; mark loop as `completed-without-deploy` |
| Disk/write error | Halt loop, preserve loop-state |
| User interrupt | Save current loop-state, exit gracefully |

## Checklist

- [ ] loop-state.json updated at each transition
- [ ] Each phase invoked with `--auto --loop --app {name}` (except Prepare)
- [ ] Gatekeeper score recorded per phase (where applicable)
- [ ] Failed phases retry up to maxRetries
- [ ] Resume from last incomplete phase on re-run
- [ ] Deploy requires `deployReady: true`
- [ ] History array logs all transitions
- [ ] Summary dashboard printed on completion
- [ ] Escalation message includes actionable improvement items
- [ ] `--dry-run` shows plan without execution
- [ ] `--from` / `--to` correctly limits phase range
