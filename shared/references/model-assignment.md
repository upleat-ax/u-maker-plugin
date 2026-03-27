# Model Assignment Guide

> 각 에이전트/엔진의 역할 복잡도에 따른 모델 배정 가이드.

## Model Tier 정의

| Tier | Claude Code | Codex (OpenAI) | 특성 |
|------|-------------|----------------|------|
| **High** | `opus` | `o3` | 깊은 추론, 교차 문서 분석, 아키텍처 설계 |
| **Mid** | `sonnet` | `o4-mini` | 코드 생성, 기획, 구조화된 분석 |

---

## Agent Model Assignment

### High Tier (opus / o3)

| Agent | Model | 근거 |
|-------|-------|------|
| `u-agent-orchestrator` | **opus** | 전체 workflow 오케스트레이션, phase 판정, 의존성 그래프 관리, assumptions 기록. 가장 높은 분석/판단 능력 요구 |

### Mid Tier (sonnet / o4-mini)

| Agent | Model | 근거 |
|-------|-------|------|
| `u-agent-planner` | **sonnet** | SRS/ERD/API/IA/Screen 설계. 도메인 이해 + 교차 참조 필요하나 템플릿 기반 구조화 생성에 충분 |
| `u-agent-builder` | **sonnet** | FE+BE 코드 생성. 명세 기반 구현이므로 설계 문서가 가이드 역할 |
| `u-agent-guardian` | **sonnet** | Gate 검증, TestCase 설계, 일관성 검증. 체계적 분석과 패턴화된 작업 |

---

## Engine Model Assignment

Engine skills는 호출하는 agent의 모델을 상속한다. 별도 모델 지정 불필요.

| Engine | 소속 Agent | 상속 Model |
|--------|-----------|-----------|
| engine-router | orchestrator | opus |
| engine-phase-detector | orchestrator | opus |
| engine-dep | orchestrator | opus |
| engine-workflow-runner | orchestrator | opus |
| engine-facilitator | orchestrator | opus |
| engine-doc | planner | sonnet |
| engine-analyzer | planner | sonnet |
| engine-designer | planner | sonnet |
| engine-estimator | planner | sonnet |
| engine-code | builder | sonnet |
| engine-validator | guardian | sonnet |
| engine-test | guardian | sonnet |

---

## 비용 최적화 전략

### Claude Code 환경

```
Full PDCA Cycle 모델 사용 패턴:

PLAN Phase:
  orchestrator (opus) → planner (sonnet) → guardian (sonnet)

DESIGN Phase:
  orchestrator (opus) → planner (sonnet) → guardian (sonnet)

DO Phase:
  orchestrator (opus) → builder (sonnet)  ← opus는 라우팅만

CHECK Phase:
  orchestrator (opus) → guardian (sonnet)

ACT Phase:
  orchestrator (opus) → guardian (sonnet)
```

### 비용 비중 (예상)

| Phase | opus 호출 | sonnet 호출 |
|-------|-----------|-------------|
| PLAN | 1 (orchestrator) | 2 (planner, guardian) |
| DESIGN | 1 (orchestrator) | 2 (planner, guardian) |
| DO | 1 (orchestrator) | 1 (builder) |
| CHECK | 1 (orchestrator) | 1 (guardian) |
| ACT | 1 (orchestrator) | 1 (guardian) |

**Iteration당**: opus 5회 (라우팅+오케스트레이션), sonnet 7회 (실행)

### Codex (OpenAI) 환경

| Claude Model | Codex Equivalent | 비고 |
|-------------|------------------|------|
| `opus` | `o3` | 깊은 추론 필요 시 |
| `sonnet` | `o4-mini` | 대부분의 작업 |

---

## 모델 변경 가이드

### 비용 절감이 필요할 때

```yaml
# orchestrator를 sonnet으로 다운그레이드
model: sonnet
```

- 트레이드오프: 복합 라우팅/판단 품질 저하 가능
- 권장: 단순 프로젝트나 Iteration 2+ 증분 작업 시

### 품질 극대화가 필요할 때

```yaml
# planner를 opus로 업그레이드
model: opus
```

- 트레이드오프: 비용 증가
- 권장: 복잡한 도메인 분석/대규모 ERD 설계 시에만 임시 적용
