---
name: u-output
description: "This skill should be used when the user asks to '/u-output', '/u-html', 'generate HTML', 'render output', 'rebuild HTML', 'regenerate output', 'u-maker HTML 생성', '출력 재생성', 'HTML 다시 생성', 'u-maker 렌더링', or wants to convert existing docs/ markdown+JSON into HTML output without re-running phase logic."
version: 4.0.0
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

Process each document according to its type. **Apply html-engine's full CSS rules — including the HARD RULE `§Border/Accent — 한쪽 border 강조 금지`**: no single-side accent borders (decorative `border-left/right/top/bottom` color bars, color-bar nav/tab active states, accent heading underlines); emphasize with full 4-side `border` + background tint + `font-weight`. Neutral 1px dividers, focus rings, and chart/data markers are allowed. Enforced by Gatekeeping GK-07.

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

### ⚠️ Per-Domain Page Rendering Specs

Each split-document domain page (Screens, ERD) requires a **mandatory full rendering** — stub pages with only metadata are **incomplete output**. Each spec defines layout, required SVG diagrams, annotation panels, component/relationship tables, and index-page composition.

- **Screens domain page** (wireframe + annotation panel + component spec + 4 SVG diagrams) → **see `references/screens-rendering.md`**
- **ERD domain page** (inline SVG ERD + relationship cards + entity detail tables + common references) → **see `references/erd-rendering.md`**

Both specs must be loaded by the html-engine when rendering split documents under `output/{app}/design/screens/` and `output/{app}/design/erd/` respectively.

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

---
