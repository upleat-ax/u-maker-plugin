# Deploy Gate Check (≥ 98)

> Enforcement rules for the Deploy gate in PBGD v4.0.

## 1. Rule

`/u-deploy` must not produce artifacts unless `.state/deploy-readiness.json` has:

```json
{
  "deployReady": true,
  "docScore": 98 or higher,
  "deployThreshold": 98
}
```

The file is written by `u-agent-gatekeeper` on every Gatekeeping run. See `hooks/on-gate-result.js` for the emission logic.

## 2. Rationale

Two thresholds exist because "docs are good enough for internal flow" (95) is different from "docs are good enough to deploy publicly" (98). The 3-point delta is a buffer for the last-mile polish:

- Completeness — no TODOs/FIXMEs remaining
- Cross-reference — every link resolves
- Traceability — no orphan FTs or uncovered TCs

## 3. Failure behavior

When `deployReady: false`:

```
ERROR: /u-deploy blocked.
  docScore:   97.2 (threshold 98)
  Reason:     docScore 97.2 < deployThreshold 98
  Next:       Re-run /u-gatekeeping --loop to raise the score,
              or (discouraged) /u-deploy --force to bypass.
```

## 4. `--force` bypass

`--force` bypasses the gate but:

1. Writes a prominent warning comment at the top of every generated artifact:
   ```
   # WARNING: generated with --force; Gatekeeping docScore below deployThreshold (98).
   # docScore at time of generation: {N}
   # This deploy has NOT been quality-verified. Do not ship without follow-up review.
   ```
2. Marks the deploy manifest `gate.deployReady = false` and `gate.forced = true`.
3. Surfaces the bypass in the summary output.

`--force` is intended for emergency re-deploys (e.g., rollback) and should not be a habit.

## 5. Stale detection

If `deploy-readiness.json` is older than any SSoT doc hash currently recorded, the gate is treated as **stale**:

```
ERROR: Gate is stale.
  deploy-readiness.json checked at: 2026-04-15T09:00:00Z
  SRS last modified:                2026-04-17T14:22:11Z
  Action: Run /u-gatekeeping first to refresh the gate.
```

Stale gates cannot be `--force`-bypassed; the user must re-run Gatekeeping.

## 6. Audit trail

Every Deploy run (successful or not) writes an audit entry to `reports/deploy/{timestamp}.json` with:

- `docScore`, `deployReady`, `forced`
- `target`, `artifacts` requested
- `result`: `success` / `blocked-by-gate` / `error`
- `runBy`: `u-agent-deploy`

Retained indefinitely for compliance review.
