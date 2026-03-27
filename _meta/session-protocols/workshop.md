# Workshop Session Protocol

## Purpose
Structured 4-phase collaborative workshop for complex problem-solving and design.

## Phases

### Phase 1: Diverge
- **Goal:** Generate maximum ideas and possibilities
- **Rules:** No criticism, all ideas welcome, agent expands with variations
- **Duration:** Until user triggers `/next-phase`
- **Output:** Raw idea list

### Phase 2: Group
- **Goal:** Organize ideas into coherent themes/categories
- **Rules:** Agent proposes grouping, user adjusts. Duplicates merged. Orphans assigned.
- **Duration:** Until all items grouped
- **Output:** Themed clusters

### Phase 3: Prioritize
- **Goal:** Rank items within each group
- **Rules:** Use MoSCoW (must/should/could/wont) or dot-voting. Agent provides data-driven recommendations.
- **Duration:** Until all groups prioritized
- **Output:** Prioritized list per group

### Phase 4: Decide
- **Goal:** Select items for action and assign next steps
- **Rules:** User makes final selections. Each selected item gets an owner and timeline. Decisions are recorded.
- **Duration:** Until user confirms
- **Output:** Action items with assignments

## Phase Transition
- Orchestrator manages transitions via `/next-phase`
- Cannot skip phases (sequential only)
- Can return to previous phase with `/prev-phase`

## Rules Per Phase
| Phase | Criticism | Agent Role | User Role |
|-------|-----------|------------|-----------|
| Diverge | Forbidden | Expand ideas | Generate ideas |
| Group | Allowed (grouping only) | Propose clusters | Adjust/confirm |
| Prioritize | Allowed | Recommend rankings | Decide rankings |
| Decide | Allowed | Summarize options | Select & assign |

## Output
- All 4 phases preserved in session transcript
- Action items extracted with `type: action`
- Decisions recorded with `type: decision`
- Grouped and prioritized items available for backlog registration

## Micro-Commands
| Command | Action |
|---------|--------|
| `/next-phase` | Advance to next phase |
| `/prev-phase` | Return to previous phase |
| `/status` | Show current phase and progress |
| `/add [idea]` | Add idea (diverge phase) |
| `/group [name]` | Create/assign group (group phase) |
| `/rank [id] [priority]` | Set priority (prioritize phase) |
| `/assign [id] [owner]` | Assign action (decide phase) |
| `/done` | End workshop |
