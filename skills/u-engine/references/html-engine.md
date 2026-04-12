# html-engine Reference

The html-engine converts SSoT markdown documents into polished, self-contained HTML pages. It handles markdown parsing, inline SVG diagram generation (primary), Mermaid fallback for UML diagrams, base64 image embedding, Tailwind CSS styling, dark/light mode toggling, sidebar navigation, and Table of Contents generation. **SVG is the preferred diagram format** — self-contained, offline-capable, instantly rendered without CDN dependencies.

## 1. MD to HTML Conversion Pipeline

The full conversion pipeline processes a single `.md` document into a standalone `.html` file:

```
Step 1: Read .md source
Step 2: Parse YAML frontmatter → extract metadata
Step 3: Resolve --diagram mode (svg | mermaid | all; default: svg)
Step 4: Convert markdown body → HTML fragments
Step 5: Generate diagrams per mode:
        svg     → all diagrams as inline SVG from .json data
        mermaid → all diagrams as <pre class="mermaid"> blocks
        all     → SVG primary + Mermaid for UML (erDiagram, classDiagram, sequenceDiagram)
Step 6: Scan for image references → encode as base64
Step 7: Generate Table of Contents from headings
Step 8: Apply output-page.template.html wrapper
Step 9: Inject dark/light toggle, Tailwind; load Mermaid CDN only if mode=mermaid|all
Step 10: Write to output/{app}/{phase}/{docName}.html
Step 11: Update output/{app}/index.html sidebar navigation
Step 12: Update root index files (output/index.html, reports/index.html, index.html)
```

### Input / Output Paths

| Input | Output | Mode |
|-------|--------|------|
| `docs/{app}/plan/srs.md` | `output/{app}/plan/srs/index.html` + `srs/{fr-slug}.html` | **Split** |
| `docs/{app}/plan/ia.md` | `output/{app}/plan/ia.html` | Single |
| `docs/{app}/design/erd.md` | `output/{app}/design/erd/index.html` + `erd/{domain-slug}.html` | **Split** |
| `docs/{app}/design/api.md` | `output/{app}/design/api/index.html` + `api/{group-slug}.html` | **Split** |
| `docs/{app}/design/screens.md` | `output/{app}/design/screens/index.html` + `screens/{group-slug}.html` | **Split** |
| `docs/{app}/design/design-system.md` | `output/{app}/design/design-system.html` | **HTML-first** (see below) |
| `docs/{app}/check/testcases.md` | `output/{app}/check/testcases/index.html` + `testcases/{group-slug}.html` | **Split** |
| `docs/{app}/check/test-results.md` | `output/{app}/check/test-results.html` | Single |

See § 12 "Domain Split Pipeline" for split mode details.

### Markdown Conversion Rules

- **Headings** (`# H1` through `###### H6`): Convert to `<h1>` through `<h6>` with auto-generated `id` attributes for TOC anchoring. The `id` is derived from the heading text: lowercase, spaces replaced with hyphens, special characters removed.
- **Tables**: Convert to `<table>` with Tailwind classes: `class="w-full border-collapse text-sm"`. Header row uses `<thead>` with `class="bg-gray-100 dark:bg-gray-800"`. Body rows alternate with `even:bg-gray-50 dark:even:bg-gray-900`.
- **Code blocks**: Wrap in `<pre><code>` with `class="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 overflow-x-auto text-sm font-mono"`. Language-specific syntax highlighting via class `language-{lang}`.
- **Lists**: Convert `- item` to `<ul>` and `1. item` to `<ol>` with appropriate Tailwind spacing classes.
- **Bold / Italic**: `**bold**` → `<strong>`, `*italic*` → `<em>`.
- **Links**: `[text](url)` → `<a href="url" class="text-blue-600 dark:text-blue-400 underline">text</a>`.

## 2. Mandatory Diagram Requirements

Every HTML document MUST include diagrams appropriate to its document type. Diagrams are not optional — they are a core part of the HTML output that distinguishes it from the raw markdown. When converting `.md` to `.html`, the engine MUST ensure the following diagrams exist. Generate them from the companion `.json` data if not present in source `.md`.

### Diagram Rendering Mode (`--diagram`)

The `--diagram` parameter controls how all diagrams are rendered. Defaults to `svg`.

| Mode | Behavior | Mermaid CDN |
|------|----------|-------------|
| **`svg`** (default) | **All** diagrams as inline SVG — including ERD, class, sequence | Not loaded |
| `mermaid` | **All** diagrams via Mermaid CDN (always `theme: 'default'` light) | Loaded |
| `all` | SVG primary + Mermaid fallback for UML (`erDiagram`, `classDiagram`, `sequenceDiagram`) | Loaded |

When `--diagram svg` (default):
- ERD entity-relationship → SVG with entity boxes, curved connectors, cardinality labels
- Class diagrams → SVG with class boxes, method lists, inheritance/composition arrows
- Sequence diagrams → SVG with lifelines, arrows, activation bars
- All other diagrams → SVG (same as before)

When `--diagram mermaid`:
- All diagrams rendered as Mermaid code blocks (`<pre class="mermaid">`)
- Mermaid CDN loaded with `theme: 'default'` (always light mode)
- Wrapped in `.mermaid-wrapper` (white background)

When `--diagram all`:
- Non-UML diagrams → inline SVG (flowcharts, trees, charts, matrices)
- UML diagrams → Mermaid (`erDiagram`, `classDiagram`, `sequenceDiagram`)

### Diagram Requirements per Document

The "Default" column shows the rendering engine when `--diagram svg` (default). With `--diagram mermaid`, all become Mermaid. With `--diagram all`, the "Fallback" column shows the alternative.

