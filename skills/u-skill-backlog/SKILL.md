---
name: u-skill-backlog
description: "백로그 CRUD, 우선순위 관리, 스프린트 할당, 속도 계산, 번다운 추적을 수행하는 내부 엔진."
---

# u-skill-backlog -- Backlog Management Engine

백로그 CRUD, 우선순위 정렬, Iteration 할당, Velocity 계산, Burndown 추적.

**Owner Agent:** u-agent-orchestrator

---

## 1. Backlog Item Schema

```json
{
  "id": "BL-{NNN}",
  "title": "...",
  "type": "bug|feature|improvement|tech-debt|task",
  "status": "backlog|todo|in-progress|review|done|blocked|archived",
  "priority": "must|should|could|wont",
  "severity": "critical|major|minor|trivial",
  "storyPoints": 5,
  "iteration": null,
  "assignedTo": "u-agent-builder",
  "labels": [],
  "source": { "type": "check|discuss|ingest|manual", "ref": "DEF-0001" },
  "relatedItems": { "ft": "FT-0034", "tc": "TC-U-0023", "defect": "DEF-0001" },
  "createdAt": "{ISO}", "updatedAt": "{ISO}", "resolvedAt": null,
  "description": "...", "acceptanceCriteria": []
}
```

**Storage:** `_backlog/BL-{NNN}.json` + `_backlog/_index.json` + `_backlog/_counter.json`

---

## 2. Status Lifecycle

```
backlog → todo → in-progress → review → done → archived
                      ↓
                   blocked → in-progress
```

| Status | Allowed Transitions |
|--------|-------------------|
| `backlog` | → todo |
| `todo` | → in-progress, → blocked |
| `in-progress` | → review, → blocked |
| `review` | → done, → in-progress (반려) |
| `done` | → archived |
| `blocked` | → in-progress (차단 해제) |
| `archived` | terminal |

---

## 3. CRUD Operations

- **create(item):** nextId → 중복 검사 → 파일 생성 → 인덱스 갱신
- **read(filters):** type, status, iteration, assignedTo, priority, labels, source.type 필터 → 우선순위 정렬 반환
- **update(id, changes):** status 전환 유효성 검사 → merge → done이면 resolvedAt 설정 → 파일/인덱스 갱신
- **delete(id):** soft-delete (status → archived)

---

## 4. Auto-Import

| Source | Trigger | Type | Priority |
|--------|---------|------|----------|
| `/u-qa` defects | 결함 발견 | bug | Critical→must, Major→must, Minor→should, Trivial→could |
| `/u-discuss` actions | session wrap | improvement | Medium |
| `/u-ingest` requirements | validated | feature | 추출된 priority |
| `/u-qa` tech-debt | 코드 분석 | tech-debt | should |

source.ref 기준 중복 검사 후 등록.

---

## 5. Sprint Planning

### assignToIteration(ids, iteration)

항목을 Iteration에 할당: status → todo, 총 Story Point 계산, velocity(최근 3 iteration 평균) 반환.

---

## 6. Velocity & Burndown

### calculateVelocity(window=3)

최근 N개 Iteration 평균 완료 SP. `{ window, iterations, pointsPerIteration, averageVelocity, trend: improving|stable|declining }`

### burndown(iteration)

Iteration 진행률: `{ total, totalStoryPoints, byStatus(todo/inProgress/review/done/blocked), completionRate, pointsRemaining }`

---

## 7. Priority Sorting

정렬 규칙 (순서): priority tier(must>should>could>wont) → type(bug>tech-debt>feature>improvement>task) → severity → dependencies → story points(작은 것 먼저) → created date(오래된 것 먼저)

---

## 8. Safety Rules

1. ID 전역 sequential, 삭제 ID 재사용 금지
2. status 전환은 정의된 lifecycle만, done→archived 외 역전환 금지
3. blocked 시 blockReason 필수, auto-import 시 중복 검사 필수
4. Iteration SP가 velocity 1.2배 초과 시 경고
5. `_index.json` 모든 CRUD 후 즉시 갱신
6. Critical/Major bug priority 하향 조정 금지
