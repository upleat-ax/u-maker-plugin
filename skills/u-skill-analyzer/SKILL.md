---
name: u-skill-analyzer
description: "_input/ 원시 자료(RFP, 회의록, AS-IS 문서)를 파싱하여 청크 기반 분석 후 12개 카테고리로 분류하고, _classified/에 구조화 JSON으로 적재하는 내부 엔진."
---

# u-skill-analyzer -- Raw Data Analysis & Classification Engine

`_input/` 원시 자료를 청크 단위 분석 → 12개 카테고리 분류 → `_classified/` 구조화 JSON 적재.

**Owner Agent:** u-agent-planner

---

## 1. Operations

### scanInput(scope)

`_input/` 파일 스캔 → `_manifest.json` 대비 상태 판정 (new/modified/processed)

**입력 디렉토리:** `_input/` 하위 `rfp/`, `as-is/`, `meeting-notes/`, `benchmarks/`, `links/`

**출력:** `{ scope, totalFiles, newFiles, modifiedFiles, processedFiles, files: [{ path, size, status, mtime }] }`

### analyzeChunk(content, sourceRef)

텍스트 청크 분석 → 항목 추출.

**청크 분할:** <50KB 단일 / 50-200KB ~30KB / >200KB ~20KB (섹션 경계 우선: heading → 빈줄 → 페이지 → 강제)

**프로세스:** 텍스트 파싱 → 의미 단위 식별 → 카테고리 배정 → source metadata 부착 (MANDATORY)

**Source metadata:** `{ file, page, section, extractedAt, confidence: "high|medium|low" }`

### classify(item)

추출 항목을 12개 카테고리 중 하나에 분류.

### dedup(newItem, existingIndex)

중복 검사: title similarity(0.4) + description overlap(0.3) + same category(0.2) + same source(0.1) → 종합 >0.75 중복 후보. auto: 가정 기록+완전한 항목 보존 / interactive: 사용자 선택. 병합 시 source 배열 보존.

### updateManifest(scope)

처리 완료 파일 정보를 `_manifest.json`에 갱신.

---

## 2. 12 Categories

| # | Category | ID Pattern | Key Fields |
|---|----------|-----------|------------|
| 1 | `requirements/` | FR-nnn, NR-nnn | id, type(FR/NR), title, description, priority(MoSCoW), source, related, status, tags |
| 2 | `pain-points/` | PP-nnn | id, description, severity, affected_users, workaround, source |
| 3 | `domain-terms/` | DT-nnn | id, term, definition, synonyms, context, source |
| 4 | `stakeholders/` | SH-nnn | id, name, role, department, needs, pain_points, source |
| 5 | `workflows/` | WF-nnn | id, name, actors, steps, systems, pain_points, source |
| 6 | `screens/` | SC-nnn | id, name, url, functions, issues, screenshot_path, source |
| 7 | `data-models/` | DM-nnn | id, table_name, columns, relations, issues, source |
| 8 | `constraints/` | CN-nnn | id, type(tech/policy/legal), description, impact, source |
| 9 | `decisions/` | DC-nnn | id, date, participants, decision, rationale, source |
| 10 | `questions/` | QS-nnn | id, question, context, status(open/resolved), answer, source |
| 11 | `standards/` | STD-nnnn | id, category, title, type(naming/process/approval/security/etc), scope, priority(mandatory/recommended/optional), appliesTo, source, status |
| 12 | `ux-standards/` | UXS-nnnn | id, category, title, type(component/layout/typography/color/etc), scope, priority, appliesTo, source, status |

### standards/ -- 기획 표준정책

네이밍, 프로세스, 승인 절차, 폼 표준, 데이터, 보안, 성능 기준. Source keywords: 표준, 정책, 규칙, 가이드라인, convention, policy, standard, guideline

### ux-standards/ -- UX 표준정책

컴포넌트, 레이아웃, 타이포, 컬러, 간격, 인터랙션, 접근성, 반응형. Source keywords: 디자인시스템, UI가이드, UX표준, design system, component library

---

## 3. Item Status Lifecycle

`extracted` → `validated` → `adopted` | `rejected`

| Status | Transitioned By |
|--------|----------------|
| `extracted` | analyzeChunk 자동 |
| `validated` | /u-ingest --review 또는 /u-assume approve |
| `adopted` | /u-plan 실행 시 자동 |
| `rejected` | /u-assume reject |

---

## 4. _classified/ Output Structure

```
_classified/
  _summary.json
  {category}/
    _index.json
    {ID}.json
```

`_summary.json`: `{ lastIngestAt, filesProcessed, totalItems, byCategory: { [cat]: { total, extracted, validated, adopted, rejected } }, byStatus }`

---

## 5. Safety Rules

1. `_input/` READ-ONLY, 모든 항목에 source metadata 필수
2. 기존 ID 재사용 금지, 대용량 청크 분할 필수
3. `--incremental` 시 기존 보존+신규만 추가
4. confidence "low" → status "extracted" + 검증 필요 표시
5. 카테고리별 `_index.json` 갱신 필수, 가정은 `_assumptions/`에 기록
