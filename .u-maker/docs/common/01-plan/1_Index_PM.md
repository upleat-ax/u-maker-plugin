---
document: "1_Index_PM"
title: "u-maker Plugin Document Index"
owner: "u-PM"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
related_docs:
  - ".u-maker/docs/_links.json"
  - ".u-maker/docs/common/01-plan/1_Roadmap_PM.md"
  - ".u-maker/docs/web/01-plan/1_SRS_RA.md"
external_links: []
---

# u-maker Plugin Document Index

- **Owner**: u-PM
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [Links](../../_links.json), [Roadmap](1_Roadmap_PM.md), [SRS](../../web/01-plan/1_SRS_RA.md)

## 1. Current State

| Key | Value |
|---|---|
| Project | u-maker-plugin |
| Document Language | ko |
| Current Phase | plan |
| Current Iteration | 1 |
| Loop Status | STOPPED |
| App Scope | web (logical command/interaction surface) |
| Generated Docs | 20 including `_links.json` |

## 2. Document Registry

### 2.1 Common

| Doc ID | Path | Owner | Status |
|---|---|---|---|
| 1_Roadmap_PM | `.u-maker/docs/common/01-plan/1_Roadmap_PM.md` | u-PM | Draft |
| 1_Index_PM | `.u-maker/docs/common/01-plan/1_Index_PM.md` | u-PM | Draft |
| 1_Common_RA | `.u-maker/docs/common/01-plan/1_Common_RA.md` | u-RA | Draft |
| 2_ERD_SA | `.u-maker/docs/common/02-design/2_ERD_SA.md` | u-SA | Draft |
| 2_RTM_RA | `.u-maker/docs/common/02-design/2_RTM_RA.md` | u-RA | Draft |
| 2_UXGuide_UX | `.u-maker/docs/common/02-design/2_UXGuide_UX.md` | u-UX | Draft |
| 3_UIComponents_UX | `.u-maker/docs/common/03-dev/3_UIComponents_UX.md` | u-UX | Draft |
| 3_DesignToken_UX | `.u-maker/docs/common/03-dev/3_DesignToken_UX.md` | u-UX | Draft |
| 5_IterationLog_RA | `.u-maker/docs/common/05-act/5_IterationLog_RA.md` | u-RA | Draft |
| 5_Retrospective_PM | `.u-maker/docs/common/05-act/5_Retrospective_PM.md` | u-PM | Draft |

### 2.2 web

| Doc ID | Path | Owner | Status |
|---|---|---|---|
| 1_SRS_RA | `.u-maker/docs/web/01-plan/1_SRS_RA.md` | u-SA | Draft |
| 1_IA_RA | `.u-maker/docs/web/01-plan/1_IA_RA.md` | u-UX | Draft |
| 2_API_SA | `.u-maker/docs/web/02-design/2_API_SA.md` | u-SA | Draft |
| 2_Screen_UX | `.u-maker/docs/web/02-design/2_Screen_UX.md` | u-UX | Draft |
| 2_ScreenFlow_UX | `.u-maker/docs/web/02-design/2_ScreenFlow_UX.md` | u-UX | Draft |
| 3_Code_DV | `.u-maker/docs/web/03-dev/3_Code_DV.md` | u-DV-FE | Draft |
| 3_Screen_UX | `.u-maker/docs/web/03-dev/3_Screen_UX.md` | u-UX | Draft |
| 4_Case_QA | `.u-maker/docs/web/04-check/4_Case_QA.md` | u-QA | Draft |
| 4_Report_QA | `.u-maker/docs/web/04-check/4_Report_QA.md` | u-QA | Draft |

## 3. Phase Gate Snapshot

| Gate | Required Docs | Status |
|---|---|---|
| PLAN -> DESIGN | Roadmap, SRS, IA | Not Ready, all Draft |
| DESIGN -> DO | ERD, RTM, UXGuide, API, Screen, ScreenFlow | Not Ready, all Draft |
| DO -> CHECK | 3_Code_DV + build success | Not Ready |
| CHECK -> COMPLETE | QA zero critical/major + all FR implemented + build success | Not Ready |

## 4. Reverse-Engineering Notes

- 루트 기준 `package.json`, `prisma/schema.prisma`, `app/`, `pages/`, `components/`는 존재하지 않았다.
- 저장소의 실제 핵심 자산은 `README.md`, `.claude-plugin/`, `skills/`, `agents/`, `hooks/`, `lib/`, `scripts/`, `templates/`, `_refer/`이다.
- 설계 문서는 웹 UI 대신 터미널/markdown/command interaction surface를 기준으로 작성했다.
- DB/API 부재 영역은 `{{TODO: 수동 입력 필요}}` 대신 개념 모델과 automation contract로 선기입했다.

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-PM | Initial reverse-engineered index created |
