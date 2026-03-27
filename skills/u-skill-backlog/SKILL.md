---
name: u-skill-backlog
description: "백로그 CRUD, 우선순위 관리, 스프린트 할당, 속도 계산, 번다운 추적을 수행하는 내부 엔진."
---

# u-skill-backlog -- Backlog Management Engine

백로그 항목의 CRUD, 우선순위 정렬, Iteration 할당, Velocity 계산, Burndown 추적을 관리하는 내부 엔진. 다양한 소스(classified, check, discuss)에서 항목을 자동 수집하고, 백로그 전체 lifecycle을 관리한다.

**Owner Agent:** u-agent-orchestrator

---

## 1. Backlog Item Schema

```json
{
  "id": "BL-{NNN}",
  "title": "결제 프로세스 타임아웃 처리",
  "type": "bug|feature|improvement|tech-debt|task",
  "status": "backlog|todo|in-progress|review|done|blocked|archived",
  "priority": "must|should|could|wont",
  "severity": "critical|major|minor|trivial",
  "storyPoints": 5,
  "iteration": null,
  "assignedTo": "u-agent-builder",
  "labels": ["payment", "error-handling"],
  "source": {
    "type": "check|discuss|ingest|manual",
    "ref": "DEF-0001|DS-003|FR-0015"
  },
  "relatedItems": {
    "ft": "FT-0034",
    "tc": "TC-U-0023",
    "defect": "DEF-0001"
  },
  "createdAt": "{ISO 8601}",
  "updatedAt": "{ISO 8601}",
  "resolvedAt": null,
  "description": "상세 설명",
  "acceptanceCriteria": ["기준 1", "기준 2"]
}
```

### Storage

- 개별 항목: `_backlog/BL-{NNN}.json`
- 인덱스: `_backlog/_index.json`
- ID 카운터: `_backlog/_counter.json`

---

## 2. Item Status Lifecycle

```
backlog → todo → in-progress → review → done
                      ↓
                   blocked → (unblock) → in-progress
                                            ↓
done → archived (soft-delete)
```

| Status | Description | Allowed Transitions |
|--------|-------------|-------------------|
| `backlog` | 미정리. 우선순위 미배정 | → todo |
| `todo` | 정리 완료. Iteration 할당됨 | → in-progress, → blocked |
| `in-progress` | 작업 진행 중 | → review, → blocked |
| `review` | 작업 완료, 검토 대기 | → done, → in-progress (반려) |
| `done` | 완료 확정 | → archived |
| `blocked` | 차단됨. 사유 기록 필수 | → in-progress (차단 해제) |
| `archived` | 보관 (soft-delete) | -- (terminal) |

---

## 3. CRUD Operations

### create(item)

새 백로그 항목을 생성한다.

```
function create(item):
  id = nextId()  // _counter.json에서 auto-increment
  item.id = "BL-" + pad(id, 3)
  item.status = item.status || "backlog"
  item.createdAt = now()
  item.updatedAt = now()

  // 중복 검사
  if isDuplicate(item):
    return { status: "duplicate", existingId: duplicateId }

  writeFile("_backlog/BL-{NNN}.json", item)
  updateIndex("add", item)
  return { status: "created", id: item.id }
```

### read(filters)

필터 조건으로 백로그 항목을 조회한다.

**지원 필터:**

| Filter | Type | Example |
|--------|------|---------|
| `type` | string | `"bug"` |
| `status` | string or string[] | `"todo"` or `["todo", "in-progress"]` |
| `iteration` | number | `3` |
| `assignedTo` | string | `"u-agent-builder"` |
| `priority` | string | `"must"` |
| `labels` | string[] | `["payment"]` |
| `source.type` | string | `"check"` |

```
function read(filters):
  index = loadIndex()
  items = index.items

  for key, value in filters:
    items = items.filter(item => matches(item, key, value))

  return sortByPriority(items)
```

### update(id, changes)

항목 필드를 수정한다.

```
function update(id, changes):
  item = loadItem(id)

  // status 전환 유효성 검사
  if changes.status:
    validateTransition(item.status, changes.status)

  merge(item, changes)
  item.updatedAt = now()

  if changes.status === "done":
    item.resolvedAt = now()

  writeFile("_backlog/{id}.json", item)
  updateIndex("update", item)
  return { status: "updated", id }
```

### delete(id)

항목을 soft-delete (archived) 처리한다.

```
function delete(id):
  item = loadItem(id)
  item.status = "archived"
  item.updatedAt = now()
  writeFile("_backlog/{id}.json", item)
  updateIndex("update", item)
  return { status: "archived", id }
```

---

## 4. Auto-Import

### autoImport(source, items)

외부 소스에서 항목을 자동 수집하여 백로그에 등록한다.

| Source | Trigger | Item Type | Priority Mapping |
|--------|---------|-----------|-----------------|
| `/u-qa` defects | 결함 발견 시 자동 | bug | Critical→must, Major→must, Minor→should, Trivial→could |
| `/u-discuss` actions | session wrap 시 | improvement | Medium (기본) |
| `/u-ingest` requirements | validated requirements | feature | 추출된 priority 유지 |
| `/u-qa` tech-debt | 코드 분석 시 | tech-debt | should (기본) |

