# Figma Frame Analysis Reference

> Comprehensive guide for analyzing Figma frames during ingest and design phases. A single Figma frame may contain mixed content types (wireframes, diagrams, annotations, design specs). This reference defines how to detect content types, which MCP tools to use, and how to produce structured digest output.

## 1. Overview

Figma links may point to an entire file, a specific page, or a specific frame. When the link targets a **specific frame**, the frame often contains heterogeneous content — not just a single screen design, but a mix of planning artifacts, design specifications, annotations, and interactive prototypes. The analysis engine must classify each content region within the frame and apply the appropriate extraction strategy.

### 1.1 Input Sources

| Source | Format | When Used |
|--------|--------|-----------|
| Figma link in `data/dropzone/` | `.figma-link` file containing URL | During `/u-ingest` |
| Figma link provided by user | Direct URL in conversation | During `/u-ingest`, `/u-design` |
| Figma file reference in SRS/IA | URL in document body | During `/u-design` design system generation |

### 1.2 Link Anatomy

```
https://www.figma.com/design/{file_key}/{file_name}?node-id={node_id}
                              │                        │
                              └─ File identifier        └─ Specific frame/node
```

- **File-level link** (no `node-id`): Analyze entire file structure, pages, top-level frames
- **Page-level link** (`node-id` points to page): Analyze all frames within the page
- **Frame-level link** (`node-id` points to frame): Deep-analyze the single frame — this is the primary use case

### 1.2.1 Figma Link Traceability (MANDATORY)

Figma 분석으로 생성되는 **모든** `.json` 및 `.md` 산출물에는 원본 Figma 링크를 반드시 기록한다.

| 산출물 형식 | 기록 방식 |
|---|---|
| `.json` | `figmaUrl` 필드 (개별 item에도 `figmaUrl` 포함 권장) |
| `.md` | 문서 상단 메타 섹션 또는 각 섹션에 `> Figma: <url>` 형태 |

- 링크는 가능한 한 **deep link** (`?node-id=...`) 형태로 남겨 프레임 단위 추적성 확보
- 파일 수준 링크와 프레임 수준 링크를 모두 보존 (파일 링크: `figmaFileUrl`, 프레임 링크: `figmaUrl`)
- 이 규칙은 digest, SRS, IA, ERD, API, Screen Spec, Design System 등 모든 다운스트림 산출물에 전파

### 1.3 MCP Server Selection

Two Figma MCP servers are supported. The engine detects which is available and selects accordingly.

| Priority | Server | MCP Prefix | Connection | Capabilities |
|---|---|---|---|---|
| **1 (Primary)** | `figma-mcp-go` | `mcp__figma-mcp-go__` | Local — connects to Figma desktop app | Full tool set: granular node scanning, text extraction, variable/style queries, annotations, reactions, screenshots |
| **2 (Fallback)** | Figma Official MCP | `mcp__plugin_figma_figma__` | Remote — REST API via `https://mcp.figma.com/mcp` | Auth-required, REST API-based: file/node read, styles, variables, components, images |

#### Detection Algorithm

```
function selectFigmaServer():
    // 1. Check if figma-mcp-go is available
    if canCallTool("mcp__figma-mcp-go__get_node"):
        return {
            server: "figma-mcp-go",
            prefix: "mcp__figma-mcp-go__",
            capabilities: "full"
        }

    // 2. Fallback to Figma Official MCP (claude.ai)
    if canCallTool("mcp__plugin_figma_figma__authenticate"):
        // Ensure authenticated before proceeding
        authenticate()  // may require user interaction
        return {
            server: "plugin_figma",
            prefix: "mcp__plugin_figma_figma__",
            capabilities: "rest-api"
        }

    // 3. No Figma MCP available
    error("No Figma MCP server detected. Install figma-mcp-go or enable Figma MCP in claude.ai settings.")
```

#### Capability Differences

| Capability | figma-mcp-go | Figma Official MCP |
|---|---|---|
| Node tree traversal | `scan_nodes_by_types`, `scan_text_nodes` (batch, filtered) | `get_file` / `get_node` (full tree, client-side filtering) |
| Screenshots | `get_screenshot` (direct) | `get_images` (rendered via REST API) |
| Variables | `get_variable_defs` (structured) | `get_variables` (REST API response) |
| Styles | `get_styles` (typed: paint, text, effect, grid) | `get_styles` (flat list) |
| Components | `get_local_components` (with metadata) | `get_components` (REST API response) |
| Annotations | `get_annotations` (native) | Not directly supported — fallback to text node scan |
| Prototype reactions | `get_reactions` (per-node) | Not directly supported — limited to prototype links in file data |
| Design context | `get_design_context` (combined) | Not available — compose from get_file + get_styles |
| Token export | `export_tokens` (structured) | Not available — derive from get_variables |
| Authentication | Not required (local) | Required (`authenticate` → `complete_authentication`) |

> **Rule:** All tool references in this document use **short names** (e.g., `get_node`). Prepend the appropriate MCP prefix based on the detected server. See § 5 for the complete tool name mapping.

## 2. Content Type Detection

A single Figma frame can contain multiple content types. The analysis engine scans the frame's node tree and classifies regions by node composition patterns.

### 2.1 Detection Algorithm

```
function detectContentTypes(frameNodeId):
    node = getNode(frameNodeId)
    children = node.children (recursive scan)

    types = []

    // 1. Node type distribution
    textNodes = children.filter(type == "TEXT")
    componentInstances = children.filter(type == "INSTANCE")
    components = children.filter(type == "COMPONENT")
    vectors = children.filter(type == "VECTOR" or type == "LINE")
    frames = children.filter(type == "FRAME")
    rectangles = children.filter(type == "RECTANGLE")
    images = children.filter(fills contain IMAGE type)

    // 2. Pattern matching
    if hasConnectorPattern(vectors, frames):
        types.add("diagram")
    if hasUIComponentPattern(componentInstances, frames):
        types.add("screen-design")
    if hasWireframePattern(rectangles, textNodes, low-fidelity):
        types.add("screen-planning")
    if hasStickyNotePattern(frames, textNodes):
        types.add("annotation")
    if hasSpecificationPattern(textNodes, frames):
        types.add("specification")
    if hasTokenPattern(rectangles, textNodes, grid-layout):
        types.add("design-tokens")
    if hasAssetPattern(components, vectors, images):
        types.add("assets")
    if hasPrototypeReactions(frameNodeId):
        types.add("prototype")

    return types
```

> **`hasSpecificationPattern` Detection:**
> ```
> function hasSpecificationPattern(textNodes, frames):
>     // 기획서/명세서 패턴: 긴 텍스트 블록, 번호 매김, 테이블형 레이아웃, 규칙/조건 키워드
>     longTextNodes = textNodes.filter(t => t.characters.length > 100)
>     numberedPatterns = textNodes.filter(t => t.characters.match(/^\d+[\.\)]/))
>     specKeywords = ["규칙", "조건", "처리", "검증", "공통", "비고", "예외", "필수",
>                      "Rule", "Condition", "Validation", "Process", "Common",
>                      "상태", "전이", "권한", "계산", "기본값", "자동"]
>     keywordHits = textNodes.filter(t => specKeywords.some(k => t.characters.contains(k)))
>
>     return (longTextNodes.length >= 3) or
>            (numberedPatterns.length >= 5) or
>            (keywordHits.length >= 3)
> ```

### 2.2 Content Type Definitions

| Content Type | Detection Signal | Examples |
|---|---|---|
| **screen-design** | High-fidelity UI: INSTANCE nodes referencing design system components, styled frames with fills/strokes, realistic content | Login screen, Dashboard, Settings page |
| **screen-planning** | Low-fidelity layouts: simple rectangles with text labels, placeholder boxes ("Image here"), minimal styling | Wireframe layouts, page structure sketches |
| **diagram** | Connector lines (VECTOR/LINE) linking labeled frames/shapes, flow patterns, decision diamonds | User flow, IA diagram, ERD, process flow |
| **annotation** | Sticky notes (colored rectangles + text), comment markers, callout frames, numbered labels pointing to elements | Design rationale, decisions, review comments |
| **specification** | Dense text blocks with business rules, numbered conditions, domain-specific terms, processing procedures, state descriptions, validation rules. Often found alongside screen-design/screen-planning as supplementary planning content | 비즈니스 규칙, 처리방법, 공통규칙, 도메인 규칙, 상태 전이, 검증 규칙, 권한 규칙, 결정사항, 기획 노트 |
| **design-tokens** | Grid-arranged color swatches, typography samples, spacing demonstrations, systematic naming in text nodes | Color palette, type scale, spacing guide |
| **assets** | Standalone COMPONENT definitions, icon sets, logo variations, illustration elements | Icon library, logo variants, illustrations |
| **prototype** | Frames with reactions (onClick, onHover, onDrag), navigation connections between frames | Interactive prototype, micro-interaction spec |

### 2.3 Mixed Frame Handling

Most real-world frames contain **2-4 content types** simultaneously. The engine does NOT force a single classification. Instead:

1. Identify all present content types
2. Extract each type using its dedicated strategy (Section 3)
3. Merge extractions into a single digest with cross-references

Example: A "Login Screen Spec" frame might contain:
- `screen-design` — the actual login UI
- `annotation` — sticky notes explaining validation rules
- `diagram` — a user flow showing login → dashboard transition
- `prototype` — click reactions linking to the next screen

All four are extracted and cross-referenced.

## 3. Extraction Strategies

Each content type uses specific MCP tools for optimal extraction.

### 3.1 Screen Design Extraction

**Goal:** Extract component structure, layout hierarchy, visual properties

**MCP Tools:**
1. `get_node` — Retrieve frame structure with full property details
2. `get_design_context` — Get design context including styles and layout
3. `scan_nodes_by_types` — Filter for INSTANCE, FRAME, TEXT nodes
4. `get_local_components` — Identify component references
5. `get_styles` — Extract applied styles (color, text, effect)
6. `get_screenshot` — Visual capture for reference

