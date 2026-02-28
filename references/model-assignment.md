# Model Assignment Guide

> 각 에이전트/스킬의 역할 복잡도에 따른 모델 배정 가이드.

## Model Tier 정의

| Tier | Claude Code | Codex (OpenAI) | 특성 |
|------|-------------|----------------|------|
| **High** | `opus` | `o3` | 깊은 추론, 교차 문서 분석, 아키텍처 설계 |
| **Mid** | `sonnet` | `o4-mini` | 코드 생성, 기획, 구조화된 분석 |
| **Low** | `haiku` | `o4-mini` | 반복 실행, 기록, 단순 처리 |

---

## Agent Model Assignment

### High Tier (opus / o3)

| Agent | Model | 근거 |
|-------|-------|------|
| `u-a` (Architect) | **opus** | SRS/ERD/API 설계는 도메인 전체를 이해하고 교차 참조가 필요. 요구사항→데이터 모델→API 스키마 간 일관성 추론이 핵심 |
| `u-m` (Master) | **opus** | 모든 Phase의 문서 간 모순 탐지. Screen↔API↔ERD 교차 검증은 가장 높은 분석 능력 요구 |

### Mid Tier (sonnet / o4-mini)

| Agent | Model | 근거 |
|-------|-------|------|
| `u-pm` (Project Manager) | **sonnet** | 로드맵/유저스토리는 구조화된 작업. 깊은 기술 추론보다 조직화 능력 중요 |
| `u-cx` (CX/UX Designer) | **sonnet** | IA/화면 설계는 창의성 필요하나 명확한 패턴 존재. 템플릿 기반 생성에 충분 |
| `u-dv-fe` (Frontend Dev) | **sonnet** | Contract 기반 코드 생성. 2CX_Screen + 2A_API 참조하여 구현하므로 설계 문서가 가이드 역할 |
| `u-dv-be` (Backend Dev) | **sonnet** | 2A_API + 2A_ERD 기반 코드 생성. ORM 모델/라우트는 스키마에서 직접 변환 |
| `u-qa-a` (QA Analyst) | **sonnet** | SRS FR→테스트 케이스 도출은 체계적 분석. 정상/비정상/경계값 패턴이 정형화됨 |
| `u-qa-n` (QA Defect Analyst) | **sonnet** | 결함 분류/원인 분석은 분석적 사고 필요하나 패턴화 가능 |

### Low Tier (haiku / o4-mini)

| Agent | Model | 근거 |
|-------|-------|------|
| `u-qa-t` (QA Tester) | **haiku** | 케이스 실행→Pass/Fail 기록은 기계적 작업. 설계된 케이스를 따라가며 결과만 기록 |

---

## Skill & Command Model Assignment

| Skill/Command | Model | 근거 |
|---------------|-------|------|
| `u-agent-ssot` (Orchestrator) | **sonnet** | 명령어 라우팅, Phase Gate 검증, Agent 체인 호출. 복잡하지만 규칙 기반 |
| `help` (Command) | **haiku** | 정적 텍스트 출력. 추론 불필요 |

---

## 비용 최적화 전략

### Claude Code 환경

```
Full PDCA Cycle 모델 사용 패턴:

PLAN Phase:
  u-pm (sonnet) → u-a (opus) → u-cx (sonnet) → u-m (opus)

DESIGN Phase:
  u-cx (sonnet) → u-a (opus) → u-m (opus)

DO Phase:
  u-dv-fe (sonnet) + u-dv-be (sonnet)  ← 병렬, opus 불필요

CHECK Phase:
  u-qa-a (sonnet) → u-qa-t (haiku) → u-qa-n (sonnet)

ACT Phase:
  u-qa-n (sonnet) → u-pm (sonnet) → u-m (opus)
```

### 비용 비중 (예상)

| Phase | opus 호출 | sonnet 호출 | haiku 호출 |
|-------|-----------|-------------|------------|
| PLAN | 2 (u-a, u-m) | 2 (u-pm, u-cx) | 0 |
| DESIGN | 2 (u-a, u-m) | 1 (u-cx) | 0 |
| DO | 0 | 2 (u-dv-fe, u-dv-be) | 0 |
| CHECK | 0 | 2 (u-qa-a, u-qa-n) | 1 (u-qa-t) |
| ACT | 1 (u-m) | 2 (u-qa-n, u-pm) | 0 |

**Iteration당**: opus 5회, sonnet 9회, haiku 1회

### Codex (OpenAI) 환경

Codex CLI에서 사용 시 아래 매핑 적용:

| Claude Model | Codex Equivalent | 비고 |
|-------------|------------------|------|
| `opus` | `o3` | 깊은 추론 필요 시 |
| `sonnet` | `o4-mini` | 대부분의 작업 |
| `haiku` | `o4-mini` | 단순 작업 (Codex는 2-tier) |

> Codex CLI는 현재 `o3`와 `o4-mini` 2가지 모델만 지원하므로,
> Claude의 3-tier 구조에서 sonnet/haiku를 모두 `o4-mini`로 매핑한다.

---

## 모델 변경 가이드

### 비용 절감이 필요할 때

```yaml
# u-a, u-m을 sonnet으로 다운그레이드
model: sonnet
```

- 트레이드오프: 교차 문서 분석 품질 저하 가능
- 권장: Iteration 2+ 증분 갱신 시에는 sonnet도 충분

### 품질 극대화가 필요할 때

```yaml
# u-dv-fe, u-dv-be를 opus로 업그레이드
model: opus
```

- 트레이드오프: 비용 증가
- 권장: 복잡한 비즈니스 로직 구현 시에만 임시 적용