| Document | Required Diagrams | Default (svg) | Fallback (all) |
|----------|-------------------|---------------|----------------|
| **SRS** | FR→US→FT traceability tree | SVG | SVG |
| **SRS** | MoSCoW priority distribution (donut/bar chart) | SVG | SVG |
| **SRS** | Stakeholder-FR responsibility matrix | SVG | SVG |
| **IA** | Site map hierarchy | SVG | SVG |
| **IA** | User flows (per major US) | SVG | SVG |
| **IA** | Navigation structure | SVG | SVG |
| **ERD** | Full entity-relationship diagram (entity boxes + curved connectors + cardinality) | SVG | Mermaid `erDiagram` |
| **ERD** | Entity grouping by domain | SVG | SVG |
| **ERD** | Relationship description cards (per relationship — from/to, type, FK, prose description) | SVG | SVG |
| **ERD** | Sample data tables per entity (3~5 records with FK highlight) | HTML | HTML |
| **ERD** | Sample data relation diagram (record cards + FK curved connectors + scenario) | SVG | SVG |
| **API** | Data model class diagram | SVG | Mermaid `classDiagram` |
| **API** | Request/response sequence per endpoint group | SVG | Mermaid `sequenceDiagram` |
| **API** | Endpoint-to-FR traceability | SVG | SVG |
| **Screens** | Screen flow / navigation map (index page) | SVG | SVG |
| **Screens** | SVG wireframe per screen (app-frame: sidebar + header + body with actual UI elements) | SVG | SVG |
| **Screens** | Annotation panel per screen (numbered markers mapped to wireframe elements) | HTML | HTML |
| **Screens** | Component spec table per screen (component, type, props/validation, API) | HTML | HTML |
| **Screens** | Business logic diagram per screen (condition flow chart SVG) | SVG | SVG |
| **Screens** | Sequential diagram per screen (actor-system interaction SVG) | SVG | SVG |
| **Screens** | Data flow diagram per screen (data stores, processes, external entities SVG) | SVG | SVG |
| **Screens** | Used ERD section per screen (related entities from erd.json) | SVG | SVG |
| **Design System** | **HTML-first: not generated by html-engine.** The design-system.html is the primary artifact created directly from `_meta/templates/design-system.template.html` during the Design phase (Step 4a). It already contains live CSS variables, component showcases, color swatches, typography scale, and spacing visualizations. The html-engine does NOT convert design-system.md → HTML; instead MD/JSON are derived from the HTML. | — | — |
| **Test Cases** | FT→TC coverage map | SVG | SVG |
| **Test Cases** | TC distribution by type (donut chart) | SVG | SVG |
| **Test Results** | FR→US→FT→TC→Result full traceability | SVG | SVG |
| **Test Results** | Pass/Fail summary (donut chart) | SVG | SVG |

### SVG Diagram Generation Rules

0. **No ASCII art (folder tree 제외):** ASCII art (`+--`, `|`, box-drawing characters in `<pre>` blocks)는 folder tree 구조(`├──`, `└──`)에서만 허용. 그 외 모든 다이어그램(레이아웃, ERD, 클래스, 시퀀스, 플로우, 노드맵, 타임라인 등)은 반드시 inline `<svg>`로 렌더링. SVG mode에서는 Mermaid 문법/스타일에 구애받지 않고 자유로운 시각적 표현(UML 박스, 카드형 노드, 타임라인 컬럼, 커넥터 등)을 사용.
1. **Placement:** Insert each diagram immediately after the relevant section heading.
2. **Responsive:** Use `viewBox` + `width="100%"` on all `<svg>` elements. Never use fixed pixel widths.
3. **Curved connectors:** All arrows/lines MUST use `<path>` with cubic Bezier curves (`C` or `Q`). NEVER use `<line>` or straight `<polyline>`.
4. **Arrowhead markers:** Define reusable `<marker id="arrowhead">` inside `<defs>`. Use `marker-end="url(#arrowhead)"` on paths.
5. **Node labels:** Every node must display a human-readable label. Use `<text>` inside `<g>` groups with the node shape.
6. **Color coding:**
   - Plan phase: `#3b82f6` (blue-500)
   - Design phase: `#10b981` (green-500)
   - Check phase: `#f59e0b` (amber-500)
   - Failed/blocked: `#ef4444` (red-500)
   - Neutral/border: `#334155` (slate-700)
   - Background: `#f8fafc` (slate-50)
7. **Dark mode:** Use CSS variables or `currentColor` so diagrams adapt. Wrap color-sensitive fills in `class` attributes that respond to `dark:` selectors:
   ```svg
   <rect class="fill-white dark:fill-gray-800" ... />
   <text class="fill-gray-900 dark:fill-gray-100" ... />
   ```
8. **Node shapes by type:**
   - Rectangles with rounded corners (`rx="8"`) for entities/screens/features
   - Circles for status indicators
   - Diamonds (`<polygon>`) for decision points
   - Pill shapes (`rx="16"`) for start/end nodes
9. **Maximum nodes:** If a diagram exceeds 30 nodes, split into sub-diagrams by logical grouping.
10. **Chart types (SVG):**
    - **Donut chart:** `<circle>` with `stroke-dasharray` for segments. Include center label with count/percentage.
    - **Bar chart:** `<rect>` elements with labels. Horizontal bars for comparison.
    - **Tree/hierarchy:** Top-down layout with curved parent→child connectors.
    - **Matrix:** Grid of `<rect>` cells with fill color intensity indicating coverage.
11. **Free-form SVG design:** SVG mode에서는 Mermaid 문법/스타일에 구애받지 않는다. 데이터 특성에 맞는 최적의 시각 표현을 자유롭게 설계:
    - **UML class/entity boxes:** Header(colored) + attribute rows, 관계선에 cardinality 라벨
    - **Card-style nodes:** 제목, 메타데이터, 상태 배지, 미니 차트를 포함하는 카드형 노드
    - **Timeline/Roadmap:** 컬럼별 phase, 세로 축 위에 pill-shape 항목, 점선 연결
    - **Node-link maps:** 노드 카드 + 라벨 달린 링크 커넥터, 그룹별 배경 영역
    - 데이터에 맞는 다른 시각 표현도 자유롭게 사용 가능
12. **ERD SVG diagram (필수):** ERD 문서의 각 도메인 페이지에 반드시 inline SVG ERD를 생성한다. `erd.json`의 entities + relationships 데이터로부터 생성:
    - **Entity boxes:** 각 엔티티를 rounded rectangle로 렌더링. 헤더 영역(colored, 엔티티명) + column rows (name, type, PK/FK/UK 배지)
    - **Relationship connectors:** 엔티티 간 curved path (`C` Bezier)로 연결. 직선(`<line>`) 금지
    - **Cardinality labels:** 커넥터 양 끝에 `1`, `N`, `0..1`, `0..N` 등 카디널리티 텍스트 표시
    - **Relationship labels:** 커넥터 중앙에 관계 설명 텍스트 (예: "has many", "belongs to")
    - **Color scheme:** Entity header: `#3b82f6` (blue-500), PK badge: `#8b5cf6` (violet), FK badge: `#f59e0b` (amber), UK badge: `#10b981` (green)
    - **Domain grouping:** 같은 도메인 엔티티를 배경 영역(`<rect>` with light fill)으로 그룹핑
    - **Layout:** 엔티티 30개 초과 시 도메인별로 분할. 엔티티 간 겹침 없도록 자동 배치
