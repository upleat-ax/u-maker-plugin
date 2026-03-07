---
document: "2_UXGuide_UX"
title: "u-maker Plugin UX Guide"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
related_docs:
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/web/02-design/2_ScreenFlow_UX.md"
  - ".u-maker/docs/common/03-dev/3_UIComponents_UX.md"
  - ".u-maker/docs/common/03-dev/3_DesignToken_UX.md"
external_links: []
---

# u-maker Plugin UX Guide

- **Owner**: u-UX
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [Screen Design](../../web/02-design/2_Screen_UX.md), [Screen Flow](../../web/02-design/2_ScreenFlow_UX.md), [UI Components](../03-dev/3_UIComponents_UX.md), [Design Tokens](../03-dev/3_DesignToken_UX.md)

## 1. Design Intent

이 프로젝트의 UX는 브라우저 기반 제품 UI가 아니라 에이전트 협업을 보조하는 터미널/markdown 중심 경험이다. 따라서 좋은 UX는 화려한 시각 효과보다 다음 조건을 만족해야 한다.

- 상태가 빠르게 스캔된다.
- 추천 명령과 다음 액션이 명시된다.
- Gate 실패 원인이 숨지 않는다.
- 문서 경로와 파일명이 일관되다.
- 긴 텍스트보다 표, 체크리스트, 코드블록이 우선한다.

## 2. Interaction Principles

| Principle | Guidance |
|---|---|
| Clarity | 모든 응답은 현재 phase, 대상 app, 산출물 경로를 먼저 보여준다. |
| Traceability | FR, US, FT, 문서 경로, 코드 경로의 링크를 남긴다. |
| Non-destructive | 덮어쓰기 전 경고, 기존 문서 보존, Draft 기본값을 유지한다. |
| Operational Readability | 표, 짧은 bullets, monospace path를 선호한다. |
| Progressive Disclosure | 첫 응답은 요약, 상세는 문서나 하위 섹션에서 제공한다. |

## 3. Interaction Surface Patterns

| Surface | Pattern |
|---|---|
| Slash command response | 요약 1문단 + 생성/수정 파일 목록 + 다음 추천 명령 |
| Hook warning | 차단 이유 1개, 우선 실행할 명령 1개, 금지 행동 1개 |
| Validation report | PASS/FAIL를 먼저, 이후 file-specific issues |
| Phase status | `phase`, `iteration`, `loopStatus`, gate readiness를 표로 제시 |

## 4. Accessibility for Text UI

- status 값은 색상에 의존하지 않고 텍스트(`Draft`, `Review`, `Final`)로 식별한다.
- markdown 표는 column 이름만 봐도 의미가 드러나게 작성한다.
- 긴 경로는 inline code로, 핵심 파일은 링크로 노출한다.
- 경고 문구는 한글 설명과 영문 identifier를 함께 보여준다.

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-UX | UX guide specialized for terminal/markdown interaction surfaces |
