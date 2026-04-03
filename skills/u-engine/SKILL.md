---
name: u-engine
description: "This skill should be used when any u-maker command needs internal engine support — document CRUD, HTML generation, dependency graph management, digest processing, or command routing. Provides shared infrastructure for all phase skills."
version: 4.0.0
---

# u-engine — Shared Engine Infrastructure

Internal engine bundle providing cross-cutting capabilities for all u-maker phase skills.

## Engines

| Engine | Reference | Purpose |
|--------|-----------|---------|
| doc-engine | `references/doc-engine.md` | Document CRUD, template rendering, JSON companion generation |
| html-engine | `references/html-engine.md` | MD→HTML conversion, SVG diagrams, Mermaid CDN, base64 images, sidebar navigation, root index management |
| dep-engine | `references/dep-engine.md` | links.json dependency graph, cascade propagation |
| digest-engine | `references/digest-engine.md` | dropzone→digest refinement, hash comparison, _index.json management |
| router | `references/router.md` | Intent classification, command parsing, agent dispatch |

## Document CRUD Protocol

All document operations follow this protocol:

1. Read template from `_meta/templates/{docType}.template.md`
2. Generate `.md` document with template structure filled
3. Generate `.json` companion with structured items, IDs, cross-references
4. Update `data/links.json` with new nodes and edges
5. Verify `.md` ↔ `.json` synchronization

### ID Convention

- All IDs use 10-increment: FR-010, FR-020, FR-030
- Insert between existing: FR-015 (between 010 and 020)
- Format: `{TYPE}-{NNN}` where NNN is zero-padded 3 digits
- Types: FR, NFR, US, FT, SC, TC, ENT, REL, API, IA, DS, CMP, STK

### JSON Companion Structure

Every `.md` SSoT document has a `.json` companion following `_meta/schemas/doc-companion.schema.json`.

## HTML Generation Protocol

1. Read `.md` source document
2. Parse frontmatter metadata
3. Convert markdown → HTML body
4. Render Mermaid diagrams via CDN (`https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js`)
5. Generate SVG diagrams inline (curved connectors)
6. Encode images as base64
7. Apply `_meta/templates/output-page.template.html` wrapper
8. Generate TOC from headings
9. Write to `output/{app}/{phase}/{docName}.html`
10. Update `output/{app}/index.html` navigation
11. Update root index files (`output/index.html`, `reports/index.html`, `index.html`) — see `html-engine.md` § 8

### HTML Rules

- Light mode default
- Tailwind CSS utility classes
- Dark/light toggle switcher
- Mermaid CDN for UML rendering
- SVG inline with curved connectors (flowchart curve: 'basis')
- Images embedded as base64
- Footer: `Copyright(c) 2026 U PLEAT`

## Command Options (All Phase Skills)

| Option | Default | Description |
|--------|---------|-------------|
| `--auto` | ON | No questions, proceed automatically |
| `--loop` | OFF | Gatekeeper-driven iteration (avg < 95 → retry, max 3) |
| `--app {name}` | — | Target app name |

## Reference Files

For detailed specifications, consult:
- **`references/doc-engine.md`** — Document lifecycle, template rendering, JSON companion details
- **`references/html-engine.md`** — HTML conversion pipeline, SVG generation, Mermaid integration
- **`references/dep-engine.md`** — Dependency graph structure, cascade rules
- **`references/digest-engine.md`** — Dropzone scanning, hash comparison, digest format
- **`references/router.md`** — Intent classification patterns, command dispatch rules