**프로세스:**

```
function autoImport(source, items):
  imported = []
  duplicates = []

  for item in items:
    // 중복 검사: source.ref가 동일한 기존 항목 확인
    existing = findBySourceRef(item.source.ref)
    if existing:
      duplicates.push({ new: item, existing: existing.id })
      continue

    created = create({
      ...item,
      source: { type: source, ref: item.sourceRef }
    })
    imported.push(created)

  return { imported: imported.length, duplicates: duplicates.length, details: { imported, duplicates } }
```

---

## 5. Sprint Planning

### assignToIteration(ids, iteration)

항목을 특정 Iteration에 할당한다.

```
function assignToIteration(ids, iteration):
  results = []
  totalPoints = 0

  for id in ids:
    item = loadItem(id)
    item.iteration = iteration
    item.status = "todo"  // backlog → todo 전환
    item.updatedAt = now()
    writeFile("_backlog/{id}.json", item)
    totalPoints += item.storyPoints || 0
    results.push({ id, points: item.storyPoints })

  updateIndex("bulk-update", results)

  return {
    iteration: iteration,
    itemCount: ids.length,
    totalStoryPoints: totalPoints,
    velocity: getVelocity(3)  // 최근 3 iteration 평균
  }
```

---

## 6. Velocity & Burndown

### calculateVelocity(window)

최근 N개 Iteration의 평균 완료 Story Point를 계산한다.

```
function calculateVelocity(window = 3):
  completedByIteration = {}

  allItems = read({ status: "done" })
  for item in allItems:
    iter = item.iteration
    if iter:
      completedByIteration[iter] = (completedByIteration[iter] || 0) + (item.storyPoints || 0)

  // 최근 N개 iteration
  iterations = Object.keys(completedByIteration).sort().slice(-window)
  points = iterations.map(i => completedByIteration[i])

  return {
    window: window,
    iterations: iterations,
    pointsPerIteration: points,
    averageVelocity: average(points),
    trend: calculateTrend(points)  // "improving" | "stable" | "declining"
  }
```

### burndown(iteration)

특정 Iteration의 진행률을 계산한다.

```
function burndown(iteration):
  items = read({ iteration: iteration })
  total = items.length
  totalPoints = sum(items, "storyPoints")

  byStatus = groupBy(items, "status")

  return {
    iteration: iteration,
    total: total,
    totalStoryPoints: totalPoints,
    byStatus: {
      todo: { count: byStatus.todo?.length || 0, points: sum(byStatus.todo, "storyPoints") },
      inProgress: { count: byStatus["in-progress"]?.length || 0, points: sum(byStatus["in-progress"], "storyPoints") },
      review: { count: byStatus.review?.length || 0, points: sum(byStatus.review, "storyPoints") },
      done: { count: byStatus.done?.length || 0, points: sum(byStatus.done, "storyPoints") },
      blocked: { count: byStatus.blocked?.length || 0, points: sum(byStatus.blocked, "storyPoints") }
    },
    completionRate: (byStatus.done?.length || 0) / total,
    pointsCompleted: sum(byStatus.done, "storyPoints"),
    pointsRemaining: totalPoints - sum(byStatus.done, "storyPoints")
  }
```

---

## 7. Priority Sorting

### prioritize(items)

항목을 우선순위에 따라 정렬한다.

**정렬 규칙 (순서대로 적용):**

1. **Priority tier:** must > should > could > wont
2. **Type preference:** bug > tech-debt > feature > improvement > task (동일 priority 내)
3. **Severity (bugs only):** critical > major > minor > trivial
4. **Dependencies:** 의존 항목이 있으면 의존 대상을 먼저
5. **Story points:** 작은 것 먼저 (동점 시)
6. **Created date:** 오래된 것 먼저 (동점 시)

```
function prioritize(items):
  return items.sort((a, b) =>
    comparePriority(a.priority, b.priority) ||
    compareType(a.type, b.type) ||
    compareSeverity(a.severity, b.severity) ||
    compareDependency(a, b) ||
    comparePoints(a.storyPoints, b.storyPoints) ||
    compareDate(a.createdAt, b.createdAt)
  )
```

---

## 8. Safety Rules

1. ID는 전역 sequential, 삭제된 ID 재사용 금지
2. status 전환은 정의된 lifecycle만 허용 (임의 전환 거부)
3. `done` → `archived` 외에 `done`에서 다른 상태로 역전환 금지
4. `blocked` 설정 시 사유(blockReason) 필수
5. auto-import 시 중복 검사 필수 (source.ref 기준)
6. Iteration 할당 시 해당 Iteration의 총 Story Point가 velocity의 1.2배를 초과하면 경고
7. `_index.json`은 모든 CRUD 후 즉시 갱신
8. Critical/Major severity bug의 priority 하향 조정 금지
