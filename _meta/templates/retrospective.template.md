---
Owner: {{owner}}
Status: {{status}}
Version: {{version}}
Last Updated: {{date}}
Related Docs: [{{relatedDocs}}]
App: {{app}}
---

# Retrospective — Iteration {{iterationNumber}}

| Item | Value |
|------|-------|
| Date | {{date}} |
| Iteration | {{iterationNumber}} |
| Participants | {{participants}} |
| Facilitator | {{facilitator}} |

## 1. Keep (What went well)

{{#keepItems}}
- {{description}}
{{/keepItems}}

## 2. Problem (What went wrong)

{{#problemItems}}
### {{id}}: {{title}}

- **Description:** {{description}}
- **Impact:** {{impact}}
- **Root Cause:** {{rootCause}}
{{/problemItems}}

## 3. Try (Improvements for next iteration)

{{#tryItems}}
### {{id}}: {{title}}

- **Description:** {{description}}
- **Related Problem:** {{relatedProblem}}
- **Expected Outcome:** {{expectedOutcome}}
- **Owner:** {{owner}}
{{/tryItems}}

## 4. Action Items

| ID | Action | Owner | Deadline | Status | Related Problem |
|----|--------|-------|----------|--------|-----------------|
{{#actionItems}}
| {{id}} | {{action}} | {{owner}} | {{deadline}} | {{status}} | {{relatedProblem}} |
{{/actionItems}}

## 5. Metrics

| Metric | This Iteration | Previous | Trend |
|--------|---------------|----------|-------|
| Velocity | {{currentVelocity}} | {{prevVelocity}} | {{velocityTrend}} |
| Completion Rate | {{currentCompletion}} | {{prevCompletion}} | {{completionTrend}} |
| Defect Count | {{currentDefects}} | {{prevDefects}} | {{defectTrend}} |
| Carry-Over Items | {{currentCarryOver}} | {{prevCarryOver}} | {{carryOverTrend}} |
