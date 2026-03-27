# 3-Layer Data Pipeline

> _input → _classified → docs 파이프라인의 설계 원칙과 실행 규칙.

---

## 1. Overview

raw data(RFP, 회의록, AS-IS 자료)를 Claude가 한 번에 처리하면 context window 한계로 앞부분이 loss된다. 중간 정제 레이어(_classified)를 두면:

- chunk 단위 분석 → classified에 누적 → 전체 context 없이도 이전 분석 참조 가능
- 모든 항목에 `source: {file, page, section}` 메타데이터 → 역추적 가능
- classified 기반 산출물 생성은 멱등(같은 input → 같은 output)
- 새 회의록 추가 시 incremental 분석만 → 처음부터 재생성 불필요

---

## 2. Layer 1: _input/ (Raw Data)

사람이 넣는 원본. Claude가 수정하지 않음.

### 허용 파일 유형
- RFP 원문 (PDF, DOCX, MD)
- AS-IS 시스템/화면/DB/워크플로 자료
- 질의록, 회의록, 인터뷰 노트
- Pain Points 수집 결과
- 벤치마킹, 외부 참고 링크

### 구조
```
_input/
├── rfp/              # RFP 원문
├── as-is/            # AS-IS 자료
├── meeting-notes/    # 회의록/질의록
└── _manifest.json    # 파일 목록 + 메타데이터
```

### _manifest.json 스키마
```json
{
  "files": [
    {
      "path": "rfp/main-rfp.pdf",
      "type": "rfp",
      "addedAt": "2026-03-27",
      "processedAt": null,
      "status": "pending"
    }
  ]
}
```

---

## 3. Layer 2: _classified/ (Structured Data)

engine-analyzer가 raw를 chunk 단위로 분석하여 분류/태깅, JSON으로 적재.

### 10개 카테고리

| 카테고리 | ID 패턴 | 핵심 필드 | 입력 소스 |
|----------|---------|-----------|-----------|
| requirements/ | FR-nnn, NR-nnn | id, type, title, description, priority, source, tags | RFP, 회의록 |
| pain-points/ | PP-nnn | id, description, severity, affected_users, source | 인터뷰 |
| domain-terms/ | DT-nnn | id, term, definition, synonyms, source | RFP, AS-IS |
| stakeholders/ | SH-nnn | id, name, role, department, needs, source | RFP |
| workflows/ | WF-nnn | id, name, actors, steps[], systems[], source | AS-IS |
| screens/ | SC-nnn | id, name, url, functions[], issues[], source | AS-IS |
| data-models/ | DM-nnn | id, table_name, columns[], relations[], source | AS-IS DB |
| constraints/ | CN-nnn | id, type(tech\|policy\|legal), description, source | RFP, 법규 |
| decisions/ | DC-nnn | id, date, participants[], decision, rationale, source | 회의록 |
| questions/ | QS-nnn | id, question, context, status, answer, source | 분석 중 |

### 항목 Lifecycle

```
extracted → validated → adopted / rejected
```

- **extracted**: analyzer가 raw에서 자동 추출. 사람 검증 안 됨.
- **validated**: FDE가 확인/수정 완료. 산출물 생성에 사용 가능.
- **adopted**: 실제 산출물(SRS 등)에 반영 완료. 역참조 링크 생성됨.
- **rejected**: 검토 후 제외. 사유 기록.

### _index.json (카테고리별)

각 카테고리 폴더에 `_index.json` 존재. engine-doc이 산출물 생성 시 index만 읽어서 필요한 항목 선택적 로드.

```json
{
  "category": "requirements",
  "items": [
    { "id": "FR-001", "title": "회원가입", "status": "validated", "priority": "high", "tags": ["auth"] }
  ],
  "stats": { "total": 42, "extracted": 10, "validated": 25, "adopted": 7, "rejected": 0 }
}
```

### _summary.json (앱 전체)

```json
{
  "app": "retail",
  "lastAnalyzed": "2026-03-27T10:00:00Z",
  "categories": {
    "requirements": { "total": 42, "validated": 25 },
    "pain-points": { "total": 15, "validated": 12 }
  },
  "coverage": {
    "requirements-to-srs": 0.85,
    "screens-to-design": 0.60
  }
}
```

---

## 4. Layer 3: docs/ (Deliverables)

classified 데이터를 조합하여 생성. 각 항목에 출처 링크 보존.

### 매핑 규칙

| 산출물 | classified 소스 |
|--------|----------------|
| SRS | requirements/ + constraints/ + stakeholders/ |
| IA | workflows/ + screens/ + domain-terms/ |
| Roadmap | requirements/ + estimator 결과 |
| ERD | data-models/ + requirements/ |
| Screen | screens/ + workflows/ + pain-points/ |
| API | requirements/ + data-models/ |
| TestCase | requirements/ + screens/ + constraints/ |

### 문서 Status

```
Draft → Review → Final
```

---

## 5. Pipeline 실행 규칙

### /u-ingest 실행 시
1. `_input/_manifest.json`에서 `status: "pending"` 파일 수집
2. chunk 단위로 engine-analyzer 실행
3. 분류된 항목을 해당 `_classified/{category}/` 에 JSON 적재
4. `_classified/{category}/_index.json` 자동 갱신
5. `_classified/_summary.json` 갱신
6. `_input/_manifest.json`의 `processedAt`, `status` 갱신

### Incremental 처리 (--incremental)
- `_manifest.json`에서 `processedAt`이 null이거나 파일 수정시각보다 이전인 항목만 처리
- 기존 classified 항목은 보존, 신규분만 추가

### Context Window 절약 전략
1. **Index-first**: `_index.json`만 먼저 읽고 필요한 항목만 개별 로드
2. **Chunk processing**: raw를 100줄 단위로 분할 처리
3. **Summary reference**: `_summary.json`으로 전체 통계 파악 후 선택적 접근
