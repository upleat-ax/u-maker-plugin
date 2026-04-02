# u-report REFERENCE

SKILL.md에서 참조하는 상세 구현 명세.

---

## Progress Summary 공통 블록

모든 phase별 리포트 상단에 포함되는 Progress Summary:

```
┌─────────────────────────────────────────────────────┐
│  ✅ Done (12)    │  ⏳ Remaining (5)   │  💡 Improve (3)  │
├─────────────────┼────────────────────┼─────────────────┤
│ FR-0001 Login   │ FR-0015 알림       │ FR-0003 결제     │
│ FR-0002 회원가입 │ FR-0016 통계       │   → API 응답 최적화│
│ ...              │ ...                │ ...              │
└─────────────────┴────────────────────┴─────────────────┘
```

| 섹션 | 아이콘 | 내용 | 소스 |
|------|--------|------|------|
| **Done** | ✅ | 완료된 항목 (status: Final, validated, passed) | `_index.json` status, test results |
| **Remaining** | ⏳ | 미완료 항목 (status: Draft, extracted, todo) | `_index.json`, `data/backlog/` |
| **Improve** | 💡 | 개선 필요 항목 (리뷰 코멘트, 실패 테스트, tech debt, assumptions) | test-report, spec-sync, `data/assumptions/`, `data/backlog/` |

각 항목: ID + Title + Status 배지. Improve인 경우 개선 사유 1줄 설명 (예: "→ API 응답 시간 2초 초과").

---

## ingest-report 섹션 명세

**입력:** `data/classified/_summary.json`, `data/classified/*/_index.json`

| 섹션 | 내용 |
|------|------|
| **Progress** | Done: validated 항목 / Remaining: extracted 항목 / Improve: rejected 사유 + 미분류(raw/) 파일 |
| Summary | 처리 파일 수, 총 항목 수, Status 분포 pie chart (SVG) |
| Screens | Design System 컴포넌트 테이블 + 화면 그룹별 목록 (소계) |
| Requirements | FR 테이블 (ID, Title, Priority, Status) + NR 테이블. Priority 분포 bar chart |
| Pain Points | severity별 분류 테이블 |
| Workflows | 워크플로우 목록 + 단계 수 |
| Domain Terms | 용어 사전 테이블 (term, definition, synonyms) |
| Stakeholders | 이해관계자 역할 매트릭스 |
| Constraints | 제약사항 목록 (type: tech/policy/legal) |
| Decisions | 결정사항 타임라인 |
| Questions | 미해결 질문 목록 (open/resolved) |

---

## plan-report 섹션 명세

