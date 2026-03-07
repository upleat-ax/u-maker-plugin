---
document: "3_UIComponents_UX"
title: "u-maker Plugin UI Components"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
related_docs:
  - ".u-maker/docs/common/02-design/2_UXGuide_UX.md"
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/common/03-dev/3_DesignToken_UX.md"
  - ".u-maker/docs/web/03-dev/3_Code_DV.md"
external_links: []
---

# u-maker Plugin UI Components

- **Owner**: u-UX
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [UX Guide](../02-design/2_UXGuide_UX.md), [Screen Design](../../web/02-design/2_Screen_UX.md), [Design Tokens](3_DesignToken_UX.md), [Code Record](../../web/03-dev/3_Code_DV.md)

## 1. Reusable Interaction Components

| Component | Purpose | Typical Surface |
|---|---|---|
| StatusBadge | `Draft`, `Review`, `Final`, `PASS`, `FAIL` 상태 표현 | status/report/validation |
| DocRegistryTable | 문서 목록과 상태 추적 | index/docs/status |
| CommandBlock | 실행 가능한 명령 제안 | help/build/validate/init |
| IssueList | validation defect, backlog item, hook block reason 정리 | check/act/guard |
| TraceabilityTable | FR-US-FT-Doc-Code-QA 연결 표시 | SRS/RTM/gap analysis |
| GateSummary | phase gate readiness 요약 | status/index/report |

## 2. Component Rules

- `StatusBadge`는 색 이름 대신 상태 문자열을 반드시 포함한다.
- `CommandBlock`는 한 번에 실행 가능한 최소 명령만 제시한다.
- `DocRegistryTable`의 첫 열은 Doc ID, 마지막 열은 Status로 고정한다.
- `IssueList`는 severity 또는 blocking 여부로 정렬한다.
- `TraceabilityTable`은 FR/FT 식별자 없이 설명만 쓰지 않는다.

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-UX | Reusable markdown/terminal component patterns defined |
