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
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-pm: u-maker:u-agent-pm
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
---

# PLAN Phase

> 로드맵 → SRS(FR+NFR→US→FT) → IA → 인덱스 순서로 문서를 생성한다.

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app (e.g., `/u-skill-plan web`) |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Execution Sequence

PLAN Phase는 `FR+NFR → US → FT` 단일 체인으로 진행한다.

1. `u-agent-pm`: 로드맵 생성 (`common/01-plan/1_Roadmap_PM.md`)
2. `u-agent-sa`: SRS 작성 (`{app}/01-plan/1_SRS_RA.md`)
3. `u-agent-sa`: FR+NFR → US → FT 순서로 도출 후 Cross-mapping 완료 (`TBD` 잔존 불허)
4. `u-agent-ux`: 정보 구조도 작성 (`{app}/01-plan/1_IA_RA.md`)
5. `u-agent-pm`: 인덱스 생성 (`common/01-plan/1_Index_PM.md`)

### SRS 작성 규칙
- `u-agent-sa`: SRS의 FR/NFR(Section 2~3)을 기준으로 US(Section 5), FT(Section 6)를 순차 도출
- `u-agent-sa`: 암묵적(Implicit) FT 추가 도출 (유효성 검증, 에러 처리, 권한 등)
- User Story 1개당 3~7개 FT 도출 목표

## Gate → DESIGN

`common/1_Roadmap_PM` Final + 모든 앱의 `1_SRS_RA`, `1_IA_RA` Final + **FR+NFR→US→FT mapping complete** (`TBD` 잔존 불허)

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성 (스키마: `json-export.md`)
- 각 문서에 최소 1개 이상 Mermaid 다이어그램 포함 (가이드: `mermaid-guide.md`)
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