13. **ERD relationship description section (필수):** ERD 도메인 페이지에 SVG 다이어그램 아래 관계 설명 카드를 HTML로 생성:
    - 각 relationship을 카드 형태로 표시: From Entity → To Entity, Type (1:1/1:N/N:M), FK Column, 상세 설명(prose)
    - 관계의 비즈니스 의미를 자연어로 서술 (예: "하나의 주문(Order)은 여러 개의 주문항목(OrderItem)을 가진다")
    - 참조 무결성 규칙 명시 (CASCADE/SET NULL/RESTRICT 등)
14. **ERD sample data section (필수):** ERD 도메인 페이지에 관계 설명 카드 아래, 샘플 데이터 섹션을 생성한다. `erd.json`의 각 entity `sampleData` 배열로부터:
    - **샘플 데이터 테이블:** 엔티티별 샘플 레코드를 `<table>`로 렌더링. PK 컬럼은 `font-weight: bold`, FK 컬럼은 amber 배경 하이라이트
    - **Sample Data Relation Diagram (inline SVG, 필수):** 샘플 데이터 간의 실제 FK 연결을 시각화하는 inline SVG 다이어그램:
      - **노드:** 각 샘플 레코드를 rounded rectangle 카드로 표현. 카드 내용 = 엔티티명 + PK 값 + 대표 컬럼값 (이름, 제목 등)
      - **커넥터:** FK 관계에 따라 부모 레코드 → 자식 레코드를 curved path (`C` Bezier)로 연결. 직선 금지
      - **레이블:** 커넥터 위에 FK 컬럼명 표시 (예: `userId`, `orderId`)
      - **그룹핑:** 같은 엔티티의 레코드를 수평으로 나열하고, 엔티티 그룹을 수직으로 배치. 각 엔티티 그룹에 라벨 헤더
      - **Color scheme:** 엔티티 그룹별 헤더 색상 구분 (blue-500, green-500, amber-500, violet-500 순환). 카드 배경: white/gray-50. 커넥터: slate-700
      - **비즈니스 시나리오:** 다이어그램 하단에 샘플 데이터가 표현하는 비즈니스 시나리오를 1~2문장으로 서술하는 `<p>` 텍스트 추가
      - **Dark mode:** 카드/텍스트에 `dark:` 클래스 적용
    - **관계 매핑 테이블:** 각 REL별로 부모 PK, 부모 대표값, 자식 PK, 자식 대표값, FK 컬럼을 정리하는 요약 테이블
16. **Screen wireframe (SVG — 대체 기존 screen layout diagram):** 기존 layout 박스 대신, 실제 UI를 묘사하는 고충실도 SVG wireframe을 생성한다. `screens.json`의 `layout` + `components` + `state` 필드로부터:
    - **App-frame 구조:** 2-column layout — 좌측 sidebar (앱 내비게이션) + 우측 main area (page header + body + footer)
    - **Sidebar:** 앱 이름/로고, 메뉴 항목 목록. 현재 화면 active 상태 표시
    - **Page header:** breadcrumb + page title + action buttons
    - **Page body:** 실제 UI 요소를 SVG로 렌더링:
      - Input fields: labeled `<rect>` with placeholder text
      - Select/Dropdown: `<rect>` with dropdown arrow indicator
      - Buttons: rounded `<rect>` with label (primary: filled, outline: bordered)
      - Tables: header row + body rows with cell borders
      - Cards: rounded `<rect>` with title + content area
      - File dropzone: dashed border `<rect>` with upload icon
      - Form groups: label + input stacked vertically
    - **Annotation markers:** 각 주요 UI 요소에 numbered circle marker (`<circle>` + `<text>`) 배치. 마커 번호는 annotation panel과 1:1 매핑
    - **Color scheme:** sidebar bg: `#2d3a4a`, header bg: `#3b1e6e`, body bg: `#f0f3f7`, marker: `#7c3aed`
    - **Sizing:** `viewBox` 기반 반응형. sidebar 약 200px, main area 나머지
    - State Transition 다이어그램은 생성하지 않는다
17. **Screen annotation panel (HTML):** wireframe 오른쪽에 배치되는 어노테이션 패널:
    - 각 numbered marker에 대응하는 설명 항목: marker number + component name (bold) + 상세 설명
    - 설명에는 component type, validation rules, related BR(Business Rule) ID 포함
    - 하단에 **비즈니스 규칙** 섹션: `BR-{screenId}-XX` 형식의 규칙 목록
    - 어노테이션 범례(legend)는 생성하지 않는다
18. **Screen component spec table (HTML):** wireframe + annotation 아래 배치:
    - 테이블 컬럼: `#` (marker 번호), `컴포넌트`, `타입` (Input/Select/Button/Upload/Display/Form/Action...), `Props / 유효성`, `API`
    - `screens.json`의 `components` 배열로부터 생성
    - API 컬럼: 해당 컴포넌트가 트리거하는 API endpoint (없으면 `-`)
19. **Screen business logic diagram (SVG):** 해당 화면의 유효성 검사 / 조건 분기 흐름을 condition flow chart로 생성:
    - **Start node:** pill shape (화면 진입)
    - **Action nodes:** rounded rect (사용자 입력, API 호출 등)
    - **Decision diamonds:** `<polygon>` diamond shape (조건 분기: 유효성 검사, 상태 체크)
    - **Error nodes:** red-tinted rect (에러 표시, 비활성 등)
    - **Success node:** green-tinted rect (최종 성공 상태)
    - **Connectors:** curved path with Yes/No labels
    - `screens.json`의 `validationRules` + `businessRules` 데이터로부터 생성
20. **Screen sequential diagram (SVG):** 해당 화면의 사용자-시스템 상호작용 시퀀스:
    - **Actors:** 사용자(User), Frontend, Backend API, DB/External 등 — 각각 colored box + dashed lifeline
    - **Messages:** solid arrow (request) + dashed arrow (response) with numbered step labels
    - **Activation bars:** Frontend/Backend 처리 구간을 thin rect로 표시
    - **Self-calls:** Frontend 내부 처리 (유효성 검사 등) — loop-back arrow
    - `screens.json`의 `apiCalls` + `components` 데이터로부터 흐름 추론
