# Retrospective Session Protocol

## Purpose
Reflect on the completed iteration using Keep/Problem/Try format with data-driven insights.

## Rules

1. **Agent provides data first** — Before discussion, agent presents:
   - Velocity (planned vs actual story points)
   - Defect rates (by severity)
   - Completion percentage
   - Carry-over count from previous iteration
   - Build success/failure rate
2. **Keep/Problem/Try format** — Strict 3-section structure:
   - **Keep:** What went well and should continue
   - **Problem:** What went wrong or caused friction
   - **Try:** Improvements to attempt next iteration
3. **Each Problem must have >= 1 Try** — No problem without a proposed solution.
4. **Action items auto-registered** — All Try items with concrete actions are registered to the backlog as `type: improvement`.
5. **Quantitative over qualitative** — Prefer measurable observations over subjective feelings.
6. **Blame-free zone** — Focus on process, not people.

## Retro Flow

```
Data Presentation → Keep → Problem → Try → Action Items → Summary
```

## Data Metrics Template

| Metric | Value | Previous | Delta |
|--------|-------|----------|-------|
| Planned SP | | | |
| Completed SP | | | |
| Velocity | | | |
| Completion Rate | | | |
| Critical Defects | | | |
| Major Defects | | | |
| Minor Defects | | | |
| Carry-Over Items | | | |
| Build Failures | | | |

## Problem-Try Mapping
Each Problem MUST link to at least one Try:

| Problem ID | Problem | Try ID | Proposed Improvement |
|------------|---------|--------|---------------------|
| P-001 | ... | T-001 | ... |

## Output
- Keep/Problem/Try items recorded in session
- Action items extracted and registered to backlog
- Metrics snapshot preserved for trend analysis
- Summary written to retrospective document

## Micro-Commands
| Command | Action |
|---------|--------|
| `/keep [text]` | Add Keep item |
| `/problem [text]` | Add Problem item |
| `/try [text]` | Add Try item (must link to problem) |
| `/action [text]` | Register explicit action item |
| `/metrics` | Re-display iteration metrics |
| `/done` | Finalize retrospective |
