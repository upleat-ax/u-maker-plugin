---
name: u-skill-phase-detector
description: "_index.json 파일을 읽어 문서 상태를 집계하고, 완료도 규칙에 따라 현재 PDCA Phase를 자동 감지하며, Gate 충족 여부를 판정하는 내부 엔진."
---

# u-skill-phase-detector -- PDCA Phase Detection Engine

`_index.json` 파일의 문서 상태(Draft/Review/Final)를 읽어 집계하고, 규칙 기반으로 현재 PDCA Phase를 자동 감지한다. Gate 충족 여부를 판정하여 Phase 전환 가능 여부를 보고한다.

**Owner Agent:** u-agent-orchestrator

---

## 1. Core Concept

PDCA 4-Phase 모델:

```
PLAN → DO → CHECK → ACT
```

각 Phase는 특정 문서가 존재하고 특정 상태에 도달했을 때 완료로 판정된다. 이 엔진은 현재 프로젝트가 어떤 Phase에 있는지를 문서 상태로부터 자동으로 감지한다.

---

## 2. Operations

### detectPhase(scope)

현재 Phase를 감지하고 각 Phase의 완료도를 반환한다.

**입력:** scope (앱 이름 또는 "all")

**프로세스:**

1. `docs/{scope}/_index.json` 읽기
2. 각 Phase별 문서 존재 여부 + 상태 확인
3. Phase Detection Rules 적용
4. 결과 반환

**출력:**

```json
{
  "scope": "retail",
  "currentPhase": "Do",
  "phases": {
    "plan": { "status": "complete", "readiness": 1.0, "documents": {...} },
    "do": { "status": "in-progress", "readiness": 0.6, "documents": {...} },
    "check": { "status": "not-started", "readiness": 0.0, "documents": {...} },
    "act": { "status": "not-started", "readiness": 0.0, "documents": {...} }
  },
  "gateStatus": {
    "plan→do": "passed",
    "do→check": "not-ready",
    "check→act": "not-ready"
  },
  "detectedAt": "{ISO 8601}"
}
```

### checkGate(fromPhase, toPhase, scope)

특정 Phase 전환의 Gate 충족 여부를 상세 판정한다.

**출력:**

```json
{
  "gate": "do→check",
  "passed": false,
  "criteria": [
    { "id": "G-01", "description": "All FT code-complete", "status": "fail", "detail": "3/15 FT incomplete" },
    { "id": "G-02", "description": "Build success", "status": "pass" }
  ],
  "blockers": ["FT-0012", "FT-0014", "FT-0015"]
}
```

### getPhaseProgress(scope)

전체 프로젝트의 Phase별 진행률을 요약한다. `/u-status`에서 사용.

---

## 3. Phase Detection Rules

### Phase: Plan

| Document | Required Status | Weight |
|----------|----------------|--------|
| `srs.md` | exists (any status) | 0.3 |
| `srs.md` | Final | 0.2 |
| `ia.md` | exists (any status) | 0.2 |
| `ia.md` | Final | 0.15 |
| `roadmap.md` | exists | 0.15 |

**완료 판정:** readiness >= 0.85 (SRS Final + IA Final 필수)

**Gate (Plan → Do):**

| Criterion | Required |
|-----------|----------|
| SRS status = Final | MUST |
| IA status = Final | MUST |
| Roadmap exists | SHOULD |
| 모든 FR에 >= 1 US | MUST |
| 모든 US에 >= 1 FT | MUST |

### Phase: Do

Do Phase는 Design + Development를 포함한다.

#### Design Documents

| Document | Required Status | Weight |
|----------|----------------|--------|
| `erd.md` | exists | 0.10 |
| `erd.md` | Final | 0.05 |
| `api.md` | exists | 0.10 |
| `api.md` | Final | 0.05 |
| `screens.md` | exists | 0.10 |
| `screens.md` | Final | 0.05 |
| `screen-flow.md` | exists | 0.05 |
| `rtm.md` | exists | 0.05 |

#### Development Artifacts

