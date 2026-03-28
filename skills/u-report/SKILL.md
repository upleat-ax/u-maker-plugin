---
name: u-report
description: "SSoT 문서를 HTML 리포트로 변환. sidebar navigation + UML 다이어그램 SVG + 통계 차트를 포함한 브라우저 열람용 리포트를 생성한다. /u-loop 완료 시 자동 호출된다."
triggers:
  - "/u-report"
  - "report"
  - "리포트"
  - "HTML 생성"
  - "리포트 생성"
  - "html report"
---

# u-report -- SSoT to HTML Report Generator

`/u-report [scope] [--only X]` 명령으로 SSoT 문서(.md + .json)를 브라우저에서 열람할 수 있는 HTML 리포트로 변환한다.

**Primary Agent:** u-agent-orchestrator (engine-doc 사용)

> **역할 분담:** `.md` + `.json`은 작업 중 항상 생성되는 SSoT 원본이고, `.html`은 리뷰/공유용 시각화 산출물이다. `/u-report`는 후자만 담당한다.

---

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--only X` | - | 특정 리포트만 생성 (ingest, plan, design, dev, qa, dashboard) |
| `--open` | - | 생성 후 브라우저에서 자동 열기 |
| `--clean` | - | 기존 `_reports/` 삭제 후 재생성 |

---

## Output Structure

```
.u-maker/_reports/{scope}/
├── index.html                  # 대시보드 (전체 문서 인덱스 + 통계)
├── ingest-report.html          # classified 항목 요약
├── plan-report.html            # SRS + IA + Roadmap
├── design-report.html          # ERD + API + Screen + ScreenFlow + RTM
├── dev-report.html             # Code + Spec-Sync + Build 결과
├── qa-report.html              # TestCase + TestReport + 커버리지
└── wireframes/                 # 와이어프레임 뷰어 (기존 index.html)
```

---

## Execution Flow

### Step 1: Resolve Scope & Scan Documents

1. `u-maker.config.json` → scope 해석
2. `_index.json` → 문서 목록 + 상태 로드
3. `_classified/_summary.json` → 분류 통계 로드
4. `--only` 플래그 → 대상 리포트 결정. 생략 시 전체 생성
5. `_reports/{scope}/` 디렉토리 생성 (없으면)

### Step 2: Generate Per-Phase Reports

각 Phase별 `.md` + `.json`을 읽어 HTML로 변환한다.

#### 2-1. ingest-report.html

**입력:** `_classified/_summary.json`, `_classified/*/​_index.json`

| 섹션 | 내용 |
|------|------|
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

#### 2-2. plan-report.html

**입력:** `01-plan/srs.md`, `01-plan/ia.md`, `01-plan/roadmap.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| SRS Overview | USR → FR → US → FT 계층 통계 | Use Case Diagram (SVG) |
| FR 목록 | 전체 FR 테이블 (ID, Title, Priority, US 수, FT 수) | Priority 분포 pie chart |
| US 목록 | 전체 US 테이블 (관련 FR, FT 수) | - |
| FT 목록 | 전체 FT 테이블 (관련 US, Screen, API) | - |
| IA | 화면 계층 구조 | Mindmap/Tree (SVG) |
| Roadmap | 마일스톤 타임라인 | Gantt chart (SVG) |
| Coverage | classified → SRS 매핑률 | 매핑 매트릭스 heatmap |

#### 2-3. design-report.html

**입력:** `02-design/*.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| ERD | 엔티티 목록 + 컬럼 상세 | ER Diagram (SVG) |
| API | 엔드포인트 목록 (method, path, auth, related FT) | Sequence Diagram (주요 흐름, SVG) |
| Screens | 화면별 컴포넌트 구성, API 연결, 상태 | Component Diagram (SVG) |
| Screen Flow | 화면 간 내비게이션 경로 | Flowchart (SVG) |
| RTM | FR → US → FT → Screen → API → ERD 매핑 매트릭스 | Traceability heatmap |
| UX/Token | Design Token 목록 (있으면) | - |
| 정합성 | ERD↔API↔Screen 교차 검증 결과 | 누락 항목 경고 표시 |

#### 2-4. dev-report.html

**입력:** `03-dev/code.md`, `03-dev/spec-sync-report.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| Generated Files | FE/BE/DB 분류별 파일 목록 | Package Diagram (SVG) |
| Spec-Sync | 검증 결과 테이블 (Rule, Check, Severity, Status) | 커버리지 bar chart |
| Build Result | TypeScript/Lint/Build 통과 여부 | pass/fail 배지 |
| Tech Debt | 자동 등록된 기술 부채 목록 | - |
| FT → File | FT별 생성 파일 매핑 | - |

#### 2-5. qa-report.html

**입력:** `04-check/test-cases.md`, `04-check/test-report.md` + `.json`

| 섹션 | 내용 | 다이어그램 |
|------|------|-----------|
| TC Overview | 총 TC 수, FT별 TC 수, 커버리지 | 커버리지 pie chart (SVG) |
| TC 목록 | 전체 TC 테이블 (ID, FT, Description, Type, Status) | - |
| Test Results | pass/fail/skip 분포 | bar chart (SVG) |
| Defects | 결함 목록 (severity: Critical/Major/Minor) | severity 분포 pie chart |
| FT Coverage | FT → TC 매핑률 (100% = 완전 커버) | heatmap |

### Step 3: Generate Dashboard (index.html)

전체 리포트를 묶는 대시보드.

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
│    ...       │                                           │
│              │                                           │
└──────────────┴───────────────────────────────────────────┘
```

**Sidebar 구성:**

1. **Dashboard** — 전체 요약 (기본 선택)
2. **Phase별 문서** — `_index.json` 기반, 문서 클릭 시 `.md` → HTML 렌더링
3. **Wireframes** — IA 그룹별 화면 목록, 클릭 시 와이어프레임 로드
4. 각 항목에 Status 배지 (Draft/Review/Final)
5. 검색 필터 (문서명/ID 키워드)
6. Phase별 리포트 링크 (→ `plan-report.html` 등)

**Main Content:**
- Dashboard 선택 시: 통계 카드 + Phase별 요약
- 문서 선택 시: `.md` → HTML 렌더링 (Mermaid → 인라인 SVG)
- 와이어프레임 선택 시: `.html` 직접 렌더링 / `.md` → HTML 변환

### Step 4: Render Diagrams to SVG

모든 HTML 리포트에서 Mermaid 코드 블록을 인라인 SVG로 변환한다.

```
function renderMermaidToSVG(htmlContent):
  // 1. ```mermaid 블록 감지
  // 2. Mermaid.js로 SVG 문자열 생성
  // 3. <div class="diagram"> 안에 SVG 인라인 삽입
  // 4. viewBox 설정 → 반응형 스케일링
  // 5. 클릭 시 확대 모달 (zoom)
  return htmlWithSVG
```

지원 다이어그램:
- `erDiagram` → ERD
- `sequenceDiagram` → API 흐름
- `flowchart` / `graph` → Screen Flow, 워크플로우
- `classDiagram` → 코드 구조
- `stateDiagram` → 상태 전이
- `mindmap` → IA 계층
- `pie` → 통계 분포
- `gantt` → Roadmap 타임라인

### Step 5: Apply Common Style

모든 리포트에 공통 스타일을 적용한다.

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

### Step 6: Notify Completion

```
## u-report Complete

**Scope:** {scope}
**Reports:** {n} HTML files generated
**Location:** .u-maker/_reports/{scope}/

### Generated Files
| File | Size | Sections |
|------|------|----------|
| index.html | 45KB | Dashboard + 12 docs + 57 wireframes |
| ingest-report.html | 28KB | 10 categories, 156 items |
| plan-report.html | 35KB | SRS + IA + Roadmap |
| design-report.html | 52KB | ERD + API + Screen + RTM |
| dev-report.html | 22KB | Code + Spec-Sync |
| qa-report.html | 18KB | 24 TC, 20 passed |

Open in browser:
  open .u-maker/_reports/{scope}/index.html
```

---

## --only Flag

| Value | 생성 파일 |
|-------|----------|
| `--only ingest` | `ingest-report.html` |
| `--only plan` | `plan-report.html` |
| `--only design` | `design-report.html` |
| `--only dev` | `dev-report.html` |
| `--only qa` | `qa-report.html` |
| `--only dashboard` | `index.html` (대시보드만) |
| (생략) | 전체 생성 |

---

## /u-loop 연동

`/u-loop` 실행 시 각 단계 완료 후 해당 리포트를 자동 생성한다:

```
[ingest 완료] → /u-report {scope} --only ingest
[plan 완료]   → /u-report {scope} --only plan
[design 완료] → /u-report {scope} --only design
[dev 완료]    → /u-report {scope} --only dev
[qa 완료]     → /u-report {scope} --only qa
[루프 종료]   → /u-report {scope} --only dashboard
```

루프용 리포트는 `.u-maker/_reports/loop-{loopId}/`에 저장되며, 루프 메타데이터(소요 시간, 에러, 가정)가 추가로 포함된다.

---

## Safety Rules

1. **소스 문서 무수정:** `.md` / `.json` 파일은 읽기만 수행 (READ-ONLY)
2. **`_reports/` 디렉토리만 쓰기:** HTML 파일은 `_reports/` 하위에만 생성
3. **인라인 리소스:** 외부 의존성 없는 단일 HTML (Mermaid.js CDN만 예외)
4. **민감 정보 제외:** `.env` 값, 하드코딩 시크릿은 리포트에 포함하지 않음
5. **기존 리포트 덮어쓰기:** 같은 scope의 기존 리포트는 경고 없이 덮어쓰기 (스냅샷 개념)
6. **SVG 인라인 필수:** 다이어그램은 외부 이미지 파일이 아닌 인라인 SVG로 렌더링
7. **`language.documents` 반영:** 리포트 본문 언어는 config 설정을 따름
