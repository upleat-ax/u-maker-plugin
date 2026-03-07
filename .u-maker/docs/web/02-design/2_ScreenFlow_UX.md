---
document: "2_ScreenFlow_UX"
title: "u-maker Plugin Screen Flow"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/web/01-plan/1_IA_RA.md"
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/common/02-design/2_UXGuide_UX.md"
external_links: []
---

# u-maker Plugin Screen Flow

- **Owner**: u-UX
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [IA](../01-plan/1_IA_RA.md), [Screen Design](2_Screen_UX.md), [UX Guide](../../common/02-design/2_UXGuide_UX.md)

## 1. Global Flow

```mermaid
flowchart TD
    START["Repository Open"] --> SESSION["SessionStart Hook"]
    SESSION -->|docs missing| INIT_DOCS["Create/repair .u-maker/docs"]
    SESSION --> CMD["S-0010 Command Entry"]
    INIT_DOCS --> CMD
    CMD --> DEPLOY["S-0020 Deployment Surface"]
    CMD --> INIT["S-0030 Existing Repo Init Report"]
    CMD --> PHASE["S-0040 Phase Workspace"]
    PHASE --> VALIDATE["S-0050 Validation Review"]
    VALIDATE --> STATUS["S-0060 Status Dashboard"]
    STATUS -->|next iteration| CMD
```

## 2. Main Transition Rules

| From | To | Trigger | Condition |
|---|---|---|---|
| Repository Open | S-0010 | session start complete | docs structure exists or repaired |
| S-0010 | S-0020 | deploy/check/clean command | maintainer action |
| S-0010 | S-0030 | `/u-skill-init` | existing repo selected |
| S-0030 | S-0040 | draft docs generated | init complete |
| S-0040 | S-0050 | validate/build/check command | docs or code review needed |
| S-0050 | S-0060 | status or retrospective review | report available |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-UX | Screen flow defined for repo initialization and PDCA progression |