**Extraction Output:**
```json
{
  "type": "screen-design",
  "screenName": "Login Screen",
  "layout": {
    "direction": "vertical",
    "padding": { "top": 64, "right": 32, "bottom": 64, "left": 32 },
    "gap": 24,
    "width": 1440,
    "height": 900
  },
  "components": [
    {
      "name": "Input / Email",
      "type": "INSTANCE",
      "componentRef": "Input/Text",
      "position": { "x": 0, "y": 120 },
      "size": { "width": 360, "height": 48 },
      "properties": { "placeholder": "Enter email", "variant": "default" }
    }
  ],
  "appliedStyles": ["Primary/500", "Body/Regular", "Shadow/sm"]
}
```

### 3.2 Screen Planning (Wireframe) Extraction

**Goal:** Extract layout structure, placeholder content, information hierarchy

**MCP Tools:**
1. `get_node` — Frame structure
2. `scan_nodes_by_types` — FRAME, RECTANGLE, TEXT nodes
3. `scan_text_nodes` — All text content for labels and placeholders
4. `get_screenshot` — Visual capture

**Extraction Output:**
```json
{
  "type": "screen-planning",
  "screenName": "Dashboard Wireframe",
  "sections": [
    {
      "name": "Header",
      "position": "top",
      "elements": ["Logo", "Navigation", "User Menu"]
    },
    {
      "name": "Main Content",
      "position": "center",
      "elements": ["Stats Cards (4x)", "Chart Area", "Recent Activity List"]
    }
  ],
  "placeholders": ["[Chart]", "[User Avatar]", "[Notification Badge]"]
}
```

### 3.3 Diagram Extraction

**Goal:** Extract nodes, connections, flow direction, decision points

**MCP Tools:**
1. `scan_nodes_by_types` — VECTOR, LINE, FRAME, TEXT, ELLIPSE
2. `scan_text_nodes` — Labels on nodes and connectors
3. `get_annotations` — Any attached annotations
4. `get_screenshot` — Visual capture for complex diagrams

**Extraction Output:**
```json
{
  "type": "diagram",
  "diagramType": "user-flow",
  "nodes": [
    { "id": "n1", "label": "Login Page", "shape": "rectangle" },
    { "id": "n2", "label": "Valid Credentials?", "shape": "diamond" },
    { "id": "n3", "label": "Dashboard", "shape": "rectangle" },
    { "id": "n4", "label": "Error Message", "shape": "rectangle" }
  ],
  "edges": [
    { "from": "n1", "to": "n2", "label": "Submit" },
    { "from": "n2", "to": "n3", "label": "Yes" },
    { "from": "n2", "to": "n4", "label": "No" }
  ]
}
```

### 3.4 Annotation & Planning Content Extraction

**Goal:** Figma 프레임에 포함된 모든 기획·설계 텍스트를 빠짐없이 추출하고 카테고리별로 분류한다. 기업용 시스템 Figma에는 단순 sticky note뿐 아니라 비즈니스 로직, 결정사항, 도메인 규칙, 처리방법, 공통규칙, 검증규칙, 권한규칙, 상태전이 등 화면기획서 수준의 풍부한 정보가 텍스트로 기재되어 있다. 이 모든 내용이 digest에 구조화되어 보존되어야 한다.

**MCP Tools:**
1. `scan_text_nodes` — 프레임 내 **모든** 텍스트 노드 수집 (UI 라벨 제외 필터링은 후처리)
2. `get_annotations` — Figma native annotations
3. `scan_nodes_by_types` — FRAME, RECTANGLE, TEXT, SECTION, GROUP 노드 탐색
4. `get_node` — 공간적 컨텍스트 (어떤 UI 요소 근처에 위치하는지)
5. `get_screenshot` — 시각적 참조 (텍스트 추출 보완용)

**Step 1: 전체 텍스트 수집**

프레임 내 모든 TEXT 노드를 수집한 후, 아래 기준으로 **UI 라벨**과 **기획 텍스트**를 분리:

```
function classifyTextNode(textNode, parentNode):
    // UI 라벨: INSTANCE 내부, 짧은 텍스트(< 30자), 버튼/입력/메뉴 컴포넌트 자식
    if parentNode.type == "INSTANCE" and textNode.characters.length < 30:
        return "ui-label"

    // 기획 텍스트: 긴 텍스트, INSTANCE 외부, 설명적 내용
    if textNode.characters.length >= 30:
        return "planning-text"

    // 중간 길이: 위치 기반 판단 (UI 영역 외부면 planning-text)
    if isOutsideUIBounds(textNode, mainScreenFrame):
        return "planning-text"

    return "ui-label"
```

**Step 2: 기획 텍스트 카테고리 분류**

수집된 planning-text를 내용 기반으로 아래 카테고리로 분류:

| Category | Detection Keywords/Patterns | Examples |
|---|---|---|
| `business-rule` | "규칙", "Rule", "~인 경우", "~할 때", "조건:", "IF/THEN", 계산식, 공식 | "연체이자 = 미납금 × 일이율 × 경과일수" |
| `decision` | "결정", "Decision", "확정", "→ 채택", "변경이력", "[QA]", "[확인]" | "OAuth2 방식으로 확정 (2026-03-15)" |
| `domain-rule` | "상태", "전이", "코드", "분류", "체계", 상태명 나열, 코드표 | "계약상태: 신청→심사→승인→해약" |
| `processing-rule` | "처리", "절차", "Process", "Step", 번호 매김 절차, "~한다" | "1. 신청접수 2. 자격심사 3. 승인처리" |
| `common-rule` | "공통", "전역", "Global", "모든 화면", "일괄 적용" | "모든 금액 필드는 천단위 콤마 표시" |
| `validation-rule` | "검증", "Validation", "필수", "형식", "범위", "중복체크" | "이메일 형식 검증, 중복 불허" |
| `permission-rule` | "권한", "역할", "Role", "접근", "제한", "관리자만" | "해약 처리는 팀장 이상만 가능" |
| `state-transition` | 상태 → 상태 패턴, "전이", "Lifecycle", 매트릭스, 상태 다이어그램 | "대기→배정→진행→완료→마감" |
| `ui-specification` | "UI", "화면", "표시", "숨김", "비활성", "기본값", "자동계산" | "해약사유 필드는 해약 상태일 때만 표시" |
| `data-rule` | "데이터", "기본값", "자동", "참조", "연계", "마스터" | "담당자 기본값 = 로그인 사용자" |
| `screen-description` | 화면 목적, 개요, 설명, 화면코드(Sxxxx), 화면명 | "S2030101: 선불상조 가입조회 현황" |
| `note` | 위 카테고리에 해당하지 않는 일반 메모/비고 | "추후 2차 개발 시 추가 예정" |

**Step 3: 공간적 연관 매핑**

각 기획 텍스트가 **어떤 화면/컴포넌트에 관한 것인지** 공간 좌표 기반으로 매핑:

```
function mapToNearestScreen(textNode, screenFrames):
    // 1. textNode가 특정 screen frame 내부에 위치하면 해당 화면
    for screen in screenFrames:
        if isInsideBounds(textNode, screen):
            return screen.name

    // 2. 외부이면 가장 가까운 화면 프레임과 연결
    nearest = findNearestFrame(textNode.position, screenFrames)
    if distance(textNode, nearest) < threshold:
        return nearest.name

    // 3. 특정 화면과 무관하면 "global" (공통)
    return "global"
```

**Extraction Output:**
```json
{
  "type": "annotation",
  "notes": [
    {
      "content": "Password must be 8+ chars with at least one special character",
      "category": "validation-rule",
      "nearScreen": "Login Screen",
      "nearElement": "Password Input",
      "figmaNodeId": "1234:5678"
    },
    {
      "content": "Decision: Use OAuth2 instead of custom auth (확정 2026-03-15)",
      "category": "decision",
      "nearScreen": "Login Screen",
      "nearElement": "Login Form",
      "figmaNodeId": "1234:5680"
    }
  ],
  "planningContent": {
    "businessRules": [...],
    "decisions": [...],
    "domainRules": [...],
    "processingRules": [...],
    "commonRules": [...],
    "validationRules": [...],
    "permissionRules": [...],
    "stateTransitions": [...],
    "uiSpecifications": [...],
    "dataRules": [...],
    "screenDescriptions": [...]
  }
}
```

> **CRITICAL:** 기획 텍스트는 **하나도 누락 없이** 추출한다. 카테고리 분류가 모호한 경우에도 `note`로 분류하여 반드시 포함. 짧은 텍스트라도 UI 라벨이 아닌 기획 메모라면 추출해야 한다.

### 3.5 Design Token Extraction

**Goal:** Extract color palette, typography scale, spacing values, other design tokens

**MCP Tools:**
1. `get_variable_defs` — Figma Variables (colors, numbers, strings, booleans)
2. `get_styles` — Local paint styles, text styles, effect styles, grid styles
3. `export_tokens` — Export design tokens in structured format
4. `scan_nodes_by_types` — Token swatch layouts (RECTANGLE grids with TEXT labels)
5. `get_fonts` — Font family and weight information

**Extraction Output:**
```json
{
  "type": "design-tokens",
  "variables": {
    "colors": [
      { "name": "Primary/500", "value": "#3B82F6", "collection": "Brand" },
      { "name": "Gray/100", "value": "#F3F4F6", "collection": "Neutral" }
    ],
    "spacing": [
      { "name": "space-1", "value": 4, "unit": "px" },
      { "name": "space-2", "value": 8, "unit": "px" }
    ],
    "radius": [
      { "name": "radius-sm", "value": 4, "unit": "px" }
    ]
  },
  "styles": {
    "paint": [
      { "name": "Primary/500", "type": "SOLID", "color": "#3B82F6" }
    ],
    "text": [
      { "name": "Heading/H1", "fontFamily": "Inter", "fontSize": 36, "fontWeight": 700, "lineHeight": 1.2 }
    ],
    "effect": [
      { "name": "Shadow/sm", "type": "DROP_SHADOW", "offset": { "x": 0, "y": 1 }, "blur": 3, "spread": 0 }
    ]
  },
  "fonts": ["Inter", "Fira Code"]
}
```

### 3.6 Asset Extraction

**Goal:** Inventory reusable assets — icons, logos, illustrations