21. **Screen data flow diagram (SVG):** 해당 화면의 데이터 흐름:
    - **External entity:** `<rect>` (사용자, 외부 시스템)
    - **Process:** `<circle>` or `<ellipse>` (화면 Page, API endpoint)
    - **Data store:** open-top `<rect>` (state store, DB table)
    - **Data flows:** labeled curved arrows showing data movement
    - 화면에서 사용하는 state, API request/response, DB 읽기/쓰기를 시각화
22. **Screen used ERD section (SVG):** 해당 화면이 사용하는 엔티티만 추출하여 mini ERD를 inline SVG로 생성:
    - `screens.json`의 `relatedEntities` 또는 API endpoint에서 참조하는 entity를 `erd.json`에서 조회
    - 해당 엔티티 + 엔티티 간 관계만 포함하는 축소된 ERD SVG
    - 전체 ERD와 동일한 스타일 (entity box + curved connector + cardinality)
23. **Fallback:** If source data is insufficient, insert a placeholder `<div class="text-center text-gray-400 py-8">` with note: `"Diagram will be generated when {dependency} data is available."`

## 3. Mermaid Rendering Configuration

Mermaid is activated when `--diagram mermaid` or `--diagram all` is specified. When `--diagram svg` (default), Mermaid CDN is **not loaded** and all diagrams are inline SVG.

- `--diagram mermaid`: All diagrams rendered via Mermaid
- `--diagram all`: Mermaid used only for UML (`erDiagram`, `classDiagram`, `sequenceDiagram`); all others inline SVG

Mermaid code blocks are preserved as `<pre class="mermaid">` elements wrapped in `<div class="mermaid-wrapper">` for client-side rendering.

### CDN Script Inclusion

```html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js';
  mermaid.initialize({
    startOnLoad: true,
    theme: 'default',
    flowchart: {
      curve: 'basis',
      useMaxWidth: true,
      htmlLabels: true
    },
    er: {
      useMaxWidth: true
    },
    sequence: {
      useMaxWidth: true,
      mirrorActors: false
    },
    themeVariables: {
      fontFamily: 'Inter, system-ui, sans-serif',
      fontSize: '14px'
    }
  });
</script>
```

### Key Configuration Parameters

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `theme` | `'default'` | Use Mermaid default theme (light-friendly) |
| `flowchart.curve` | `'basis'` | Curved connectors instead of straight-line arrows |
| `startOnLoad` | `true` | Auto-render all `.mermaid` blocks on page load |
| `useMaxWidth` | `true` | Responsive diagram sizing |

### Mermaid Diagram Types

| Mermaid Type | u-maker Usage | Document |
|--------------|---------------|----------|
| `erDiagram` | Entity-Relationship diagrams | ERD |
| `classDiagram` | API model diagrams | API |
| `flowchart` | Navigation flows, workflows | IA, Screens |
| `sequenceDiagram` | API interaction sequences | API, Screens |
| ~~`stateDiagram-v2`~~ | ~~State transitions~~ | ~~Screens~~ (removed — use SVG screen layout instead) |

### erDiagram Constraint Rules

In Mermaid `erDiagram`, PK, FK, and UK constraints MUST NEVER be combined on a single attribute. Each constraint occupies its own annotation:

```
CORRECT:
  entity {
    string id PK
    string email UK
    string org_id FK
  }

INCORRECT (never do this):
  entity {
    string id PK,FK
    string email PK,UK
  }
```

### Mermaid Theme: Always Light Mode

Mermaid diagrams MUST always render in **light mode** (`theme: 'default'`). When the page toggles to dark mode, Mermaid diagrams remain in light theme — do NOT re-initialize Mermaid with `theme: 'dark'`. Instead, wrap Mermaid containers in a light-background wrapper:

```html
<div class="mermaid-wrapper bg-white rounded-lg p-4 my-4">
  <pre class="mermaid">
    erDiagram ...
  </pre>
</div>
```

This ensures Mermaid diagrams are always readable regardless of page theme.

### Mermaid Syntax Error Prevention (Critical)

Mermaid syntax errors break the entire diagram. Follow these rules strictly:

**erDiagram rules:**
1. Entity names: `PascalCase`, no spaces, no hyphens → `OrderItem` not `Order-Item`
2. Column constraints: **ONE per column** — never combine `PK FK` or `PK UK`
3. Column format: `{type} {name} {constraint}` — e.g. `bigint id PK`
4. Relationship labels: always in double quotes → `"has many"` not `has many`
5. No trailing commas inside entity blocks
6. No empty entity blocks — must have at least one column
7. Comment with `%%` not `//`

**classDiagram rules:**
1. Class names: `PascalCase`, no spaces
2. Methods: `+methodName(param: Type): ReturnType`
3. Access modifiers: `+` public, `-` private, `#` protected
4. Relationships: `<|--` inheritance, `*--` composition, `o--` aggregation

**sequenceDiagram rules:**
1. Participant names: no special characters, use `participant X as "Display Name"` for aliases
2. Arrow types: `->>` async, `-->>` async reply, `->` sync, `-->` sync reply
3. No unclosed `alt`/`opt`/`loop`/`par` blocks

**Pre-render validation:** Before writing Mermaid code blocks, mentally walk through the syntax to verify no parser errors exist.

## 4. SVG Inline Generation

For diagrams that are not Mermaid-based (custom flow diagrams, architecture diagrams, wireframes), html-engine generates inline SVG directly in the HTML output.

### SVG Rules

1. **Curved connectors**: All connectors (arrows, lines) MUST use curved paths (`<path>` with cubic Bezier curves), never straight lines (`<line>`).

```svg
<!-- CORRECT: Curved connector -->
<path d="M 50,100 C 100,100 100,200 150,200"
      stroke="#334155" stroke-width="2" fill="none"
      marker-end="url(#arrowhead)" />

<!-- INCORRECT: Straight line -->
<line x1="50" y1="100" x2="150" y2="200" stroke="#334155" />
```

2. **Arrowhead marker definition**: Include a reusable arrowhead marker in each SVG:

```svg
<defs>
  <marker id="arrowhead" markerWidth="10" markerHeight="7"
          refX="10" refY="3.5" orient="auto">
    <polygon points="0 0, 10 3.5, 0 7" fill="#334155" />
  </marker>
</defs>
```

3. **Responsive sizing**: Use `viewBox` attribute and `width="100%"` for responsive SVGs:

```svg
<svg viewBox="0 0 800 600" width="100%" xmlns="http://www.w3.org/2000/svg">
```

