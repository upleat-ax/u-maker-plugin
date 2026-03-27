# Review Session Protocol

## Purpose
Systematically review artifacts (documents, designs, code) with clear dispositions.

## Rules

1. **Agent presents first** — Agent analyzes the artifact and presents findings before user input.
2. **Structured review** — Each item reviewed individually, never batch-approved.
3. **Mandatory disposition** — Every reviewed item must receive one of:
   - **Approve** — Item is accepted as-is
   - **Revise** — Item needs modification (with specific feedback)
   - **Reject** — Item is unacceptable (with mandatory rationale)
4. **Rejection requires rationale** — Every rejected item must have a documented reason.
5. **Revision tracking** — Revised items are re-queued for next review round.
6. **No silent pass** — Agent must explicitly call out potential issues, even if recommending approval.

## Review Flow

```
Agent Analysis → Present Item → User Verdict → Record Disposition → Next Item
```

## Checklist Per Item
- [ ] Completeness — All required fields/sections present?
- [ ] Consistency — Aligned with related documents?
- [ ] Correctness — Technically/logically sound?
- [ ] Traceability — Properly linked to source items?

## Output
- Each item's disposition recorded in session `items[]` with `type: decision`
- Summary with approve/revise/reject counts
- Revised items registered for follow-up

## Micro-Commands
| Command | Action |
|---------|--------|
| `/approve [id]` | Approve item |
| `/revise [id] [feedback]` | Request revision |
| `/reject [id] [reason]` | Reject with rationale |
| `/skip [id]` | Defer to next round |
| `/summary` | Show review progress |
| `/done` | End session |
