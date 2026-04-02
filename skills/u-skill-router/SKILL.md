---
name: u-skill-router
description: "자연어 및 /u-* 커맨드에서 의도를 분류하고, 스코프 해석, 플래그 파싱, 에이전트 디스패치를 수행하는 내부 라우팅 엔진."
---

# u-skill-router -- Intent Classification & Agent Dispatch Engine

사용자 입력(자연어 또는 `/u-*` 커맨드) 파싱 → 의도 분류 → 에이전트 디스패치. `u-agent-orchestrator`가 모든 진입점에서 호출.

**Owner Agent:** u-agent-orchestrator

---

## 1. Command Grammar

```
/u-{command} [scope] [target] [flags]
```

| Segment | Examples |
|---------|----------|
| `command` | init, ingest, plan, design, build, check, ship, add, update, ... |
| `scope` | retail, corp, common, all (앱 이름 또는 예약어) |
| `target` | srs, erd, FR-0001 (문서/항목) |
| `flags` | `-i`, `--step`, `--only X`, `--cascade`, `--review`, `--loop` |

---

## 2. Command → Agent Routing Table

### Lifecycle

| Command | Agent | Engine Skills | Phase |
|---------|-------|--------------|-------|
| `/u-init` | orchestrator | doc | -- |
| `/u-reverse` | planner | doc | Design |
| `/u-ingest` | planner | analyzer | Plan |
| `/u-plan` | planner | doc, estimator | Plan |
| `/u-design` | planner | designer, doc | Design |
| `/u-dev` | builder | code | Do |
| `/u-qa` | gatekeeper | validator, test | Check |
| `/u-ship` | orchestrator | validator, workflow-runner | Act |
| `/u-loop` | orchestrator | workflow-runner | ALL |

### Operations

| Command | Agent | Engine Skills |
|---------|-------|--------------|
| `/u-add` | planner | doc |
| `/u-update` | planner | doc, dep |
| `/u-doc` | planner | doc |
| `/u-sync` | gatekeeper | validator, dep |
| `/u-gate` | orchestrator | phase-detector, validator |
| `/u-codereview` | gatekeeper | validator |

### Observability

| Command | Agent | Engine Skills |
|---------|-------|--------------|
| `/u-status` | orchestrator | phase-detector, dep |
| `/u-coverage` | gatekeeper | validator |
| `/u-trace` | orchestrator | dep |
| `/u-report` | orchestrator | doc |

### Collaboration

| Command | Agent | Engine Skills |
|---------|-------|--------------|
| `/u-ask` | orchestrator | (context read only) |
| `/u-discuss` | orchestrator | facilitator |
| `/u-assume` | orchestrator | doc |
| `/u-backlog` | orchestrator | backlog |

---

## 3. Scope Resolution (6-Rule)

첫 번째 매칭에서 확정:

1. **Exact App Match:** config apps[].name 일치 → 해당 앱
2. **common:** `docs/common/` 스코프
3. **all:** 모든 앱 순차 (또는 --parallel)
4. **Comma-Separated:** "retail,corp" → 각 앱 순차
5. **Auto-Detect:** 생략 시 앱 1개 자동 / 2개+ 사용자 질문
6. **Fallback to Target:** 앱 이름 아님 → target으로 재해석 (예: `/u-doc srs`)

---

## 4. Flag Parsing

### Global Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `-i` | boolean | false | Interactive mode |
| `--step` | boolean | false | Step mode (매 단계 승인) |
| `--only <v>` | string | null | 지정 문서만 처리 |
| `--cascade` | boolean | false | 하위 의존 문서 자동 갱신 |
| `--review` | boolean | false | 사용자 검증 후 반영 |
| `--incremental` | boolean | false | 변경 파일만 처리 |
| `--parallel` | boolean | false | all 스코프 병렬 |
| `--loop` | boolean | false | Quality Loop — 실행 결과를 gatekeeper이 10개 기준으로 평가, 평균 95점 초과까지 고도화 반복 |
| `--loop-max <n>` | number | 3 | Quality Loop 최대 반복 횟수 (기본 3회) |
| `--loop-threshold <n>` | number | 95 | Quality Loop 통과 기준 점수 (기본 95점) |

**Mode 우선순위:** `--step` > `-i` > auto(기본)

**`--loop` 동작:** 모든 command/skill에 공통 적용. 실행 agent가 결과를 산출하면 gatekeeper이 10개 품질 기준으로 평가(각 0-100점). 평균 점수가 threshold 이하면 gatekeeper 피드백을 기반으로 고도화된 방법으로 재수행. 평균 > threshold 또는 max 도달 시 종료.

---

## 5. Reserved Words

| Type | Words |
|------|-------|
| Scope | `common`, `all` |
| Target (docs) | srs, ia, roadmap, erd, api, screens, screen-flow, ux-guide, design-token, rtm, code, test-cases, test-report, iteration-log, retrospective |
| Type (/u-add) | fr, nr, us, ft, screen, tc |
| Session (/u-discuss) | brainstorm, review, decision, workshop, retro |

---

## 6. Natural Language Intent Classification

명시적 `/u-*`가 아닌 자연어 처리:

**Confidence 기반 라우팅:** >=0.85 즉시 / 0.70-0.84 확인 요청 / <0.70 상위 3후보 제시

**Keyword → Command 매핑:** 초기화→init, 역공학→reverse, 분석→ingest, 기획/SRS→plan, 설계/ERD→design, 개발/코드→dev, 테스트/QA→qa, 배포→ship, 루프/자동→loop, 추가→add, 수정→update, 토론→discuss, 상태→status, 리포트→report, 질문→ask 등

**Non-u-maker Fallback:** 범위 밖 판정 시 안내 + help 제안

---

## 7. Dispatch Protocol

확정된 라우팅 정보를 에이전트에 전달: `{ command, scope, target, flags, mode, resolvedPaths, currentPhase, config }`

`--loop` 플래그 포함 시 추가 전달: `{ loop: { enabled: true, maxIterations: n, threshold: n, currentIteration: 0 } }`

---

## 8. Error Handling

| Error | Response |
|-------|----------|
| Unknown command | 커맨드 안내 + help |
| Invalid scope | 등록 앱 목록 표시 |
| Missing argument | 필수 인자 안내 |
| Phase gate failure | /u-gate 먼저 실행 안내 |
| Config not found | /u-init 먼저 실행 안내 |