4. **Color palette**: Use Tailwind-aligned colors for consistency:
   - Backgrounds: `#f8fafc` (slate-50), `#f1f5f9` (slate-100)
   - Borders/lines: `#334155` (slate-700)
   - Primary accent: `#3b82f6` (blue-500)
   - Success: `#22c55e` (green-500)
   - Warning: `#f59e0b` (amber-500)
   - Error: `#ef4444` (red-500)

5. **Text styling**: Use `font-family="Inter, system-ui, sans-serif"` and appropriate font sizes (12-16px).

## 5. Base64 Image Encoding

All images referenced in the markdown source MUST be embedded as base64 data URIs in the output HTML. This ensures the HTML file is completely self-contained.

### Encoding Procedure

1. Scan the rendered HTML for `<img src="...">` tags
2. For each image with a local file path (not an external URL):
   a. Read the image file as binary
   b. Detect MIME type from file extension
   c. Encode as base64
   d. Replace `src` attribute with `data:{mime};base64,{encoded}`

### Supported Image Formats

| Extension | MIME Type |
|-----------|-----------|
| `.png` | `image/png` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.gif` | `image/gif` |
| `.svg` | `image/svg+xml` |
| `.webp` | `image/webp` |

### Example Transformation

```html
<!-- Before -->
<img src="assets/logo.png" alt="Logo" />

<!-- After -->
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUg..." alt="Logo" />
```

### External Images

External images (URLs starting with `http://` or `https://`) are left as-is. They are NOT converted to base64.

## 6. Tailwind CSS Integration

All generated HTML uses Tailwind CSS utility classes for styling. Tailwind is loaded via CDN to keep output files self-contained.

### CDN Inclusion

```html
<script src="https://cdn.tailwindcss.com"></script>
<script>
  tailwind.config = {
    darkMode: 'class',
    theme: {
      extend: {
        fontFamily: {
          sans: ['Inter', 'system-ui', 'sans-serif'],
          mono: ['JetBrains Mono', 'Fira Code', 'monospace']
        }
      }
    }
  };
</script>
```

### Base Layout Classes

```html
<body class="bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100
             font-sans leading-relaxed">
  <div class="flex min-h-screen">
    <!-- Sidebar -->
    <nav class="w-64 bg-gray-50 dark:bg-gray-900 border-r border-gray-200
                dark:border-gray-800 p-4 sticky top-0 h-screen overflow-y-auto">
    </nav>
    <!-- Main content -->
    <main class="flex-1 max-w-4xl mx-auto px-8 py-12">
    </main>
  </div>
</body>
```

### Typography Scale

| Element | Classes |
|---------|---------|
| `<h1>` | `text-3xl font-bold mt-12 mb-6 text-gray-900 dark:text-white` |
| `<h2>` | `text-2xl font-semibold mt-10 mb-4 text-gray-800 dark:text-gray-100` |
| `<h3>` | `text-xl font-semibold mt-8 mb-3 text-gray-800 dark:text-gray-200` |
| `<h4>` | `text-lg font-medium mt-6 mb-2 text-gray-700 dark:text-gray-300` |
| `<p>` | `text-base leading-7 mb-4 text-gray-700 dark:text-gray-300` |
| `<code>` inline | `bg-gray-100 dark:bg-gray-800 px-1.5 py-0.5 rounded text-sm font-mono` |

## 7. Dark/Light Toggle

Every generated HTML page includes a dark/light mode toggle switcher in the top-right corner of the page header.

### Default Mode

Light mode is the default. The `<html>` element starts without the `dark` class.

### Toggle Implementation

```html
<button id="theme-toggle"
        class="fixed top-4 right-4 z-50 p-2 rounded-lg
               bg-gray-200 dark:bg-gray-700
               hover:bg-gray-300 dark:hover:bg-gray-600
               transition-colors duration-200"
        aria-label="Toggle dark mode">
  <svg id="sun-icon" class="w-5 h-5 hidden dark:block" fill="currentColor" viewBox="0 0 20 20">
    <!-- Sun icon SVG path -->
  </svg>
  <svg id="moon-icon" class="w-5 h-5 block dark:hidden" fill="currentColor" viewBox="0 0 20 20">
    <!-- Moon icon SVG path -->
  </svg>
</button>

<script>
  const toggle = document.getElementById('theme-toggle');
  const html = document.documentElement;

  // Check saved preference or system preference
  if (localStorage.getItem('theme') === 'dark' ||
      (!localStorage.getItem('theme') &&
       window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    html.classList.add('dark');
  }

  toggle.addEventListener('click', () => {
    html.classList.toggle('dark');
    localStorage.setItem('theme', html.classList.contains('dark') ? 'dark' : 'light');
    // NOTE: Mermaid stays in light mode ('default' theme) regardless of page theme.
    // Mermaid diagrams are wrapped in .mermaid-wrapper with white background.
  });
</script>
```

### Persistence

Theme preference is saved in `localStorage` under the key `theme`. On page load, the saved preference is checked before the system preference.

## 8. Root Index Navigation System

The u-maker project maintains a 3-tier index navigation hierarchy. **All three index files MUST be updated whenever any HTML document or report is generated.**

### Index Hierarchy

```
.u-maker/
├── index.html                    ← Root hub (links to output/ and reports/)
├── output/
│   ├── index.html                ← Output root (lists all apps)
│   └── {app}/
│       └── index.html            ← Per-app portal (sidebar + iframe)
└── reports/
    └── index.html                ← Reports listing (chronological table)
```

### Templates

| Index File | Template | Placeholders |
|------------|----------|-------------|
| `.u-maker/index.html` | `_meta/templates/root-index.template.html` | `projectName`, `projectDescription`, `apps[]`, `planCount`, `designCount`, `checkCount`, `reportCount` |
| `.u-maker/output/index.html` | `_meta/templates/output-root-index.template.html` | `projectName`, `apps[]` (with `name`, `initial`, `description`, `planCount/Docs`, `designCount/Docs`, `checkCount/Docs`) |
| `.u-maker/reports/index.html` | `_meta/templates/reports-index.template.html` | `projectName`, `reportCount`, `reports[]` (with `file`, `title`, `type`, `typeClass`, `app`, `date`, `score`, `scoreClass`) |
| `.u-maker/output/{app}/index.html` | `_meta/templates/output-index.template.html` | `appName`, `appDescription`, `planItems[]`, `designItems[]`, `checkItems[]`, counts |

### Root Index Update Protocol

Whenever **any** of these events occur, ALL relevant index files MUST be regenerated:

| Event | Index Files to Update |
|-------|----------------------|
| HTML document generated (`output/{app}/{phase}/*.html`) | `output/{app}/index.html` + `output/index.html` + `index.html` |
| Report generated (`reports/*.html`) | `reports/index.html` + `index.html` |
| New app initialized | `output/index.html` + `index.html` |

