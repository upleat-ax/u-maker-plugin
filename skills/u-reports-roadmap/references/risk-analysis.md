# Risk Analysis — per-track risk identification + scoring

Risk content lands in each track's **`notes` block** ("진척 · 공수 · 리스크 · 메모") and the worst risks surface in the **headline / framing / a warn snapshot card**. The reference report's `notes` blocks are the worked example — its categories below are not invented, they are extracted from real per-track notes.

## Risk taxonomy (from the reference)

| # | Risk | Detection signal (from `scope-analysis.md`) | Roadmap treatment |
|---|---|---|---|
| 1 | **Cross-repo BE dependency** | `TODO(backend)`, mock-only routes, `/v1/...` endpoints absent, "별도 백엔드" notes | muted "엔드포인트 도착 대기" bar + wiring bar `(도착분부터)`; completion is **not** owned by this repo |
| 2 | **Mock drift / dual-source** | a live copy and a static/migrated copy diverge (commit counts differ wildly, e.g. 372 vs 41) | explicit sync phase; call out which copy OP fixes land on |
| 3 | **Churn-prone area** | top files in `git log` churn ranking; "되돌림/revert" history | "변경 시 회귀 주의" note; avoid scheduling risky rewrites near the deadline |
| 4 | **Stale spec / SSoT** | `spec-sync`/`srs.md` dated older than recent merges | recommend spec re-run (common track) before trusting gap counts |
| 5 | **Scope-denominator ambiguity** | two screen-count bases disagree (310 vs 577) | state which basis the report uses; widen the estimate range |
| 6 | **Capacity shortfall** | `projectedCapacity < remaining/weeks` (estimation-model) | visible overrun bars or scope-narrowing; never silent compression |
| 7 | **Technical debt block** | inline styles, direct `authApi` calls, orphan files, `@ts-nocheck` | rewrite phase budgeted; flag as drag on velocity |
| 8 | **Unmerged / parked work** | diverged branches not in default branch | drift-cleanup phase; human-merge dependency (no auto-merge) |

## Scoring (lightweight, for ordering — not false precision)

Per track, score each present risk **Likelihood × Impact** on a 1–3 scale:

```
severity = likelihood(1-3) × impact(1-3)   →  1-2 low · 3-4 med · 6-9 high
```

- **Likelihood**: how certain the trigger is (BE not arrived = 3; possible churn = 2).
- **Impact**: effect on the deadline (blocks a release bar = 3; cosmetic = 1).

Use scores only to **order** risks within a `notes` block and to decide which 1–3 reach the headline/framing. Do not render a numeric risk matrix unless asked — the reference keeps risk as prose, which reads better and invites editing.

## Writing the `notes` block

Each track's `notes` (inline HTML) should answer, in 1–3 sentences:
1. **진척/공수** — rough % done and remaining effort (from estimation), with the velocity basis.
2. **핵심 리스크** — the highest-severity risk(s) for this track, concretely (file, MR, endpoint, date), not generically.
3. **회귀/주의** — churn or coupling hotspots to watch when changing.

Mirror the reference's voice: specific artifacts (`MR !1356`, `OP#395`, `srs.md §126`), explicit dependency ownership ("backend 는 별도 프로젝트, 구현 금지"), and honest uncertainty (`(TBD)`, `추정`).

## Project-level risk → headline / framing / snapshot

- Put the single most consequential framing risk in the **headline** mark (e.g. "BE 연동·도메인 정합" pending) and the **framing** paragraph's closing sentence (the reference uses it to explain cross-repo dependency).
- If a hard constraint dominates (capacity short, a freeze before scope completes), consider a **warn snapshot card** or a `(추정)` note on the D-day card.
- Always state the meta-risk the reference states: **the deadline is a stabilization checkpoint, not "all features complete"**, and BE-dependent tracks' completion is contingent on another team's progress.
