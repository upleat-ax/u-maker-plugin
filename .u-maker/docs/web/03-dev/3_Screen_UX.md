---
document: "3_Screen_UX"
title: "u-maker Plugin Screen Implementation Guide"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
  - ".u-maker/docs/web/03-dev/3_Code_DV.md"
external_links: []
---

# u-maker Plugin Screen Implementation Guide

- **Owner**: u-UX
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [Screen Design](../02-design/2_Screen_UX.md), [API Contract](../02-design/2_API_SA.md), [Code Record](3_Code_DV.md)

## 1. Implementation Guidance

| Screen | Implementation Anchor |
|---|---|
| S-0010 | README command sections, `skills/*/SKILL.md` |
| S-0020 | `deploy_local.sh` console output |
| S-0030 | init workflow and generated docs listing |
| S-0040 | templates, `_refer` docs, index/RTM |
| S-0050 | `validate-ssot.py`, `check-exit-criteria.py`, QA docs |
| S-0060 | `.u-maker/u-maker.config.json`, iteration log, status skill |

## 2. Rendering Rules

- 결과 요약은 먼저, 세부 진단은 뒤에 배치한다.
- 표의 첫 column은 항상 identifier를 둔다.
- 실패 메시지는 원인과 조치 명령을 함께 보여준다.
- 문서 생성 결과는 생성 파일 목록과 skip/placeholder 항목을 분리한다.

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-UX | Implementation notes created for terminal-oriented surfaces |
