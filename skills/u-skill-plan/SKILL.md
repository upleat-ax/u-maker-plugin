---
name: u-skill-plan
description: |
  PLAN Phase 실행. 로드맵 → SRS → IA → 인덱스 순서로 문서를 생성한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-plan web`).
  Triggers: /u-skill-plan, plan phase, 플랜, 계획
model: sonnet
user-invocable: true
argument-hint: "[web]"
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
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
agents:
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
---

# PLAN Phase

> 로드맵 → SRS(US+FR) → IA → 인덱스 순서로 문서를 생성한다.

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app (e.g., `/u-skill-plan web`) |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Execution Sequence

PLAN Phase는 US-First 또는 FT-First 두 가지 패턴을 지원한다.

### Pattern A (US-First)
1. `u-agent-ra`: 로드맵 생성 (`common/01-plan/1_Roadmap_PM.md`)
2. `u-agent-sa`: SRS 작성 — USR(Section 2) → US(Section 3) → FT 도출(Section 4) → FR 도출(Section 5) (`{app}/01-plan/1_SRS_RA.md`)
3. Cross-mapping: US↔FT TBD → 실제 ID 매핑 전체 갱신 (TBD 불허)
4. `u-agent-ux`: 정보 구조도 작성 (`{app}/01-plan/1_IA_RA.md`)
5. `u-agent-ra`: 인덱스 생성 (`common/01-plan/1_Index_PM.md`)

### Pattern B (FT-First)
1. `u-agent-sa`: SRS 작성 — FT 먼저 (`{app}/01-plan/1_SRS_RA.md`)
2. `u-agent-ra`: 로드맵 생성 (`common/01-plan/1_Roadmap_PM.md`)
3. Cross-mapping 완료
4. `u-agent-ux`: 정보 구조도 작성 (`{app}/01-plan/1_IA_RA.md`)
5. `u-agent-ra`: 인덱스 생성 (`common/01-plan/1_Index_PM.md`)

### SRS 작성 규칙
- `u-agent-sa`: SRS의 User Stories(Section 3)에서 FT 도출 → US Mapping 필드로 추적
- `u-agent-sa`: 암묵적(Implicit) FT 추가 도출 (유효성 검증, 에러 처리, 권한 등)
- User Story 1개당 3~7개 FT 도출 목표

## Gate → DESIGN

`common/1_Roadmap_PM` Final + 모든 앱의 `1_SRS_RA`, `1_IA_RA` Final + **US→FR mapping complete** (모든 US에 FR-ID 매핑 완료, TBD 잔존 불허)

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성 (스키마: `json-export.md`)
- 각 문서에 최소 1개 이상 Mermaid 다이어그램 포함 (가이드: `mermaid-guide.md`)
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
