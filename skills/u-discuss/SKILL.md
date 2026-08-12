---
name: u-discuss
description: "This skill should be used when the user asks to '/u-discuss', 'brainstorm', 'review session', 'decision', 'u-maker 토론', 'u-maker 브레인스토밍', '회의 검토 세션', or '의사결정 세션'. Runs a structured collaboration session."
version: 4.0.0
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

> **Plain language (HARD RULE):** Session documents (summaries, decisions, action items) are written so a middle-school student understands the explanatory prose on first read. Rule source: `skills/u-engine/references/doc-engine.md` § 8 / `html-engine.md` § 0.6; enforced by the GK-06 `plain-language-middle-school` check.

## Reference Files

- **`references/session-types.md`** — Detailed facilitation guides for each session type