**MCP Tools:**
1. `get_local_components` — All component definitions in the file
2. `scan_nodes_by_types` — COMPONENT, COMPONENT_SET nodes
3. `get_node` — Individual asset details

**Extraction Output:**
```json
{
  "type": "assets",
  "icons": [
    { "name": "icon/arrow-right", "size": "24x24", "variants": ["default", "filled"] },
    { "name": "icon/search", "size": "24x24", "variants": ["default"] }
  ],
  "logos": [
    { "name": "logo/full", "size": "200x48" },
    { "name": "logo/icon-only", "size": "48x48" }
  ],
  "illustrations": [
    { "name": "empty-state/no-data", "size": "320x240" }
  ]
}
```

### 3.7 Prototype Extraction

**Goal:** Extract screen-to-screen navigation flow, interaction triggers, transitions

**MCP Tools:**
1. `get_reactions` — All prototype reactions (triggers + actions)
2. `get_node` — Source/destination frame identification
3. `scan_text_nodes` — Frame labels for screen naming

**Extraction Output:**
```json
{
  "type": "prototype",
  "flows": [
    {
      "from": "Login Screen",
      "to": "Dashboard",
      "trigger": "onClick",
      "target": "Submit Button",
      "transition": { "type": "SLIDE_IN", "direction": "LEFT", "duration": 300 }
    },
    {
      "from": "Dashboard",
      "to": "Settings",
      "trigger": "onClick",
      "target": "Settings Icon",
      "transition": { "type": "PUSH", "direction": "LEFT", "duration": 200 }
    }
  ],
  "startingFrame": "Login Screen"
}
```

### 3.8 Specification Content Extraction

**Goal:** Figma 프레임에 포함된 기획서·명세서 수준의 상세 텍스트를 구조화하여 추출. § 3.4에서 분류된 `planningContent`를 최종 digest 필드로 정규화한다.

> **왜 별도 전략이 필요한가:** 기업용 시스템 Figma는 단순 UI 디자인 도구가 아닌 **기획 문서** 역할을 겸한다. 한 페이지에 화면 설계 + 비즈니스 규칙 + 처리방법 + 결정사항 + 공통규칙이 혼재한다. 이 모든 기획 정보가 downstream(SRS, Screen Spec, Wireframe)에서 활용되려면 digest 단계에서 빠짐없이 구조화되어야 한다.

**의존:** § 3.4 Annotation & Planning Content Extraction 결과 사용

#### 3.8.1 Business Rules (비즈니스 규칙)

조건부 로직, 계산식, 판단 기준 등 시스템이 수행하는 비즈니스 로직.

```json
{
  "id": "BR-001",
  "title": "연체이자 계산",
  "description": "연체이자 = 미납금액 × 일이율(0.025%) × 연체경과일수. 소수점 이하 절사.",
  "condition": "납부기한 경과 시",
  "action": "연체이자 자동 산정 후 다음 청구에 합산",
  "scope": "screen",
  "relatedScreens": ["S2030101"],
  "figmaNodeId": "2791:66100",
  "figmaUrl": "https://www.figma.com/design/...?node-id=2791-66100"
}
```

#### 3.8.2 Decisions (결정사항)

기획/설계 과정에서 확정된 의사결정. 대안과 선택 이유 포함.

```json
{
  "id": "DEC-001",
  "title": "OAuth2 인증 방식 채택",
  "description": "자체 인증 대신 OAuth2 방식으로 확정",
  "rationale": "보안 감사 요구사항 충족 + SSO 확장성",
  "decidedAt": "2026-03-15",
  "alternatives": ["자체 JWT 인증", "SAML"],
  "relatedScreens": ["S1010101"],
  "figmaNodeId": "1234:5680"
}
```

#### 3.8.3 Domain Rules (도메인 규칙)

해당 도메인(업종/업무)에 특화된 규칙. 상태 체계, 코드 분류, 업무 용어 정의 등.

```json
{
  "id": "DR-001",
  "title": "상조 계약 상태 체계",
  "description": "계약 라이프사이클: 가입상담 → 계약체결 → 납부중 → 만기완료. 예외: 해약(중도), 연체(조건부)",
  "domain": "계약관리 > 상조",
  "type": "state-system",
  "states": ["가입상담", "계약체결", "납부중", "만기완료", "해약", "연체"],
  "relatedScreens": ["S2030101", "S2030201"],
  "figmaNodeId": "2791:66150"
}
```

#### 3.8.4 Processing Rules (처리 규칙)

데이터 처리 절차, 배치 처리 로직, 연쇄 API 호출 등.

```json
{
  "id": "PR-001",
  "title": "선불상조 가입상담 → 계약 전환 처리",
  "trigger": "상담사가 '계약전환' 버튼 클릭",
  "steps": [
    "1. 가입상담 정보 유효성 검증",
    "2. 중복 계약 체크 (동일 고객 + 동일 상품)",
    "3. 계약 생성 (상태: 계약체결)",
    "4. 상담 건 상태 → '전환완료'로 변경",
    "5. 담당 모집인에게 알림 발송"
  ],
  "errorHandling": "중복 계약 발견 시 모달로 기존 계약 정보 표시, 강제 진행 여부 확인",
  "relatedScreens": ["S2030101"],
  "figmaNodeId": "2791:66200"
}
```

#### 3.8.5 Common Rules (공통 규칙)

여러 화면에 일괄 적용되는 전역 규칙.

```json
{
  "id": "CMR-001",
  "title": "금액 필드 표시 규칙",
  "description": "모든 금액 필드는 천단위 콤마 표시, 음수는 빨간색, 단위(원) 접미",
  "applicableScreens": "all",
  "figmaNodeId": "2791:66050"
}
```

#### 3.8.6 State Transitions (상태 전이)

엔티티의 상태 전이 매트릭스. Figma에서 상태 라벨 그룹/매트릭스로 시각화된 것을 구조화.

```json
{
  "entity": "상조계약",
  "states": ["가입상담", "계약체결", "1회차납부", "납부중", "만기완료", "해약", "연체"],
  "transitions": [
    { "from": "가입상담", "to": "계약체결", "trigger": "계약전환 처리", "condition": "상담 유효성 통과" },
    { "from": "계약체결", "to": "1회차납부", "trigger": "첫 납부 완료", "condition": null },
    { "from": "납부중", "to": "연체", "trigger": "납부기한 N일 경과", "condition": "자동 배치" },
    { "from": "연체", "to": "납부중", "trigger": "연체금 완납", "condition": null },
    { "from": "납부중", "to": "해약", "trigger": "해약 신청 + 팀장 승인", "condition": "환급금 정산 완료" }
  ],
  "relatedScreens": ["S2030101", "S2030201"],
  "figmaNodeId": "2117917190"
}
```

#### 3.8.7 Validation Rules (검증 규칙)

필드별 유효성 검증 규칙. 단순 required 외에 교차 검증, 조건부 필수, 비즈니스 검증.

```json
{
  "id": "VR-001",
  "field": "해약사유",
  "rule": "conditionalRequired",
  "condition": "계약상태 == '해약'",
  "message": "해약 처리 시 해약사유는 필수",
  "relatedScreens": ["S2030201"],
  "figmaNodeId": "2791:66300"
}
```

#### 3.8.8 Permission Rules (권한 규칙)

역할 기반 접근 제어, 기능별 권한 제한.

```json
{
  "id": "PMR-001",
  "title": "해약 처리 권한",
  "description": "해약 처리는 팀장(TL) 이상 직급만 실행 가능. 일반 상담사는 해약 신청만 가능.",
  "roles": ["TL", "Manager", "Admin"],
  "action": "계약 해약 처리",
  "relatedScreens": ["S2030201"],
  "figmaNodeId": "2791:66350"
}
```

#### 3.8.9 UI Specifications (UI 상세 사양)

컴포넌트 동작 방식, 조건부 표시/숨김, 기본값, 자동계산 등 UI 동작 명세.

```json
{
  "id": "UI-001",
  "title": "해약사유 필드 조건부 표시",
  "description": "계약상태가 '해약'일 때만 해약사유 셀렉트박스와 해약일자 필드 표시. 그 외 상태에서는 숨김.",
  "type": "conditional-visibility",
  "condition": "contractStatus == 'CANCEL'",
  "affectedComponents": ["해약사유 Select", "해약일자 DatePicker"],
  "relatedScreens": ["S2030201"],
  "figmaNodeId": "2791:66400"
}
```

#### 3.8.10 Data Rules (데이터 규칙)

기본값, 자동계산, 참조 데이터, 연계 조회 등.

```json
{
  "id": "DAT-001",
  "title": "담당자 기본값 자동 설정",
  "description": "신규 계약 등록 시 담당자 필드는 로그인 사용자로 자동 세팅. 변경 가능.",
  "type": "auto-fill",
  "field": "담당자",
  "defaultValue": "currentUser",
  "editable": true,
  "relatedScreens": ["S2030201"],
  "figmaNodeId": "2791:66450"
}
```

#### 3.8.11 Screen Descriptions (화면별 상세 설명)

화면 목적, 업무 컨텍스트, 화면 간 관계, 사용 시나리오 등 화면별 기획 설명.

```json
{
  "code": "S2030101",
  "name": "선불상조 가입조회 현황",
  "kind": "list",
  "description": "선불상조 가입상담 신청 건을 포함한 상조 계약을 종합 조회하는 화면. 가입상담 → 가입조회 현황 기반의 캠페인 실행 현황/결과와 연계.",
  "purpose": "계약 라이프사이클 전체 상태를 한 화면에서 모니터링하며, 상담사별 실적·전환율 추적",
  "searchContext": "가입상담(선계약) → 계약 체결 → 납부 중 → 만기/해약 단계별 조회",
  "linkedScreens": [
    { "code": "S2030201", "name": "계약 상세", "relation": "행 클릭 → 상세 이동" },
    { "code": "S2030301", "name": "캠페인 실행 현황", "relation": "탭 전환" }
  ],
  "figmaUrl": "https://www.figma.com/design/FK8YQNPvK7A504JxRhHeB1?node-id=2791-66049",
  "figmaNodeId": "2791:66049"
}
```

#### 3.8.12 Extraction Priority