### Update Algorithm

1. **Scan** the filesystem for existing HTML files:
   - `output/*/plan/*.html`, `output/*/design/*.html`, `output/*/check/*.html`
   - `reports/*.html`
2. **Collect** metadata: file paths, document titles (from `<title>` or filename), app names, phases, dates
3. **Render** each template with collected data
4. **Write** all affected index files

### Report Type Classification

| Report filename pattern | Type | `typeClass` |
|------------------------|------|-------------|
| `daily-*.html` | Daily | `bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300` |
| `gate-*.html` | Gate | `bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300` |
| `summary-*.html` | Summary | `bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300` |
| `loop-*.html` | Loop | `bg-purple-100 text-purple-700 dark:bg-purple-900/40 dark:text-purple-300` |

### Score Badge Classification

| Score Range | `scoreClass` |
|-------------|-------------|
| >= 95 | `bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300` |
| 80–94 | `bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300` |
| < 80 | `bg-red-100 text-red-700 dark:bg-red-900/40 dark:text-red-300` |

### HTML Link Rule (CRITICAL)

**모든 `<a href>` 링크는 반드시 파일명까지 명시해야 한다.** 폴더 경로만 사용하면 `file://` 프로토콜에서 작동하지 않는다.

| Pattern | Bad (금지) | Good (필수) |
|---------|-----------|------------|
| 폴더 index | `href="output/"` | `href="output/index.html"` |
| 폴더 index | `href="reports/"` | `href="reports/index.html"` |
| 앱 폴더 | `href="myapp/"` | `href="myapp/index.html"` |
| Split doc 폴더 | `href="plan/srs/"` | `href="plan/srs/index.html"` |
| 단일 파일 | `href="plan/ia"` | `href="plan/ia.html"` |

**규칙:**
1. 디렉토리 링크 → 항상 `index.html` 포함: `{dir}/index.html`
2. 단일 파일 링크 → 항상 `.html` 확장자 포함: `{file}.html`
3. `../` 상대 경로도 동일 적용: `href="../index.html"` (not `href="../"`)
4. 이 규칙은 sidebar, breadcrumb, back link, card link 등 **모든 `<a href>`에 적용**

## 9. Per-App Sidebar Navigation (output/{app}/index.html)

The `output/{app}/index.html` file serves as the project's documentation portal with a sidebar navigation listing all generated HTML documents.

### Sidebar Structure

```html
<nav class="w-64 bg-gray-50 dark:bg-gray-900 border-r border-gray-200
            dark:border-gray-800 p-4 sticky top-0 h-screen overflow-y-auto">
  <h2 class="text-lg font-bold mb-4 text-gray-900 dark:text-white">
    {App Name}
  </h2>

  <!-- Plan Phase -->
  <div class="mb-6">
    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500
               dark:text-gray-400 mb-2">Plan</h3>
    <ul class="space-y-1">
      <li>
        <a href="plan/srs/index.html"
           class="block px-3 py-1.5 rounded text-sm text-gray-700
                  dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-800">
          SRS
        </a>
      </li>
      <li>
        <a href="plan/ia.html" class="...">IA</a>
      </li>
    </ul>
  </div>

  <!-- Design Phase -->
  <div class="mb-6">
    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500
               dark:text-gray-400 mb-2">Design</h3>
    <ul class="space-y-1">
      <li><a href="design/erd/index.html" class="...">ERD</a></li>
      <li><a href="design/api/index.html" class="...">API</a></li>
      <li><a href="design/screens/index.html" class="...">Screens</a></li>
      <li><a href="design/design-system.html" class="...">Design System</a></li>
    </ul>
  </div>

  <!-- Check Phase -->
  <div class="mb-6">
    <h3 class="text-xs font-semibold uppercase tracking-wider text-gray-500
               dark:text-gray-400 mb-2">Check</h3>
    <ul class="space-y-1">
      <li><a href="check/testcases/index.html" class="...">Test Cases</a></li>
      <li><a href="check/test-results.html" class="...">Test Results</a></li>
    </ul>
  </div>
</nav>
```

### Dynamic Sidebar Update

When a new HTML document is generated, the sidebar navigation in `output/{app}/index.html` MUST be updated:

1. Read existing `index.html`
2. Parse the `<nav>` sidebar section
3. Determine which phase group the new document belongs to (Plan, Design, Check)
4. Add a new `<li><a>` entry if it does not already exist
5. Sort entries within each phase group alphabetically
6. Write updated `index.html`

### Active Page Highlighting

When viewing a specific document page, the corresponding sidebar entry is highlighted:

```html
<a href="plan/srs/index.html"
   class="block px-3 py-1.5 rounded text-sm bg-blue-100 dark:bg-blue-900
          text-blue-700 dark:text-blue-300 font-medium">
  SRS
</a>
```

## 10. TOC Auto-Generation

Every document HTML page includes an auto-generated Table of Contents derived from the document's headings.

### TOC Generation Algorithm

1. Scan the HTML body for all heading elements (`<h2>` through `<h4>` — skip `<h1>` as it is the document title)
2. Build a nested list structure based on heading levels
3. Each TOC entry links to the heading's `id` attribute via anchor
4. Insert the TOC after the document title (`<h1>`) and before the first `<h2>`

### TOC HTML Structure

```html
<div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-6 mb-8 border
            border-gray-200 dark:border-gray-800">
  <h2 class="text-lg font-semibold mb-3 text-gray-900 dark:text-white">
    Table of Contents
  </h2>
  <ul class="space-y-1 text-sm">
    <li>
      <a href="#functional-requirements"
         class="text-blue-600 dark:text-blue-400 hover:underline">
        Functional Requirements
      </a>
      <ul class="ml-4 mt-1 space-y-1">
        <li>
          <a href="#user-registration"
             class="text-gray-600 dark:text-gray-400 hover:underline">
            User Registration
          </a>
        </li>
      </ul>
    </li>
  </ul>
</div>
```

### Heading ID Generation

Heading `id` attributes are derived from the heading text:

1. Convert to lowercase
2. Replace spaces with hyphens
3. Remove special characters (except hyphens and underscores)
4. Remove consecutive hyphens
5. Trim leading/trailing hyphens

Example: `## 3. Functional Requirements` → `id="3-functional-requirements"`

## 11. Footer Template

Every generated HTML page includes a standard footer at the bottom of the main content area.

### Footer HTML

