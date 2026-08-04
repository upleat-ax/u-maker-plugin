# Estimation Model — scope + team capacity → Gantt phases

The deliverable is an **editable first-draft estimate**, not an authoritative schedule. Everything in the rendered HTML is draggable/contenteditable; the framing text states bars are estimates. So the bar is to produce a *defensible draft with visible uncertainty* — not a precise formula. Do not emit confident exact dates from a textbook constant.

## Principle: anchor on measured velocity, modulate by team size

Order of preference for the base unit of velocity:

1. **An explicit measured rate already in the repo/docs** (e.g. `srs.md` "주간 +19.5화면"). Use it verbatim and cite the source. Strongest anchor.
2. **Observed git throughput** from `scope-analysis.md` Step C: merged feature commits/PRs per week, or screens/routes completed per week over the last 6–8 weeks. This is the default base.
3. **Only if no history exists** (greenfield): fall back to a coarse per-unit range and label the whole roadmap "추정(이력 없음)".

Team size **modulates** capacity; it is not the base unit:

```
observedVelocity   = completed scope units / weeks  (from git, per track or repo-wide)
activeContributors = distinct git authors in the measurement window (per track if possible)
perDevVelocity     = observedVelocity / max(1, activeContributors)
projectedCapacity  = perDevVelocity × devs(confirmed) × focusFactor
```

- `focusFactor` ≈ 0.6–0.8 (meetings, review, context-switch, OP tickets). State the value used.
- **Designers / planners** rarely move the implementation bar directly — they gate *upstream* readiness (specs, DS, screens). Model them as **dependency constraints** on a track's start, not as added implementation throughput. A track blocked on design starts later; a planner shortfall widens scope uncertainty.
- If `projectedCapacity < remaining scope / weeksToDeadline`, the project is **capacity-short** → flag in risk (see `risk-analysis.md`) and either push release bars past the deadline (visible overrun) or narrow scope, never silently compress.

## Team capacity input — estimate then confirm

1. **Estimate** from git: `git shortlog -sne --since='8 weeks ago'` → active authors; infer roles from CODEOWNERS / paths (`*/ui-*`, `*.figma*` → designer; `docs/`, `*.srs.*` → planner; rest → dev). Produce a draft `{devs, planners, designers}`.
2. **Confirm** with the user via `AskUserQuestion` — present the estimate as the default and let them correct. Record the confirmed counts in the report (subtitle/framing) so the estimate's basis is transparent.

## Mapping scope → phases → week buckets

The grid is fixed at **PRE + W1..W10 + FINAL** (12 columns; 11 working segments). Bucket size auto-derives as span/11 so the deadline lands in FINAL (`buildTimeline` in the template: weekly when span≈10–11wk, bi-weekly when longer). Place phases by bucket id (`from`/`to`), not by raw date.

Per track, decompose into 2–4 phases following the reference's grammar:

| Phase kind | When | Bar style | Release |
|---|---|---|---|
| **Completed** | already merged (git done signal) | normal, in PRE/W1 | `release.kind:'done'` |
| **In-flight / active build** | current work, known MR/branch | normal | `release.kind:'normal'` ('v1', '모듈화'…) |
| **Pending / wiring** | depends on BE arrival or upstream | normal, starts mid-grid | optional |
| **Continuous / standing** | OP, hardening, BE-arrival-wait | `muted:true` (빗금), spans PRE→FINAL | none |
| **Integration QA** | repo-wide, near deadline | normal, W9→FINAL | `release.kind:'fair'` (deadline) |

Duration of a build phase = `ceil(phaseScope / projectedCapacity)` buckets, clamped to the grid. Round generously and **show uncertainty**: append `(TBD)` or `추정` to `meta` for any bar whose scope or dependency is unconfirmed (exactly as the reference does for BE-dependent bars). Cross-repo BE-pending work → a muted "도착 대기" bar PLUS a tentative wiring bar marked `(도착분부터)`.

## Deadlines, milestones, freeze

- `DEFAULT_DEADLINES`: the hard deadline (`kind:'hard'` at FINAL), any feature-freeze (`kind:'launch'`), and a soft mid-checkpoint (`kind:'soft'`). `within` = fraction inside the bucket (e.g. a date on day 1 of 7 → ~0.14).
- `DEFAULT_MILESTONES`: 4–7 dated checkpoints. Mark past ones `cls:'done'`, the freeze `cls:'launch'`, the final `cls:'fair'`.
- `UPCOMING`: same future checkpoints as real `Date` objects (drives the "다음 체크포인트" card).

## Sanity checks before rendering

- Every release/deadline date consistent with `CONFIG.startDate`/`deadline`.
- No build phase silently extends past the deadline without it being visible (overrun must show, not hide).
- Capacity-short or BE-dependent conclusions appear in both the `notes` block and the headline/framing.
- State assumptions once, plainly: measurement window, velocity source, focusFactor, confirmed team counts.
