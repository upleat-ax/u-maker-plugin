# screens-rendering — Screens Domain Page Full Rendering Spec

> **CRITICAL:** Each screen group page MUST include the full content below for EVERY screen in the group. DO NOT generate simplified stub pages with only path/FR/IA info. Screens pages without wireframes are **incomplete output**.

## Screen Page Layout (per screen, in order)

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

## 1. Doc-header

SC-ID badge, screen title, route path (`/path/to`), related FR IDs, priority, date.

## 2. SVG Wireframe (`screens.json` → `layout` + `components` + `state`)

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
- **Colors:** sidebar `#2d3a4a`, header `#3b1e6e`, body `#f0f3f7`, marker `#64748b`
- `viewBox` 기반 반응형. State Transition 다이어그램 생성 금지.

### Annotation Panel (wireframe 우측, HTML)

- 각 numbered marker: marker번호 + component name(bold) + 상세 설명 (type, validation, BR ID)
- 하단 비즈니스 규칙 섹션: `BR-{screenId}-XX` 형식. 어노테이션 범례(legend) 생성 금지.

## 3. Component Spec Table (`screens.json` → `components`)

| # | 컴포넌트 | 타입 | Props / 유효성 | API |
|---|---------|------|--------------|-----|
| 1 | ... | Input/Select/Button/... | required, ... | endpoint or `-` |

## 4. Diagrams (inline SVG, `screens.json` 데이터 기반)

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

## Screens Index Page

`output/{app}/design/screens/index.html` includes:
- Summary metrics (total screens, groups, components, forms)
- SVG navigation map — 4-column grid of group boxes with arrows
- Screen groups card grid (link to each group page with screen count + description)
