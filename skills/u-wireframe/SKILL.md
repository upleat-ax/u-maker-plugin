---
name: u-wireframe
description: "This skill should be used when the user asks to 'generate wireframes', 'create wireframe', '/u-wireframe', or wants to produce per-screen HTML wireframe files from Screen Specification documents."
version: 3.2.0
triggers:
  - "/u-wireframe"
  - "wireframe"
  - "generate wireframe"
  - "screen wireframe"
---

# u-wireframe — Screen Wireframe Generator

`/u-wireframe [--app {name}] [--screen {SCR-ID}] [--all]`

Generate individual HTML wireframe files for each screen defined in `docs/{app}/design/screens.md` + `screens.json`. Each wireframe is a self-contained HTML page with mockup UI, Design/Develop annotations, related ERD entities, Sequence Diagram, and Screen Flow.

**Engine Dependencies:** doc-engine, html-engine, dep-engine
**Gate Prerequisite:** Design phase documents exist (screens.json, erd.json, api.json)

## Input Sources

| Source | Path | Purpose |
|--------|------|---------|
| Screen Spec | `docs/{app}/design/screens.md` + `screens.json` | Screen inventory, components, API calls, state, validation |
| ERD | `docs/{app}/design/erd.md` + `erd.json` | Data model entities related to each screen |
| API Contract | `docs/{app}/design/api.md` + `api.json` | API endpoints for sequence diagrams |
| Screen Flow | `docs/{app}/design/screen-flow.md` + `screen-flow.json` | Navigation flow between screens |
| Design System | `docs/{app}/design/design-system.md` + `design-system.json` | Design tokens, UI component specs |
| IA | `docs/{app}/plan/ia.md` + `ia.json` | Page hierarchy for sidebar navigation |

## Output Structure

```
output/{app}/design/wireframes/
  index.html              # Wireframe browser (sidebar + iframe viewer)
  {SCR-ID}.html           # Per-screen wireframe page (e.g., SCR-APP-001.html)
```

## Execution Flow

### Step 0: Verify Design Documents

1. Read `docs/{app}/design/screens.json` — MUST exist
2. Read `docs/{app}/design/erd.json` — for entity mapping
3. Read `docs/{app}/design/api.json` — for sequence diagrams
4. Read `docs/{app}/design/screen-flow.json` — for flow navigation
5. Read `docs/{app}/design/design-system.json` — for tokens/components
6. If screens.json missing -> error: "Run /u-design first"

### Step 1: Build Screen-to-Data Map

For each screen in `screens.json`:

1. **Components**: Extract component list with types, props, interactions
2. **API Calls**: Map API endpoint IDs to `api.json` definitions -> build sequence diagram data
3. **ERD Entities**: Trace API response types -> find matching entities in `erd.json`
4. **Screen Flow**: Find inbound/outbound navigation edges from `screen-flow.json`
5. **Design Tokens**: Map component types to design-system tokens

### Step 2: Generate Per-Screen HTML

For each screen, generate `{SCR-ID}.html` using `references/wireframe-page.template.html`.

**Page Structure — 5 Sections (top→bottom):**