| Document | Required Status | Weight |
|----------|----------------|--------|
| `code.md` | exists | 0.15 |
| `code.md` | Final (all FT implemented) | 0.15 |
| Build markers | `bun run build` success | 0.15 |

**완료 판정:** readiness >= 0.85 (ERD/API/Screens Final + code.md exists + build success)

**Gate (Do → Check):**

| Criterion | Required |
|-----------|----------|
| ERD status = Final | MUST |
| API Contract status = Final | MUST |
| Screens status = Final | MUST |
| RTM exists | MUST |
| code.md exists | MUST |
| 모든 FT = code-complete | MUST |
| `bun run build` = success (exit 0) | MUST |

### Phase: Check

| Document | Required Status | Weight |
|----------|----------------|--------|
| `test-cases.md` | exists | 0.20 |
| `test-report.md` | exists | 0.30 |
| test pass rate >= 95% | computed | 0.25 |
| Critical/Major defects = 0 | computed | 0.25 |

**완료 판정:** readiness >= 0.85 (test-report exists + pass rate >= 95% + Critical/Major = 0)

**Gate (Check → Act):**

| Criterion | Required |
|-----------|----------|
| test-cases.md exists | MUST |
| test-report.md exists | MUST |
| Critical defects = 0 open | MUST |
| Major defects = 0 open | MUST |
| All FR implemented & tested (RTM) | MUST |
| Build success | MUST |
| Test pass rate >= 95% | MUST |

### Phase: Act

| Document | Required Status | Weight |
|----------|----------------|--------|
| `iteration-log` entry exists | 0.30 |
| `retrospective.md` exists | 0.30 |
| Backlog groomed | 0.20 |
| Archive completed | 0.20 |

**완료 판정:** readiness >= 0.80

---

## 4. Document Status Aggregation

`_index.json` 파일에서 문서 상태를 읽어 집계한다.

### _index.json Structure

```json
{
  "documents": [
    {
      "id": "srs",
      "path": "01-plan/srs.md",
      "type": "srs",
      "status": "Final",
      "version": "1.2.0",
      "lastUpdated": "2026-03-27T10:00:00Z",
      "owner": "u-agent-planner"
    }
  ]
}
```

### Status Values

| Status | Meaning |
|--------|---------|
| `Draft` | 초안 생성됨. 미검증. |
| `Review` | 검토 진행 중. 사용자 확인 대기. |
| `Final` | 확정됨. 변경 시 사용자 확인 필수. |

### Aggregation Logic

```
function aggregatePhase(documents, phaseRules):
  readiness = 0.0
  details = {}

  for rule in phaseRules:
    doc = documents.find(d => d.id === rule.docId)
    if rule.condition === "exists":
      met = doc !== null
    elif rule.condition === "Final":
      met = doc?.status === "Final"
    elif rule.condition === "computed":
      met = evaluateComputed(rule, documents)

    readiness += met ? rule.weight : 0
    details[rule.docId] = { required: rule.condition, actual: doc?.status, met }

  return { readiness, details }
```

---

## 5. Multi-App Aggregation

`scope === "all"` 인 경우:

1. `u-maker.config.json`에서 모든 앱 조회
2. 앱별로 `detectPhase()` 실행
3. 전체 프로젝트 Phase = 가장 느린 앱의 Phase (min)
4. 앱별 readiness 비교표 생성

```json
{
  "projectPhase": "Plan",
  "appPhases": {
    "retail": { "currentPhase": "Do", "readiness": { "plan": 1.0, "do": 0.6 } },
    "corp": { "currentPhase": "Plan", "readiness": { "plan": 0.7 } }
  },
  "bottleneck": "corp"
}
```

---

## 6. Safety Rules

1. _index.json이 없으면 모든 Phase = not-started (에러가 아닌 초기 상태)
2. Phase 감지는 READ-ONLY (문서 상태를 변경하지 않음)
3. Gate 판정 실패 시 자동 Phase 전환 불가 (Always-Pause)
4. computed 조건(pass rate, defect count)은 실제 데이터 기반 (추정 금지)
5. 다중 앱에서 프로젝트 Phase는 보수적으로 판정 (가장 느린 앱 기준)
