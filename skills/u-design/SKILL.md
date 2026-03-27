---
name: u-design
description: |
  DESIGN Phase 문서 생성. SRS/IA 기반 ERD, API, Screen, Flow, UXGuide 연쇄 생성.
  Triggers: /u-design, 설계, design, ERD, API, 화면 설계, screen, UX 가이드, flow
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [-i] [--step] [--only erd|api|screens|screen-flow|ux-guide]"
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
  - ${PLUGIN_ROOT}/templates/02-design/erd.template.md
  - ${PLUGIN_ROOT}/templates/02-design/api.template.md
  - ${PLUGIN_ROOT}/templates/02-design/screens.template.md
  - ${PLUGIN_ROOT}/templates/02-design/screen-flow.template.md
  - ${PLUGIN_ROOT}/templates/02-design/ux-guide.template.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-design -- DESIGN Phase 문서 생성

> SRS/IA를 입력으로 ERD, API Contract, Screen 명세, Screen Flow, UX Guide를 연쇄 생성한다.

## 문법

```
/u-design [scope] [-i] [--step] [--only erd|api|screens|screen-flow|ux-guide]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## Flags

| Flag | 설명 |
|------|------|
| `-i` | 대화형 모드 |
| `--step` | 단계별 실행 |
| `--only` | 특정 산출물만 생성 |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **선행 문서 확인** -- SRS, IA 존재 및 상태 검증
3. **ERD 생성** -- SRS의 데이터 모델 기반 엔티티-관계 다이어그램
4. **API Contract 생성** -- US/FT 기반 RESTful API 명세
5. **Screen 명세 생성** -- IA + US 기반 화면별 상세 명세
6. **Screen Flow 생성** -- 화면 간 전환 흐름도
7. **UX Guide 생성** -- 디자인 원칙, 컴포넌트 규칙, 접근성 기준
8. **일관성 검증** -- guardian이 SRS↔ERD↔API↔Screen 정합성 확인
9. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-workflow-runner | 연쇄 생성 오케스트레이션 |
| engine-doc | 문서 생성/갱신 |
| engine-designer | ERD, Screen, Flow 설계 |
| engine-validator | 문서 간 일관성 검증 |

## 에이전트 시퀀스

```
orchestrator → planner (설계 문서 생성) → guardian (일관성 검증)
```

## 규칙

- SRS가 Approved 상태가 아니면 경고 후 사용자 확인
- ERD의 엔티티는 SRS의 데이터 모델과 1:1 대응
- API의 엔드포인트는 US/FT와 추적 가능해야 함
- Screen은 IA의 모든 페이지를 커버해야 함
- 모든 문서 `.md` + `.json` 동시 생성

## 사용 예시

```
/u-design my-app
/u-design my-app --only erd
/u-design -i --step
```
