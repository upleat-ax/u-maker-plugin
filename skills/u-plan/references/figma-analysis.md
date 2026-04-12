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
    if hasTokenPattern(rectangles, textNodes, grid-layout):
        types.add("design-tokens")
    if hasAssetPattern(components, vectors, images):
        types.add("assets")
    if hasPrototypeReactions(frameNodeId):
        types.add("prototype")

    return types
```

### 2.2 Content Type Definitions

| Content Type | Detection Signal | Examples |
|---|---|---|
| **screen-design** | High-fidelity UI: INSTANCE nodes referencing design system components, styled frames with fills/strokes, realistic content | Login screen, Dashboard, Settings page |
| **screen-planning** | Low-fidelity layouts: simple rectangles with text labels, placeholder boxes ("Image here"), minimal styling | Wireframe layouts, page structure sketches |
| **diagram** | Connector lines (VECTOR/LINE) linking labeled frames/shapes, flow patterns, decision diamonds | User flow, IA diagram, ERD, process flow |
| **annotation** | Sticky notes (colored rectangles + text), comment markers, callout frames, numbered labels pointing to elements | Design rationale, decisions, review comments |
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

### 3.4 Annotation Extraction

**Goal:** Extract design rationale, decisions, review comments, specification notes

**MCP Tools:**
1. `scan_text_nodes` — All text content
2. `get_annotations` — Figma native annotations
3. `scan_nodes_by_types` — Identify sticky-note-like frames (small colored rectangles with text)
4. `get_node` — Spatial context (what element the annotation is near)

**Extraction Output:**
```json
{
  "type": "annotation",
  "notes": [
    {
      "content": "Password must be 8+ chars with at least one special character",
      "category": "requirement",
      "nearElement": "Password Input",
      "position": { "x": 400, "y": 250 }
    },
    {
      "content": "Decision: Use OAuth2 instead of custom auth",
      "category": "decision",
      "nearElement": "Login Form",
      "position": { "x": 500, "y": 100 }
    }
  ]
}
```

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
   ├─ annotation → § 3.4
   ├─ design-tokens → § 3.5
   ├─ assets → § 3.6
   └─ prototype → § 3.7

5. Digest Generation
   ├─ Map extractions to digest schema fields
   ├─ Cross-reference related extractions
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

Figma-sourced digests follow the standard `digest.schema.json` with extended metadata:

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
    "contentTypes": ["screen-design", "annotation", "prototype"],
    "screenshotPath": "data/digest/_screenshots/abc123_1234-5678.png"
  },
  "summary": "Login screen design with OAuth2 authentication flow...",
  "keywords": ["login", "authentication", "OAuth2", "form validation"],
  "requirements": [
    {
      "id": "REQ-001",
      "type": "functional",
      "title": "Email/Password Login",
      "description": "Extracted from Login form component structure",
      "priority": "Must",
      "figmaSource": "annotation near Password Input"
    }
  ],
  "constraints": ["Password: 8+ chars with special character"],
  "domainTerms": [],
  "stakeholders": [],
  "painPoints": [],
  "workflows": [
    {
      "name": "Login Flow",
      "steps": ["Enter credentials", "Validate", "Redirect to Dashboard"],
      "figmaSource": "prototype reactions"
    }
  ],
  "designTokens": { ... },
  "screenSpecs": { ... },
  "assets": { ... }
}
```

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
