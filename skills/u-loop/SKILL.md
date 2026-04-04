---
name: u-loop
description: "Unattended PDCA auto-execution loop. Runs Plan→Design→Dev→Check→Ship phases sequentially with gatekeeper validation (--loop) at each phase. Use when automating full project pipeline or resuming from a specific phase."
version: 3.2.0
triggers:
  - "/u-loop"
  - "auto loop"
  - "run all phases"
  - "full pipeline"
  - "unattended"
---

# u-loop — Unattended PDCA Auto-Execution Loop

`/u-loop [--app {name}] [--from {phase}] [--to {phase}] [--dry-run] [--max-retries {n}] [--criteria {n}]`

Run all PDCA phases (Plan → Design → Dev → Check → Ship) sequentially. Each phase executes with `--loop` enabled so the gatekeeper validates and retries until quality passes (avg >= 95) or max retries exhausted.

**Engine Dependencies:** All engines (doc, html, digest, dep, router)
**State:** `.state/loop-state.json`

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | required | Target app name |
| `--from {phase}` | `plan` | Start from this phase (plan/design/dev/check/ship) |
| `--to {phase}` | `ship` | Stop after this phase |
| `--dry-run` | OFF | Show execution plan without running |
| `--max-retries {n}` | `3` | Max gatekeeper retries per phase |
| `--criteria {n}` | `5` | Number of gatekeeper criteria to validate (1-11). Passed as `--loop {n}` to each phase |

## PDCA Phase Sequence

```
Phase 1: PLAN    → /u-plan --auto --loop {criteria} --app {name}
Phase 2: DESIGN  → /u-design --auto --loop {criteria} --app {name}
Phase 3: DEV     → /u-dev --auto --loop {criteria} --app {name}
Phase 4: CHECK   → /u-check --auto --loop {criteria} --app {name}
Phase 5: SHIP    → (Final gate + output packaging)
```

Each phase MUST pass its gatekeeper gate (avg >= 95) before advancing to the next phase.

## Execution Flow

### Step 0: Initialize Loop State

1. Read or create `.state/loop-state.json`
2. Determine starting phase (from `--from` or last incomplete phase)
3. Validate `--app` parameter exists
4. If `--dry-run` → print execution plan and exit

**loop-state.json schema:**

```json
{
  "app": "myapp",
  "startedAt": "2026-04-04T10:00:00Z",
  "currentPhase": "plan",
  "maxRetries": 3,
  "phases": {
    "plan":   { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "design": { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "dev":    { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "check":  { "status": "pending", "attempts": 0, "score": null, "completedAt": null },
    "ship":   { "status": "pending", "attempts": 0, "score": null, "completedAt": null }
  },
  "history": []
}
```

### Step 1: Execute Phase

For the current phase:

1. Set `phases[phase].status = "running"`
2. Save loop-state
3. Invoke the phase skill with `--auto --loop --app {name}`:

| Phase | Skill | What it produces |
|-------|-------|-----------------|
| plan | `/u-plan` | SRS + IA (md+json+html) |
| design | `/u-design` | ERD + API + Screens + Design System (md+json+html) |
| dev | `/u-dev` | FE + BE + DB code |
| check | `/u-check` | Test Cases + Test Results (md+json+html) |
| ship | (final gate) | Output packaging, version bump, summary |

### Step 2: Gatekeeper Validation

Each phase skill with `--loop {N}` automatically invokes `u-agent-gatekeeper`:

1. Gatekeeper scores top N criteria (GK-01 through GK-{N}, default 5)
2. Calculate average score
3. If avg >= 95 → **PASS**:
   - Set `phases[phase].status = "passed"`
   - Record score and completedAt
   - Advance to next phase
4. If avg < 95 → **FAIL**:
   - Increment `phases[phase].attempts`
   - Record improvement items in history
   - If attempts < maxRetries → re-execute phase with improvements
   - If attempts >= maxRetries → **ESCALATE** (halt loop, notify user)

### Step 3: Phase Transition

On PASS:

1. Log transition in `history[]`:
   ```json
   {
     "phase": "plan",
     "action": "passed",
     "score": 96.5,
     "timestamp": "2026-04-04T10:15:00Z"
   }
   ```
2. Update `currentPhase` to next phase
3. Save loop-state
4. If current phase <= `--to` phase → goto Step 1
5. If all phases complete → goto Step 4

On FAIL (max retries):

