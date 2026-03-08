---
name: u-skill-design
description: |
  DESIGN Phase 실행. 화면설계 → ERD + API Contract + RTM → 모순검수 순서로 진행한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-design, design phase, 설계
model: sonnet
user-invocable: true
argument-hint: "[app]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-ux: u-maker:u-agent-ux
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ra: u-maker:u-agent-ra
---

# DESIGN Phase

> 화면설계 → ERD + API Contract + RTM → 모순검수 순서로 문서를 생성한다.

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app (e.g., `/u-skill-design web`) |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Execution Sequence

1. `u-agent-ux`: UX 표준가이드 + 디자인 시스템 (`common/02-design/2_UXGuide_UX.md`)
   - UX 원칙, 컬러, 타이포, 스페이싱, 컴포넌트 카탈로그
2. `u-agent-ux`: 화면 상세 설계 (`{app}/02-design/2_Screen_UX.md`)
   - UI 컴포넌트, 상태 전이, 반응형 규격
3. `u-agent-ux`: 화면 간의 흐름도 (`{app}/02-design/2_ScreenFlow_UX.md`)
   - 네비게이션 플로우, 조건부 전환, 딥링크 맵
4. `u-agent-ux`: 와이어프레임 (`{app}/02-design/2_Screen_Wireframes/`)
   - HTML/CSS 레이아웃 시각화, floating 어노테이션 패널
5. `u-agent-ux`: 화면 디자인 (`.pen` 파일, pencil.dev MCP)
   - 시각적 디자인 구현
6. `u-agent-sa`: ERD 작성 (`common/02-design/2_ERD_SA.md`)
   - Entity 정의, Relationship 다이어그램 (Mermaid erDiagram)
7. `u-agent-sa`: API Contract 작성 (`{app}/02-design/2_API_SA.md`)
   - OpenAPI 3.0 스펙, Endpoint 목록, Request/Response Schema
8. `u-agent-ra`: 요구사항 추적표(RTM) 작성 (`common/02-design/2_RTM_RA.md`)
   - `FR+NFR → US → FT` 기준으로 IA/Screen/API/ERD/QA 매핑 검증
9. `u-agent-ra`: 모순 검수
   - Screen ↔ ScreenFlow ↔ API ↔ ERD 간 불일치 탐지

## Gate → DO

`common/2_ERD_SA`, `common/2_RTM_RA`, `common/2_UXGuide_UX` Final + 모든 앱의 `2_API_SA`, `2_Screen_UX`, `2_ScreenFlow_UX` Final + u-RA 검수 통과

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성 (스키마: `json-export.md`)
- 각 문서에 최소 1개 이상 Mermaid 다이어그램 포함 (가이드: `mermaid-guide.md`)
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