텍스트 추출 시 아래 우선순위를 따른다:

| Priority | Category | Reason |
|---|---|---|
| 1 | `business-rule`, `processing-rule` | 개발 시 로직 구현에 직접 필요 |
| 2 | `state-transition`, `domain-rule` | 데이터 모델·상태 설계에 필수 |
| 3 | `validation-rule`, `permission-rule` | 보안·무결성에 영향 |
| 4 | `ui-specification`, `data-rule` | UI 구현 상세 |
| 5 | `decision`, `common-rule` | 설계 근거·전역 정책 |
| 6 | `screen-description`, `note` | 컨텍스트·참고 |

> **모든 카테고리는 누락 없이 추출한다.** 우선순위는 분류 모호 시 상위 카테고리 우선 적용을 위한 것이지 하위 카테고리 생략을 의미하지 않는다.

## 4. Analysis Pipeline

### 4.1 Full Pipeline (Ingest Context)

When a Figma link is processed during `/u-ingest`:

```
0. MCP Server Detection (§ 1.3)
   ├─ Check figma-mcp-go availability → use if present
   ├─ Fallback to Figma Official MCP (mcp.figma.com) → authenticate if needed
   └─ Set server prefix for all subsequent tool calls

1. Parse Figma URL
   ├─ Extract file_key, node_id
   └─ Determine scope: file / page / frame

2. Authenticate (Figma Official MCP only) & Fetch Structure
   ├─ get_node(file_key, node_id) → frame tree
   └─ get_screenshot(node_id) → visual reference

3. Content Type Detection
   ├─ scan_nodes_by_types → node distribution
   ├─ scan_text_nodes → text content inventory
   └─ Classify content types (§ 2.1 algorithm)

4. Per-Type Extraction (parallel where possible)
   ├─ screen-design → § 3.1
   ├─ screen-planning → § 3.2
   ├─ diagram → § 3.3
   ├─ annotation & planning content → § 3.4 (모든 텍스트 수집 + 카테고리 분류)
   ├─ design-tokens → § 3.5
   ├─ assets → § 3.6
   └─ prototype → § 3.7

4b. Specification Structuring (§ 3.8)
   ├─ § 3.4의 planningContent를 정규화
   ├─ businessRules, decisions, domainRules, processingRules 등 구조화
   ├─ screenDescriptions에 화면별 상세 설명 매핑
   ├─ stateTransitions 매트릭스 구성
   └─ 공간적 연관으로 화면↔규칙 매핑

5. Digest Generation
   ├─ Map extractions to digest schema fields (§ 4.3 확장 포맷)
   ├─ Cross-reference related extractions
   ├─ screenDescriptions ↔ businessRules ↔ stateTransitions 간 상호참조
   ├─ Set figmaMeta.figmaUrl (deep link with node-id) and figmaMeta.figmaFileUrl
   └─ Write digest.json (§ 4.3)

6. Index Update
   ├─ Add to _index.json with source_type: "figma-frame"
   └─ Update data/links.json
```

### 4.2 Design System Context

When Figma is analyzed during `/u-design` (design system generation):

```
0. MCP Server Detection (§ 1.3)
   ├─ Select figma-mcp-go or Figma Official MCP
   └─ Authenticate if using Figma Official MCP

1. Detect Figma Variables & Styles
   ├─ get_variable_defs → all variable collections
   │   (Figma Official MCP: get_variables)
   ├─ get_styles → paint, text, effect, grid styles
   ├─ export_tokens → structured token export
   │   (Figma Official MCP: derive from get_variables)
   └─ get_fonts → font inventory
       (Figma Official MCP: derive from text styles)

2. Map to Design System Tokens
   ├─ Figma Variables → CSS custom properties
   │   ├─ Color variables → --color-{name}-{shade}
   │   ├─ Number variables → --space-{n}, --radius-{name}
   │   └─ String variables → --font-family-{name}
   ├─ Paint styles → DS-010~DS-040 color tokens
   ├─ Text styles → DS-050 typography tokens
   └─ Effect styles → DS-080 shadow tokens

3. Map to Design System Components
   ├─ get_local_components → component inventory
   ├─ Match Figma components to CMP-xxx IDs
   │   ├─ Button variants → CMP-010
   │   ├─ Input variants → CMP-020
   │   └─ ... (per component taxonomy)
   └─ Extract variant/size/state matrix per component

4. Feed into HTML-First Pipeline
   ├─ Token values → :root CSS variables
   ├─ Component specs → .ds-* class definitions
   └─ Override SRS/IA-derived defaults with Figma actuals
```

### 4.3 Digest Output Format

Figma-sourced digests follow the standard `digest.schema.json` with extended metadata. **기업용 시스템 Figma에서는 `planningContent` 블록이 digest의 핵심**으로, 비즈니스 로직·도메인 규칙·처리방법 등 화면기획서 수준의 상세 정보를 구조화하여 보존한다.

```json
{
  "sourceFile": "figma://file_key/node_id",
  "sourceType": "figma-frame",
  "sourceHash": "sha256:{hash-of-serialized-node-tree}",
  "analyzedAt": "2026-04-12T10:00:00Z",
  "figmaMeta": {
    "fileKey": "abc123",
    "fileName": "Project Design",
    "nodeId": "1234:5678",
    "nodeName": "Login Screen Spec",
    "pageId": "0:1",
    "pageName": "Screens",
    "figmaUrl": "https://www.figma.com/design/abc123/Project-Design?node-id=1234:5678",
    "figmaFileUrl": "https://www.figma.com/design/abc123/Project-Design",
    "contentTypes": ["screen-design", "annotation", "specification", "prototype"],
    "screenshotPath": "data/digest/_screenshots/abc123_1234-5678.png"
  },
  "domain": "계약관리 > 상조 계약관리 > 상조 계약조회",
  "summary": "선불상조 가입상담 신청 건을 포함한 상조 계약을 종합 조회...",
  "keywords": ["상조", "계약관리", "가입상담", "캠페인", "계약상태"],

  "screenDescriptions": [
    {
      "code": "S2030101",
      "name": "선불상조 가입조회 현황",
      "kind": "list",
      "description": "선불상조 가입상담 신청 건을 포함한 상조 계약을 종합 조회. 캠페인 실행 현황/결과와 연계.",
      "purpose": "계약 라이프사이클 상태를 모니터링, 상담사별 실적·전환율 추적",
      "searchContext": "가입상담(선계약) → 계약 체결 → 납부 중 → 만기/해약 단계별 조회",
      "linkedScreens": [
        { "code": "S2030201", "name": "B2C계약정보 상세", "relation": "행 클릭 → 상세 전이" },
        { "code": "S2030301", "name": "캠페인 실행 현황/결과", "relation": "탭 전환" }
      ],
      "components": [
        { "name": "검색 조건 영역", "type": "Form.Horizontal", "fields": ["기간", "상태", "담당자", "캠페인"] },
        { "name": "가입조회 그리드", "type": "Table.Sortable", "columns": ["계약번호", "고객명", "상태", "납부현황", "담당자"] },
        { "name": "상태 매트릭스", "type": "StatCard", "description": "계약 상태별 건수 시각화" }
      ],
      "figmaUrl": "https://www.figma.com/design/FK8YQNPvK7A504JxRhHeB1?node-id=2791-66049",
      "figmaNodeId": "2791:66049"
    }
  ],

  "businessRules": [
    {
      "id": "BR-001",
      "title": "연체이자 계산",
      "description": "연체이자 = 미납금액 × 일이율(0.025%) × 연체경과일수. 소수점 이하 절사.",
      "condition": "납부기한 경과 시",
      "action": "연체이자 자동 산정 후 다음 청구에 합산",
      "scope": "screen",
      "relatedScreens": ["S2030101"],
      "figmaNodeId": "2791:66100",
      "figmaUrl": "https://www.figma.com/design/...?node-id=2791-66100"
    }
  ],

  "decisions": [
    {
      "id": "DEC-001",
      "title": "캠페인 실적 연계 방식",
      "description": "캠페인 실행 결과를 계약 목록과 동일 화면 탭으로 통합 표시",
      "rationale": "상담사가 캠페인→계약 전환을 한 화면에서 추적할 수 있도록",
      "decidedAt": "2026-03-20",
      "relatedScreens": ["S2030101"],
      "figmaNodeId": "2791:66120"
    }
  ],

  "domainRules": [
    {
      "id": "DR-001",
      "title": "상조 계약 상태 체계",
      "description": "계약 라이프사이클: 가입상담 → 계약체결 → 납부중 → 만기완료. 예외: 해약, 연체",
      "domain": "계약관리 > 상조",
      "type": "state-system",
      "states": ["가입상담", "계약체결", "납부중", "만기완료", "해약", "연체"],
      "relatedScreens": ["S2030101"],
      "figmaNodeId": "2791:66150"
    }
  ],

  "processingRules": [
    {
      "id": "PR-001",
      "title": "가입상담 → 계약 전환 처리",
      "trigger": "상담사가 '계약전환' 버튼 클릭",
      "steps": [
        "1. 가입상담 정보 유효성 검증",
        "2. 중복 계약 체크 (동일 고객 + 동일 상품)",
        "3. 계약 생성 (상태: 계약체결)",
        "4. 상담 건 상태 → '전환완료'로 변경",
        "5. 담당 모집인에게 알림 발송"
      ],
      "errorHandling": "중복 계약 발견 시 모달로 기존 계약 정보 표시, 강제 진행 여부 확인",
      "relatedScreens": ["S2030101"],
      "figmaNodeId": "2791:66200"
    }
  ],

  "commonRules": [
    {
      "id": "CMR-001",
      "title": "금액 필드 표시 규칙",
      "description": "모든 금액 필드는 천단위 콤마 표시, 음수는 빨간색, 단위(원) 접미",
      "applicableScreens": "all",
      "figmaNodeId": "2791:66050"
    }
  ],

  "stateTransitions": [
    {
      "entity": "상조계약",
      "states": ["가입상담", "계약체결", "납부중", "만기완료", "해약", "연체"],
      "transitions": [
        { "from": "가입상담", "to": "계약체결", "trigger": "계약전환 처리", "condition": "상담 유효성 통과" },
        { "from": "납부중", "to": "연체", "trigger": "납부기한 N일 경과", "condition": "자동 배치" },
        { "from": "연체", "to": "납부중", "trigger": "연체금 완납", "condition": null },
        { "from": "납부중", "to": "해약", "trigger": "해약 신청 + 팀장 승인", "condition": "환급금 정산 완료" }
      ],
      "relatedScreens": ["S2030101", "S2030201"],
      "figmaNodeId": "2117917190"
    }
  ],

  "validationRules": [
    {
      "id": "VR-001",
      "field": "해약사유",
      "rule": "conditionalRequired",
      "condition": "계약상태 == '해약'",
      "message": "해약 처리 시 해약사유는 필수",
      "relatedScreens": ["S2030201"],
      "figmaNodeId": "2791:66300"
    }
  ],

  "permissionRules": [
    {
      "id": "PMR-001",
      "title": "해약 처리 권한",
      "description": "해약 처리는 팀장(TL) 이상만 실행 가능",
      "roles": ["TL", "Manager", "Admin"],
      "action": "계약 해약 처리",
      "relatedScreens": ["S2030201"],
      "figmaNodeId": "2791:66350"
    }
  ],

  "uiSpecifications": [
    {
      "id": "UI-001",
      "title": "해약사유 조건부 표시",
      "description": "해약 상태일 때만 해약사유 셀렉트 + 해약일자 필드 표시",
      "type": "conditional-visibility",
      "condition": "contractStatus == 'CANCEL'",
      "affectedComponents": ["해약사유 Select", "해약일자 DatePicker"],
      "relatedScreens": ["S2030201"],
      "figmaNodeId": "2791:66400"
    }
  ],

  "dataRules": [
    {
      "id": "DAT-001",
      "title": "담당자 기본값",
      "description": "신규 계약 등록 시 담당자 = 로그인 사용자 (변경 가능)",
      "type": "auto-fill",
      "field": "담당자",
      "defaultValue": "currentUser",
      "relatedScreens": ["S2030201"],
      "figmaNodeId": "2791:66450"
    }
  ],

  "requirements": [
    {
      "id": "REQ-001",
      "type": "functional",
      "title": "상조 계약 종합 조회",
      "description": "가입상담·계약·납부·해약 전 라이프사이클 단계별 조회",
      "priority": "Must",
      "figmaSource": "screen-design S2030101"
    }
  ],
  "constraints": [],
  "domainTerms": [
    { "term": "선불상조", "definition": "납입 완료 후 서비스 제공받는 상조 상품 형태" },
    { "term": "모집인", "definition": "상조 가입 상담 담당자 (영업 채널)" }
  ],
  "stakeholders": [],
  "painPoints": [],
  "workflows": [
    {
      "name": "선불상조 가입조회",
      "steps": ["검색조건 입력", "가입조회 현황 목록 표시", "행 클릭 → B2C계약정보 상세", "캠페인 실행 현황 탭"],
      "figmaSource": "diagram extraction"
    }
  ],

  "crossRefs": [
    { "to": "B2C 계약관리 계약고객조회", "relation": "상세 전이", "figmaPage": "p10" },
    { "to": "캠페인관리", "relation": "캠페인 실적 연계", "figmaPage": "p17" },
    { "to": "모집인 관리", "relation": "가입상담 담당자", "figmaPage": "p15" }
  ],

  "acceptanceHints": [
    "상조 계약조회는 가입상담·캠페인 실행과 연계되어 상담부터 체결까지 이력 확인 가능",
    "계약 상태 라벨(정상/연체/해약/최고/상담중 등)은 상태별 컬러·아이콘 기준 통일"
  ],

  "designTokens": {},
  "screenSpecs": {},
  "assets": {}
}
```

