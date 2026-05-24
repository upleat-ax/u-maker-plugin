---
name: u-wireframe
description: "This skill should be used when the user asks to '/u-wireframe', 'wireframe', 'generate wireframe', 'screen wireframe', 'u-maker 와이어프레임', '화면 와이어프레임', or '와이어프레임 생성'. Produces per-screen HTML wireframe files from Screen Specification documents."
version: 4.0.0
---

# u-wireframe — Screen Wireframe Generator

`/u-wireframe [--app {name}] [--loop] [--screen {SCR-ID}] [--all]`

Generate individual HTML wireframe files for each screen defined in `docs/{app}/design/screens.md` + `screens.json`. Each wireframe is a self-contained HTML page with mockup UI, Design/Develop annotations, related ERD entities, Sequence Diagram, and Screen Flow.

**Engine Dependencies:** doc-engine, html-engine, dep-engine
**Gate Prerequisite:** Design phase documents exist (screens.json, erd.json, api.json)
**PBGD Phase:** Build.UIDesign (companion — orthogonal to `/u-design`)

> **PBGD invocation note (v4.0):** Wireframe generation is time-consuming. `/u-plan` prompts the user after SRS+IA are complete to note that wireframes are available as an optional post-Design step (wireframes need Screens.md from `/u-design`). Typical sequence: `/u-prepare` → `/u-plan` → `/u-design` → `/u-wireframe` → `/u-dev`. When `/u-build` is used as the Build orchestrator, it does *not* auto-invoke `/u-wireframe`; the user runs it explicitly at the point they want.

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

**Page Structure — 6 Sections (top→bottom):**

