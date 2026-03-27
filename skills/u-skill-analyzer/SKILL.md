---
name: u-skill-analyzer
description: "_input/ 원시 자료(RFP, 회의록, AS-IS 문서)를 파싱하여 청크 기반 분석 후 10개 카테고리로 분류하고, _classified/에 구조화 JSON으로 적재하는 내부 엔진."
---

# u-skill-analyzer -- Raw Data Analysis & Classification Engine

`_input/` 디렉토리의 원시 자료(RFP, 회의록, AS-IS 문서 등)를 청크 단위로 분석하여 10개 카테고리로 분류하고, `_classified/`에 구조화된 JSON으로 적재하는 내부 엔진이다.

**Owner Agent:** u-agent-planner

---

## 1. Operations

### scanInput(scope)

`_input/` 디렉토리의 파일 목록을 스캔하고, 처리 상태를 식별한다.

**프로세스:**

1. `_input/_manifest.json` 읽기 (없으면 초기화)
2. `_input/` 하위 전체 파일 스캔
3. 파일별 상태 판정:
   - manifest에 없는 파일 → `new`
   - manifest timestamp < 파일 mtime → `modified`
   - manifest timestamp >= 파일 mtime → `processed`

**입력 디렉토리 구조:**

```
_input/
  rfp/          # RFP 문서, 제안 요청서
  as-is/        # 현행 시스템 문서
  meeting-notes/ # 회의록, 인터뷰 기록
  benchmarks/   # 벤치마크, 경쟁 분석
  links/        # URL 북마크, 외부 참조
```

**출력:**

```json
{
  "scope": "retail",
  "totalFiles": 15,
  "newFiles": 3,
  "modifiedFiles": 1,
  "processedFiles": 11,
  "files": [
    {
      "path": "_input/rfp/main-rfp.pdf",
      "size": 245760,
      "status": "new",
      "mtime": "{ISO 8601}"
    }
  ]
}
```

### analyzeChunk(content, sourceRef)

텍스트 청크를 분석하여 항목을 추출한다.

**청크 분할 규칙:**

| File Size | Chunk Size | Split Strategy |
|-----------|-----------|----------------|
| < 50KB | 전체 (단일 청크) | 분할 없음 |
| 50-200KB | ~30KB | 섹션 경계에서 분할 |
| > 200KB | ~20KB | 섹션 경계에서 분할 |

**분할 우선순위:**