| Section | Description |
|---------|-------------|
| **A. Document Header** | Sticky top bar: SCR-ID badge, screen name, route path, related FT/FR links, 전체 목록 link |
| **B. Stage** | 2-column grid: App Frame (sidebar + main mockup) + Annotation Panel (상세 기획 명세) |
| **C. Component Spec** | Component specification table (#, 컴포넌트, 타입, Props, API) |
| **D. Logic Flow Diagrams** | inline SVG diagrams: **Business Process Flow** (full-width) + Sequence Diagram + Screen Flow |
| **E. Overlay UI** | Alert, Confirm, Modal, BottomSheet, Popup, Drawer, Toast — 각각 렌더링된 미리보기 카드 + 상세 기획 설명 |

#### B. Stage — App Frame + Annotation Panel

**App Frame** (left, `grid-template-columns: 1fr 300px`):
- **Sidebar** (196px, dark): App name/description + IA navigation menu. Current screen = `.active`
- **Main Area**: Page header (breadcrumb + title with back button) + Page body (components rendered as HTML mockup with annotation markers `<span class="mk">N</span>`) + Footer action bar (submit/cancel buttons)

**Annotation Panel** (right, 300px):
- Numbered annotation items matching mockup markers
- Each item: marker number + **영역명** (bold title) + **상세 기획 설명**
- **기획 명세 수준의 상세 내용 필수** — 단순 컴포넌트 타입 나열 금지

**Annotation 작성 규칙 (CRITICAL):**

각 annotation은 해당 영역의 **기획서 역할**을 해야 한다. 아래 항목을 해당되는 만큼 포함:

1. **컴포넌트 동작 설명**: 버튼 클릭 시 동작, 입력 필드 용도, 리스트 표시 내용
2. **입력/수정 가능 여부**: "수정 가능", "수정 불가(읽기 전용)", "조건부 수정" 명시
3. **필드별 상세**: 각 입력 필드의 데이터 타입, 선택지, 기본값, 필수 여부
4. **비즈니스 규칙/조건**: 활성화 조건, 유효성 검증, 계산 로직 (예: "TM 수당 = 총지급수당 - 모집인 수당, 자동 계산")
5. **관련 화면 연동**: 다른 화면에서 데이터를 가져오거나 다른 화면으로 이동하는 경우
6. **자동 생성/계산 항목**: 코드 자동 발급, 금액 자동 계산, 테이블 자동 생성 등
7. **알럿/확인**: 저장 시 확인 알럿, 금액 불일치 경고, 필수값 누락 안내 등

**BAD example (금지):**
```
Form.Horizontal — onFilter -> query state 갱신 후 재조회
```

**GOOD example:**
```
기능 권한 버튼
  목록 버튼: 목록으로 이동
  상품복제하기 버튼:
    • 현재 상품 정보로 신규상품 생성, 상품코드 신규발급(저장 시)
  저장 버튼: 수정 내용 저장
    • 저장 시 확인 알럿
```

- Business rules section at bottom: `BR-{SCR-ID}-NN` items

#### B. Wireframe Mockup Rendering Rules

Components are rendered as styled HTML elements (not SVG, not images) using the template's built-in CSS classes:

| Component Type | CSS Class / Rendering |
|---------------|-----------|
| **Table** | `.wf-table` with thead/tbody, sample rows, `.wf-badge-*` status badges |
| **Form** | `.wf-input`, `.wf-label`, `.wf-select` fields with sample values |
| **Button** | `.btn.primary`, `.btn.secondary`, `.btn.danger`, `.btn.outline` |
| **Card** | `.card` with `.card-title` + content |
| **Tabs** | `.wf-tabs` + `.wf-tab.active` |
| **Photo Grid** | `.photo-grid` + `.photo-thumb` + `.photo-add` (dashed border) |
| **Signature** | `.sign-canvas` + `.sign-reset` |
| **Info Grid** | `.info-grid` + `.info-row` (label/value pairs) |
| **Sidebar Nav** | `.sb-list` + `.sbi` items (`.sbi.active`, `.sbi.sub`) |
| **Badge** | `.wf-badge-blue`, `.wf-badge-green`, `.wf-badge-red`, `.wf-badge-amber`, `.wf-badge-gray` |
| **Stats Card** | `.wf-stat` with `.wf-stat-value` + `.wf-stat-label` |

All annotation markers use `<span class="mk">N</span>` (blue circle with number).

#### B-3. 기획 상세도 규칙 (CRITICAL)

와이어프레임은 **기획서 역할**을 해야 한다. 개발자가 이 문서만 보고 구현할 수 있을 정도의 상세도가 필요하다.

**금지사항:**
- `샘플 데이터 A/B/C`, `항목`, `담당자` 같은 **generic placeholder 금지**
- `후속 액션 또는 등록 화면 이동` 같은 **모호한 설명 금지**
- 실제 도메인과 무관한 컬럼명, 상태값 사용 금지

**필수사항:**
1. **테이블 컬럼**: `screens.json`의 실제 필드명 사용 (예: 계약번호, 고객명, 상품명, 납입상태, 배정일자)
2. **필터/검색**: 실제 검색 조건 반영 (예: 배정유형, 배정상태, 담당지사, 배정기간)
3. **상태 배지**: 실제 비즈니스 상태값 사용 (예: 배정대기, 배정완료, 반려, 회수)
4. **통계 카드**: 실제 집계 항목 반영 (예: 금일배정, 미처리, 배정완료, 반려)
5. **버튼/액션**: 실제 기능명 사용 (예: 일괄배정, 배정취소, 담당자변경, 엑셀다운로드)
6. **폼 필드**: 실제 입력 항목과 타입 반영 (예: 배정일자=date, 담당지사=select, 비고=textarea)

**테이블 샘플 데이터**: 3~5행의 현실적인 샘플 데이터를 도메인에 맞게 생성 (실제 이름, 날짜, 금액 등)

#### D. Logic Flow Diagrams

Diagrams are rendered as **inline SVG** (`<svg class="diag">`) in a grid (`.diag-grid`).

Each diagram block (`.diag-block`) has:
- `<h3>` title (uppercase, cyan accent)
- `<svg class="diag" viewBox="...">` with inline SVG content

**Diagram types per screen** (generate what's relevant):

| Diagram | Purpose | When to include | Layout |
|---------|---------|-----------------|--------|
| **Business Process Flow (업무 프로세스 흐름도)** | 화면의 전체 업무 프로세스를 단계별로 시각화 | **모든 화면 (필수)** | `.full` (전체 너비) |
| **Sequence Diagram** | API call sequence (Actor → Frontend → Backend → DB) | Screens with API calls | `.full` |
| **Screen Flow** | Navigation inbound/outbound with trigger labels | All screens (from screen-flow.json) | 1-column |

**~~Data Flow~~ — 삭제됨. 생성하지 않는다.**

##### Business Process Flow 작성 규칙 (CRITICAL)

업무 프로세스 흐름도는 해당 화면에서 사용자가 수행하는 **전체 업무 흐름**을 좌→우 방향으로 표현한다.

**SVG 구성 요소:**

| 요소 | 도형 | 색상 | 용도 |
|------|------|------|------|
| **시작/종료** | 둥근 사각형 (rx=20) | `#1e293b` fill, white text | 업무 시작점/종료점 |
| **프로세스 단계** | 사각형 (rx=4) | `#fff` fill, `#334155` border | 각 업무 단계 (기본정보 입력, 계약유형 선택 등) |
| **단계 상세** | 사각형 (rx=4, 아래 배치) | `#f8fafc` fill, `#e2e8f0` border | 해당 단계에서 입력/선택하는 필드 목록 (bullet list) |
| **DB/테이블** | 실린더 (cylinder path) | `#e0f2fe` fill, `#0284c7` border | 관련 DB 테이블 (품목 DB, 약관 테이블 등) |
| **관련 화면** | 사각형 (rx=4) | `#fff` fill, `#94a3b8` border | 다른 화면으로의 이동/참조 (품목 관리, 스펙유형 관리 등) |
| **분기** | 마름모 (diamond) | `var(--svg-condition)` | Y/N 분기 판단 |
| **화살표** | 직선/곡선 + marker | `var(--svg-arrow)` | 단계 간 흐름 방향 |

**레이아웃 규칙:**
1. **좌→우 흐름**: 시작(좌) → 중간 단계들 → 종료(우)
2. **상단 흐름선**: 주요 프로세스 단계는 상단 가로줄에 배치
3. **하단 상세**: 각 단계 아래에 입력 필드 목록, DB, 관련화면을 세로로 배치
4. **연결선**: 프로세스 단계 간 → 화살표, DB/화면 연결은 점선
5. **viewBox**: 내용에 맞게 충분히 넓게 설정 (최소 1200px 너비)

**예시 구조 (상조 상품 등록 화면):**
```
[신규 등록 시작] → [기본정보 입력] → [스펙유형 선택] → [계약유형 선택] → [계약내용 입력] → [약관 및 상품설명] → [저장]
                      ↓                    ↓                                    ↓                    ↓
                  상품명 입력           스펙유형 선택                         입력/선택:            상품 약관/증서 선택
                  판매기간 입력         품목 판매가 설정                       계약 구분             상품 실명 입력
                  상품 이미지           대체/업그레이드                        거래 형태                  ↓
                  상위 노출 선택        /페이백 설정                          납입 방식           [상품코드 생성] ←◇ N
                  노출 채널                  ↓                               만기환급비율               ↓ Y
                  검색 조건            스펙유형 품목 테이블                     ...               [등록일, 등록자 생성]
                                           ↓                                  ↓                       ↓
                                      품목 관리 화면                      자동 계산:            [상품등록 완료]
                                           ↓                             납부면제금액
                                        품목 DB                          부금총액
                                                                         월납입액
```

SVG style tokens (use CSS variables from template):
- Node: `var(--svg-node)` (#3b82f6) + `var(--svg-node-text)` (#fff)
- Condition diamond: `var(--svg-condition)` (#f59e0b)
- Action/success: `var(--svg-action)` (#10b981)
- Arrows: `var(--svg-arrow)` (#6b7280)
- Actor: `var(--svg-actor)` (#8b5cf6)
- Background: `var(--svg-bg)` (#f8fafc)

Use `.diag-block.full` (spans 2 columns) for wide diagrams (Business Process Flow, Sequence Diagram).

#### E. Overlay UI — Modals / BottomSheets / Popups

**All overlay components (modals, bottomsheets, popups, drawers, toasts) used by the screen MUST be rendered at the bottom** in a 2-column grid (`.overlay-grid`).

Each overlay is an `.overlay-card` containing:
- **Header**: Type badge (`.overlay-type-badge`) + overlay name + annotation marker
- **Body**: Rendered component mockup (same HTML rendering rules as main wireframe body)

Overlay types and badge colors:

| Type | Badge Style | Example |
|------|------------|---------|
| `modal` | Blue | Confirm dialog, form modal, detail modal |
| `bottomsheet` | Amber | Mobile action sheet, filter panel |
| `popup` | Purple | Tooltip, popover, context menu |
| `drawer` | Green | Side panel, filter drawer |
| `toast` | Red | Success/error notification |

Extract overlays from `screens.json` component list — components with type containing `Modal`, `BottomSheet`, `Popup`, `Drawer`, `Toast`, or `Dialog`.

If the screen has **no overlay components**, omit section E entirely.

### Step 3: Generate Index HTML (Browser)

Generate `index.html` as a sidebar browser using the dark-theme template.

See `references/wireframe-index.template.html` for the full template.

**Key structure:**
- Dark sidebar (260px) with search, tree navigation grouped by IA category
- iframe viewer (flex:1) loading individual wireframe pages
- Mobile-responsive hamburger menu
- Footer with screen count and generation date

**FILES array generation:**
```javascript
// Auto-generated from screens.json
const FILES = [
  {"path":"{SCR-ID}.html","name":"{SCR-ID}: {screenName}","icon":"...","dir":"wireframes","section":"Wireframes","group":"{category}"}
];
```

### Step 4: Update Parent Navigation

1. Add wireframes link to `output/{app}/index.html` sidebar under Design section
2. Add link: `<a href="design/wireframes/index.html">Wireframes</a>`

## Checklist

- [ ] All screens from screens.json have individual HTML files
- [ ] Each wireframe has: mockup + Business Process Flow + Sequence Diagram + Screen Flow + ERD
- [ ] Annotations contain 기획 명세 수준의 상세 설명 (generic placeholder 없음)
- [ ] Business Process Flow: 단계별 업무 흐름 + DB + 관련화면 + 분기 포함
- [ ] Index browser has correct FILES array with all screens
- [ ] Sidebar groups match IA categories
- [ ] Dark/light toggle works on all pages
- [ ] Navigation links (Index, FT, FR) are correct
- [ ] ERD constraints: PK/FK/UK never combined
- [ ] Data Flow 다이어그램 없음 (삭제됨)
- [ ] Annotation Legend 섹션 없음 (삭제됨)
- [ ] 테이블 샘플 데이터가 도메인에 맞는 현실적 데이터임
- [ ] Footer: Copyright(c) 2026 U PLEAT
- [ ] Self-contained HTML (Tailwind CDN, Mermaid CDN, no external deps)

## Reference Files

- **`references/wireframe-page.template.html`** — Single screen wireframe page template
- **`references/wireframe-index.template.html`** — Browser index page template (sidebar + iframe)
