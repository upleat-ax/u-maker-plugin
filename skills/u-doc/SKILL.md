---
name: u-doc
description: |
  특정 SSoT 문서 조회, 편집, 재생성.
  Triggers: /u-doc, 문서, document, 조회, 편집, 재생성, doc, 문서 관리
version: 2.0.0
user-invocable: true
argument-hint: "[scope] [doc]"
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

# u-doc -- 문서 조회/편집/재생성

> 특정 SSoT 문서를 조회하거나 편집, 재생성한다.

## 문법

```
/u-doc [scope] [doc]
```

- `scope`: 앱 이름 | `common` (생략 시 자동 감지)
- `doc`: 문서 이름 (생략 시 문서 목록 표시)

## 지원 문서

| 문서 | 설명 | Phase |
|------|------|-------|
| `srs` | Software Requirements Specification | PLAN |
| `ia` | Information Architecture | PLAN |
| `roadmap` | Roadmap | PLAN |
| `erd` | Entity Relationship Diagram | DESIGN |
| `api` | API Contract | DESIGN |
| `screens` | Screen 명세 | DESIGN |
| `screen-flow` | Screen Flow | DESIGN |
| `ux-guide` | UX Guide | DESIGN |
| `testcase` | Test Cases | CHECK |
| `qa-report` | QA Report | CHECK |

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **문서 탐색** -- doc 생략 시 `.u-maker/docs/` 하위 문서 목록 표시
3. **문서 로드** -- engine-doc으로 대상 문서 읽기
4. **모드 판단** -- 사용자 요청에 따라 조회/편집/재생성 결정
   - 조회: 문서 내용 요약 또는 전문 표시
   - 편집: 대화형으로 수정 사항 반영
   - 재생성: 기존 문서 삭제 후 템플릿 기반 재생성
5. **갱신** -- `.md` + `.json` 동시 갱신
6. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-doc | 문서 읽기/쓰기/재생성 |

## 에이전트 시퀀스

```
orchestrator → planner (문서 조회/편집/재생성)
```

## 규칙

- 재생성 시 기존 문서 백업 후 진행
- 편집 시 변경 로그 자동 기록
- 조회 시 문서 상태(Status)와 최종 수정일 함께 표시

## 사용 예시

```
/u-doc my-app srs
/u-doc my-app
/u-doc common erd
```