1. 장/절 제목 경계 (# heading)
2. 큰 단락 경계 (빈 줄 2개+)
3. 페이지 경계 (PDF의 경우)
4. 강제 크기 분할 (위 경계가 없을 때)

**분석 프로세스:**

1. 청크 텍스트 파싱
2. 의미 단위 식별 (요구사항, 문제점, 도메인 용어 등)
3. 각 항목에 카테고리 배정
4. 소스 메타데이터 부착 (MANDATORY)

**소스 메타데이터 (필수):**

```json
{
  "source": {
    "file": "_input/rfp/main-rfp.pdf",
    "page": 47,
    "section": "3.2.1 Authentication Requirements",
    "extractedAt": "{ISO 8601}",
    "confidence": "high|medium|low"
  }
}
```

### classify(item)

추출된 항목을 10개 카테고리 중 하나에 분류한다.

### dedup(newItem, existingIndex)

새 항목과 기존 항목 간 중복을 검사한다.

**중복 판정 기준:**

| Criterion | Threshold | Weight |
|-----------|-----------|--------|
| Title similarity | > 0.8 | 0.4 |
| Description overlap | > 0.7 | 0.3 |
| Same category | exact match | 0.2 |
| Same source file | exact match | 0.1 |

- 종합 점수 > 0.75 → 중복 후보
- auto mode: 가정으로 기록 + 더 완전한 항목 보존
- interactive mode: 사용자에게 병합/보존 선택 요청
- 병합 시 source 배열에 모든 출처 보존

### updateManifest(scope)

처리 완료된 파일 정보를 `_manifest.json`에 갱신한다.

```json
{
  "lastScanAt": "{ISO 8601}",
  "files": {
    "_input/rfp/main-rfp.pdf": {
      "processedAt": "{ISO 8601}",
      "size": 245760,
      "mtime": "{ISO 8601}",
      "itemsExtracted": 42,
      "status": "processed"
    }
  }
}
```

---

## 2. 10 Categories

### Category Schema Table

| # | Category | ID Pattern | Key Fields |
|---|----------|-----------|------------|
| 1 | `requirements/` | FR-nnn, NR-nnn | id, type(FR/NR), title, description, priority(Must/Should/Could/Won't), source, related, status, tags |
| 2 | `pain-points/` | PP-nnn | id, description, severity(high/medium/low), affected_users, current_workaround, source |
| 3 | `domain-terms/` | DT-nnn | id, term, definition, synonyms[], context, source |
| 4 | `stakeholders/` | SH-nnn | id, name, role, department, needs[], pain_points[], source |
| 5 | `workflows/` | WF-nnn | id, name, actors[], steps[], systems[], pain_points[], source |
| 6 | `screens/` | SC-nnn | id, name, url, functions[], issues[], screenshot_path, source |
| 7 | `data-models/` | DM-nnn | id, table_name, columns[], relations[], issues[], source |
| 8 | `constraints/` | CN-nnn | id, type(tech/policy/legal), description, impact, source |
| 9 | `decisions/` | DC-nnn | id, date, participants[], decision, rationale, source |
| 10 | `questions/` | QS-nnn | id, question, context, status(open/resolved), answer, source |

### Category-Specific Field Schemas

#### requirements/ (FR/NR)

```json
{
  "id": "FR-0001",
  "type": "FR",
  "title": "사용자 인증",
  "description": "이메일/비밀번호 기반 로그인 기능",
  "priority": "Must",
  "source": { "file": "...", "page": 12, "section": "3.1" },
  "related": ["FR-0002"],
  "status": "extracted",
  "tags": ["auth", "security"]
}
```

#### workflows/

```json
{
  "id": "WF-001",
  "name": "주문 처리 프로세스",
  "actors": ["고객", "관리자"],
  "steps": [
    { "order": 1, "action": "상품 검색", "actor": "고객", "system": "검색 엔진" },
    { "order": 2, "action": "장바구니 추가", "actor": "고객", "system": "장바구니 서비스" }
  ],
  "systems": ["검색 엔진", "장바구니 서비스", "결제 게이트웨이"],
  "pain_points": ["검색 속도 3초 이상", "결제 실패 시 재시도 불편"],
  "source": { "file": "...", "section": "4.2" }
}
```

#### data-models/

```json
{
  "id": "DM-001",
  "table_name": "users",
  "columns": [
    { "name": "id", "type": "bigint", "pk": true, "nullable": false },
    { "name": "email", "type": "varchar(255)", "pk": false, "nullable": false, "unique": true }
  ],
  "relations": [
    { "type": "one-to-many", "target": "orders", "fk": "user_id" }
  ],
  "issues": ["인덱스 누락", "정규화 부족"],
  "source": { "file": "...", "section": "ERD" }
}
```

---

## 3. Item Status Lifecycle

```
extracted → validated → adopted | rejected
```

| Status | Description | Transitioned By |
|--------|-------------|----------------|
| `extracted` | 자동 추출 완료. 미검증 | analyzeChunk (자동) |
| `validated` | 사용자 검증 완료 | /u-ingest --review 또는 /u-assume approve |
| `adopted` | SSoT 문서에 반영 완료 | /u-plan 실행 시 자동 |
| `rejected` | 검토 후 제외. 사유 기록 | /u-assume reject |

---

## 4. _classified/ Output Structure

```
_classified/
  _summary.json         # 전체 분석 요약
  requirements/
    _index.json         # 카테고리 인덱스
    FR-0001.json
    NR-0001.json
  pain-points/
    _index.json
    PP-001.json
  domain-terms/
    _index.json
    DT-001.json
  stakeholders/
    _index.json
    SH-001.json
  workflows/
    _index.json
    WF-001.json
  screens/
    _index.json
    SC-001.json
  data-models/
    _index.json
    DM-001.json
  constraints/
    _index.json
    CN-001.json
  decisions/
    _index.json
    DC-001.json
  questions/
    _index.json
    QS-001.json
```

### _summary.json

```json
{
  "lastIngestAt": "{ISO 8601}",
  "lastIngestScope": "retail",
  "filesProcessed": 12,
  "totalItems": 156,
  "byCategory": {
    "requirements": { "total": 42, "extracted": 30, "validated": 12, "adopted": 0, "rejected": 0 },
    "pain-points": { "total": 18, "extracted": 15, "validated": 3, "adopted": 0, "rejected": 0 }
  },
  "byStatus": {
    "extracted": 120,
    "validated": 36,
    "adopted": 0,
    "rejected": 0
  }
}
```

---

## 5. Safety Rules

1. `_input/` 파일은 절대 수정하지 않음 (READ-ONLY)
2. 모든 추출 항목에 source 메타데이터 필수 (미부착 항목은 신뢰 불가)
3. 기존 ID 재사용 금지 (삭제된 항목의 ID도 재할당하지 않음)
4. 대용량 파일은 반드시 청크 분할 (context window 보호)
5. `--incremental` 시 기존 분류 데이터 보존, 신규 항목만 추가
6. confidence가 "low"인 항목은 status = "extracted" + 사용자 검증 필요 표시
7. 카테고리별 `_index.json` 갱신 필수
8. 분석 가정(auto mode)은 `_assumptions/`에 기록