1. Set `phases[phase].status = "failed"`
2. Log failure with accumulated improvement items
3. Print escalation message:
   ```
   LOOP HALTED at {phase} after {n} retries.
   Last score: {score}/100
   Blocking issues:
   - [GK-04] Missing traceability: FR-030 → no linked US
   - [GK-09] Mermaid syntax error in erd.md
   Action: Fix issues manually, then run /u-loop --from {phase}
   ```
4. Exit loop

### Step 4: Completion

When all phases pass (or `--to` phase reached):

1. Set all completed phases to `"passed"`
2. Print summary dashboard:

```
========================================
  u-loop Complete: {app}
========================================
  Phase    | Score  | Attempts | Time
  ---------|--------|----------|--------
  Plan     | 97.2   | 1        | 2m 15s
  Design   | 95.8   | 2        | 4m 30s
  Dev      | 96.1   | 1        | 3m 45s
  Check    | 98.0   | 1        | 1m 50s
  Ship     | 99.0   | 1        | 0m 30s
  ---------|--------|----------|--------
  Overall  | 97.2   | 6 total  | 12m 50s
========================================
  Status: ALL PHASES PASSED
========================================
```

3. Write summary to `.state/loop-state.json` with `"status": "completed"`
4. If any reports were generated during the loop (daily/gate/summary), update `reports/index.html` and `index.html` (see html-engine § 8 "Root Index Navigation System")

## Resume Support

If a loop was interrupted (crash, user cancel, timeout):

1. `/u-loop --app {name}` auto-detects existing loop-state
2. Finds first phase with `status != "passed"`
3. Resumes from that phase
4. Previous phase results are preserved (no re-execution)

To force restart: delete `.state/loop-state.json` or use `--from plan`

## Phase Dependencies

```
plan ──────► design ──────► dev ──────► check ──────► ship
  SRS+IA       ERD+API       Code        TC+Results    Package
               Screens
               DesignSys
```

Each phase reads outputs of all previous phases. If an upstream phase changes (e.g., SRS updated), downstream phases MUST re-execute. The dep-engine (`data/links.json`) tracks these dependencies.

## Dry Run Output

`/u-loop --app myapp --dry-run` prints:

```
u-loop Execution Plan for: myapp
──────────────────────────────────
Phase 1: PLAN
  → /u-plan --auto --loop 5 --app myapp
  Input:  data/dropzone/
  Output: docs/myapp/plan/ (SRS, IA)
  Gate:   {N}-criteria avg >= 95

Phase 2: DESIGN
  → /u-design --auto --loop 5 --app myapp
  Input:  docs/myapp/plan/ (SRS, IA)
  Output: docs/myapp/design/ (ERD, API, Screens, Design System)
  Gate:   {N}-criteria avg >= 95

Phase 3: DEV
  → /u-dev --auto --loop 5 --app myapp
  Input:  docs/myapp/design/ (ERD, API, Screens, Design System)
  Output: Generated code (FE, BE, DB)
  Gate:   {N}-criteria avg >= 95

Phase 4: CHECK
  → /u-check --auto --loop 5 --app myapp
  Input:  docs/myapp/plan/srs.json (FT items) + generated code
  Output: docs/myapp/check/ (Test Cases, Test Results)
  Gate:   {N}-criteria avg >= 95

Phase 5: SHIP
  → Final gate + output packaging
  Output: output/myapp/ (all HTML), version bump
──────────────────────────────────
Max retries per phase: 3
Estimated phases: 5
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Missing `--app` | Error: "--app is required for /u-loop" |
| Missing dropzone data | Error at plan phase: "No data in data/dropzone/" |
| Phase skill not found | Error: "Skill u-{phase} not found" |
| Gatekeeper unavailable | Retry once, then halt with warning |
| Disk/write error | Halt loop, preserve loop-state |
| User interrupt (Ctrl+C) | Save current loop-state, exit gracefully |

## Checklist

- [ ] loop-state.json created/updated at each transition
- [ ] Each phase invoked with `--auto --loop --app {name}`
- [ ] Gatekeeper score recorded per phase
- [ ] Failed phases retry up to maxRetries
- [ ] Resume from last incomplete phase on re-run
- [ ] History array logs all transitions
- [ ] Summary dashboard printed on completion
- [ ] Escalation message includes actionable improvement items
- [ ] `--dry-run` shows plan without execution
- [ ] `--from` / `--to` correctly limits phase range
