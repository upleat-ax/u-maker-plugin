---
name: u-skill-router
description: "자연어 및 /u-* 커맨드에서 의도를 분류하고, 스코프 해석, 플래그 파싱, 에이전트 디스패치를 수행하는 내부 라우팅 엔진."
---

# u-skill-router -- Intent Classification & Agent Dispatch Engine

사용자 입력(자연어 또는 명시적 `/u-*` 커맨드)을 파싱하여 의도를 분류하고, 올바른 에이전트에 작업을 디스패치하는 내부 엔진. `u-agent-orchestrator`가 모든 진입점에서 이 엔진을 호출한다.

**Owner Agent:** u-agent-orchestrator

---

## 1. Command Grammar

```
/u-{command} [scope] [target] [flags]
```

| Segment | Description | Examples |
|---------|-------------|----------|
| `command` | 실행할 명령어 | init, ingest, plan, design, build, check, ship, add, update, ... |
| `scope` | 앱 이름, `common`, `all`, 생략(자동) | retail, corp, common, all |
| `target` | 문서/항목 이름 (선택적) | srs, erd, FR-0001 |
| `flags` | 동작 변경자 | `-i`, `--step`, `--only X`, `--cascade`, `--review`, `--incremental` |

---

## 2. Command → Agent Routing Table

### Lifecycle Commands

| Command | Primary Agent | Engine Skills Used | Phase |
|---------|--------------|-------------------|-------|
| `/u-init` | orchestrator | engine-doc | -- |
| `/u-reverse` | planner | engine-doc | Design |
| `/u-ingest` | planner | engine-analyzer | Plan |
| `/u-plan` | planner | engine-doc, engine-estimator | Plan |
| `/u-design` | planner | engine-designer, engine-doc | Design |
| `/u-dev` | builder | engine-code | Do |
| `/u-check` | guardian | engine-validator, engine-test | Check |
| `/u-ship` | orchestrator | engine-validator, engine-workflow-runner | Act |

### Operations Commands

| Command | Primary Agent | Engine Skills Used |
|---------|--------------|-------------------|
| `/u-add` | planner | engine-doc |
| `/u-update` | planner | engine-doc, engine-dep |
| `/u-doc` | planner | engine-doc |
| `/u-sync` | guardian | engine-validator, engine-dep |
| `/u-gate` | orchestrator | engine-phase-detector, engine-validator |

### Observability Commands

| Command | Primary Agent | Engine Skills Used |
|---------|--------------|-------------------|
| `/u-status` | orchestrator | engine-phase-detector, engine-dep |
| `/u-coverage` | guardian | engine-validator |
| `/u-trace` | orchestrator | engine-dep |

### Collaboration Commands

| Command | Primary Agent | Engine Skills Used |
|---------|--------------|-------------------|
| `/u-ask` | orchestrator | -- (context read only) |
| `/u-discuss` | orchestrator | engine-facilitator |
| `/u-assume` | orchestrator | engine-doc |
| `/u-backlog` | orchestrator | u-skill-backlog |

---

## 3. Scope Resolution Algorithm

6-Rule 순차 평가. 첫 번째 매칭 규칙에서 확정.

### Rule 1: Exact App Match

```
scope가 u-maker.config.json의 apps[].name과 일치하면 → 해당 앱 스코프
```

### Rule 2: Reserved Scope -- common

```
scope === "common" → docs/common/ 스코프
```

### Rule 3: Reserved Scope -- all

```
scope === "all" → 모든 등록 앱 순차 실행 (기본) 또는 --parallel
```

### Rule 4: Comma-Separated Multi-App

```
scope에 콤마 포함 (e.g., "retail,corp") → 각 앱에 대해 순차 실행
```

### Rule 5: Auto-Detect (Omitted Scope)

```
scope 생략 시:
  - 등록 앱 1개 → 자동 선택
  - 등록 앱 2개+ → 사용자에게 선택 질문
```

### Rule 6: Fallback to Target

```
scope가 앱 이름도 예약어도 아님 → [target]으로 재해석
예: /u-doc srs → scope=auto, target=srs
```

### Resolution Procedure

```
function resolveScope(args, config):
  apps = config.apps[].name
  word = args[0]

  if word in apps           → return { scope: word, remaining: args[1:] }    // Rule 1
  if word === "common"      → return { scope: "common", remaining: args[1:] }  // Rule 2
  if word === "all"         → return { scope: "all", remaining: args[1:] }     // Rule 3
  if word contains ","      → return { scope: word.split(","), remaining: args[1:] }  // Rule 4
  if word is undefined      → return { scope: autoDetect(apps), remaining: args }  // Rule 5
  else                      → return { scope: autoDetect(apps), remaining: args }  // Rule 6 (word → target)
```

---

## 4. Flag Parsing Rules

### Global Flags (모든 커맨드에서 사용 가능)

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `-i` | boolean | false | Interactive mode: 분기점에서만 중단하여 사용자 확인 |
| `--step` | boolean | false | Step mode: 매 단계 결과 표시 후 승인 대기 |
| `--only <value>` | string | null | 지정 문서/영역만 처리 |
| `--cascade` | boolean | false | 변경 시 하위 의존 문서 자동 갱신 |
| `--review` | boolean | false | 추출 항목을 사용자 검증 후 반영 |
| `--incremental` | boolean | false | 변경된 파일만 처리 |
| `--parallel` | boolean | false | `all` 스코프에서 병렬 실행 |

