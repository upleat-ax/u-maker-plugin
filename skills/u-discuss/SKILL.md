---
name: u-discuss
description: "This skill should be used when the user asks to 'discuss', 'brainstorm', 'review meeting', 'decision session', '/u-discuss', or wants to run a structured collaboration session."
version: 4.0.0
triggers:
  - "/u-discuss"
  - "brainstorm"
  - "review session"
  - "decision"
---

# u-discuss — Structured Discussion

`/u-discuss {type} [topic]`

Run structured collaboration sessions. Types: brainstorm, review, decision, workshop, retro.

## Session Types

| Type | Purpose | Output |
|------|---------|--------|
| brainstorm | Divergent ideation | Ideas list, grouped themes |
| review | Document/code review | Feedback, action items |
| decision | Decision-making | Options, criteria, final decision |
| workshop | Design workshop | Artifacts, design outputs |
| retro | Retrospective | Keep/Problem/Try/Actions |

## Flow

1. Announce session type + topic
2. Facilitate structured phases per type
3. Capture decisions, action items, ideas
4. Export session summary

## Reference Files

- **`references/session-types.md`** — Detailed facilitation guides for each session type