### 4.3.1 Digest Field Reference

| Field | Type | Required | Description |
|---|---|---|---|
| `figmaMeta` | object | Yes | Figma 원본 메타데이터 (URL, nodeId, contentTypes 등) |
| `domain` | string | Yes | 도메인 경로 (대분류 > 중분류 > 소분류) |
| `screenDescriptions` | array | Yes | 화면별 상세 설명 — code, name, kind, purpose, searchContext, components, linkedScreens |
| `businessRules` | array | Yes* | 비즈니스 규칙 — 계산식, 조건부 로직, 판단 기준 |
| `decisions` | array | Yes* | 결정사항 — 기획/설계 확정 사항과 근거 |
| `domainRules` | array | Yes* | 도메인 규칙 — 상태 체계, 코드 분류, 업무 특수 규칙 |
| `processingRules` | array | Yes* | 처리 규칙 — 절차, 배치, 연쇄 처리 |
| `commonRules` | array | Yes* | 공통 규칙 — 전역 적용 규칙 |
| `stateTransitions` | array | Yes* | 상태 전이 매트릭스 — 엔티티별 상태 머신 |
| `validationRules` | array | Yes* | 검증 규칙 — 교차 검증, 조건부 필수 |
| `permissionRules` | array | Yes* | 권한 규칙 — 역할 기반 접근 제어 |
| `uiSpecifications` | array | Yes* | UI 사양 — 조건부 표시, 자동계산, 동작 명세 |
| `dataRules` | array | Yes* | 데이터 규칙 — 기본값, 참조, 연계 |
| `crossRefs` | array | Yes* | 타 화면/기능 참조 — 화면 간 이동, 연계 |
| `acceptanceHints` | array | Yes* | 인수 기준 힌트 — Figma에서 도출한 검증 포인트 |
| `requirements` | array | Yes* | 기능 요구사항 (기존) |
| `constraints` | array | Yes* | 제약조건 (기존) |
| `domainTerms` | array | Yes* | 도메인 용어 (기존) |
| `workflows` | array | Yes* | 워크플로우 (기존) |

> `*` = 배열이 비어있을 수 있으나 필드 자체는 항상 포함. Figma에 해당 내용이 없으면 빈 배열 `[]`.

### 4.3.2 Planning Content Completeness Rule

> **CRITICAL — 기획 정보 완전성:**
>
> Figma 프레임에서 추출 가능한 기획 텍스트는 **하나도 누락 없이** digest에 포함되어야 한다. 이 digest는 SRS, Screen Spec, Wireframe 등 모든 다운스트림 산출물의 **유일한 소스**가 되므로, digest에서 누락된 정보는 이후 단계에서 복구할 수 없다.
>
> 추출 완전성 체크리스트:
> 1. 화면 설명 텍스트 → `screenDescriptions[].description`, `purpose`, `searchContext`
> 2. 조건/규칙 텍스트 → `businessRules`, `domainRules`, `validationRules`
> 3. 절차/처리 텍스트 → `processingRules`
> 4. 상태 라벨/매트릭스 → `stateTransitions`, `domainRules`
> 5. 권한/역할 텍스트 → `permissionRules`
> 6. UI 동작 텍스트 → `uiSpecifications`
> 7. 결정/확정 텍스트 → `decisions`
> 8. 공통규칙 텍스트 → `commonRules`
> 9. 데이터 규칙 텍스트 → `dataRules`
> 10. 화면 간 관계 텍스트 → `crossRefs`, `screenDescriptions[].linkedScreens`
> 11. 분류 불가 텍스트 → `acceptanceHints` 또는 `screenDescriptions[].description`에 포함

## 5. MCP Tool Mapping

### 5.1 Server-Specific Tool Names

All extraction strategies in § 3 use **short names**. Resolve to the full MCP tool name based on the active server:

| Purpose | Short Name | figma-mcp-go | Figma Official MCP (mcp.figma.com) |
|---|---|---|---|
| File structure | `get_document` | `mcp__figma-mcp-go__get_document` | `get_file` |
| Frame / node | `get_node` | `mcp__figma-mcp-go__get_node` | `get_node` |
| Multiple nodes | `get_nodes_info` | `mcp__figma-mcp-go__get_nodes_info` | `get_node` (per-node) |
| Design context | `get_design_context` | `mcp__figma-mcp-go__get_design_context` | Compose: `get_file` + `get_styles` |
| Node filtering | `scan_nodes_by_types` | `mcp__figma-mcp-go__scan_nodes_by_types` | `get_file` → client-side filter by `type` |
| Text content | `scan_text_nodes` | `mcp__figma-mcp-go__scan_text_nodes` | `get_file` → client-side filter `type == "TEXT"` |
| Search nodes | `search_nodes` | `mcp__figma-mcp-go__search_nodes` | `get_file` → client-side search |
| Variables | `get_variable_defs` | `mcp__figma-mcp-go__get_variable_defs` | `get_variables` |
| Token export | `export_tokens` | `mcp__figma-mcp-go__export_tokens` | Derive from `get_variables` |
| Styles | `get_styles` | `mcp__figma-mcp-go__get_styles` | `get_styles` |
| Components | `get_local_components` | `mcp__figma-mcp-go__get_local_components` | `get_components` |
| Annotations | `get_annotations` | `mcp__figma-mcp-go__get_annotations` | N/A — use text node scan fallback |
| Reactions | `get_reactions` | `mcp__figma-mcp-go__get_reactions` | N/A — parse prototype links from file data |
| Fonts | `get_fonts` | `mcp__figma-mcp-go__get_fonts` | Derive from text styles in `get_styles` |
| Screenshot | `get_screenshot` | `mcp__figma-mcp-go__get_screenshot` | `get_images` |
| Pages | `get_pages` | `mcp__figma-mcp-go__get_pages` | `get_file` → `document.children` |
| Metadata | `get_metadata` | `mcp__figma-mcp-go__get_metadata` | `get_file` → `name`, `lastModified`, etc. |

### 5.2 Figma Official MCP Compensation Patterns

The Figma Official MCP has a smaller tool surface. These patterns compensate for missing tools:

