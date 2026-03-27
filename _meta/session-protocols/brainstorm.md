# Brainstorm Session Protocol

## Purpose
Generate maximum ideas without judgment. Quantity over quality during diverge phase.

## Rules

### Phase: Diverge
1. **No criticism** — All ideas are valid during diverge. No filtering, no "but", no rejection.
2. **All ideas recorded** — Every idea is logged as a session item with `type: idea`.
3. **Agent expands** — After each user idea, agent contributes 2-3 related/adjacent ideas.
4. **Wild ideas welcome** — Encourage unconventional, boundary-pushing suggestions.
5. **Build on others** — "Yes, and..." pattern. Combine and extend existing ideas.

### Phase: Converge
6. **Group similar ideas** — Cluster related items into themes.
7. **Vote/prioritize** — User selects top ideas per theme.
8. **Refine selected** — Flesh out selected ideas with details.

## Time-Boxing
- Each diverge round: max 10 idea cycles
- User can extend with `/more` or move to converge with `/next-phase`

## Output
- All ideas recorded in session `items[]` with timestamps
- Summary groups ideas by theme
- Selected ideas tagged for follow-up action

## Micro-Commands
| Command | Action |
|---------|--------|
| `/more` | Continue diverge round |
| `/group` | Start grouping phase |
| `/pick [id]` | Select idea for refinement |
| `/next-phase` | Move to converge |
| `/done` | End session |
