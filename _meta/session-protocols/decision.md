# Decision Session Protocol

## Purpose
Make a definitive decision with full context, options analysis, and recorded rationale.

## Rules

1. **Agent presents options** — Agent must present at least 2 options with structured analysis.
2. **Pros/cons required** — Each option must list pros, cons, and impact.
3. **Impact matrix** — Agent provides comparison matrix across key dimensions.
4. **User selects** — Only the user (FDE) can make the final decision.
5. **Mandatory rationale** — User must provide rationale for the selected option.
6. **Decision is final** — Once recorded, the decision stands unless a new decision session overrides it.
7. **Context preserved** — Full decision context (options considered, rejected alternatives, rationale) is recorded.

## Decision Flow

```
Define Question → Agent Research → Present Options → Impact Matrix → User Decides → Record
```

## Option Presentation Format

### Option N: [Name]
- **Description:** What this option entails
- **Pros:** Benefits and advantages
- **Cons:** Drawbacks and risks
- **Impact:** Effect on timeline, cost, quality, scope
- **Effort:** Estimated effort to implement
- **Recommendation:** Agent's assessment

## Impact Matrix Dimensions
| Dimension | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Timeline | | | |
| Cost | | | |
| Quality | | | |
| Risk | | | |
| Complexity | | | |

## Output
- Decision recorded with `type: decision` in session items
- All options preserved (including rejected ones)
- Rationale documented
- Affected documents/items flagged for update

## Micro-Commands
| Command | Action |
|---------|--------|
| `/options` | Show all options |
| `/compare` | Show impact matrix |
| `/select [option]` | Select option (prompts for rationale) |
| `/more-options` | Request additional options |
| `/done` | Finalize and end session |