| Missing Tool | Compensation Strategy |
|---|---|
| `scan_nodes_by_types` | Call `get_file` or `get_node` with `depth` param, then filter the returned node tree by `type` field client-side |
| `scan_text_nodes` | Same as above, filter for `type == "TEXT"` nodes |
| `get_design_context` | Call `get_file` (for structure) + `get_styles` (for styles) + `get_variables` (for tokens) and merge results |
| `get_annotations` | Scan text nodes for sticky-note patterns: small colored FRAME with single TEXT child, positioned outside main content bounds |
| `get_reactions` | Parse `prototypeStartNodeID` and `flowStartingPoints` from file data; interaction details limited to navigation destinations |
| `export_tokens` | Call `get_variables`, transform variable collections into token format: `collection/mode/variable` → `--token-name: value` |
| `get_fonts` | Extract unique `fontFamily` + `fontWeight` pairs from text style definitions returned by `get_styles` |

### 5.3 Authentication (Figma Official MCP Only)

The Figma Official MCP requires OAuth authentication before any data access:

```
1. Call mcp__plugin_figma_figma__authenticate
   → Returns auth URL for user to visit
2. User authorizes in browser
3. Call mcp__plugin_figma_figma__complete_authentication
   → Returns access token, session established
4. Proceed with data tools (get_file, get_node, etc.)
```

Authentication is **not required** for `figma-mcp-go` (connects directly to the local Figma desktop app).

## 6. Edge Cases

### 6.1 Empty or Minimal Frames

If a frame contains fewer than 3 meaningful nodes (excluding auto-layout wrappers), classify as `annotation` and extract text content only.

### 6.2 Deeply Nested Frames

Figma frames can nest 10+ levels deep. The scanner limits recursive depth to 8 levels. Beyond that, leaf nodes are cataloged but not individually analyzed.

### 6.3 External Component References

INSTANCE nodes may reference components from external libraries (team libraries). These are recorded by reference name but not deep-analyzed. The digest notes them as `"externalComponent": true`.

### 6.4 Variable Modes

Figma Variables support multiple modes (e.g., Light/Dark, Desktop/Mobile). All modes are extracted and mapped:

| Figma Mode | Design System Mapping |
|---|---|
| Light | `:root` default tokens |
| Dark | `[data-theme="dark"]` overrides |
| Desktop | Default responsive values |
| Mobile | Breakpoint-specific overrides |

### 6.5 No Variables Defined

If the Figma file has no Variables or Styles defined (common in early-stage wireframes), the engine falls back to:
1. Extract colors from fill properties of rectangles/frames
2. Extract typography from text node properties
3. Generate approximate tokens with `"confidence": "inferred"` flag

---

# PART II — Orchestrated Pipeline (v2, 2026-04-18)

> **Relation to PART I (§1–§6):** PART I defines **what** to extract from a single frame (content types, per-type strategies, MCP tools, edge cases). PART II defines **how** to orchestrate extraction across an entire file: enumerating every page/frame/variant, tracking coverage, recovering from failure, and integrating results into `/u-plan` and `/u-design`. PART I stays authoritative for per-frame extraction; PART II supersedes §4.1's file-level pipeline for v2.
>
> **User-stated pain priority** (for design trade-offs): missing content (a) > coverage opacity (d) > volume overload (b) > type confusion (c). Within (a): variant/state > page-level > frame-level > comments > nested text > sticky-notes. Every decision below traces back to this ordering.

## 7. Variant / State Detection Algorithm

User's #1 missing-content pain. Four variant sources are detected and **unioned** (not exclusive); every match becomes an independent manifest entry. No variant can slip through manifest construction.

### 7.1 Four variant sources

| Source | Detection | MCP tool |
|---|---|---|
| **A. COMPONENT_SET** | `nodeType == "COMPONENT_SET"` — enumerate all child COMPONENTs and their `componentPropertyDefinitions` | `get_local_components`, `scan_nodes_by_types(["COMPONENT_SET","COMPONENT"])` |
| **B. Naming pattern** | Frame name carries a state suffix (` / `, `·`, ` - `, `_suffix`, `(..)`, `[..]`) | `scan_nodes_by_types(["FRAME"])` + regex |
| **C. Positional cluster** | Frames sharing an LHS base name, horizontally adjacent (gap < 1.5 × avgWidth), same Y (±50 px) | bbox clustering |
| **D. Suffix marker** | Frame name ending with `_error`, `-loading`, `(empty)`, `[disabled]`, etc. | regex |

### 7.2 Base/State extraction

```
function extractBase(frameName):
    patterns = [
        /^(.+?)\s*\/\s*(.+)$/,                 # "Login / Error"
        /^(.+?)\s*·\s*(.+)$/,                  # "Login · Error"
        /^(.+?)\s*-\s*(.+)$/,                  # "Login - Error"
        /^(.+?)_(default|hover|pressed|disabled|error|loading|empty|success|focus)$/i,
        /^(.+?)\s*\((.+)\)$/,                  # "Login (empty)"
        /^(.+?)\s*\[(.+)\]$/                   # "Login [disabled]"
    ]
    for p in patterns:
        m = frameName.match(p)
        if m: return { base: m[1].trim(), state: m[2].trim() }
    return { base: frameName, state: null }
```

### 7.3 Positional clustering (source C)

```
function detectPositionalVariants(frames):
    clusters = groupBy(frames, f => extractBase(f.name).base)
    for cluster in clusters:
        if cluster.size < 2: continue
        sortedByX = sort(cluster.frames, f => f.bbox.x)
        if areHorizontallyAdjacent(sortedByX) and shareYCoord(sortedByX):
            markAsVariantSeries(cluster)
```

### 7.4 Manifest entry — variant is a first-class citizen

```json
{
  "nodeId": "5:102",
  "name": "Login / Error",
  "variantOf": {
    "baseName": "Login",
    "baseNodeId": "5:100",
    "stateLabel": "Error",
    "detectionSource": "component-set | naming-pattern | positional | suffix-marker"
  },
  "status": "pending",
  "digestPath": "frames/5-102.digest.json"
}
```

### 7.5 Post-scan completeness checks

1. **Component-set completeness**: every COMPONENT_SET must have `variants.length >= 1`. 0 → warning.
2. **Orphan base**: 2+ frames share an LHS but `variantOf == null` → `coverageWarnings.type = "orphan-base"`.
3. **State gap**: a base has only `Default` but no `Error|Loading|Empty` → info warning.
4. **Naming inconsistency**: `/` vs `-` mixed within the same page → warning.

---

## 8. Manifest Schema & Coverage Ledger

Single source of truth for inventory, progress, change detection, and recovery. Per-frame digest files live alongside the manifest (isolated for context safety).

### 8.1 File layout

```
.u-maker/data/figma/<file_key>/
  manifest.json                      # inventory + ledger (authoritative)
  comments.json                      # see §11
  frames/
    <node_id>.digest.json
    <node_id>/                       # dense-frame chunking (§10.3)
      chunk-<section_id>.digest.json
  screenshots/
    <node_id>.png
  aggregate.json                     # roll-up for downstream
  _errors/
    <node_id>.error.json
```

### 8.2 `manifest.json` schema (v1.0)

```json
{
  "schemaVersion": "1.0",
  "fileKey": "rthR0h9cahAAFfWL1JyAMq",
  "fileName": "...",
  "figmaUrl": "https://www.figma.com/design/...",
  "figmaFileUrl": "https://www.figma.com/design/rthR0h9cahAAFfWL1JyAMq",

  "scan": {
    "scannedAt": "2026-04-18T10:00:00+09:00",
    "scannedBy": "u-figma@<version>",
    "mcpServer": "figma-mcp-go | plugin_figma",
    "scope": "file | page | frame"
  },

  "stats": {
    "totalPages": 15,
    "totalFrames": 247,
    "totalComponentSets": 34,
    "totalVariants": 89,
    "totalComments": 47,
    "extractStatus": { "pending": 0, "in_progress": 0, "done": 247, "failed": 0, "skipped": 0 }
  },

  "pages": [
    {
      "pageId": "0:1",
      "pageName": "01. Wireframes",
      "pageIndex": 0,
      "hash": "sha256:...",
      "frames": [
        {
          "nodeId": "1:2",
          "name": "Login",
          "nodeType": "FRAME",
          "bbox": { "x": 0, "y": 0, "w": 1440, "h": 900 },
          "nodeCount": 89,
          "textNodeCount": 42,
          "depth": 6,
          "variantOf": null,
          "detectedContentTypes": ["screen-design", "annotation", "specification"],
          "denseness": "normal | dense | extreme",
          "hash": "sha256:...",
          "status": "pending | in_progress | done | failed | skipped",
          "digestPath": "frames/1-2.digest.json",
          "screenshotPath": "screenshots/1-2.png",
          "extractedAt": "...",
          "extractionAttempts": 1,
          "errorPath": null,
          "subFrameChunks": null
        }
      ]
    }
  ],

  "componentSets": [
    {
      "nodeId": "5:100",
      "name": "Button",
      "pageId": "p3",
      "variants": [
        { "nodeId": "5:101", "label": "Primary/Default", "properties": {"style":"Primary","state":"Default"}, "status": "done" }
      ]
    }
  ],

  "comments": {
    "source": "rest-api | rest-api+annotations+heuristic | skipped | not-available",
    "fetchedAt": "...",
    "counts": { "rest": 47, "devAnnotations": 12, "stickyNotes": 8, "sectionNotes": 23, "merged": 78, "dedupeRemoved": 12 },
    "unresolved": 12,
    "path": "comments.json",
    "patConfigured": true,
    "warnings": []
  },

  "coverageWarnings": [
    { "type": "orphan-base", "baseName": "Dashboard", "frameIds": ["2:10","2:11"], "reason": "..." },
    { "type": "state-gap", "baseName": "Form", "presentStates": ["Default"], "missingSuspected": ["Error","Loading"] },
    { "type": "naming-inconsistency", "scope": "p3", "detail": "..." },
    { "type": "extreme-density", "nodeId": "2791:66049", "nodeCount": 1847 }
  ],

  "retry": {
    "maxAttempts": 3,
    "backoffSeconds": [0, 2, 8]
  }
}
```

### 8.3 Status machine

```
pending → in_progress → done
                     ↘ failed  → (retry) → in_progress
                     ↘ skipped           (--skip)
```

- `in_progress` entries on process start → reset to `pending` (crash recovery).
- `done` entries are never overwritten when hash is unchanged.

### 8.4 Change detection (re-run)

