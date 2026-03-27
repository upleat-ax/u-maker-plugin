# Cascade Rules

> _links.json 기반 의존성 그래프와 변경 cascade 전파 규칙. engine-dep이 관리.

---

## 1. Overview

문서 간 의존 관계를 _links.json에 그래프로 관리. 상위 문서 변경 시 하위 문서에 impact flag를 자동 전파.

---

## 2. _links.json 구조

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-03-27T10:00:00Z",
  "nodes": [
    { "id": "srs", "path": "docs/01-plan/srs.md", "type": "document", "status": "Final" },
    { "id": "erd", "path": "docs/02-design/erd.md", "type": "document", "status": "Draft" },
    { "id": "FR-001", "path": "_classified/requirements/FR-001.json", "type": "classified" }
  ],
  "edges": [
    { "from": "srs", "to": "erd", "type": "derives", "strength": "strong" },
    { "from": "srs", "to": "test-cases", "type": "derives", "strength": "strong" },
    { "from": "FR-001", "to": "srs", "type": "source", "strength": "strong" }
  ]
}
```

---

## 3. Edge Types

| Type | 방향 | 의미 | Cascade |
|------|------|------|---------|
| `derives` | A → B | B는 A에서 파생됨 | A 변경 → B에 impact flag |
| `source` | A → B | B의 출처가 A | A 변경 → B 재검증 필요 |
| `references` | A → B | A가 B를 참조 | B 변경 → A에 정보성 알림 |
| `validates` | A → B | A가 B를 검증 | B 변경 → A 재검증 필요 |
| `implements` | A → B | A가 B를 구현 | B 변경 → A 재구현 필요 |

---

## 4. Strength Levels

| Level | 의미 | Cascade 동작 |
|-------|------|-------------|
| **strong** | 핵심 의존. 소스 변경 시 반드시 갱신 | impact flag = "must-update" |
| **moderate** | 부분 의존. 검토 필요 | impact flag = "review-needed" |
| **weak** | 참조 수준. 정보성 알림 | impact flag = "info" |

---

## 5. 기본 의존성 그래프

```
SRS ──derives──→ ERD
SRS ──derives──→ API
SRS ──derives──→ Screen
SRS ──derives──→ TestCase
SRS ──derives──→ RTM
IA ──derives──→ Screen
IA ──derives──→ ScreenFlow
Screen ──derives──→ Code (FE)
API ──derives──→ Code (BE)
ERD ──derives──→ Code (DB)
TestCase ──validates──→ Code
```

---

## 6. Cascade 실행 규칙

### 변경 감지 시 (on-doc-change hook)
1. 변경된 문서의 node ID 확인
2. _links.json에서 이 node를 `from`으로 가진 edges 검색
3. 각 target node에 impact flag 설정:
   - `_index.json`의 해당 문서에 `impactFlag` 추가
   - flag 값 = edge.strength에 따른 분류
4. /u-status에서 impact flags 표시

### --cascade 플래그 사용 시
- impact flag만 설정하는 게 아니라, 실제로 하위 문서를 자동 갱신
- engine-doc이 상위 문서 변경분을 읽고 하위 문서 diff 적용
- 갱신된 문서의 status는 "Review"로 변경 (Final→Review)

---

## 7. Impact Flag 스키마

`_index.json`에 추가:
```json
{
  "id": "erd",
  "path": "docs/02-design/erd.md",
  "status": "Final",
  "impactFlag": {
    "level": "must-update",
    "source": "srs",
    "changedAt": "2026-03-27T10:00:00Z",
    "description": "SRS FR-015 변경으로 ERD 갱신 필요"
  }
}
```
