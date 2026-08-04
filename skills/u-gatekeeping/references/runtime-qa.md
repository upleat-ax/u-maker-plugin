# Runtime QA — Gatekeeping.RuntimeQA

> Runtime quality assurance: testcase design, execution, result recording, coverage. Complements `doc-scoring.md`. PBGD v4.0.

## 1. Scope

Runtime QA covers:

1. Designing test cases (TCs) from SRS Features (FTs) — 1:N mapping.
2. Executing TCs against implemented code.
3. Recording PASS/FAIL results.
4. Building the traceability coverage matrix (FR→US→FT→TC→Result).
5. Flagging defects by severity.

See `testcase-spec.md` and `test-execution.md` for the detailed rules (both retained from v3.x `u-check`).

## 2. Output locations

| File | Purpose |
|------|---------|
| `docs/{app}/gatekeeping/testcases.md` | Human-readable TC inventory |
| `docs/{app}/gatekeeping/testcases.json` | Companion JSON (doc-companion schema; `phase: "gatekeeping"`, `subPhase: "runtime-qa"`) |
| `docs/{app}/gatekeeping/test-results.md` | Execution report |
| `docs/{app}/gatekeeping/test-results.json` | Companion JSON with per-TC result + coverage matrix |
| `.state/runtime-qa-state.json` | Run state (in-progress, pass counts, failing TC IDs) |

## 3. Severity & blocking

| Severity | Behavior |
|----------|----------|
| `blocker` | Blocks Gatekeeping pass; escalates to Dev sub-phase for fix. |
| `critical` | Blocks Deploy gate (≥ 98 target cannot be reached). |
| `major` | Warns but does not block pass. |
| `minor` | Informational. |

## 4. Relationship to doc scoring

Doc scoring (GK-10 JSON Sync, GK-04 Traceability) directly inspects the testcases + test-results docs written here. If those docs are malformed or the coverage matrix is incomplete, doc scoring will fail → Gatekeeping as a whole fails.

## 5. Deploy gate contribution

Runtime QA does **not** set `deployReady` — that's owned by doc scoring. However, if any `blocker` or `critical` test failed, the doc-scoring run will read the QA results and subtract from the relevant criterion scores, which in turn lowers the avg and pushes `deployReady` to false.

## 6. See also

- `doc-scoring.md` — the complementary sub-phase.
- `testcase-spec.md` — TC derivation rules (6 TC types, priority).
- `test-execution.md` — execution protocol, defect classification.
