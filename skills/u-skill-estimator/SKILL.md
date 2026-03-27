---
name: u-skill-estimator
description: "SRS 항목(FR, US, FT) 수량과 복잡도를 분석하여 공수 추정, 일정 계획, Gantt 차트 기반 Roadmap을 생성하는 내부 엔진."
---

# u-skill-estimator -- Effort Estimation & Roadmap Engine

SRS의 Feature(FT) 목록에 Story Point를 배정하고, Velocity 기반 Iteration 할당 및 Milestone 그룹핑을 수행하여 Roadmap을 생성하는 내부 엔진이다.

**Owner Agent:** u-agent-planner

---

## 1. Operations

### estimateFeatures(srsFeatures)

SRS의 FT 목록에 Story Point를 배정한다.

**입력:** `srs.json` → features 배열

**복잡도 평가 기준:**

| Factor | Weight | Scoring |
|--------|--------|---------|
| UI Complexity | 0.25 | 0: 없음, 1: 기본 폼, 2: 테이블/리스트, 3: 대시보드/차트, 4: 복잡 인터랙션 |
| API Endpoints | 0.25 | 0: 없음, 1: CRUD 1개, 2: CRUD 2-3개, 3: 복합 비즈니스 로직, 4: 외부 연동 |
| DB Changes | 0.20 | 0: 없음, 1: 단순 CRUD, 2: 관계 2-3개, 3: 복잡 쿼리/집계, 4: 마이그레이션 필요 |
| Integration Points | 0.15 | 0: 없음, 1: 내부 API 1개, 2: 내부 2-3개, 3: 외부 API, 4: 복수 외부 시스템 |
| Business Logic | 0.15 | 0: 없음, 1: 단순 조건, 2: 상태 전환, 3: 복잡 계산/규칙, 4: 워크플로우 엔진 |

**복잡도 → Story Point 매핑:**

| Complexity Score | Label | Story Points | Estimated Days |
|-----------------|-------|-------------|----------------|
| 0.0 - 1.0 | Simple | 1-2 | 0.5일 |
| 1.1 - 2.0 | Medium | 3-5 | 1-2일 |
| 2.1 - 3.0 | Complex | 8-13 | 3-5일 |
| 3.1 - 4.0 | Epic | 21+ | 5-10일 |

**프로세스:**

```
function estimateFeatures(features):
  results = []
  for ft in features:
    scores = {
      uiComplexity: evaluateUI(ft),
      apiEndpoints: evaluateAPI(ft),
      dbChanges: evaluateDB(ft),
      integrationPoints: evaluateIntegration(ft),
      businessLogic: evaluateLogic(ft)
    }

    weightedScore = sum(scores[k] * weights[k] for k in scores)
    storyPoints = mapToStoryPoints(weightedScore)
    label = mapToLabel(weightedScore)

    results.push({
      ftId: ft.id,
      title: ft.title,
      scores: scores,
      weightedScore: round(weightedScore, 2),
      complexity: label,
      storyPoints: storyPoints,
      estimatedDays: mapToDays(storyPoints)
    })

  return {
    features: results,
    summary: {
      totalFeatures: results.length,
      totalStoryPoints: sum(results, "storyPoints"),
      totalEstimatedDays: sum(results, "estimatedDays"),
      byComplexity: groupCount(results, "complexity")
    }
  }
```

**출력 예시:**

```json
{
  "features": [
    {
      "ftId": "FT-0010",
      "title": "사용자 로그인",
      "scores": { "uiComplexity": 1, "apiEndpoints": 2, "dbChanges": 1, "integrationPoints": 0, "businessLogic": 1 },
      "weightedScore": 1.10,
      "complexity": "Medium",
      "storyPoints": 3,
      "estimatedDays": 1.5
    }
  ],
  "summary": {
    "totalFeatures": 45,
    "totalStoryPoints": 234,
    "totalEstimatedDays": 112,
    "byComplexity": { "Simple": 12, "Medium": 20, "Complex": 10, "Epic": 3 }
  }
}
```

### calculateRoadmap(features, velocity)

Feature를 Iteration에 배분하여 Roadmap을 생성한다.

**입력:**
- `features` -- estimateFeatures 출력
- `velocity` -- Iteration당 처리 가능한 Story Point (기본: 20)

