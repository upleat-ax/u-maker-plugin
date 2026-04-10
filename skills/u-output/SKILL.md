---
name: u-output
description: "This skill should be used when the user asks to 'generate HTML', 'render output', 'rebuild HTML', 'regenerate output', '/u-output', or wants to convert existing docs/ markdown+JSON into HTML output without re-running phase logic."
version: 4.0.0
triggers:
  - "/u-output"
  - "/u-html"
  - "generate HTML"
  - "render output"
  - "rebuild HTML"
  - "regenerate output"
---

# u-output — HTML Output Generation

`/u-output [--app {name}] [--doc {docType}] [--force]`
**Alias:** `/u-html`

Standalone HTML generation: reads existing `docs/{app}/` markdown + JSON files and (re)generates all HTML output in `output/{app}/` via html-engine. Does NOT re-run phase logic (plan/design/check) — only converts existing documents to HTML.

**Engine Dependencies:** html-engine, dep-engine

## When to Use

- After manual edits to `.md` or `.json` documents
- When HTML output is missing or corrupted
- To regenerate HTML after template or engine changes
- To rebuild a single document's HTML without re-running the full phase

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app {name}` | auto-detect | Target app (auto-detect if only one app exists) |
| `--doc {docType}` | all | Specific doc type: `srs`, `ia`, `erd`, `api`, `screens`, `design-system`, `testcases`, `test-results` |
| `--diagram {mode}` | `svg` | Diagram rendering mode: `svg`, `mermaid`, `all` (see below) |
| `--force` | OFF | Regenerate even if HTML is newer than source `.md` |

### `--diagram` Mode

| Mode | Behavior |
|------|----------|
| `svg` **(default)** | All diagrams rendered as inline SVG. Mermaid CDN **not loaded**. ERD, class, sequence 등 모든 다이어그램을 자유형 SVG로 렌더링 — Mermaid 스타일에 구애받지 않고 UML 박스, 카드형 노드, 타임라인 컬럼, 곡선 커넥터 등 최적의 시각 표현 사용. ASCII art 금지 (folder tree 제외) |
| `mermaid` | All diagrams rendered via Mermaid CDN (`theme: 'default'`, always light mode). No inline SVG generated |
| `all` | SVG as primary + Mermaid as fallback for UML (`erDiagram`, `classDiagram`, `sequenceDiagram`). Both rendering engines active |

## Execution Flow

### Step 1: Discover Documents

1. If `--app` not specified, scan `docs/` for app directories
2. If multiple apps found and no `--app` → error: "Specify --app {name}"
3. Build document inventory from `docs/{app}/`:

| Phase | Documents |
|-------|-----------|
| Plan | `plan/srs.md+json`, `plan/ia.md+json` |
| Design | `design/erd.md+json`, `design/api.md+json`, `design/screens.md+json`, `design/design-system.md+json` |
| Check | `check/testcases.md+json`, `check/test-results.md+json` |

4. If `--doc` specified, filter to that document only
5. Skip documents where `.md` file does not exist
6. Unless `--force`, skip documents where HTML output is newer than source `.md`

### Step 2: Validate Sources

For each document to process:

1. Verify `.md` file exists and is non-empty
2. Verify `.json` companion exists
3. Verify `.md` ↔ `.json` sync (item counts match, IDs consistent)
4. If validation fails → warn and continue with next document

### Step 3: Generate HTML via html-engine

Process each document according to its type.

#### Split Documents (Domain Split)

| Document | Split Key | Output |
|----------|-----------|--------|
| SRS | FR items | `output/{app}/plan/srs/index.html` + `srs/{fr-slug}.html` per FR |
| ERD | Entity domain | `output/{app}/design/erd/index.html` + `erd/{domain-slug}.html` |
| API | Endpoint group | `output/{app}/design/api/index.html` + `api/{group-slug}.html` |
| Screens | Screen group | `output/{app}/design/screens/index.html` + `screens/{group-slug}.html` |
| Test Cases | FR/FT group | `output/{app}/check/testcases/index.html` + `testcases/{group-slug}.html` |

For each split document:
1. Read companion `.json` → determine domain groups
2. Create `output/{app}/{phase}/{doc}/` directory
3. Render index page from `output-split-index.template.html`
4. Render each domain page from `output-split-page.template.html`
5. Inject sidebar navigation + prev/next links

#### Single Documents (No Split)

| Document | Output |
|----------|--------|
| IA | `output/{app}/plan/ia.html` |
| Design System | `output/{app}/design/design-system.html` |
| Test Results | `output/{app}/check/test-results.html` |

For each single document:
1. Convert `.md` → `.html` via standard html-engine pipeline
2. Apply `output-page.template.html` wrapper

#### All Documents: Diagram Requirements

Generate all mandatory diagrams per document type. Rendering depends on `--diagram` mode:

| Mode | SVG diagrams | Mermaid UML | Mermaid CDN loaded |
|------|-------------|-------------|-------------------|
| `svg` (default) | All diagrams as inline SVG | ERD/Class/Sequence also as SVG | No |
| `mermaid` | None | All diagrams via Mermaid | Yes |
| `all` | Non-UML diagrams as SVG | ERD/Class/Sequence via Mermaid | Yes |

---

### ⚠️ Screens Domain Page — Full Rendering Spec

> **CRITICAL:** Each screen group page MUST include the full content below for EVERY screen in the group. DO NOT generate simplified stub pages with only path/FR/IA info. Screens pages without wireframes are **incomplete output**.

#### Screen Page Layout (per screen, in order)

```
┌─────────────────────────────────────────────────────┐
│  1. Doc-header (SC-ID badge, name, path, FT/FR/P)   │
├──────────────────────────────┬──────────────────────┤
│  2. SVG Wireframe            │  Annotation Panel    │
│     (app-frame mockup)       │  (numbered markers   │
│                              │   + biz rules)       │
├──────────────────────────────┴──────────────────────┤
│  3. Component Spec Table (#, Component, Type, Props, API) │
├─────────────────────────────────────────────────────┤
│  4. Diagrams (2-column SVG grid):                   │
│     A. Business Logic (condition flow)              │
│     B. Sequential (actor-system interaction)        │
│     C. Data Flow (state/API/DB)                     │
│     D. Used ERD (mini ERD for related entities)     │
└─────────────────────────────────────────────────────┘
```

**1. Doc-header:** SC-ID badge, screen title, route path (`/path/to`), related FR IDs, priority, date

**2. SVG Wireframe** (`screens.json` → `layout` + `components` + `state`):
- **App-frame:** 2-column — 좌측 sidebar (앱 네비게이션, 약 200px) + 우측 main area (header + body + footer)
- **Sidebar:** 앱 이름 + 메뉴 목록, 현재 화면 active
- **Page header:** breadcrumb + title + action buttons
- **Page body:** 실제 UI 요소를 SVG로 렌더링:
  - Input: labeled `<rect>` + placeholder text
  - Select: `<rect>` + dropdown arrow
  - Buttons: rounded `<rect>` — primary(filled) / outline(bordered)
  - Tables: header row + body rows with cell borders
  - Cards: rounded `<rect>` + title + content area
  - Form groups: label + input stacked vertically
- **Annotation markers:** 각 UI 요소에 numbered circle (`<circle>` + `<text>`) 배치
- **Colors:** sidebar `#2d3a4a`, header `#3b1e6e`, body `#f0f3f7`, marker `#7c3aed`
- `viewBox` 기반 반응형. State Transition 다이어그램 생성 금지.

**Annotation Panel** (wireframe 우측, HTML):
- 각 numbered marker: marker번호 + component name(bold) + 상세 설명 (type, validation, BR ID)
- 하단 비즈니스 규칙 섹션: `BR-{screenId}-XX` 형식. 어노테이션 범례(legend) 생성 금지.

**3. Component Spec Table** (`screens.json` → `components`):

| # | 컴포넌트 | 타입 | Props / 유효성 | API |
|---|---------|------|--------------|-----|
| 1 | ... | Input/Select/Button/... | required, ... | endpoint or `-` |

**4. Diagrams** (inline SVG, `screens.json` 데이터 기반):

- **A. Business Logic** (`validationRules` + `businessRules`): condition flow chart SVG
  - Start node: pill shape / Action nodes: rounded rect / Decision: `<polygon>` diamond / Error: red rect / Success: green rect
  - Curved path connectors with Yes/No labels
- **B. Sequential** (`apiCalls` + `components`): actor-system interaction SVG
  - Actors: User, Frontend, Backend API, DB — colored box + dashed lifeline
  - Request: solid arrow / Response: dashed arrow, numbered steps
- **C. Data Flow** (state + API + DB): DFD SVG
  - External entity: `<rect>` / Process: `<ellipse>` / Data store: open-top `<rect>`
  - Labeled curved arrows
- **D. Used ERD** (`relatedEntities` or API refs → `erd.json`): mini ERD SVG
  - 관련 엔티티만 추출, entity box + curved connector + cardinality

> If `screens.json` data is insufficient for a diagram, insert: `<div class="text-center text-gray-400 py-8">Diagram will be generated when data is available.</div>`

#### Screens Index Page

`output/{app}/design/screens/index.html` includes:
- Summary metrics (total screens, groups, components, forms)
- SVG navigation map — 4-column grid of group boxes with arrows
- Screen groups card grid (link to each group page with screen count + description)

---

### ⚠️ ERD Domain Page — Full Rendering Spec

> **CRITICAL:** Each ERD domain page MUST include ALL four sections below. DO NOT generate pages with only text or entity lists. ERD pages without inline SVG diagrams and relationship cards are **incomplete output**.

#### ERD Domain Page Content (per entity group, in order)

**1. Inline SVG ERD (필수)** (`erd.json` → `entities` + `relationships`):
- **Entity boxes:** rounded rectangle per entity
  - Header row: colored (`#3b82f6` blue-500), entity name bold
  - Column rows: column name + type + 배지 (PK: `#8b5cf6` violet / FK: `#f59e0b` amber / UK: `#10b981` green)
  - PK/FK/UK 배지는 절대 동일 컬럼에 중복 표시 금지 (각 제약조건은 독립 행)
- **Relationship connectors:** 엔티티 간 **curved `<path>` (C Bezier)** 로 연결. `<line>` / `<polyline>` 사용 금지
  - 커넥터 양 끝: 카디널리티 텍스트 (`1`, `N`, `0..1`, `0..N`)
  - 커넥터 중앙: 관계 설명 라벨 (예: "has many", "belongs to")
- **Domain grouping:** 같은 도메인 엔티티를 배경 `<rect>` (light fill)으로 그룹핑
- **Layout:** 엔티티 간 겹침 없도록 배치. 엔티티 30개 초과 시 도메인별 분할
- `viewBox` 기반 반응형 (`width="100%"`)

**2. Relationship Description Cards (필수)** — SVG 다이어그램 바로 아래 HTML 카드:

각 relationship마다 카드 1개:
| 필드 | 내용 |
|------|------|
| From → To | `EntityA` → `EntityB` |
| Type | `1:1` / `1:N` / `N:M` |
| FK Column | `entityB.entityAId` |
| 비즈니스 의미 | 자연어 prose (예: "하나의 주문은 여러 주문항목을 가진다") |
| 참조 무결성 | `CASCADE` / `SET NULL` / `RESTRICT` 등 |

**3. Entity Detail Tables** — 각 엔티티의 컬럼 상세:

| Column | Type | PK | FK | Nullable | Default | Description |
|--------|------|----|----|----------|---------|-------------|

**4. Common Table References** — 이 도메인 엔티티를 참조하는 다른 도메인 목록 (있는 경우)

#### ERD Index Page

`output/{app}/design/erd/index.html` includes:
- Full ER overview SVG (모든 도메인 entity boxes + curved connectors + cardinality labels)
- Entity count / relationship count 요약 메트릭
- Relationship summary table (From, To, Type, FK)
- Domain cards grid (link to each domain page)

---

### Step 4: Update Index Navigation

1. Regenerate `output/{app}/index.html` from `output-index.template.html`
   - Split docs → `{phase}/{doc}/index.html`
   - Single docs → `{phase}/{doc}.html`
   - Include `domainCount` for split documents
2. Regenerate `output/index.html` from `output-root-index.template.html`
3. Regenerate root `index.html` from `root-index.template.html`

### Step 5: Report

Print summary after completion:

```
u-output complete.
  App:        {app-name}
  Generated:  {N} documents ({M} split, {K} single)
  Skipped:    {S} (up-to-date)
  Errors:     {E}

  Plan:    srs (5 domains), ia
  Design:  erd (3 domains), api (4 domains), screens (3 domains), design-system
  Check:   testcases (5 domains), test-results
```

## Examples

```bash
# Regenerate all HTML (SVG-only, default)
/u-output

# Regenerate with Mermaid diagrams only
/u-output --diagram mermaid

# Regenerate with both SVG + Mermaid fallback
/u-output --diagram all

# Regenerate only ERD HTML with SVG diagrams
/u-output --doc erd

# Regenerate only ERD HTML with Mermaid
/u-output --doc erd --diagram mermaid

# Force regenerate all HTML for specific app
/u-output --app myapp --force
```