```html
<footer class="mt-16 pt-8 border-t border-gray-200 dark:border-gray-800">
  <div class="flex items-center justify-between text-sm text-gray-500
              dark:text-gray-400">
    <p>Copyright(c) 2026 U PLEAT</p>
    <p>Generated by u-maker v4.0.0</p>
  </div>
</footer>
```

### Footer Rules

1. The copyright notice is always `Copyright(c) 2026 U PLEAT` — no variation.
2. The version shown matches the u-maker plugin version from `SKILL.md` frontmatter.
3. The footer appears inside `<main>`, after all document content and before the closing `</main>` tag.
4. The footer border separates it visually from the document content.

## 12. Domain Split Pipeline

For documents with many items, the engine splits output into multiple HTML pages grouped by domain. This keeps individual pages fast-loading, focused, and navigable.

### 12.1 Split vs Single Decision

| Document | Mode | Split Key | Reason |
|----------|------|-----------|--------|
| **SRS** | **Split** | FR ID | Each FR + its traced US/FT chain = 1 domain page |
| **ERD** | **Split** | Entity domain group | Entities grouped by domain = 1 page per domain |
| **API** | **Split** | Endpoint group (by related FR) | Endpoints sharing the same FR = 1 page |
| **Screens** | **Split** | Screen group / navigation section | Screens in the same flow = 1 page |
| **Test Cases** | **Split** | FR/FT group | TCs grouped by parent FT's FR = 1 page |
| **IA** | Single | — | Typically small |
| **Design System** | Single | — | Typically small |
| **Test Results** | Single | — | Summary page |

### 12.2 Split Output Directory Structure

Split documents produce a directory instead of a single file:

```
output/{app}/{phase}/{doc}/
├── index.html                    ← Split index (dashboard overview)
├── {domain-1-slug}.html         ← Domain page 1
├── {domain-2-slug}.html         ← Domain page 2
└── ...
```

Non-split documents remain as single files: `output/{app}/{phase}/{doc}.html`

### 12.3 Split Pipeline Steps

When a document qualifies for splitting, replace Steps 8–10 of the single-file pipeline with:

```
Step 8a: Read companion .json → determine domain groups
Step 8b: Extract index-level content (overview sections, summary tables, overview diagrams)
Step 8c: For each domain group, extract domain-specific content + diagrams
Step 8d: Create output directory: output/{app}/{phase}/{doc}/
Step 8e: Render index page from output-split-index.template.html → index.html
Step 8f: For each domain, render page from output-split-page.template.html → {slug}.html
Step 8g: Inject cross-page navigation (prev/next links, sidebar domain list)
```

Steps 11–12 (index updates) continue as before, but sidebar links point to `{phase}/{doc}/index.html` instead of `{phase}/{doc}.html`.

### 12.4 Domain Grouping Rules

#### SRS Domain Grouping

Read `srs.json` companion:

- **Index page** includes: Project Overview (§1), Stakeholders (§2), NFR summary table (§4), Constraints (§7), Glossary (§8), and overview-level diagrams (full FR→US→FT traceability tree, MoSCoW priority donut chart, Stakeholder-FR matrix)
- **Domain page per FR**: Each FR item + all US items where `tracedFrom` includes this FR + all FT items where `tracedFrom` includes those USs
- **Slug**: FR ID + slugified title (e.g., `fr-010-user-management.html`)
- **Stats**: Total FR count, US count, FT count, NFR count

#### ERD Domain Grouping

Read `erd.json` companion:

- **Index page** includes: Full ER overview diagram (inline SVG — entity boxes with columns, curved connectors with cardinality labels), entity count summary, relationship summary table
- **Domain page per entity group**: Entities sharing the same `domain` field + relationships involving those entities:
  1. **Inline SVG ERD (필수):** 해당 도메인의 entity boxes + relationship connectors를 SVG로 렌더링 (§ 2 Rule 12 참조). Mermaid가 아닌 inline SVG로 생성해야 `--diagram svg` 모드에서 정상 표시됨
  2. **Relationship descriptions (필수):** 각 관계를 카드 형태로 설명 — From → To, Type (1:1/1:N/N:M), FK Column, 비즈니스 의미 prose, 참조 무결성 규칙 (§ 2 Rule 13 참조)
  3. **Entity detail tables:** 각 엔티티의 column 상세 테이블 (Column, Type, PK, FK, Nullable, Default, Description)
  4. **Sample data tables (필수):** 각 엔티티의 샘플 데이터를 `<table>`로 렌더링. PK 컬럼 bold, FK 컬럼 amber 하이라이트 (§ 2 Rule 14 참조)
  5. **Sample data relation diagram (필수):** 도메인 내 샘플 데이터 간 FK 연결을 inline SVG로 시각화. 레코드 카드 + curved connector + FK 라벨 + 비즈니스 시나리오 설명 (§ 2 Rule 14 참조)
  6. **Common table references:** 다른 도메인에서 참조하는 테이블 목록
- **Slug**: Domain name slugified (e.g., `auth-domain.html`)
- **Stats**: Entity count, relationship count, domain count

#### API Domain Grouping

Read `api.json` companion:

- **Index page** includes: API summary table (all endpoints), Authentication & Authorization (§3), Common Models (§4), overview diagrams (endpoint→FR traceability SVG)
- **Domain page per endpoint group**: Endpoints sharing the same `relatedFR` (or grouped by resource path prefix) + full request/response details + sequence diagrams
- **Slug**: Group name slugified (e.g., `user-management-apis.html`)
- **Stats**: Total endpoint count, group count, method distribution

#### Screens Domain Grouping

Read `screens.json` companion:

