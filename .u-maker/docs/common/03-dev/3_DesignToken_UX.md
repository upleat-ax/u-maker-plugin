---
document: "3_DesignToken_UX"
title: "u-maker Plugin Design Tokens"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
related_docs:
  - ".u-maker/docs/common/02-design/2_UXGuide_UX.md"
  - ".u-maker/docs/common/03-dev/3_UIComponents_UX.md"
  - ".u-maker/docs/web/03-dev/3_Code_DV.md"
external_links: []
---

# u-maker Plugin Design Tokens

- **Owner**: u-UX
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [UX Guide](../02-design/2_UXGuide_UX.md), [UI Components](3_UIComponents_UX.md), [Code Record](../../web/03-dev/3_Code_DV.md)

## 1. Semantic Tokens for Text UI

| Token | Value | Usage |
|---|---|---|
| `status.draft` | `Draft` | 초기 생성 문서 |
| `status.review` | `Review` | 검토 대기 문서 |
| `status.final` | `Final` | Gate 통과 가능 문서 |
| `result.pass` | `PASS` | 검증 성공 |
| `result.fail` | `FAIL` | 검증 실패 |
| `severity.critical` | `Critical` | 즉시 조치 필요 |
| `severity.major` | `Major` | Gate 차단 가능 |
| `severity.minor` | `Minor` | 후속 보완 |

## 2. Suggested Visual Mapping

| Semantic Role | Light Value | Notes |
|---|---|---|
| primary text | `#111827` | 일반 본문 |
| secondary text | `#4B5563` | 설명/힌트 |
| border default | `#D1D5DB` | 표/섹션 구분 |
| accent plan | `#2563EB` | PLAN 관련 강조 |
| accent design | `#0891B2` | DESIGN 관련 강조 |
| accent do | `#059669` | DO 관련 강조 |
| accent check | `#D97706` | CHECK 관련 강조 |
| accent act | `#7C3AED` | ACT 관련 강조 |
| danger | `#DC2626` | blocking issue |

## 3. Typography Rules

- heading은 짧게 유지한다.
- 파일 경로, 명령어, doc id는 backtick 처리한다.
- 긴 설명은 표 아래 bullet 3개 이내로 제한한다.
- 사용자에게 보이는 기본 응답은 3단계 이상 nested list를 만들지 않는다.

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-UX | Minimal design tokens for markdown-oriented surfaces |
