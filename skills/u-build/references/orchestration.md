# Build Orchestration — Design ↔ Dev Ping-Pong

> Detailed rules for `/u-build` orchestration logic. PBGD Build phase, v4.0.

## 1. When ping-pong is triggered

After `/u-dev` completes a round, it may emit a **design-gap report** in `.state/build-gap-report.json`:

```json
{
  "round": 1,
  "gaps": [
    {
      "type": "missing-entity",
      "reference": "Subscription",
      "foundIn": "src/views/UserProfileView.tsx",
      "expectedIn": "docs/app/design/erd.md"
    },
    {
      "type": "missing-endpoint",
      "reference": "POST /api/v1/payments",
      "foundIn": "src/services/billing.ts",
      "expectedIn": "docs/app/design/api.md"
    },
    {
      "type": "undefined-component",
      "reference": "DataTable<Subscription>",
      "foundIn": "src/views/SubscriptionList.tsx",
      "expectedIn": "docs/app/design/screens.md"
    },
    {
      "type": "missing-design-token",
      "reference": "color.brand.tertiary",
      "foundIn": "src/styles/theme.ts",
      "expectedIn": "docs/app/design/design-system.md"
    }
  ]
}
```

If this file is present and `gaps[]` is non-empty, `/u-build` re-enters `/u-design` with the list.

## 2. Gap types

| Type | Resolution target |
|------|-------------------|
| `missing-entity` | ERD — add entity + relations |
| `missing-endpoint` | API — add route + request/response schema |
| `undefined-component` | Screens — add component spec |
| `missing-design-token` | Design System — add token (color/spacing/typography) |
| `navigation-gap` | IA (special — escalates back to Plan; see §4) |
| `unresolved-requirement` | SRS (special — escalates back to Plan) |

## 3. Delta patch mode

When `/u-design` is invoked with a patch list (`--patch-list {file}`), it must:

1. Load existing design docs unchanged.
2. Add the requested items using the 10-increment rule (continue the existing numbering sequence, don't renumber).
3. Update `links.json` only for the new items.
4. Re-run doc-companion JSON sync for the affected docs.
5. Do **not** regenerate unrelated sections.

This preserves stability — previously approved design content is not perturbed.

## 4. Escalation to Plan

If a gap's type is `navigation-gap` or `unresolved-requirement`, the issue is fundamentally a Plan-phase deficiency. `/u-build` must:

1. Stop the ping-pong loop.
2. Write the escalation report to `.state/build-escalation.json`.
3. Surface to user: `"Plan-level gaps detected. Re-run /u-plan to address: [list]. /u-build cannot proceed."`
4. Exit with non-zero status; do not mark Build as complete.

## 5. Termination

The ping-pong loop terminates when **any** of:

| Condition | Result |
|-----------|--------|
| `/u-dev` reports `gaps.length === 0` | Success |
| `pingpongRound >= --max-pingpong` (default 2) | Surface remaining gaps; exit with warning |
| Escalation to Plan triggered | Abort (§4) |
| Either sub-phase returns a hard error (schema violation, template failure) | Abort |
| User interrupt (interactive mode only) | Save `.state/build-state.json`, exit |

## 6. State tracking

`.state/build-state.json` keeps:

```json
{
  "phase": "build",
  "app": "my-app",
  "pingpongRound": 2,
  "lastSubPhase": "dev",
  "gaps": [],
  "designDocsFinal": true,
  "codeGenerated": true,
  "startedAt": "…",
  "completedAt": "…"
}
```

Reused by `/u-loop` to resume after interruption.

## 7. Why an orchestrator

Without an orchestrator, users invoking `/u-design` and `/u-dev` separately tend to miss the ping-pong step — they generate code, discover gaps, patch them manually, and the design docs drift out of sync. `/u-build` makes the round-trip explicit and auditable.
