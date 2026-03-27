---
name: u-init
description: |
  프로젝트 초기화. .u-maker/ 전체 구조 생성, u-maker.config.json 초기화, 앱 등록.
  Triggers: /u-init, 프로젝트 초기화, 새 프로젝트, init project, create project, 프로젝트 시작
version: 2.0.0
user-invocable: true
argument-hint: "[project-name]"
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
  - ${PLUGIN_ROOT}/templates/config/u-maker.config.template.json
  - ${PLUGIN_ROOT}/templates/config/app.config.template.json
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-init -- 프로젝트 초기화

> .u-maker/ 전체 구조를 생성하고 프로젝트 설정을 초기화한다.

## 문법

```
/u-init [project-name]
```

- `project-name`: 프로젝트 이름 (생략 시 AskUserQuestion으로 입력 요청)

## 실행 흐름

1. **프로젝트 이름 확정** -- 인자 또는 대화형 입력
2. **디렉토리 구조 생성** -- `.u-maker/` 하위 전체 트리
   ```
   .u-maker/
   ├── docs/
   │   └── common/
   ├── scripts/
   ├── templates/
   └── u-ssot.config.json
   ```
3. **Config 초기화** -- `u-maker.config.template.json` 기반 `u-ssot.config.json` 생성
4. **앱 등록** -- `app.config.template.json` 기반 첫 앱 등록
5. **Phase 설정** -- 초기 Phase를 `PLAN`으로 설정
6. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 및 경로 결정 |
| engine-doc | 초기 문서 템플릿 배치 |
| engine-phase-detector | 초기 Phase 설정 |

## 에이전트 시퀀스

```
orchestrator → planner (구조 설계 + config 초기화)
```

## Flags

| Flag | 설명 |
|------|------|
| (없음) | 기본 초기화만 수행 |

## 규칙

- 이미 `.u-maker/` 존재 시 덮어쓰기 여부를 AskUserQuestion으로 확인
- `u-ssot.config.json`의 `documentPaths.root`는 `.u-maker/docs`로 고정
- 초기 Phase는 반드시 `PLAN`

## 사용 예시

```
/u-init my-saas-app
/u-init
```
