# Model Assignment Guide

> 각 에이전트/스킬의 역할 복잡도에 따른 모델 배정 가이드.

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
| `u-ra` (Requirements Analyst) | **opus** | Roadmap/UserStory/Index/Backlog/Retrospective 등 전 Phase 문서를 총괄. 교차 문서 모순 탐지, 추적성 검증, Gate 판정에 가장 높은 분석 능력 요구 |

### Mid Tier (sonnet / o4-mini)

| Agent | Model | 근거 |
|-------|-------|------|
| `u-sa` (Software Architect) | **sonnet** | SRS/ERD/API 설계는 도메인 전체를 이해하고 교차 참조가 필요하나, 템플릿 기반 구조화 생성에 충분 |
| `u-ux` (UX Designer) | **sonnet** | IA/Screen/DesignSystem/UIComponents/DesignToken 설계는 창의성 필요하나 명확한 패턴 존재. 템플릿 기반 생성에 충분 |
| `u-dv-fe` (Frontend Dev) | **sonnet** | Contract 기반 코드 생성. 2_Screen_UX + 2_API_SA 참조하여 구현하므로 설계 문서가 가이드 역할 |
| `u-dv-be` (Backend Dev) | **sonnet** | 2_API_SA + 2_ERD_SA 기반 코드 생성. ORM 모델/라우트는 스키마에서 직접 변환 |
| `u-qa` (QA Engineer) | **sonnet** | SRS FR→테스트 케이스 도출, 테스트 실행, 결함 분석을 통합 수행. 체계적 분석과 패턴화된 작업 |

---

## Skill & Command Model Assignment

| Skill/Command | Model | 근거 |
|---------------|-------|------|
| `u-ssot` (Orchestrator) | **sonnet** | 명령어 라우팅, Phase Gate 검증, Agent 체인 호출. 복잡하지만 규칙 기반 |

---

## 비용 최적화 전략

### Claude Code 환경

```
Full PDCA Cycle 모델 사용 패턴:

PLAN Phase:
  u-ra (opus) → u-sa (sonnet) → u-ux (sonnet) → u-ra (opus)

DESIGN Phase:
  u-ux (sonnet) → u-sa (sonnet) → u-ra (opus)

DO Phase:
  u-ux (sonnet) + u-dv-fe (sonnet) + u-dv-be (sonnet)  ← 병렬, opus 불필요

CHECK Phase:
  u-qa (sonnet)

ACT Phase:
  u-ra (opus)
```

### 비용 비중 (예상)

| Phase | opus 호출 | sonnet 호출 |
|-------|-----------|-------------|
| PLAN | 2 (u-ra ×2) | 2 (u-sa, u-ux) |
| DESIGN | 1 (u-ra) | 2 (u-ux, u-sa) |
| DO | 0 | 3 (u-ux, u-dv-fe, u-dv-be) |
| CHECK | 0 | 1 (u-qa) |
| ACT | 1 (u-ra) | 0 |

**Iteration당**: opus 4회, sonnet 8회

### Codex (OpenAI) 환경

Codex CLI에서 사용 시 아래 매핑 적용:

| Claude Model | Codex Equivalent | 비고 |
|-------------|------------------|------|
| `opus` | `o3` | 깊은 추론 필요 시 |
| `sonnet` | `o4-mini` | 대부분의 작업 |

> Codex CLI는 현재 `o3`와 `o4-mini` 2가지 모델만 지원하므로,
> Claude의 2-tier 구조와 자연스럽게 매핑된다.

---

## 모델 변경 가이드

### 비용 절감이 필요할 때

```yaml
# u-ra를 sonnet으로 다운그레이드
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
