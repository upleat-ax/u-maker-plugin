---
name: u-status
description: |
  프로젝트 대시보드. Phase, 진행률, 미완료 항목, impact flags 표시.
  Triggers: /u-status, 상태, status, 대시보드, dashboard, 진행률, progress
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [--assumptions] [--json]"
model: sonnet
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
  - ${PLUGIN_ROOT}/shared/references/ssot-standard.md
  - ${PLUGIN_ROOT}/shared/references/post-execution-summary.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-status -- 프로젝트 대시보드

> 프로젝트의 현재 상태를 대시보드 형태로 보여준다.

## 문법

```
/u-status [scope] [--assumptions] [--json]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 전체 요약)

## Flags

| Flag | 설명 |
|------|------|
| `--assumptions` | 미리뷰된 assumptions 목록 표시 |
| `--json` | JSON 형식으로 출력 |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 범위 결정
2. **Phase 감지** -- engine-phase-detector로 현재 Phase 확인
3. **문서 스캔** -- 모든 SSoT 문서 상태 수집
4. **진행률 계산** -- Phase별 완료/총계 비율
5. **미완료 항목** -- Draft/TODO 상태 항목 목록
6. **Impact Flags** -- 최근 변경이 cascade 영향을 미치는 항목
7. **Assumptions** (--assumptions) -- 미리뷰 assumption 목록
8. **대시보드 출력**

## 출력 형식

```
=== Project Status: my-app ===
Phase: PLAN (Iteration 1)
Progress: ████████░░ 80%

Documents:
  [Approved] SRS       -- FR:12 US:24 FT:48
  [Approved] IA        -- Pages:15
  [Draft]    Roadmap   -- Milestones:3 (1 미완료)

미완료 항목 (3):
  - FR-0013: 결제 시스템 연동 (Draft)
  - US-0025: 관리자 리포트 조회 (Draft)
  - Roadmap MS-3: v1.2 릴리스 (미정)

Impact Flags: 없음
```

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-phase-detector | Phase 감지 |

## 에이전트 시퀀스

```
orchestrator (단독 실행 -- sub-agent 불필요)
```

## 규칙

- 읽기 전용 (문서 수정 없음)
- --json 출력은 프로그래밍 연동용 구조화 형식
- 진행률은 Phase별 Gate 조건 기반으로 산정

## 사용 예시

```
/u-status my-app
/u-status --json
/u-status --assumptions
```