| Section | Description |
|---------|-------------|
| **A. Document Header** | Sticky top bar: SCR-ID badge, screen name, route path, related FT/FR links, 전체 목록 link |
| **B. Stage** | 2-column grid: App Frame (sidebar + main mockup) + Annotation Panel (상세 기획 명세) |
| **C. Overlay UI** | Alert, Confirm, Modal, BottomSheet, Popup, Drawer, Toast — 각각 렌더링된 미리보기 카드 + 상세 기획 설명 |
| **D. 주요 흐름도** | 3-column grid: **Sequence Diagram** + **Class Diagram** + **ERD** (해당 화면 특화, 일반적이면 생략) |
| **E. 주요 프로세스** | inline SVG: **Business Process Flow** (전체 너비) — 해당 화면의 업무 프로세스 단계별 시각화 |
| **F. Component Spec** | Component specification table (#, 컴포넌트, 타입, Props, Bound Data, API) |

#### B. Stage — App Frame + Annotation Panel

**App Frame** (left, `grid-template-columns: 1fr 300px`):
- **Sidebar** (196px, dark): App name/description + IA navigation menu. Current screen = `.active`
- **Main Area**: Page header (breadcrumb + title with back button) + Page body (components rendered as HTML mockup with annotation markers `<span class="mk">N</span>`) + Footer action bar (submit/cancel buttons)

**Annotation Panel** (right, 300px):
- Numbered annotation items matching mockup markers
- Each item: marker number + **영역명** (bold title) + **상세 기획 설명**
- **기획 명세 수준의 상세 내용 필수** — 단순 컴포넌트 타입 나열 금지

**Annotation 작성 규칙 (CRITICAL):** 각 annotation은 해당 영역의 **기획서 역할**을 해야 한다 — 7개 항목(컴포넌트 동작, 입력/수정 여부, 필드 상세, 비즈니스 규칙, 화면 연동, 자동 생성/계산, 알럿/확인)을 해당되는 만큼 포함. Business rules: `BR-{SCR-ID}-NN`. **Generic placeholder/모호한 설명 금지.**

Full rules + BAD/GOOD 예시 → **see `references/wireframe-rendering-rules.md` § B. Annotation 작성 규칙**.

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

와이어프레임은 **기획서 역할** — 개발자가 이 문서만 보고 구현할 수 있는 상세도. **Generic placeholder 금지**, `screens.json`의 실제 필드명/필터/상태/통계/버튼/폼 6개 카테고리 모두 도메인 실제 값 사용. 테이블 샘플 3~5행 현실적 데이터.

Full 금지/필수 항목 + 도메인 예시 → **see `references/wireframe-rendering-rules.md` § B-3. 기획 상세도 규칙**.

#### C. Overlay UI — Modals / BottomSheets / Popups

> **오버레이 섹션이 Stage 바로 아래에 위치** (스크린샷 레이아웃 기준)

**All overlay components (modals, bottomsheets, popups, drawers, toasts) used by the screen MUST be rendered here** in a 2-column grid (`.overlay-grid`).

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

If the screen has **no overlay components**, omit section C entirely.

#### D. 주요 흐름도 (Key Diagrams)

3-column grid (`.diag-grid-3col`) displaying the screen's key technical diagrams.
Each diagram block uses `<svg class="diag">` with inline SVG content.

| Diagram | Purpose | When to include |
|---------|---------|-----------------|
| **Sequence Diagram (시퀀스 다이어그램)** | API call sequence: Actor → Frontend → Backend → DB/External | 복수 API 연쇄 호출, 조건 분기가 있는 화면. **단일 CRUD API만 있으면 생략** |
| **Class Diagram (주요 Class)** | 화면이 다루는 핵심 도메인 클래스의 속성, 메서드, 관계 | 비즈니스 로직 클래스가 있는 화면. **단순 DTO만이면 생략** |
| **ERD (주요 ERD)** | 해당 화면이 참조하는 엔티티만 추출한 mini ERD | 2개 이상 엔티티를 참조하는 화면. **단일 테이블만이면 생략** |

**Non-Generic Policy (CRITICAL):**
- 3개 다이어그램 모두 해당 화면에 **특화된 내용**만 포함
- 일반적인 CRUD 패턴, 자명한 관계는 생략
- **3개 모두 일반적이면 섹션 D 전체 생략**
- 1~2개만 의미 있으면 해당 다이어그램만 렌더링 (빈 칸은 grid가 자동 조정)

**~~Data Flow~~ — 삭제됨. 생성하지 않는다.**
**~~Screen Flow~~ — 삭제됨. screen-flow.md에서 별도 관리.**

#### E. 주요 프로세스 (Business Process Flow)

업무 프로세스 흐름도는 `.process-section` 내에 전체 너비로 렌더링한다.
해당 화면에서 사용자가 수행하는 **전체 업무 흐름**을 좌→우 방향으로 inline SVG로 표현한다.

**Non-Generic Policy:** 단순 CRUD 흐름(목록→상세→수정→저장)만 있는 화면은 이 섹션 생략.

##### Business Process Flow 작성 규칙 (CRITICAL)

좌→우 흐름의 inline SVG. 7개 요소(시작/종료 둥근사각형, 프로세스 단계 사각형, 단계 상세, DB 실린더, 관련 화면, 분기 마름모, 화살표) 사용. 상단 흐름선 + 하단 상세 레이아웃. viewBox 최소 1200px.

Full SVG 요소 표 + 레이아웃 규칙 + 도메인 예시 (상조 상품 등록) + style tokens → **see `references/wireframe-rendering-rules.md` § E. Business Process Flow 작성 규칙**.

#### F. Component Spec Table

Component specification table rendered as `.spec-wrap` at the bottom.
Table columns: `#`, `컴포넌트`, `타입`, `Props`, `Bound Data`, `API`.

This section is always present as a reference appendix.

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
- [ ] Section order: A(Header) → B(Stage) → C(Overlay) → D(주요 흐름도) → E(주요 프로세스) → F(Component Spec) → Footer
- [ ] Annotations contain 기획 명세 수준의 상세 설명 (generic placeholder 없음)
- [ ] 주요 흐름도 (D): 3-column grid — Sequence Diagram + Class Diagram + ERD (일반적이면 개별/전체 생략)
- [ ] 주요 프로세스 (E): Business Process Flow (단순 CRUD만이면 생략)
- [ ] Component Spec (F): Bound Data 컬럼 포함
- [ ] Non-generic policy 준수: 모든 다이어그램/섹션이 해당 화면에 특화된 내용만 포함
- [ ] Overlay가 없으면 C 섹션 생략, 다이어그램이 모두 일반적이면 D/E 섹션 생략
- [ ] Index browser has correct FILES array with all screens
- [ ] Sidebar groups match IA categories
- [ ] Dark/light toggle works on all pages
- [ ] Navigation links (Index, FT, FR) are correct
- [ ] ERD constraints: PK/FK/UK never combined
- [ ] Data Flow 다이어그램 없음 (삭제됨)
- [ ] Screen Flow 다이어그램 없음 (screen-flow.md에서 별도 관리)
- [ ] Annotation Legend 섹션 없음 (삭제됨)
- [ ] 테이블 샘플 데이터가 도메인에 맞는 현실적 데이터임
- [ ] Footer: Copyright(c) 2026 U PLEAT
- [ ] Self-contained HTML (Tailwind CDN, Mermaid CDN, no external deps)

## Reference Files

- **`references/wireframe-rendering-rules.md`** — Annotation 작성 규칙 (B) + 기획 상세도 (B-3) + Business Process Flow 작성 규칙 (E). MUST consult when generating per-screen content.
- **`references/wireframe-page.template.html`** — Single screen wireframe page template
- **`references/wireframe-index.template.html`** — Browser index page template (sidebar + iframe)
