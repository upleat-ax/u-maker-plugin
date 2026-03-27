---
name: u-ingest
description: "외부 입력 데이터를 분석하여 정제/분류한다. _input/ raw data를 _classified/ 구조화 JSON으로 변환하고, 10개 카테고리로 분류한다."
triggers:
  - "/u-ingest"
  - "ingest data"
  - "데이터 분석"
  - "자료 분석"
---

# u-ingest -- Raw to Classified Analysis

`/u-ingest [scope] [--review] [--incremental]` 명령으로 `_input/` 원시 자료를 분석하여 `_classified/` 구조화 데이터로 변환한다.

**Primary Agent:** u-agent-planner (engine-analyzer 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `--review` | 추출 항목을 사용자에게 검증받은 후 반영 |
| `--incremental` | 마지막 ingest 이후 변경된 파일만 처리 |

---

## Execution Flow

### Step 1: Resolve Scope

1. `u-maker.config.json` 읽어 앱 목록 조회
2. scope 해석 → 대상 앱의 `_input/` 경로 결정
3. scope 생략 + 앱 1개: 자동 선택 / 앱 2개+: 사용자에게 질문

### Step 2: Scan _input/

1. `_input/_manifest.json` 읽기
2. `_input/` 하위 전체 파일 스캔 (rfp/, as-is/, meeting-notes/, benchmarks/, links/)
3. 새 파일 또는 수정된 파일 식별:
   - `_manifest.json`에 없는 파일 → 신규
   - `_manifest.json` 타임스탬프 < 파일 mtime → 수정됨
4. `_manifest.json` 갱신 (파일 목록, 크기, 타임스탬프)
5. `--incremental`: 변경된 파일만 대상 목록에 포함

### Step 3: Analyze Each File (engine-analyzer)

파일별 분석 프로세스:

1. **파일 크기 확인**:
   - < 50KB: 단일 청크로 처리
   - 50-200KB: ~30KB 단위로 섹션 경계에서 분할
   - > 200KB: ~20KB 단위로 분할

2. **청크별 분석**:
   - 텍스트 파싱 + 구조 인식
   - 10개 카테고리로 항목 추출
   - 각 항목에 source metadata 필수 부착

3. **소스 메타데이터** (MANDATORY):
   ```json
   {
     "source": {
       "file": "_input/rfp/main-rfp.pdf",
       "page": 47,
       "section": "3.2.1 Authentication Requirements",
       "extractedAt": "2026-03-27T10:00:00Z",
       "confidence": "high"
     }
   }
   ```

### Step 4: Classify into 10 Categories

| Category | File Pattern | Key Fields | Input Sources |
|----------|-------------|------------|---------------|
| `requirements/` | FR-nnn.json, NR-nnn.json | id, type(FR/NR), title, description, priority, source, related, status, tags | RFP, 회의록 |
| `pain-points/` | PP-nnn.json | id, description, severity, affected_users, current_workaround, source | 인터뷰, Pain Points |
| `domain-terms/` | DT-nnn.json | id, term, definition, synonyms, context, source | RFP, 회의록, AS-IS |
| `stakeholders/` | SH-nnn.json | id, name, role, department, needs, pain_points, source | RFP, 회의록 |
| `workflows/` | WF-nnn.json | id, name, actors, steps[], systems[], pain_points[], source | AS-IS workflows |
| `screens/` | SC-nnn.json | id, name, url, functions[], issues[], screenshot_path, source | AS-IS screens |
| `data-models/` | DM-nnn.json | id, table_name, columns[], relations[], issues[], source | AS-IS DB |
| `constraints/` | CN-nnn.json | id, type(tech/policy/legal), description, impact, source | RFP, 법규, 기술검토 |
| `decisions/` | DC-nnn.json | id, date, participants[], decision, rationale, source | 회의록, 토론 세션 |
| `questions/` | QS-nnn.json | id, question, context, status(open/resolved), answer, source | 분석 중 발생 |

### Step 5: Update Index Files

각 카테고리의 `_index.json` 갱신:

```json
{
  "category": "requirements",
  "items": [
    {
      "id": "FR-0001",
      "title": "사용자 인증",
      "status": "extracted",
      "priority": "Must",
      "tags": ["auth", "security"],
      "source": "_input/rfp/main-rfp.pdf"
    }
  ],
  "lastUpdated": "{ISO 8601}",
  "totalCount": 42
}
```

### Step 6: Review Mode (--review)

`--review` 플래그 사용 시:

1. 카테고리별 추출 항목 목록을 사용자에게 표시
2. 항목별로 확인/수정/제외 선택:
   - **확인**: status → `validated`
   - **수정**: 내용 교정 후 status → `validated`
   - **제외**: status → `rejected`, 사유 기록
3. 미확인 항목은 `extracted` 상태 유지

### Step 7: Update Summary

`_classified/_summary.json` 갱신:

```json
{
  "lastIngestAt": "{ISO 8601}",
  "lastIngestScope": "{scope}",
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

### Step 8: Auto-Register to Backlog

검증된 requirements(`validated` status) 중 backlog에 미등록된 항목:
1. `_backlog/_index.json`에 등록
2. priority = 추출된 priority (또는 Medium 기본값)
3. status = "todo"
4. source = classified item ID

---

## Item Lifecycle

```
extracted → validated → adopted | rejected
```

| Status | Meaning | Transition By |
|--------|---------|---------------|
| `extracted` | analyzer가 자동 추출. 미검증 | 자동 (분석 시) |
| `validated` | 사용자가 확인/수정 완료 | `/u-ingest --review` 또는 `/u-assume approve` |
| `adopted` | 산출물(SRS 등)에 반영 완료 | `/u-plan` 실행 시 자동 |
| `rejected` | 검토 후 제외. 사유 기록됨 | `/u-assume reject` |

---

## Deduplication

분석 완료 후 교차 참조 패스:
1. 동일/유사 항목 탐지 (title similarity > 0.8)
2. 중복 후보를 사용자에게 제시 (interactive) 또는 가정으로 기록 (auto)
3. 병합 시 source 배열에 모든 출처 보존

---

## Safety Rules

1. `_input/` 파일은 절대 수정하지 않음 (READ-ONLY)
2. 모든 추출 항목에 source metadata 필수 (미부착 항목은 신뢰할 수 없음)
3. 기존 ID 재사용 금지 (삭제된 항목의 ID도 재할당하지 않음)
4. 대용량 파일은 반드시 청크 분할 (context window 보호)
5. `--incremental` 시 기존 분류 데이터 보존, 신규 항목만 추가
6. 분석 가정(auto mode)은 `_assumptions/`에 기록