- Per-frame `hash = sha256(canonicalize(node_tree))`.
- Re-run: unchanged → skip; changed → reset to `pending`; new pages/frames → append; removed → mark `removed`.
- `--refresh` forces full re-extraction.

### 8.5 Atomicity

- `manifest.json` writes are atomic (temp-file → rename).
- Per-frame progress updates touch only `frames[].status` + `extractedAt`.

### 8.6 User-facing coverage report

```
Figma: 설계-현진웹-HJW-테스트
  Pages:          15/15 enumerated
  Frames:         247 total  (219 primary + 28 variants)
  Extracted:      ████████████████░░░░  201/247  (81%)
  Variants:       89/89 (100% — component-set 34 + naming 42 + positional 11 + suffix 2)
  Comments:       47 via REST + 12 dev-annotations + 8 stickies = 78 (after dedup)
  Warnings:       3 (orphan-base:1, state-gap:1, naming-inconsistency:1)
  Failed:         2  → retry? [Y/n]
```

---

## 9. Command Surface — `/u-figma`

### 9.1 Decision: dedicated command with delegation

- Figma is consumed by multiple phases (plan + design); a flag on `/u-plan` alone is asymmetric.
- The pipeline has multi-step sub-actions (scan → gate → extract → verify → sync) that flags cannot express cleanly.
- Consistent with existing `/u-backlog add/sprint/groom` style.

### 9.2 Sub-commands

```
/u-figma scan <url>     [--scope file|page|frame] [--refresh]
/u-figma extract <url>  [--page <id>] [--frame <id>] [--retry-failed] [--limit N]
/u-figma status <url>   [--verbose] [--warnings-only]
/u-figma verify <url>   [--fix]
/u-figma sync <url>     [--to plan|design|both]
/u-figma skip <url> --frame <id> [--reason "..."]
/u-figma ingest <url>                  # scan + gate + extract + verify + sync
```

### 9.3 Delegation from existing commands (auto-trigger ON by default)

- **`/u-plan`** — scans `data/dropzone/` for `.figma-link | *.figma.txt | markdown with figma.com/design/…`; each URL triggers `/u-figma ingest <url> --to plan`.
- **`/u-design`** — if SRS has `designSystemSource: figma:<url>` or `screenDesignSource: figma:<url>`, call `/u-figma sync <url> --to design`.

Configurable via `figma.integration.autoTriggerFromPlan` / `autoTriggerFromDesign` (§12.7).

### 9.4 Adaptive gate (Approach C core)

Active inside `ingest` only. If `frames > autoExtractThreshold` (default 80) **or** estimated extraction tokens exceed the cap, prompt:

```
⚠ Large Figma file detected.
  Pages: 15  Frames: 247 (primary 219 + variants 28)
  Variants: 89 groups   Estimated tokens: ~420K

Proceed?
  [Y] Extract all
  [S] Scope — specify pages/frames
  [M] Manifest only (scan done; run /u-figma extract later)
  [N] Cancel
```

Direct `/u-figma scan` + `/u-figma extract` invocations bypass the gate (explicit intent).

### 9.5 New files

```
skills/u-figma/
  SKILL.md
  references/
    manifest-schema.md       # §8
    variant-detection.md     # §7
    pipeline.md              # §10
    comments-fallback.md     # §11
    integration.md           # §12

agents/
  u-agent-figma.md           # §12.5 — dedicated agent

skills/u-plan/references/
  figma-analysis.md          # THIS FILE (retained)
```

---

## 10. Orchestrated Pipeline & Dense-Frame Chunking

### 10.1 End-to-end pipeline (`/u-figma ingest`)

```
[Phase 0] MCP server detection
  figma-mcp-go ? → primary
  else plugin_figma → authenticate → fallback
  else → fail fast with install guidance

[Phase 1] SCAN
  1.1 Parse URL → fileKey, pageId, nodeId, scope
  1.2 get_pages() → ALL pages enumerated (no page tunnel vision)
  1.3 per page: scan_nodes_by_types([FRAME, COMPONENT_SET, COMPONENT, SECTION])
  1.4 variant detection (§7 — four sources unioned)
  1.5 per-frame metadata: name, bbox, nodeCount, depth, hash
  1.6 content type classification (PART I §2.1)
  1.7 dense-frame flagging (§10.3)
  1.8 comments fetch (§11 three-tier)
  1.9 coverageWarnings computation
  → atomic write manifest.json

[Phase 2] ADAPTIVE GATE (§9.4)

[Phase 3] EXTRACT (per-frame loop)
  For each pending frame:
    3.1 status = in_progress (atomic)
    3.2 dense check → chunking path (§10.3) if needed
    3.3 strategy dispatch by contentTypes → PART I §3.1–3.8
    3.4 write frames/<nodeId>.digest.json
    3.5 get_screenshot → screenshots/<nodeId>.png
    3.6 status = done + extractedAt (atomic)
    3.7 stream progress (§10.4)
    3.8 on error: increment attempts → backoff → retry OR mark failed

[Phase 4] VERIFY
  4.1 coverageWarnings walk
  4.2 auto-retry failed frames (1 pass even without --fix)
  4.3 orphan-base, state-gap reporting
  4.4 variant completeness (§7.5 four checks)
  4.5 summary report (§8.6)

[Phase 5] AGGREGATE
  5.1 per-frame digest → aggregate.json roll-up
  5.2 cross-ref (screen↔rules, variant↔base)
  5.3 atomic write aggregate.json

[Phase 6] SYNC (optional, per sub-command)
  → §12
```

### 10.2 Failure modes

| Phase | Failure | Recovery |
|---|---|---|
| 0 | No MCP available | fail fast, print install guidance |
| 1 | REST rate limit (comments) | exponential backoff 3× → skip with warning |
| 1 | Single page scan error | record `scanError` on that page, continue |
| 3 | Extraction timeout | mark `failed`, next frame |
| 3 | Process crash | `in_progress` → reset to `pending` on next run |
| 4 | Verify warnings unresolved | persist in report, do not block pipeline |

### 10.3 Dense-frame chunking

`denseness` levels: `normal | dense | extreme`.

```
function isDense(frame):
    if frame.nodeCount > 2000: return extreme
    if frame.nodeCount > 800: return dense
    if frame.textNodeCount > 150: return dense
    if frame.depth > 10: return dense
    if frame.bbox.w * frame.bbox.h > 4_000_000: return dense
    return normal
```

Chunking strategy (recursive, max depth 3):

```
function extractDenseFrame(frame, currentDepth):
    topSections = get_node(frame.id, depth=2)
    sections = []
    for section in topSections:
        if section.nodeCount > 300 and currentDepth < 3:
            chunkDigest = extractDenseFrame(section, currentDepth + 1)
        else:
            chunkDigest = extractNormal(section)
        path = f"frames/{frame.id}/chunk-{section.id}.digest.json"
        writeAtomic(path, chunkDigest)
        sections.append({ "sectionId": section.id, "name": section.name, "digestPath": path })
    return { "sections": sections, "chunked": true }
```

Manifest's `subFrameChunks[]` captures the section index. `aggregate.json` transparently merges main + chunks for downstream consumers. `extreme` density raises a `coverageWarnings.extreme-density` entry recommending a split in Figma.

### 10.4 Progress streaming

```
▸ Extracting 247 frames across 15 pages...

  [  1/247] p1/Login                         Default       ✓ (1.2s)
  [  2/247] p1/Login                         Error         ✓ (0.9s)
  [  4/247] p1/Dashboard                     Default       ⚙ dense (chunking 5 sections...)
  [  5/247] p2/가입조회 현황                  Default       ⚠ extreme (1847 nodes) → chunking

Elapsed 4m 12s  |  Done 201  |  Failed 2  |  Remaining 44
```

### 10.5 Idempotency

- Re-run: hash unchanged → skip; changed → re-extract the changed subset only.
- `--refresh` forces full re-extraction.
- `done` frames preserve `extractedAt`; user edits persisted (hash check on unchanged input prevents overwrite).

---

## 11. Comments Strategy (REST + Heuristic Fallback)

Neither MCP exposes `get_comments`. Three tiers collected concurrently and deduplicated.

### 11.1 Tiers

| Tier | Source | Requirement |
|---|---|---|
| **1 — REST** | `GET https://api.figma.com/v1/files/{fileKey}/comments` with `X-Figma-Token` header | `FIGMA_PAT` configured |
| **2 — Dev annotations** | `get_annotations` (figma-mcp-go; PART I §5.2 has fallback for plugin_figma) | Designer added dev-mode annotations |
| **3 — Sticky/Section heuristic** | `scan_nodes_by_types` + pattern match | Always runs |

### 11.2 PAT management

Resolution order:

1. env `FIGMA_PAT`
2. `.u-maker/secrets.local.json` → `{"figmaPat": "..."}` (gitignored — enforced by `install.sh`)
3. `u-maker.config.json` → `figma.comments.patEnv` (specify env var name)

On first scan needing REST with no PAT: prompt once; user can skip (Tier 1 marked `skipped`, pipeline continues).

### 11.3 `comments.json` schema

```json
{
  "fetchedAt": "...",
  "source": "rest-api",
  "total": 47,
  "unresolved": 12,
  "comments": [
    {
      "id": "123",
      "message": "...",
      "author": "...",
      "createdAt": "...",
      "resolvedAt": null,
      "parentId": null,
      "clientMeta": { "nodeId": "2791:66049", "nodeOffset": { "x": 240, "y": 120 } },
      "nearestFrame": { "nodeId": "2791:66049", "name": "...", "distance": 0 },
      "reactions": [{"emoji": "👍", "count": 3}],
      "thread": [ { "id": "124", "message": "...", "author": "..." } ]
    }
  ]
}
```

### 11.4 Coordinate → frame mapping

```
function mapCommentToFrame(comment, manifest):
    if comment.clientMeta.nodeId: return findFrameByNodeId(...)
    containing = findSmallestContainingFrame(manifest, comment.x, comment.y)
    if containing: return containing
    return findNearestFrame(manifest, comment.x, comment.y)
```

### 11.5 Tier 3 heuristics

