---
name: u-skill-plan
description: |
  PLAN Phase 실행. 로드맵 → SRS(FR→US→FT) → IA → 인덱스 순서로 문서를 생성한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-plan, plan phase, 플랜, 계획, planning, 계획 수립, 로드맵, roadmap, 기획, 요구사항 정리, requirements planning, SRS 작성, 이터레이션 계획, iteration planning
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
  u-agent-pm: u-maker:u-agent-pm
  u-agent-ra: u-maker:u-agent-ra
  u-agent-sa: u-maker:u-agent-sa
  u-agent-ux: u-maker:u-agent-ux
---

# PLAN Phase

> 로드맵 → SRS(FR→US→FT) → IA → 인덱스 순서로 문서를 생성한다.

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app (e.g., `/u-skill-plan web`) |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

Config 파일(`.u-maker/u-maker.config.json`)에서 `apps` 배열을 읽어 대상 앱을 결정한다.

## Prerequisites

- `.u-maker/docs/` 디렉토리 구조가 존재해야 한다 (없으면 `session-start.js` 훅이 자동 생성)
- `.u-maker/u-maker.config.json` 설정 파일이 존재해야 한다

## Execution Sequence

PLAN Phase는 `FR → US → FT` 단일 체인으로 진행한다. 각 단계는 순차 실행이며, 이전 단계의 산출물이 다음 단계의 입력이 된다.

### Step 1. 로드맵 생성

- **Agent**: `u-agent-pm`
- **Output**: `common/01-plan/1_Roadmap_PM.md` + `.json`
- **Content**: 프로젝트 목표(OKR/Goal), 마일스톤 정의, 일정 계획, 범위 설정
- **Diagram**: Mermaid flowchart로 마일스톤 흐름 시각화

### Step 1.5. 공통 정의 문서 생성

- **Agent**: `u-agent-ra`
- **Output**: `common/01-plan/1_Common_RA.md` + `.json`
- **Content**: 인증 정책, RBAC, 보안 정책, 공통 비즈니스 규칙, 에러 처리 표준, 용어 정의
- **Template**: `templates/01-plan/1_Common_RA.template.md`

### Step 2. SRS 작성

- **Agent**: `u-agent-sa`
- **Output**: `{app}/01-plan/1_SRS_RA.md` + `.json`
- **Content**: 로드맵 기반으로 요구사항 명세 전체를 작성한다

SRS 내부 작성 순서:
1. **FR 도출** (Section 2): 사용자 요구사항 + 로드맵 기반
   - Domain 코드(AUTH, CORE, ADMIN 등)로 그룹핑
   - 그룹별 최소 15개, 전체 최소 15~40개 목표
   - 암묵적(Implicit) FR 반드시 추론 (입력 검증, 에러 처리, 권한, 감사 이력, 페이지네이션, 상태 처리)
   - 각 FR에 USR Mapping + 구현 상태(`[ ] Not Started`) 포함
   - FR Details: Input/Output/Business Rule/Exception 모두 실제 내용으로 작성 (`{{TODO}}` 불허)
2. **NFR 도출** (Section 3): 최소 10개 (Performance 2, Security 3, Usability 2, Reliability 2, Scalability 1)
3. **Users 정의** (Section 4): USR-XXXX 형식
4. **User Stories 작성** (Section 5): As a / I want to / So that 형식, FR Mapping 필수
5. **Features 도출** (Section 6): US 기반 구현 단위 분해, US Mapping 필수
   - User Story 1개당 3~7개 FT 도출 목표
6. **추적성 매트릭스**: FT → Screen, FT → API 매핑 포함
7. **Mermaid flowchart**: 기능 관계도 작성

### Step 3. FR→US→FT Cross-mapping 검증

- **Agent**: `u-agent-sa`
- **Validation**: 모든 FR이 최소 1개 US에 매핑, 모든 US가 최소 1개 FT에 매핑
- **`TBD` 잔존 불허**: 매핑 필드에 `TBD`가 남아있으면 Gate 차단

### Step 4. 정보 구조도(IA) 작성

- **Agent**: `u-agent-ux`
- **Output**: `{app}/01-plan/1_IA_RA.md` + `.json`
- **Content**: SRS FR/FT 기반으로 전체 화면 계층 구조 정의
- **Diagram**: Mermaid로 네비게이션 구조 시각화

### Step 5. 인덱스 생성

- **Agent**: `u-agent-pm`
- **Output**: `common/01-plan/1_Index_PM.md` + `.json`
- **Content**: PLAN Phase에서 생성된 모든 문서의 레지스트리
  - Document Registry 테이블 (파일명, Owner, Status, Version, Last Updated)
  - Phase Status (Current Phase, Iteration, Loop Status)
  - FT Implementation Status 테이블

## Gate → DESIGN

PLAN Phase 완료 후 DESIGN Phase로 진행하기 위한 필수 조건:

| Gate Condition | Verification |
|---------------|-------------|
| `common/1_Roadmap_PM` | Status = Final |
| `common/1_Common_RA` | Status = Final |
| 모든 앱의 `1_SRS_RA` | Status = Final |
| 모든 앱의 `1_IA_RA` | Status = Final |
| FR→US→FT mapping | `TBD` 잔존 0건 |
| NFR | 최소 10개 정의 완료 |
| JSON Export | 모든 .md에 대응하는 .json 존재 |

Gate 실패 시 `u-agent-ra`가 PLAN origin BL(백로그) 항목을 생성한다.

## Iteration 2+ 동작

- 변경된 스토리/마일스톤만 증분 갱신한다
- 기존 문서의 Status가 Final인 경우, 변경 시 Draft로 강등 후 재작업
- 백로그(BL)에서 PLAN origin 항목이 있으면 해당 항목부터 처리

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성 (스키마: `json-export.md`)
- 각 문서에 최소 1개 이상 Mermaid 다이어그램 포함 (가이드: `mermaid-guide.md`)
- ID 넘버링: `XX-0010` 형식 (4자리, 10단위 증분). 앱 이름을 ID에 포함하지 않는다
- Reference-Only: 타 문서 참조 시 ID만 기재 (상세 내용 복사 금지)
- `_links.json` 매핑 갱신: FR/US/FT 추가/삭제 시 `.u-maker/docs/_links.json` 반드시 갱신
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
