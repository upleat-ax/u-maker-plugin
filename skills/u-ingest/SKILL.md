---
name: u-ingest
description: "외부 입력 데이터를 분석하여 정제/분류한다. _input/ raw data를 _classified/ 구조화 JSON으로 변환하고, 12개 카테고리로 분류한다."
triggers:
  - "/u-ingest"
  - "ingest data"
  - "데이터 분석"
  - "자료 분석"
---

# u-ingest -- Raw to Classified Analysis

`/u-ingest [scope] [--review] [--incremental]` 명령으로 `_input/` 원시 자료를 분석하여 `_classified/` 구조화 데이터(12개 카테고리)로 변환한다.

**Primary Agent:** u-agent-planner (engine-analyzer 사용)

---

## Flags

| Flag | Description |
|------|-------------|
| `--review` | 추출 항목을 사용자 검증 후 반영 |
| `--incremental` | 마지막 ingest 이후 변경 파일만 처리 |

---

## Execution Flow

### Step 1: Resolve Scope

config → 앱 목록 → scope 해석 → `_input/` 경로 결정. 생략 시 앱 1개 자동선택 / 2개+ 사용자 질문.

### Step 1.5: Collect from _dropzone/

`.u-maker/_dropzone/` 스캔 → 파일별 카테고리 판정 → `_input/{category}/`로 이동 (복사 아님) → 분류 불가 시 `_input/raw/`로 이동 → `_sort-log.json` 기록. 빈 디렉토리면 skip.

### Step 2: Sort Raw Files

`_input/raw/`에 파일 존재 시 서브폴더로 자동 분류:

| 판정 기준 | 대상 폴더 |
|----------|----------|
| RFP, 제안요청서, 요구사항, SOW | `rfp/` |
| AS-IS, 현행 시스템, DB 스키마 | `as-is/` |
| 회의록, 인터뷰, 워크숍 기록 | `meeting-notes/` |
| 벤치마킹, 경쟁사, 시장 조사 | `benchmarks/` |
| URL 목록, 외부 링크 | `links/` |
| 표준, 정책, 가이드라인, 규정 | `standards/` |
| 디자인시스템, UI가이드, UX 가이드라인 | `ux-standards/` |

**판정 로직:** 파일명 키워드 매칭(우선) → 내용 분석(fallback, 첫 ~5KB) → 판별 불가 시 `raw/`에 유지 + `_sort-log.json`에 "unresolved" 기록. 동일 파일명 충돌 시 타임스탬프 rename.

### Step 3: Scan _input/

`_manifest.json` 읽기 → 전체 파일 스캔 → 신규/수정 파일 식별 → manifest 갱신. `--incremental`: 변경 파일만 대상.

### Step 4: Analyze Each File (engine-analyzer)

- **청크 분할:** <50KB 단일 / 50-200KB ~30KB 분할 / >200KB ~20KB 분할 (섹션 경계 우선)
- **청크별:** 텍스트 파싱 → 12개 카테고리 항목 추출 → source metadata 필수 부착

**Source metadata (MANDATORY):** `{ file, page, section, extractedAt, confidence }`

### Step 5: Classify into 12 Categories

| Category | ID Pattern | Key Fields |
|----------|-----------|------------|
| `requirements/` | FR-nnn, NR-nnn | id, type, title, description, priority, source, status, tags |
| `pain-points/` | PP-nnn | id, description, severity, affected_users, workaround, source |
| `domain-terms/` | DT-nnn | id, term, definition, synonyms, context, source |
| `stakeholders/` | SH-nnn | id, name, role, department, needs, source |
| `workflows/` | WF-nnn | id, name, actors, steps, systems, pain_points, source |
| `screens/` | SC-nnn | id, name, url, functions, issues, source |
| `data-models/` | DM-nnn | id, table_name, columns, relations, issues, source |
| `constraints/` | CN-nnn | id, type, description, impact, source |
| `decisions/` | DC-nnn | id, date, participants, decision, rationale, source |
| `questions/` | QS-nnn | id, question, context, status, answer, source |
| `standards/` | STD-nnn | id, title, type(naming/process/policy/legal), appliesTo, enforcement, source |
| `ux-standards/` | UXS-nnn | id, title, type(component/layout/token/interaction), appliesTo, enforcement, source |

### Step 6: Update Index Files

각 카테고리 `_index.json` 갱신: `{ category, items: [{ id, title, status, priority, tags, source }], lastUpdated, totalCount }`

### Step 7: Review Mode (--review)

카테고리별 추출 목록 표시 → 항목별 확인(→validated) / 수정(→validated) / 제외(→rejected, 사유 기록). 미확인은 `extracted` 유지.

### Step 7.1: Generate Ingest Review Report

ingest 완료 시 `/u-report {scope} --only ingest` 자동 호출 → `.u-maker/_reports/{scope}/ingest-report.html`

### Step 8: Update Summary

`_classified/_summary.json` 갱신: filesProcessed, totalItems, byCategory(각 status 집계), byStatus 집계.

### Step 9: Auto-Register to Backlog

`validated` status requirements 중 미등록 항목 → `_backlog/_index.json` 등록 (priority 유지 또는 Medium 기본, status: "todo")

---

## Item Lifecycle

```
extracted → validated → adopted | rejected
```

| Status | Meaning | Transition By |
|--------|---------|---------------|
| `extracted` | 자동 추출, 미검증 | 분석 시 자동 |
| `validated` | 사용자 확인 완료 | `--review` 또는 `/u-assume approve` |
| `adopted` | 산출물에 반영 완료 | `/u-plan` 실행 시 자동 |
| `rejected` | 제외, 사유 기록 | `/u-assume reject` |

---

## Deduplication

분석 후 교차 참조: title similarity > 0.8 → 중복 후보 제시 (interactive) 또는 가정 기록 (auto). 병합 시 source 배열 보존.

---

## Safety Rules

1. `_input/` READ-ONLY (단, `_dropzone/`→`_input/` 이동 및 `raw/`→서브폴더 이동은 예외, 내용 변경 없음)
2. 자동 분류 불가 시 `raw/`에 유지 (강제 분류 금지)
3. 모든 항목에 source metadata 필수, 기존 ID 재사용 금지
4. 대용량 청크 분할 필수, `--incremental` 시 기존 보존+신규만 추가
5. 분석 가정은 `_assumptions/`에 기록
