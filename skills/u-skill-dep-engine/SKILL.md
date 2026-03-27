---
name: u-skill-dep-engine
description: "_links.json 글로벌 의존성 그래프를 관리하고, 문서 간 참조 추적 및 변경 시 하위 문서 impact-flag cascade를 수행하는 내부 엔진."
---

# u-skill-dep-engine -- Dependency Graph Management Engine

`_links.json` 파일에 저장되는 글로벌 의존성 그래프를 관리한다. 문서 간 참조 관계를 추적하고, 상위 문서 변경 시 하위 문서에 impact-flag를 cascade 전파하여 일관성 유지를 지원한다.

**Owner Agent:** u-agent-orchestrator

---

## 1. Graph Structure

### _links.json Schema

```json
{
  "version": "1.0",
  "lastUpdated": "{ISO 8601}",
  "nodes": {
    "{app}/srs": {
      "type": "doc",
      "app": "retail",
      "docType": "srs",
      "path": "docs/retail/01-plan/srs.md",
      "status": "Final",
      "impactFlagged": false,
      "impactReason": null,
      "lastModified": "{ISO 8601}"
    },
    "{app}/erd": {
      "type": "doc",
      "app": "retail",
      "docType": "erd",
      "path": "docs/retail/02-do/erd.md",
      "status": "Draft",
      "impactFlagged": false,
      "impactReason": null,
      "lastModified": "{ISO 8601}"
    }
  },
  "edges": [
    {
      "from": "{app}/srs",
      "to": "{app}/erd",
      "type": "derives",
      "createdAt": "{ISO 8601}"
    },
    {
      "from": "{app}/srs",
      "to": "{app}/api",
      "type": "derives",
      "createdAt": "{ISO 8601}"
    }
  ]
}
```

### Edge Types

| Type | Meaning | Example |
|------|---------|---------|
| `derives` | A에서 B가 파생됨 | SRS → ERD |
| `traces` | A가 B를 추적 (RTM) | SRS → RTM |
| `implements` | A가 B를 구현 | code → FT |
| `tests` | A가 B를 검증 | test-cases → FT |
| `references` | A가 B를 참조 (약한 의존) | screen-flow → screens |

---

## 2. Standard Document Dependency Map

```
SRS ──derives──→ IA
SRS ──derives──→ ERD
SRS ──derives──→ API
SRS ──derives──→ Screens
SRS ──traces───→ RTM
IA  ──derives──→ Screens
IA  ──derives──→ Screen-Flow
ERD ──derives──→ API
Screens ──derives──→ Screen-Flow
Screens ──derives──→ Code (FE)
API ──derives──→ Code (BE)
ERD ──derives──→ Code (DB)
SRS(FT) ──implements──→ Code
SRS(FT) ──tests──→ Test-Cases
```

---

## 3. Operations

### addNode(nodeId, metadata)

그래프에 노드를 추가한다.

```
addNode("{app}/erd", {
  type: "doc",
  app: "retail",
  docType: "erd",
  path: "docs/retail/02-do/erd.md",
  status: "Draft"
})
```

**규칙:**
- nodeId가 이미 존재하면 metadata를 병합(merge) 갱신
- `lastModified` 자동 설정

### addEdge(from, to, type)

두 노드 간 엣지를 추가한다.

```
addEdge("{app}/srs", "{app}/erd", "derives")
```

**규칙:**
- from/to 노드가 존재하지 않으면 자동 생성 (최소 metadata)
- 동일 from-to-type 엣지 중복 방지
- 순환 참조 탐지 → 경고 (cycle detection via DFS)

### removeNode(nodeId)

노드와 연결된 모든 엣지를 제거한다.

**규칙:**
- 해당 노드를 from 또는 to로 가진 모든 엣지 함께 제거
- 제거 로그 기록

### getDownstream(nodeId)

지정 노드의 모든 하위 의존 노드를 반환한다 (BFS 순회).

```
getDownstream("{app}/srs")
→ ["{app}/erd", "{app}/api", "{app}/screens", "{app}/rtm", "{app}/code", ...]
```

**알고리즘:**

