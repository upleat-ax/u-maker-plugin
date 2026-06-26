---
name: u-build
description: "This skill should be used when the user asks to '/u-build', 'build phase', 'design + dev', 'ui + code', 'u-maker 빌드', '빌드 단계', '디자인+개발', 'u-maker ping-pong', or wants to orchestrate /u-design ↔ /u-dev ping-pong under the PBGD Build phase."
version: 4.1.0
---

# u-build — Build Phase Orchestrator (PBGD Build)

`/u-build [--auto] [--loop] [--app {name}] [--only design|dev] [--max-pingpong {n}] [--sideeffect off|on|strict]`

Build-phase orchestrator. Runs the UI Design sub-phase (`/u-design`) and Development sub-phase (`/u-dev`) in sequence, with optional design↔dev ping-pong when Dev surfaces spec gaps. Both sub-phases remain callable standalone — this skill is an umbrella for the common case of running them together.

**Primary Agent:** u-agent-build
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** Plan phase gate passed (SRS=Final, IA=Final)
**PBGD Phase:** Build (umbrella)

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--auto` | No | Non-interactive; default ON. |
| `--loop` | No | Run gatekeeper loop on each sub-phase output. |
| `--app {name}` | No | App name; if omitted, infer from config. |
| `--only design` | No | Run UI Design sub-phase only; skip Dev. |
| `--only dev` | No | Run Dev sub-phase only; assumes Design is Final. |
| `--max-pingpong {n}` | No | Maximum design↔dev ping-pong rounds (default: 2). |
| `--sideeffect off\|on\|strict` | No | Side-effect gate mode for this build. Persisted to `.u-maker/.state/edit-gate-mode` and applied to **every** `/u-design`·`/u-dev` edit (`on`=`auto` low-noise · `strict` all edits · `off` disabled). Env `U_MAKER_EDIT_GATE` overrides. Default: unchanged, else `off`. |

## Execution Flow

### Step 0: Precondition check

1. Verify `docs/{app}/plan/srs.json` and `ia.json` exist with `status: "Final"`.
2. If not → error `"Plan documents not Final. Run /u-plan [--loop] first."` and exit.
3. **Resolve the side-effect gate mode.** If `--sideeffect {off|on|strict}` was passed, persist it **before any sub-phase** so it applies to every `/u-design`·`/u-dev` edit: `mkdir -p .u-maker/.state && printf '<mode>\n' > .u-maker/.state/edit-gate-mode` (`on`=`auto`; writes under `.u-maker/` are never gated). The `hooks/on-edit-guard.js` guard reads this on every edit; env `U_MAKER_EDIT_GATE` still overrides it. If omitted, the existing state file (or `off`) stands.

### Step 1: UI Design sub-phase

Invoke `/u-design --app {app} [--auto] [--loop]`. On success, `docs/{app}/design/` contains `erd.{md,json}`, `api.{md,json}`, `screens.{md,json}`, `design-system.{md,json}` all at `Final`.

Skip this step if `--only dev` was set.

### Step 2: Development sub-phase

Invoke `/u-dev --app {app} [--auto] [--loop]`. On success, FE/BE/DB code trees are generated/updated.

> **Side-effect gate is NOT bypassed by `--auto`.** `/u-dev` Step 0.5 (`references/change-safety.md`) still requires explicit user approval — via an `AskUserQuestion` **led by the `⚠️ SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음` banner** — before a **behavior-modifying** change to **already-implemented code that other code depends on** (git-tracked + clean **and** imported/referenced elsewhere **and** the edit rewrites/deletes existing lines = IMPLEMENTED·SHARED·MODIFYING; the `hooks/on-edit-guard.js` PreToolUse guard enforces this **when the gate is enabled** — it is **OFF by default**, opt-in via `--sideeffect on`/`strict` or env `U_MAKER_EDIT_GATE`). New, in-progress (untracked/dirty), leaf (no-dependent), and purely additive (insert-only) edits are not gated. `--auto` may batch the approval questions but never auto-approves deletions, renames, or signature/schema/route changes. Treat an unapproved side-effect as a first-class halt, not a silent retry.

Skip this step if `--only design` was set.

### Step 3: Ping-pong loop (if needed)

If `/u-dev` reports design gaps in its output (missing entities, undefined endpoints, unspecified components), the orchestrator re-enters UI Design with the gap list as a patch request:

```
Design gaps detected:
  - Entity 'Subscription' referenced in UserProfileView but not in ERD
  - Endpoint POST /api/v1/payments not specified
Round: 1 of 2

→ Re-invoking /u-design with patch list …
```

Rules:

- Maximum `--max-pingpong` rounds (default 2).
- Each round operates with a delta patch — do not regenerate the whole ERD/API from scratch.
- If the patch list is empty after a round, exit the loop successfully.
- If still non-empty after max rounds, surface the gaps to the user and stop.

**Design System gap routing:** When `/u-dev`'s gap report cites token/scale/a11y/component-API issues, route them to `/u-design` Step 4 with the relevant `design-system-rules.md` section:

| Gap cited by `/u-dev` | `/u-design` section to re-run |
|----------------------|-------------------------------|
| Missing or inconsistent token scales | `design-system-rules.md` §2 (10 scales) |
| Dark-mode tokens leak primitives | `design-system-rules.md` §3 dark-mode + §1 architecture |
| WCAG contrast / focus / ARIA failures | `design-system-rules.md` §4 accessibility |
| Component boolean-prop proliferation, prop drilling | `design-system-rules.md` §3 compound-components (+ `u-dev/references/fe-rules.md` §B) |

### Step 4: Handoff

On successful completion:

```
Build complete.
  Design docs: {N} files Final
  Code trees:  FE={a files} BE={b files} DB={c files}
  Ping-pong:   {k} round(s)
  Next:        /u-gatekeeping --app {app}
```

## Ping-pong termination conditions

- `patchList.length === 0` → success
- `pingpongRound >= maxPingpong` → surface gaps, exit with warning
- User interrupt (in interactive mode) → save partial state, exit
- Either sub-phase returns a hard error → abort, do not advance to Gatekeeping

## Reference Files

- **`references/orchestration.md`** — Ping-pong detection logic, gap-patch format, termination rules in depth.

## Related Commands

- `/u-design` — UI Design sub-phase (standalone).
- `/u-dev` — Development sub-phase (standalone).
- `/u-gatekeeping` — Next phase after Build.
- `/u-wireframe` — Orthogonal; typically run after `/u-plan` (not here).