**Sticky-note detection:**
```
isSticky(node) :=
  node.bbox.w ≤ 300 AND node.bbox.h ≤ 300
  AND children.length == 1 AND children[0].type == "TEXT"
  AND hasFill(node)
  AND !isInsideMainScreens(node)
  AND isStickyColor(node.fill)     // saturated yellow/pink/blue
```

**Section-block extraction:** Within Figma `SECTION` nodes, TEXT classified as `planning-text` by `classifyTextNode` (PART I §3.4) is treated as a comment.

### 11.6 Dedup

```
key(c) = hash(c.message.trim() + "|" + (c.nodeRef || c.x + "," + c.y))
priority: rest-api > dev-annotation > section-heuristic > sticky-heuristic
```

### 11.7 Injection into frame digests

Each frame digest receives an `annotations[]` array with every comment resolving to that frame. Downstream SRS can surface an "Unresolved design questions" section automatically.

### 11.8 Privacy

- PAT lives only in `.u-maker/secrets.local.json` (gitignored).
- Original comments (author names) stay in `comments.json`, not in `aggregate.json`.
- `--no-comments` disables all three tiers.

---

## 12. Integration (u-plan, u-design, u-agent-figma)

### 12.1 Data flow

```
data/figma/<file_key>/aggregate.json
        │
        ├─ (plan) ─────▶ data/digest/figma_<fileKey>.digest.json
        │                   │
        │                   ├─▶ SRS: screenDescriptions + businessRules +
        │                   │        processingRules + permissionRules +
        │                   │        validationRules → FR/NFR candidates
        │                   └─▶ IA: screen inventory + linkedScreens →
        │                           site map nodes/edges
        │
        └─ (design) ───▶ data/figma/<fileKey>/design-system-source.json
                            ├─▶ Design System (DS-010~080): tokens, styles
                            ├─▶ Component Inventory (CMP-xxx): every variant
                            └─▶ Screen Spec: per-screen layout + every variant
```

### 12.2 Plan-side (auto-trigger ON)

- `/u-plan` scans `data/dropzone/` for Figma URLs; each triggers `/u-figma ingest <url> --to plan`.
- `aggregate.json` mirrored to `data/digest/figma_<fileKey>.digest.json`.
- SRS/IA generation merges Figma digest with other digests.

#### 12.2.1 Merge priority (conflict resolution at SRS generation)

| Field | Priority | Rationale |
|---|---|---|
| `screenDescriptions[].name / code` | **Figma** | Figma is the screen-definition ground truth |
| `screenDescriptions[].components` | **Figma** | Component structure measured from actual design |
| `businessRules`, `processingRules` | **Figma** | Figma planning text is the richest source (PART I §3.8) |
| `domainTerms`, `stakeholders` | Other sources | Business context comes from docs/meetings |
| `stateTransitions` | **Merge (union)** | Both sources partial |
| `validationRules`, `uiSpecifications` | **Figma** | Screen-level detail is most current in design |

Conflicts resolved during SRS generation (not aggregate), so gatekeeper can diff.

#### 12.2.2 User Story auto-drafting

From `screenDescriptions` + `prototype.flows`, emit US candidates with `status: "extracted"`. User approval required before promotion. ID-10-increment rule (FR-010, US-010) applies.

### 12.3 Design-side

- `/u-design` reads SRS; if `designSystemSource: figma:<url>` or `screenDesignSource: figma:<url>` present → `/u-figma sync <url> --to design`.
- `aggregate.designTokens` → CSS `:root` variables.
- `aggregate.componentSets` → `CMP-xxx` with full variant/property matrices (directly addresses user's #1 pain).
- `aggregate.screenDescriptions` → Screen Spec base; each variant becomes a state subsection (Error/Empty/Loading/etc.).

### 12.4 `/u-figma sync` (manual re-sync)

```
/u-figma sync <url> --to plan       # SRS/IA only
/u-figma sync <url> --to design     # Design System only
/u-figma sync <url> --to both       # both (default)
```

Idempotent: diffs against current docs, patches only changed fields. User edits marked with `// user-edit` comments are preserved.

### 12.5 Agent: dedicated `u-agent-figma` (Option B)

**Decision: skill + new agent.** The 247-frame iteration in main context is prohibitive; agent isolation required.

```yaml
name: u-agent-figma
description: Owns Figma manifest/extract/verify. Runs scan → extract → aggregate.
tools: Read, Write, Glob, Grep, Bash,
       mcp__figma-mcp-go__*,
       mcp__plugin_figma_figma__*
```

- `/u-figma ingest` → orchestrator delegates to `u-agent-figma`.
- Agent runs the per-frame loop in its own context window.
- Returns only the `aggregate.json` path on completion.

### 12.6 Gatekeeper integration

On `/u-gate` or `--loop`:

- **Coverage gate** — `manifest.stats.extractStatus.failed == 0`
- **Variant completeness** — `coverageWarnings.orphan-base` + `state-gap` counts ≤ configured threshold
- **Traceability gate** — every `aggregate.screenDescriptions[]` has a matching FR in SRS
- **Sync freshness** — docs regenerated within N hours of `aggregate.scannedAt`

Failed gates propose an auto `/u-figma verify --fix`.

### 12.7 Config block (`u-maker.config.json`)

```json
{
  "figma": {
    "enabled": true,
    "autoExtractThreshold": 80,
    "maxChunkDepth": 3,
    "comments": {
      "enabled": true,
      "heuristicTier3": true,
      "patEnv": "FIGMA_PAT"
    },
    "variants": {
      "detectNamingPatterns": true,
      "detectPositional": true,
      "detectSuffix": true
    },
    "denseness": {
      "nodeCountThreshold": 800,
      "textNodeThreshold": 150,
      "depthThreshold": 10
    },
    "retry": {
      "maxAttempts": 3,
      "backoffSeconds": [0, 2, 8]
    },
    "integration": {
      "autoTriggerFromPlan": true,
      "autoTriggerFromDesign": true,
      "preserveUserEdits": true
    }
  }
}
```

### 12.8 Relation to `/u-sync`

- `/u-figma sync` — Figma → docs only.
- `/u-sync` — docs internal cross-refs (FR→US→FT, etc.) only.
- Independent; `/u-sync` is unaware of Figma.

### 12.9 Backlog integration

Auto-feed:

- `aggregate.decisions[]` → `data/backlog/decisions/`
- `aggregate.comments.unresolved[]` → `data/backlog/questions/`
- `aggregate.coverageWarnings[]` → `data/backlog/issues/figma/`

`/u-backlog groom` surfaces Figma-sourced items alongside others.

---

## 13. Testing & Validation

### 13.1 Golden corpora

Three user-supplied URLs serve as acceptance tests:

1. **현진웹 HJW (spec doc)** — `https://www.figma.com/design/rthR0h9cahAAFfWL1JyAMq/…?node-id=3163-50673`
   - Expected content types: `screen-planning + annotation + specification`
   - Validates: planning-text extraction depth, business/processing rule coverage.
2. **그리고라이프 화면디자인 (hi-fi)** — `https://www.figma.com/design/dbzjO8T5hWQXvuNc6IiwIH/…?node-id=532-48007`
   - Expected content types: `screen-design + prototype + annotation`
   - Validates: variant detection (sources B + C + D), prototype reactions, screenshot fidelity.
3. **그리고라이프 컴포넌트 V.02 (design system)** — `https://www.figma.com/design/LgSNuJWOrRx1K9iPVUgFKE/…?node-id=0-1`
   - Expected content types: `design-tokens + assets`; heavy COMPONENT_SET usage
   - Validates: Source A — **every** COMPONENT_SET variant enumerated; zero orphans.

### 13.2 Assertions (per corpus)

- `manifest.stats.totalVariants >= <expected>` (manually counted once, locked).
- `manifest.coverageWarnings[].type == "orphan-base"` count == 0.
- Every COMPONENT_SET has `variants.length >= 1`.
- REST comment count matches Figma 💬 UI count (PAT available case).
- Kill mid-extract → next run completes without re-doing `done` frames.

### 13.3 Regression suite

`skills/u-figma/tests/` contains:
- Mock Figma fixtures (serialized node trees) for unit tests of variant detection, dense flagging, dedup.
- Integration tests invoking `u-agent-figma` against recorded MCP responses.
- Gatekeeper-style schema assertions on manifest/aggregate.

---

## 14. Rollout & Success Criteria

### 14.1 Build sequence (high-level)

1. `skills/u-figma/SKILL.md` + references (§7, §8, §10, §11, §12 authoring).
2. `agents/u-agent-figma.md` (Option B).
3. Manifest schema file + validator in `_meta/schemas/figma-manifest.schema.json`.
4. `/u-figma scan` + `status` (read-only subset — validates schema end-to-end).
5. `/u-figma extract` + `verify` + chunking.
6. Comments Tier 1 (REST), then Tier 2/3.
7. `/u-figma sync` + plan/design delegation + gatekeeper gates.
8. Tests against the three corpora.

### 14.2 Back-compatibility

- PART I (§1–§6) remains authoritative for per-type extraction strategy.
- No breaking changes to digest schema — only additive fields.
- Users without Figma MCPs see graceful fail with setup instructions.

### 14.3 Out of scope

- Figma plugin/extension.
- Writing back to Figma (create annotations/comments).
- Cross-file team-library deep analysis.
- Historical version diffing.

### 14.4 Open questions (revisit during implementation)

1. Figma REST rate limits — batch fetch needed for 500+ comments?
2. Large screenshots (2K+ pages) — PNG vs WebP? Size budget?
3. PAT rotation UX — token expiry prompt flow?
4. Team-library INSTANCE refs — deep-analyze once per referenced file, or always shallow?

### 14.5 Success criteria

- Given the three test URLs: **0 orphan-base warnings** and **100% COMPONENT_SET variant coverage** reported by `/u-figma status`.
- Mid-extract interruption resumable with zero loss.
- `/u-plan` on a Figma-containing dropzone produces SRS with `businessRules` and `processingRules` derived from Figma planning text.
- `/u-design` on an SRS with `designSystemSource: figma:…` produces a Design System HTML representing every COMPONENT_SET variant.
- `/u-figma status <url>` surfaces coverage at any time.