**입력:** `01-plan/srs.md`, `01-plan/ia.md`, `01-plan/roadmap.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: Final 문서 / Remaining: Draft, 미작성 문서 / Improve: 누락 FR↔classified 매핑, 미해결 questions | - |
| SRS Overview | USR → FR → US → FT 계층 통계 | Use Case Diagram (SVG) |
| FR 목록 | 전체 FR 테이블 (ID, Title, Priority, US 수, FT 수) | Priority 분포 pie chart |
| US 목록 | 전체 US 테이블 (관련 FR, FT 수) | - |
| FT 목록 | 전체 FT 테이블 (관련 US, Screen, API) | - |
| IA | 화면 계층 구조 | 인라인 SVG Sitemap (페이지 카드 + 와이어프레임 썸네일) |
| Roadmap | 마일스톤 타임라인 | Gantt chart (SVG) |
| Coverage | classified → SRS 매핑률 | 매핑 매트릭스 heatmap |

---

## design-report 섹션 명세

**입력:** `02-design/*.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: Final 설계 문서 / Remaining: Draft, 미생성 RTM / Improve: ERD↔API 타입 불일치, Screen↔FT 미매핑, 고아 엔드포인트 | - |
| ERD | 엔티티 목록 + 컬럼 상세 | ER Diagram (SVG) |
| API | 엔드포인트 목록 (method, path, auth, related FT) | Sequence Diagram (주요 흐름, SVG) |
| Screens | 화면별 컴포넌트 구성, API 연결, 상태 | Component Diagram (SVG) |
| Screen Flow | 화면 간 내비게이션 경로 | Flowchart (SVG) |
| RTM | FR → US → FT → Screen → API → ERD 매핑 매트릭스 | Traceability heatmap |
| UX/Token | Design Token 목록 (있으면) | - |
| 정합성 | ERD↔API↔Screen 교차 검증 결과 | 누락 항목 경고 표시 |

---

## dev-report 섹션 명세

**입력:** `03-dev/code.md`, `03-dev/spec-sync-report.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: 생성 완료 + build pass 파일 / Remaining: 미생성 Screen/API 코드 / Improve: spec-sync 위반, build 에러, tech debt | - |
| Generated Files | FE/BE/DB 분류별 파일 목록 | Package Diagram (SVG) |
| Spec-Sync | 검증 결과 테이블 (Rule, Check, Severity, Status) | 커버리지 bar chart |
| Build Result | TypeScript/Lint/Build 통과 여부 | pass/fail 배지 |
| Tech Debt | 자동 등록된 기술 부채 목록 | - |
| FT → File | FT별 생성 파일 매핑 | - |

---

## qa-report 섹션 명세

**입력:** `04-check/test-cases.md`, `04-check/test-report.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| **Progress** | Done: passed TC / Remaining: 미작성 TC (FT 대비), skip된 TC / Improve: failed TC + 결함 + 커버리지 미달 FT | - |
| TC Overview | 총 TC 수, FT별 TC 수, 커버리지 | 커버리지 pie chart (SVG) |
| TC 목록 | 전체 TC 테이블 (ID, FT, Description, Type, Status) | - |
| Test Results | pass/fail/skip 분포 | bar chart (SVG) |
| Defects | 결함 목록 (severity: Critical/Major/Minor) | severity 분포 pie chart |
| FT Coverage | FT → TC 매핑률 (100% = 완전 커버) | heatmap |

---

## daily-report 상세 구현

**파일명:** `daily-report-{YYYY-MM-DD}.html`. 생성 시점 날짜 자동 포함. 같은 날짜 재생성 시 덮어쓴다.

**입력:** `01-plan/ia.md` + `.json`, `srs.md` + `.json`, `roadmap.md` + `.json`, `_index.json`, `data/classified/_summary.json`, `data/backlog/`, `02-design/screens.md` + `.json`, `03-dev/code.md` + `.json`, `04-check/test-cases.md` + `.json`

IA 화면 계층 기반 프로젝트 관리 뷰. 각 메뉴/화면이 PDCA 5단계를 거치는 과정을 추적한다.

> 상세 HTML 구조/스타일링: `skills/u-report/references/daily-report-template.md` 참조

### PDCA 5단계

| 단계 | 표시명 | Phase | 설명 | 커맨드 |
|------|--------|-------|------|--------|
| ① | 분류 | Ingest | 원시 자료 분석 → 화면 분류 완료 | `/u-ingest` |
| ② | 기획 | Plan | SRS FR→US→FT 매핑 + IA 정의 완료 | `/u-plan` |
| ③ | 설계 | Design | Screen 설계 + ERD/API 연결 완료 | `/u-design` |
| ④ | 개발 | Dev | FE 컴포넌트 + BE API 코드 생성 완료 | `/u-dev` |
| ⑤ | 검증 | QA | TC 생성 + 테스트 실행 통과 | `/u-qa` |

### Header 영역

```
┌──────────────────────────────────────────────────────────────────────┐
│  {ProjectName} IA 일정 조율                                          │
│  {year}년 {month}월 개발 마일스톤 - {start} ~ {end}                    │
│                                                                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐                                │
│  │  46  │ │  37  │ │  4   │ │  2   │                                │
│  │ 전체 │ │ 완료 │ │진행중│ │ D-day│                                │
│  └──────┘ └──────┘ └──────┘ └──────┘                                │
│                                                                      │
│  완료 37 ─ QA진행 2 ─ 개발중 4 ─ 설계중 1 ─ 기획중 1 ─ 대기 1        │
│  전체 진행률 ████████████████████░░░░ 85%                             │
└──────────────────────────────────────────────────────────────────────┘
```

| 요소 | 내용 | 소스 |
|------|------|------|
| 타이틀 | `{ProjectName} IA 일정 조율` | `u-maker.config.json` → `name` |
| 기간 | `{year}년 {month}월 개발 마일스톤 - {start} ~ {end}` | `roadmap.json` 현재 Iteration 또는 `--milestone` 플래그 |
| KPI 뱃지 4개 | **전체** (IA 화면 수) / **완료** (5단계 모두 완료) / **진행중** (1~4단계 진행) / **D-day** (마감 임박) | IA 화면 수 + 상태 집계 |
| 파이프라인 바 | `완료 {n}` → `QA진행 {n}` → `개발중 {n}` → `설계중 {n}` → `기획중 {n}` → `대기 {n}` | PDCA 5단계 기준 분류 |
| 전체 진행률 | 프로그레스 바 + 퍼센트 | (완료 수 / 전체 수) x 100 |

**파이프라인 상태 정의:**

| 상태 | 조건 | 뱃지 색상 |
|------|------|----------|
| 완료 | 5단계 모두 ✓ | `#22c55e` (green) |
| QA진행 | ④개발 완료, ⑤검증 진행중 | `#8b5cf6` (violet) |
| 개발중 | ③설계 완료, ④개발 진행중 | `#3b82f6` (blue) |
| 설계중 | ②기획 완료, ③설계 진행중 | `#f59e0b` (amber) |
| 기획중 | ①분류 완료, ②기획 진행중 | `#f97316` (orange) |
| 대기 | 시작하지 않은 항목 | `#64748b` (slate) |

### Main Table -- IA 진행 현황

IA L1(도메인) 그룹별로 L2/L3(메뉴) 항목을 나열. 각 항목의 PDCA 5단계 진행 상태 추적.

```
┌────┬──────────────────┬────────────┬────┬────┬────┬────┬────┬──────┬──────┬────┬──────────┬────────────────┐
│ #  │ 도메인           │ 메뉴       │ ①  │ ②  │ ③  │ ④  │ ⑤  │진행률│ 상태 │담당│완료(예정)│ 비고           │
│    │                  │            │분류│기획│설계│개발│검증│      │      │    │일        │                │
└────┴──────────────────┴────────────┴────┴────┴────┴────┴────┴──────┴──────┴────┴──────────┴────────────────┘
```

**테이블 열 상세:**

| 열 | 설명 | 소스 매핑 |
|----|------|----------|
| **#** | 순번 | 자동 생성 |
| **도메인** | IA L1 그룹명 + `(완료/전체)` 카운트 | `ia.json` → L1 screens. 노란 배경 시각 구분 |
| **메뉴** | IA L2/L3 화면명 | `ia.json` → L2/L3 screens |
| **① 분류** | 해당 화면 분류 완료 여부 | `data/classified/screens/` 존재 + `_index.json` status |
| **② 기획** | SRS에 해당 화면의 FT 매핑 존재 여부 | `srs.json` → features[].screen |
| **③ 설계** | Screen 설계 + ERD/API 연결 완료 여부 | `screens.json` → 해당 화면 정의 |
| **④ 개발** | 코드 생성 완료 여부 | `code.json` → generatedFiles[] |
| **⑤ 검증** | TC 생성 + 테스트 통과 여부 | `test-cases.json` + `test-report.json` |
| **진행률** | 완료 단계 수 / 5 (%) | 5단계 중 ✓ 수 x 20% |
| **상태** | 파이프라인 상태 배지 | 최신 완료 단계 기준 |
| **담당** | 담당자명 | `data/backlog/` → assignee |
| **완료(예정)일** | 완료일 또는 예정일 | `data/backlog/` → dueDate, completedDate |
| **비고** | 특이사항, 지연 사유 | `data/backlog/` → notes, `_index.json` → impact flags |

**5단계 셀 표시 규칙:**

| 표시 | 의미 | 셀 스타일 |
|------|------|----------|
| ✓ (체크마크) | 완료 | 배경 `#1e293b`, 체크 아이콘 white |
| 파란 블록 | 진행 중 | 배경 `#3b82f6` |
| 빨간 블록 | 이슈/블로커 | 배경 `#ef4444` |
| 빈칸 | 미도달 | 배경 `#334155` |
| -- (대시) | 미해당/스킵 | 배경 transparent |

**도메인 그룹 행:** L1 도메인명 + `(완료수/전체수)`, 도메인별 진행률 퍼센트 바, 배경 `#fbbf24` (amber-400).

### Bottom -- 기술 혁신 로드맵

Roadmap에서 기술 혁신/개선 항목을 별도 섹션으로 표시.

```
┌──────────────────────────────────────────────────────────────────────┐
│  2026 기술 혁신 로드맵   IN PROGRESS    도메인 메뉴수: 완료 0 · 진행 1│
│                                                                      │
│  ⚠ 체크리스트 반복 점검 — 핵심 개선 과제                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │    384       │  │    163       │  │     0        │                  │
│  │ 위험요인 항목│  │ 필터 적용    │  │ 반복에서     │                  │
│  │(1차 검토 표시)│ │해제 누적 항목│  │ 가능         │                  │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
└──────────────────────────────────────────────────────────────────────┘
```

**로드맵 테이블 열:** #, 메뉴, 제목, 긴급, 시기, 시작일, 상태, 비고. 소스: `roadmap.json`.

**체크리스트 반복 점검 블록:** 핵심 개선 과제 KPI 카드 3개. 소스: `data/classified/` 항목 수 또는 `roadmap.json` → metrics.

### 데이터 매핑 -- PDCA 5단계 완료 판정 로직

```
Stage 1 (분류 — Ingest):
  data/classified/screens/_index.json에서 해당 화면 ID 존재
  AND status ∈ {validated, extracted}
  → ✓

Stage 2 (기획 — Plan):
  srs.json → features[] 중
  screen 필드가 해당 화면 ID를 참조하는 FT 1개 이상 존재
  AND 해당 FT의 status ≠ "draft"
  → ✓

Stage 3 (설계 — Design):
  screens.json → screens[] 중
  해당 화면 ID의 layout/component 정의 존재
  AND status ∈ {Draft, Review, Final}
  AND (해당 화면 관련 API endpoint가 api.json에 정의됨 OR API 불필요 화면)
  → ✓

Stage 4 (개발 — Dev):
  code.json → generatedFiles[] 중
  해당 화면 관련 FE 컴포넌트 파일 존재
  AND buildStatus ≠ "error"
  → ✓

Stage 5 (검증 — QA):
  test-cases.json → testCases[] 중
  해당 화면 관련 FT에 대한 TC 존재
  AND test-report.json → 해당 TC의 result = "passed"
  → ✓
```

**예외 처리:**
- IA에 화면이 있지만 `data/classified/`에 없는 경우: 분류 미완료 (빈칸)
- SRS에 FT가 없는 화면: 기획 미완료 (빈칸)
- 전체 5단계 중 해당 없는 단계는 `—` 표시 (예: 정적 페이지는 QA 불필요)
- `data/backlog/`에 해당 화면 관련 항목이 있으면 담당/일정/비고를 backlog에서 가져옴

---

## Dashboard 구현 가이드

**구조:**

```
┌──────────────────────────────────────────────────────────┐
│  {ProjectName} — {scope} Report                          │
│  Generated: {date} | Phase: {current} | v{version}       │
├──────────────┬───────────────────────────────────────────┤
│  Sidebar     │  Main Content                             │
│              │                                           │
│  ─ Dashboard │  ┌─────────────────────────────────┐     │
│              │  │  Phase: Plan ███░░ Design ██░░░  │     │
│  01 Plan     │  │  Docs: 12  Screens: 57  TC: 24  │     │
│    SRS       │  │  FR: 25  US: 40  FT: 80         │     │
│    IA        │  └─────────────────────────────────┘     │
│    Roadmap   │                                           │
│              │  Phase별 요약 카드                          │
│  02 Design   │  ┌──────┐ ┌──────┐ ┌──────┐             │
│    ERD       │  │Ingest│ │ Plan │ │Design│ ...          │
│    API       │  │42항목 │ │12문서│ │5문서 │              │
│    Screens   │  └──────┘ └──────┘ └──────┘             │
│    RTM       │                                           │
│              │  Quick Stats                              │
│  03 Dev      │  - Requirements: 25 FR + 5 NR            │
│    Code      │  - Screens: 57 (12 groups)               │
│    Spec-Sync │  - API: 32 endpoints                     │
│              │  - ERD: 15 entities                       │
│  04 Check    │  - Tests: 20/24 passed                   │
│    TestCases │                                           │
│    TestReport│  Assumptions: 16건 (미리뷰)               │
│              │  Backlog: 8건                              │
│  Wireframes  │                                           │
│    SCR-001   │                                           │
│    SCR-002   │                                           │
└──────────────┴───────────────────────────────────────────┘
```

**Sidebar 구성:**

1. **Dashboard** -- 전체 요약 (기본 선택)
2. **Phase별 문서** -- `_index.json` 기반, 문서 클릭 시 `.md` → HTML 렌더링
3. **Wireframes** -- IA 그룹별 화면 목록, 클릭 시 와이어프레임 로드
4. 각 항목에 Status 배지 (Draft/Review/Final)
5. 검색 필터 (문서명/ID 키워드)
6. Phase별 리포트 링크 (→ `plan-report.html` 등)

**Main Content -- Dashboard:**

1. **전체 Progress Summary** (최상단):
   ```
   ✅ Done: 45건  |  ⏳ Remaining: 12건  |  💡 Improve: 8건
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 69% Complete
   ```
   - Done: 전체 Phase에서 Final/passed/validated 항목 합계
   - Remaining: Draft/extracted/todo/미생성 항목 합계
   - Improve: failed TC, spec-sync 위반, tech debt, 미리뷰 assumptions 합계
   - Progress bar (전체 완료율)

2. **Phase별 요약 카드** (클릭 → 상세 리포트)
3. **Remaining Items** 테이블: 미완료 항목 전체 목록 (Phase, ID, Title, Status, 담당)
4. **Improve Items** 테이블: 개선 필요 항목 전체 목록 (Phase, ID, 사유, Severity, 제안 액션)
5. **Assumptions** 미리뷰 목록 (ID, 내용, confidence)
6. **Backlog** 요약 (todo/in-progress/done 분포)
7. **Next Steps** 체크리스트:
   - [ ] Remaining {n}건 완료
   - [ ] Improve {n}건 수정
   - [ ] Assumptions {n}건 리뷰 (`/u-assume`)
   - [ ] 결과 확인 후 배포 (`/u-ship`)

**Main Content -- 문서/와이어프레임:**
- 문서 선택 시: `.md` → HTML 렌더링 (Mermaid → 인라인 SVG)
- 와이어프레임 선택 시: `.html` 직접 렌더링 / `.md` → HTML 변환

---

## Common Style 명세

| 요소 | 사양 |
|------|------|
| Sidebar 배경 | `#1e293b` (dark slate) |
| Sidebar 텍스트 | `#e2e8f0` (light gray) |
| Sidebar 너비 | `280px` (고정) |
| Main Content 배경 | `#f1f5f9` (light blue-gray) |
| Status 배지 | Draft(`#64748b`), Review(`#f59e0b`), Final(`#22c55e`) |
| 테이블 | zebra striping, border-collapse |
| 코드 블록 | `#1e293b` 배경, monospace |
| 다이어그램 | SVG 인라인, 클릭 zoom |
| 반응형 | 768px 미만에서 sidebar 접기 + 햄버거 메뉴 |
| 인쇄 | `@media print` 지원 (sidebar 숨김, 전체 너비) |
| Footer | `{license.type} · © {license.owner}` (`u-maker.config.json` → `license`) |

---

## /u-loop 연동 상세

`/u-loop` 실행 시 각 단계 완료 후 해당 리포트를 자동 생성:

```
[ingest 완료] → /u-report {scope} --only ingest
[plan 완료]   → /u-report {scope} --only plan
[design 완료] → /u-report {scope} --only design
[dev 완료]    → /u-report {scope} --only dev
[qa 완료]     → /u-report {scope} --only qa
[루프 종료]   → /u-report {scope} --only daily
[루프 종료]   → /u-report {scope} --only dashboard
```

루프용 리포트는 `.u-maker/out/reports/loop-{loopId}/{date}/`에 저장. 루프 메타데이터(소요 시간, 에러, 가정)가 추가 포함. `latest` 심볼릭 링크도 동일 생성.

---

## Notify Completion 출력 형식

```
## u-report Complete

**Scope:** {scope}
**Date:** {YYYY-MM-DD}
**Reports:** {n} HTML files generated
**Location:** .u-maker/out/reports/{scope}/{date}/

### Generated Files
| File | Size | Sections |
|------|------|----------|
| index.html | 45KB | Dashboard + 12 docs + 57 wireframes |
| ingest-report.html | 28KB | 10 categories, 156 items |
| plan-report.html | 35KB | SRS + IA + Roadmap |
| design-report.html | 52KB | ERD + API + Screen + RTM |
| dev-report.html | 22KB | Code + Spec-Sync |
| qa-report.html | 18KB | 24 TC, 20 passed |
| daily-report-{date}.html | 40KB | IA 일정 조율 + 로드맵 |

Open in browser:
  open .u-maker/out/reports/{scope}/latest/index.html
```