### Flag Parsing Logic

```
function parseFlags(tokens):
  flags = {}
  i = 0
  while i < tokens.length:
    token = tokens[i]
    if token === "-i"           → flags.interactive = true
    if token === "--step"       → flags.step = true
    if token === "--only"       → flags.only = tokens[++i]
    if token === "--cascade"    → flags.cascade = true
    if token === "--review"     → flags.review = true
    if token === "--incremental" → flags.incremental = true
    if token === "--parallel"   → flags.parallel = true
    if token === "--wrap"       → flags.wrap = true
    if token === "--resume"     → flags.resume = tokens[++i]  // session ID
    if token === "--agents"     → flags.agents = tokens[++i]
    if token === "--context"    → flags.context = tokens[++i]
    i++
  return flags
```

### Execution Mode Priority

```
--step  →  step mode (최우선)
-i      →  interactive mode
(none)  →  auto mode (기본)
```

---

## 5. Reserved Words

라우터는 다음 단어들을 scope/target/type으로 특별 처리한다.

### Scope Reserved Words

```
common, all
```

### Target Reserved Words (Document Types)

```
srs, ia, roadmap, erd, api, screens, screen-flow,
ux-guide, design-token, rtm, code, test-cases,
test-report, iteration-log, retrospective
```

### Type Reserved Words (/u-add 전용)

```
fr, nr, us, ft, screen, tc
```

### Session Types (/u-discuss 전용)

```
brainstorm, review, decision, workshop, retro
```

---

## 6. Natural Language Intent Classification

명시적 `/u-*` 커맨드가 아닌 자연어 입력 처리:

### Step 1: Intent Extraction

사용자 메시지에서 의도 키워드와 대상을 추출한다.

### Step 2: Confidence Scoring

| Confidence | Action |
|------------|--------|
| >= 0.85 | 매칭된 커맨드로 즉시 라우팅 |
| 0.70 - 0.84 | 매칭된 커맨드를 제시하고 사용자 확인 요청 |
| < 0.70 | 상위 3개 후보를 제시하고 사용자 선택 |

### Step 3: Keyword → Command Mapping

| Keywords (KO/EN) | Mapped Command |
|-------------------|---------------|
| 초기화, initialize, setup | `/u-init` |
| 역공학, 코드 분석, reverse, 소스 분석, 코드에서 문서 | `/u-reverse` |
| 자료 분석, 분석, ingest, analyze data | `/u-ingest` |
| 기획, 요구사항, SRS, plan | `/u-plan` |
| 설계, ERD, API 설계, design | `/u-design` |
| 개발, 코드 생성, build, code | `/u-dev` |
| 테스트, QA, 검증, check, test | `/u-check` |
| 배포, 출시, ship, deploy | `/u-ship` |
| 추가, add | `/u-add` |
| 수정, 갱신, update | `/u-update` |
| 문서 조회, doc | `/u-doc` |
| 동기화, 일관성, sync | `/u-sync` |
| 게이트, 전환, gate | `/u-gate` |
| 상태, 현황, status | `/u-status` |
| 질문, 물어볼게, 어때, 의견, ask, question | `/u-ask` |
| 토론, 브레인스토밍, discuss | `/u-discuss` |
| 백로그, backlog | `/u-backlog` |
| 추적, trace | `/u-trace` |

### Step 4: Non-u-maker Fallback

u-maker 커맨드가 아닌 것으로 판정되면:
1. "이 요청은 u-maker 범위 밖입니다." 안내
2. `/u-skill-help`로 도움말 제안

---

## 7. Dispatch Protocol

라우팅이 확정되면 다음 정보를 에이전트에 전달:

```json
{
  "command": "plan",
  "scope": "retail",
  "target": null,
  "flags": { "interactive": false, "step": false, "only": null },
  "mode": "auto",
  "resolvedPaths": {
    "docs": ".u-maker/docs/retail/",
    "classified": ".u-maker/docs/retail/_classified/",
    "input": ".u-maker/docs/retail/_input/",
    "index": ".u-maker/docs/retail/_index.json",
    "links": ".u-maker/docs/_links.json"
  },
  "currentPhase": "Plan",
  "config": { /* u-maker.config.json subset */ }
}
```

---

## 8. Error Handling

| Error | Response |
|-------|----------|
| Unknown command | "인식되지 않는 커맨드입니다. /u-skill-help로 도움말을 확인하세요." |
| Invalid scope | "'{scope}'는 등록된 앱이 아닙니다. 등록된 앱: {list}" |
| Missing required argument | 해당 커맨드의 필수 인자 안내 |
| Phase gate failure | "현재 Phase gate가 미통과입니다. /u-gate를 먼저 실행하세요." |
| Config not found | "`u-maker.config.json`이 없습니다. /u-init을 먼저 실행하세요." |