- **Index page** includes: Screen inventory table (ID, Name, Path, Category, Related IA/FR), screen flow navigation map (SVG), screen group summary
- **Domain page per screen group**: Screens sharing the same `group` or navigation section. 각 화면(screen)마다 아래 섹션을 순서대로 생성:

  **Screen Page Layout (2-column stage):**
  ```
  ┌─────────────────────────────────────────────────────┬───────────────┐
  │  doc-header (screen ID, name, path, FT/FR/P/date)   │               │
  ├──────────────────────────────────┬──────────────────┤               │
  │  SVG Wireframe (app-frame)       │  Annotation Panel│               │
  │  ├─ sidebar (app nav)            │  ├─ markers 1~N  │               │
  │  └─ main (header+body+footer)    │  ├─ descriptions │               │
  │     with actual UI elements      │  └─ biz rules    │               │
  ├──────────────────────────────────┴──────────────────┤               │
  │  Component Spec Table (#, Component, Type, Props, API)              │
  ├─────────────────────────────────────────────────────┤               │
  │  Diagrams Section                                    │               │
  │  ├─ A. Business Logic Diagram (condition flow SVG)   │               │
  │  ├─ B. Sequential Diagram (actor-system SVG)         │               │
  │  ├─ C. Data Flow Diagram (DFD SVG)                   │               │
  │  └─ D. Used ERD (mini ERD SVG for related entities)  │               │
  └─────────────────────────────────────────────────────┘               │
  ```

  1. **Doc-header:** sticky top bar — screen ID badge (`SC-XXX`), screen name, route path (`/path/to`), related FT/FR IDs, priority, date
  2. **SVG Wireframe + Annotation (2-column grid):**
     - 좌측: SVG wireframe (§ 2 Rule 14 — app-frame with sidebar, page header, form elements, tables, buttons, annotation markers)
     - 우측: Annotation panel (§ 2 Rule 15 — numbered descriptions + business rules). 어노테이션 범례는 생성하지 않는다
  3. **Component spec table:** § 2 Rule 16 — `#`, 컴포넌트, 타입, Props/유효성, API
  4. **Diagrams section:** 4개 다이어그램 순서대로:
     - A. Business Logic Diagram — condition flow chart SVG (§ 2 Rule 17)
     - B. Sequential Diagram — actor-system interaction SVG (§ 2 Rule 18)
     - C. Data Flow Diagram — DFD SVG (§ 2 Rule 19)
     - D. Used ERD — mini ERD SVG for this screen's related entities (§ 2 Rule 20)

- **Slug**: Group name slugified (e.g., `auth-screens.html`)
- **Stats**: Screen count, component count, group count

#### Test Cases Domain Grouping

Read `testcases.json` companion:

- **Index page** includes: Coverage matrix (FR→US→FT→TC), TC distribution by type donut chart (SVG), summary statistics
- **Domain page per FR group**: TCs whose parent FT traces back to the same FR + preconditions, steps, expected results
- **Slug**: FR-based group name slugified (e.g., `fr-010-test-cases.html`)
- **Stats**: TC count by type, total TC count, pass/fail summary (if available)

### 12.5 Split Index Page Template

**Template:** `_meta/templates/output-split-index.template.html`

**Placeholders:**

| Placeholder | Description |
|-------------|-------------|
| `{{docTitle}}` | Full document title (e.g., "Software Requirements Specification") |
| `{{docType}}` | Short name (e.g., "SRS") |
| `{{appName}}` | Application name |
| `{{status}}`, `{{version}}`, `{{lastUpdated}}` | Metadata |
| `{{#stats}}` | Array: `{{value}}`, `{{label}}`, `{{colorClass}}` (Tailwind color class) |
| `{{#domains}}` | Array: `{{id}}`, `{{name}}`, `{{description}}`, `{{file}}`, `{{itemCount}}`, `{{phaseColor}}` |
| `{{overviewContent}}` | HTML of non-domain overview sections |
| `{{diagrams}}` | Overview-level SVG/Mermaid diagrams |

**Layout:** Dashboard-style with summary stat cards at top, domain navigation grid in the middle, overview content and diagrams below.

### 12.6 Split Domain Page Template

**Template:** `_meta/templates/output-split-page.template.html`

**Placeholders:**

| Placeholder | Description |
|-------------|-------------|
| `{{docTitle}}` | Parent document title |
| `{{docType}}` | Parent short name |
| `{{appName}}` | Application name |
| `{{domainName}}` | Current domain name (e.g., "FR-010: User Management") |
| `{{domainId}}` | Domain ID (e.g., "FR-010") |
| `{{itemCount}}` | Item count label (e.g., "3 US · 8 FT") |
| `{{#domains}}` | All domain pages: `{{id}}`, `{{name}}`, `{{file}}`, `{{active}}` (boolean) |
| `{{content}}` | Domain HTML content |
| `{{toc}}` | Domain-specific table of contents |
| `{{prevFile}}`, `{{prevName}}` | Previous domain page (if exists) |
| `{{nextFile}}`, `{{nextName}}` | Next domain page (if exists) |

**Layout:** Fixed left sidebar (240px) listing all domains with active highlight. Main content area with breadcrumb, domain content, and bottom prev/next navigation. Mobile-responsive: sidebar collapses with hamburger toggle. Keyboard navigation: Left/Right arrow keys for prev/next.

### 12.7 Slug Generation

Domain page filenames use slugified identifiers:

1. Start with the domain ID if available (e.g., `fr-010`)
2. Append slugified domain title: lowercase, spaces → hyphens, remove special chars
3. Truncate to 60 characters max
4. Examples: `fr-010-user-management.html`, `auth-domain.html`, `payment-apis.html`

### 12.8 App-Level Index Sidebar Update

When split documents exist, the `output/{app}/index.html` sidebar links MUST point to the directory index:

```
<!-- Single file (non-split) -->
<div class="nav-item" data-src="design/design-system.html">
  <span class="label">Design System</span>
</div>

<!-- Split document (directory) -->
<div class="nav-item" data-src="plan/srs/index.html">
  <span class="label">SRS</span>
  <span class="nav-count">5 domains</span>
</div>
```

## 13. Complete HTML Page Structure

The final assembled HTML page follows this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{Document Title} — {App Name}</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>/* Tailwind config */</script>
  <script type="module">/* Mermaid init */</script>
</head>
<body class="bg-white dark:bg-gray-950 text-gray-900 dark:text-gray-100 font-sans">
  <!-- Dark/Light Toggle -->
  <button id="theme-toggle">...</button>

  <div class="flex min-h-screen">
    <!-- Sidebar (on index.html) or hidden (on doc pages) -->
    <nav>...</nav>

    <!-- Main Content -->
    <main class="flex-1 max-w-4xl mx-auto px-8 py-12">
      <h1>{Document Title}</h1>

      <!-- Metadata Badge Bar -->
      <div class="flex gap-2 mb-6">
        <span class="badge">Status: {status}</span>
        <span class="badge">Version: {version}</span>
        <span class="badge">App: {app}</span>
      </div>

      <!-- Table of Contents -->
      <div class="toc">...</div>

      <!-- Document Body -->
      {converted HTML content}

      <!-- Footer -->
      <footer>
        <p>Copyright(c) 2026 U PLEAT</p>
      </footer>
    </main>
  </div>

  <script>/* Theme toggle logic */</script>
</body>
</html>
```
