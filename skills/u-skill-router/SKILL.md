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
| `flags` | `-i`, `--step`, `--only X`, `--cascade`, `--review` |

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
| `/u-qa` | guardian | validator, test | Check |
| `/u-ship` | orchestrator | validator, workflow-runner | Act |
| `/u-loop` | orchestrator | workflow-runner | ALL |

### Operations

| Command | Agent | Engine Skills |
|---------|-------|--------------|
| `/u-add` | planner | doc |
| `/u-update` | planner | doc, dep |
| `/u-doc` | planner | doc |
| `/u-sync` | guardian | validator, dep |
| `/u-gate` | orchestrator | phase-detector, validator |

### Observability

| Command | Agent | Engine Skills |
|---------|-------|--------------|
| `/u-status` | orchestrator | phase-detector, dep |
| `/u-coverage` | guardian | validator |
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

**Mode 우선순위:** `--step` > `-i` > auto(기본)

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

---

## 8. Error Handling

| Error | Response |
|-------|----------|
| Unknown command | 커맨드 안내 + help |
| Invalid scope | 등록 앱 목록 표시 |
| Missing argument | 필수 인자 안내 |
| Phase gate failure | /u-gate 먼저 실행 안내 |
| Config not found | /u-init 먼저 실행 안내 |
