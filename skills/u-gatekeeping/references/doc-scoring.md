# Doc Scoring — Gatekeeping.DocScoring

> 11-criteria gatekeeper scoring methodology. Pass threshold **≥ 95**; deploy-readiness threshold **≥ 98**. PBGD v4.0.

## 1. Criteria

Authoritative list: `_meta/schemas/gate-rules.json` `criteria[]`. Summary:

| ID | Name | Focus |
|----|------|-------|
| GK-01 | Completeness | All required sections and items exist |
| GK-02 | Accuracy | Content matches digest + upstream docs |
| GK-03 | Consistency | IDs, terminology, values consistent |
| GK-04 | Traceability | FR→US→FT→TC chain complete |
| GK-05 | TOC Quality | TOC depth, order, entries match sections |
| GK-06 | Content Composition | Logical flow, appropriate info placement |
| GK-07 | Visual Adequacy | Stars/cards/tables used appropriately |
| GK-08 | Diagram Fitness | Diagram types match subject, SVG renders |
| GK-09 | Mermaid Integrity | No syntax errors, renderable |
| GK-10 | JSON Sync | `.md` and `.json` synchronized, 10-increment IDs |
| GK-11 | Cross-Reference | `links.json` matches actual doc refs |

Each scored 0–100. The aggregate is the arithmetic mean of the 11 scores.

## 2. Two thresholds

| Threshold | Value | Meaning |
|-----------|-------|---------|
| `passThreshold` | 95 | Gatekeeping phase succeeds; doc is acceptable for downstream phases. |
| `deployThreshold` | 98 | Doc quality is high enough to green-light `/u-deploy`. |

A run with avg 96 **passes Gatekeeping** (not blocking) but **fails the deploy gate** (Deploy will refuse to run).

## 3. Improvement list format

When avg < 95, the gatekeeper emits an improvement list that `u-agent-pm` routes back to the responsible sub-phase (Plan, UIDesign, Development). Format:

```json
{
  "runId": "{timestamp}",
  "avgScore": 92.4,
  "items": [
    {
      "criterion": "GK-04",
      "doc": "docs/app/plan/srs.md",
      "issue": "US-030 has no linked FT",
      "severity": "blocker",
      "suggestedOwner": "u-agent-plan"
    }
  ]
}
```

## 4. Deploy gate check

After any Gatekeeping run, write `.state/deploy-readiness.json`:

```json
{
  "app": "{app}",
  "docScore": 97.2,
  "passThreshold": 95,
  "deployThreshold": 98,
  "passed": true,
  "deployReady": false,
  "reason": "docScore 97.2 < deployThreshold 98",
  "checkedAt": "…"
}
```

`/u-deploy` reads this file as its first precondition check.

## 5. Retry policy

- Max 3 gatekeeper retries per Gatekeeping phase invocation.
- Each retry must show measurable improvement (avgScore increases by ≥ 1.0), else the gatekeeper raises `escalate` and hands control back to the user.

## 6. See also

- `runtime-qa.md` — the complementary sub-phase.
- `_meta/schemas/gate-rules.json` — authoritative criteria and thresholds.
