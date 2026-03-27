---
name: engine-dep
description: |
  _links.json 글로벌 의존성 그래프를 관리하고,
  문서 간 참조 추적 및 변경 시 캐스케이드 전파를 수행하는 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports:
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
---

# Engine: Dependency Manager

> 문서 간 의존성 그래프를 관리하고, 변경 시 영향받는 문서를 자동 추적한다.

## 역할

- `_links.json` 글로벌 의존성 그래프 CRUD
- 문서 간 참조 체인 추적: FR → US → FT → Screen → API → TC
- 변경 캐스케이드: 상위 문서 변경 시 하위 의존 문서에 impactFlag 설정
- 영향도 분석: 특정 변경에 대한 영향 범위 산출
- 크로스 앱 의존성 지원

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 변경된 문서 ID, 변경 유형(create/update/delete) |
| **Output** | `{ affectedDocs[], impactFlags[], cascadeLog }` |

## _links.json 구조

```json
{
  "nodes": {
    "FR-0010": { "type": "FR", "app": "web", "file": "01-plan/1_SRS_RA.md" },
    "US-0010": { "type": "US", "app": "web", "file": "01-plan/1_SRS_RA.md" }
  },
  "edges": [
    { "from": "FR-0010", "to": "US-0010", "relation": "decomposed-to" },
    { "from": "US-0010", "to": "FT-0010", "relation": "implemented-by" }
  ]
}
```

## 실행 절차

### Step 1. 의존성 등록/갱신

1. 문서 생성/수정 시 해당 문서의 ID 매핑 정보 추출
2. `_links.json`의 `nodes`에 노드 등록/갱신
3. 매핑 필드(FR Mapping, US Mapping 등)에서 `edges` 생성

### Step 2. 캐스케이드 전파

문서 A가 변경되었을 때:

1. `edges`에서 A를 `from`으로 가진 모든 간선 탐색 (직접 의존)
2. BFS/DFS로 전체 하위 의존 트리 순회
3. 각 영향 문서에 `impactFlag` 설정:
   - `needs-review`: 내용 변경으로 검토 필요
   - `needs-update`: 상위 삭제/큰 변경으로 갱신 필수
   - `broken-ref`: 참조 대상 삭제됨

### Step 3. 영향도 분석

주어진 변경에 대해:
1. 직접 영향(depth=1): 바로 연결된 문서
2. 간접 영향(depth=2+): 전이적 의존 문서
3. 크로스 앱 영향: 다른 앱의 공용 문서 참조 추적

결과를 `{ direct: [], transitive: [], crossApp: [] }` 형태로 반환

### Step 4. 정합성 검증

- 고아 노드 탐지: edges에 연결되지 않은 단독 노드
- 순환 참조 탐지: 그래프 사이클 검사
- 끊어진 참조 탐지: edges의 대상 노드가 nodes에 미존재

## 오류 처리

| 상황 | 처리 |
|------|------|
| _links.json 미존재 | 빈 구조 `{ nodes: {}, edges: [] }` 생성 |
| 순환 참조 감지 | 경고 + 순환 경로 출력, 캐스케이드 중단 |
| 노드 ID 중복 | 기존 노드 갱신 + 경고 로그 |
| 크로스 앱 참조 실패 | 해당 앱 미존재 경고 + skip |

## 연동

- **호출원**: engine-doc (문서 쓰기 후 의존성 갱신), engine-validator (정합성 검증)
- **호출 대상**: 없음 (자체 _links.json 관리)
- **의존 엔진**: engine-doc (문서 메타데이터 조회)
