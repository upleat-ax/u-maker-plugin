---
name: u-ship
description: |
  ACT Phase. 최종 검증 + iteration log + retrospective + archive.
  Triggers: /u-ship, 배포, 출시, ship, release, ACT, 회고, retrospective, 아카이브
version: 2.0.0
user-invocable: true
argument-hint: "[scope]"
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
  - ${PLUGIN_ROOT}/templates/05-act/iteration-log.template.md
  - ${PLUGIN_ROOT}/templates/05-act/retrospective.template.md
agents:
  u-agent-orchestrator: u-maker:u-agent-orchestrator
  u-agent-planner: u-maker:u-agent-planner
  u-agent-builder: u-maker:u-agent-builder
  u-agent-guardian: u-maker:u-agent-guardian
---

# u-ship -- ACT Phase 실행

> 최종 검증을 수행하고 iteration을 마무리한다. 회고록과 아카이브를 생성한다.

## 문법

```
/u-ship [scope]
```

- `scope`: 앱 이름 | `common` | `all` (생략 시 자동 감지)

## 실행 흐름

1. **스코프 해석** -- engine-router로 대상 앱 결정
2. **Gate 검증** -- CHECK Phase exit criteria 충족 확인
3. **최종 검증** -- engine-validator로 전체 문서/코드 정합성 확인
   - 미해결 결함(Critical/Major) 잔존 여부
   - 문서 간 불일치 잔존 여부
4. **Iteration Log 생성** -- 현재 iteration 요약
   - 수행한 변경, 해결한 결함, 잔여 이슈
5. **Retrospective 생성** -- 회고록
   - 잘한 점, 개선점, 액션 아이템
6. **Archive 처리** -- 현재 iteration 산출물 스냅샷
7. **Phase 전환** -- 다음 iteration 또는 릴리스 결정
   - Pass → Release 준비
   - Fail → 다음 Iteration PLAN으로 회귀
8. **결과 보고** -- Post-Execution Summary 출력

## 사용 엔진

| Engine | 역할 |
|--------|------|
| engine-router | 스코프 해석 |
| engine-workflow-runner | ACT 흐름 오케스트레이션 |
| engine-validator | 최종 검증 |
| engine-dep | 의존성 분석 및 아카이브 |

## 에이전트 시퀀스

```
orchestrator → guardian (최종 검증 + 판정 + 회고)
```

## 규칙

- CHECK Phase exit criteria 미충족 시 실행 거부
- Iteration Log는 `.md` + `.json` 동시 생성
- Retrospective는 `.md` + `.json` + `.html` 3종 생성
- Critical 결함 잔존 시 릴리스 차단
- Archive는 `.u-maker/archive/iteration-{N}/`에 저장

## 사용 예시

```
/u-ship my-app
/u-ship
```