**프로세스:**

```
function calculateRoadmap(features, velocity = 20):
  // 1. Priority 기반 정렬
  sorted = sortByPriority(features)  // must > should > could > wont

  // 2. 의존성 고려
  ordered = topologicalSort(sorted)  // 의존 FT가 먼저 배치

  // 3. 버퍼 적용
  effectiveVelocity = velocity * 0.7  // 미지 20% + 통합 10% 버퍼

  // 4. Iteration 할당
  iterations = []
  currentIteration = { id: 1, features: [], points: 0 }

  for ft in ordered:
    if currentIteration.points + ft.storyPoints > effectiveVelocity:
      iterations.push(currentIteration)
      currentIteration = { id: iterations.length + 1, features: [], points: 0 }

    currentIteration.features.push(ft)
    currentIteration.points += ft.storyPoints

  if currentIteration.features.length > 0:
    iterations.push(currentIteration)

  // 5. 일정 계산 (Iteration = 2주 기본)
  startDate = config.startDate || today()
  for iter in iterations:
    iter.startDate = addWeeks(startDate, (iter.id - 1) * 2)
    iter.endDate = addWeeks(iter.startDate, 2)

  return iterations
```

### milestoneEstimation(iterations)

Iteration을 Milestone으로 그룹핑한다.

**프로세스:**

1. Priority 기반 그룹핑:
   - M1: Must priority FT들의 Iteration 범위
   - M2: Should priority FT들의 Iteration 범위
   - M3: Could priority FT들의 Iteration 범위
2. 각 Milestone에 목표 날짜 배정
3. Mermaid Gantt 다이어그램 생성

**출력:**

```markdown
## Milestones

| Milestone | Features | Iterations | Est. Days | Target Date | Priority |
|-----------|----------|-----------|-----------|-------------|----------|
| M1: Core Auth | FT-0010~FT-0015 | 1-2 | 24 | 2026-04-10 | Must |
| M2: Dashboard | FT-0020~FT-0035 | 3-5 | 36 | 2026-05-08 | Must |
| M3: Reports | FT-0050~FT-0060 | 6-7 | 16 | 2026-05-22 | Should |
```

---

## 2. Gantt Chart Generation

Mermaid Gantt 다이어그램을 자동 생성한다.

```markdown
```mermaid
gantt
    title Project Roadmap
    dateFormat YYYY-MM-DD
    axisFormat %m/%d

    section M1: Core Auth
    FT-0010 Login           :done, 2026-03-28, 3d
    FT-0011 Register        :active, 2026-03-31, 2d
    FT-0012 Password Reset  :2026-04-02, 2d

    section M2: Dashboard
    FT-0020 KPI Cards       :2026-04-14, 3d
    FT-0021 Charts          :2026-04-17, 5d
```​
```

---

## 3. Estimation Adjustments

### Re-estimation Triggers

다음 상황에서 공수를 재추정한다:

| Trigger | Action |
|---------|--------|
| FT 추가/삭제 | 해당 FT + 관련 FT 재추정 |
| 기술 스택 변경 | 전체 재추정 |
| Velocity 변경 | Roadmap만 재계산 |
| Iteration 완료 | 실제 vs 예상 비교 → velocity 갱신 |

### Accuracy Tracking

Iteration 완료 후 예측 정확도를 추적한다:

```json
{
  "iteration": 1,
  "estimated": { "points": 20, "days": 10 },
  "actual": { "points": 18, "days": 12 },
  "accuracy": 0.90,
  "velocityAdjustment": -2
}
```

---

## 4. Safety Rules

1. Epic(21+점) FT는 분해 권고 (1 FT = 최대 13점 이하 목표)
2. 버퍼는 최소 30% 적용 (미지 20% + 통합 10%)
3. velocity 기본값 20은 실제 데이터 없을 때만 사용
4. 실제 Iteration 완료 데이터가 있으면 velocity 자동 조정
5. Must priority FT를 뒤 Iteration에 배치하지 않음 (앞부터 채움)
6. 의존성이 있는 FT는 의존 대상보다 뒤에 배치
7. 추정은 참고용이며 보장값이 아님을 명시
8. `roadmap.md` + `roadmap.json` 동반 생성 필수