```
function getDownstream(nodeId):
  visited = Set()
  queue = [nodeId]
  result = []

  while queue is not empty:
    current = queue.dequeue()
    if current in visited: continue
    visited.add(current)

    children = edges.filter(e => e.from === current).map(e => e.to)
    for child in children:
      result.push({ nodeId: child, depth: getDepth(nodeId, child) })
      queue.enqueue(child)

  return result  // nodeId 자신은 제외
```

### getUpstream(nodeId)

지정 노드에 영향을 주는 모든 상위 노드를 반환한다 (역방향 BFS).

```
getUpstream("{app}/code")
→ ["{app}/screens", "{app}/api", "{app}/erd", "{app}/srs"]
```

### cascade(nodeId, reason)

지정 노드의 모든 downstream 노드에 impact-flag를 설정한다.

```
cascade("{app}/srs", "SRS FR-0005 modified")
```

**프로세스:**

1. `getDownstream(nodeId)` 호출
2. 각 downstream 노드에 대해:
   ```json
   {
     "impactFlagged": true,
     "impactReason": "Upstream {nodeId} changed: {reason}",
     "flaggedAt": "{ISO 8601}",
     "flaggedBy": "{nodeId}"
   }
   ```
3. `_links.json` 저장
4. impact-flagged 노드 목록 반환

**출력:**

```json
{
  "sourceNode": "{app}/srs",
  "reason": "SRS FR-0005 modified",
  "impactedNodes": [
    { "nodeId": "{app}/erd", "depth": 1, "status": "Final" },
    { "nodeId": "{app}/api", "depth": 1, "status": "Final" },
    { "nodeId": "{app}/code", "depth": 2, "status": "Draft" }
  ],
  "totalImpacted": 3
}
```

### clearImpactFlag(nodeId)

특정 노드의 impact-flag를 해제한다. 해당 문서가 갱신된 후 호출.

### getImpactedNodes(scope)

scope 내 모든 impact-flagged 노드를 반환한다.

---

## 4. Cascade Rules

### --cascade Flag 동작

`/u-update --cascade` 실행 시:

1. 변경된 문서의 nodeId 식별
2. `cascade(nodeId, changeDescription)` 호출
3. impact-flagged 목록을 사용자에게 표시
4. auto mode: 하위 문서 자동 갱신 시도
5. interactive mode: 갱신할 문서를 사용자가 선택

### Auto-Cascade Triggers

다음 상황에서 자동으로 cascade가 발동한다:

| Trigger | Cascade From | Reason |
|---------|-------------|--------|
| SRS FR 추가/수정/삭제 | SRS | FR 변경 → 하위 설계/구현 영향 |
| ERD 엔티티 변경 | ERD | 엔티티 변경 → API/Code 영향 |
| API 엔드포인트 변경 | API | API 변경 → FE/BE Code 영향 |
| Screen 변경 | Screens | 화면 변경 → Code(FE) 영향 |

---

## 5. Graph Validation

### validateGraph(scope)

그래프 무결성을 검증한다.

| Check | Description | Severity |
|-------|-------------|----------|
| Orphan nodes | 엣지가 없는 고립 노드 | Warning |
| Dangling edges | 존재하지 않는 노드를 참조하는 엣지 | Error |
| Circular dependency | 순환 참조 | Error |
| Missing standard edges | 표준 의존 관계 누락 | Warning |
| Stale impact flags | 7일 이상 경과한 미해결 impact flag | Warning |

---

## 6. Safety Rules

1. `_links.json`은 프로젝트 전역 파일 (scope별이 아님). 모든 앱의 의존 관계를 하나의 파일에서 관리
2. 노드 제거 시 연결된 엣지도 반드시 함께 제거 (dangling edge 방지)
3. cascade는 downstream만 (upstream으로 역전파하지 않음)
4. Final 상태 문서에 impact-flag 설정 시 사용자 알림 (갱신 필요 경고)
5. 순환 참조 탐지 시 엣지 추가 거부 + 경고
6. 모든 그래프 변경은 `lastUpdated` 타임스탬프 갱신
