---
name: u-engine
description: "INTERNAL INFRASTRUCTURE — not directly invoked by users. Referenced by other u-* phase skills for shared engines: doc-engine (document CRUD), html-engine (HTML generation), dep-engine (dependency graph), digest-engine (dropzone processing), router (command dispatch). Do not auto-load on user requests; phase skills load specific engine references on demand."
version: 4.1.0
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
| browser-engine | `../u-tools-browser/SKILL.md` | Unified browser automation — E2E execution, screen capture, visual verify, dev-server checks (all phase skills route browser work through here) |

## Document CRUD Protocol

All document operations follow this protocol:

1. Read template from `_meta/templates/{docType}.template.md`
2. Generate `.md` document with template structure filled
3. Generate `.json` companion with structured items, IDs, cross-references
4. Update `data/links.json` with new nodes and edges
5. Verify `.md` ↔ `.json` synchronization

All generated prose follows the Plain Language rule (doc-engine.md § 8): 설명 문장은 중학생도 이해할 수 있게 — 짧은 문장, 쉬운 낱말, 전문용어 첫 등장 시 한 줄 풀이. ID·코드·수치는 그대로 둔다.

### ID Convention

- All IDs use 10-increment: FR-010, FR-020, FR-030
- Insert between existing: FR-015 (between 010 and 020)
- Format: `{TYPE}-{NNN}` where NNN is zero-padded 3 digits
- Types: FR, NFR, US, FT, SC, TC, ENT, REL, API, IA, DS, CMP, STK

### JSON Companion Structure

Every `.md` SSoT document has a `.json` companion following `_meta/schemas/doc-companion.schema.json`.

## HTML Generation Protocol

Full pipeline (Single-file, Domain Split, Index Updates, Standalone, HTML Rules) → **see `references/html-engine.md`**.

Key invariants enforced by html-engine:
- `--diagram` mode: `svg` (default) | `mermaid` | `all`
- No ASCII art except folder tree; Mermaid always light mode
- No single-side accent borders (한쪽 border만 강조하는 장식/active 스타일 금지) — 전체 4변 border + 배경 채움 + font-weight로 강조; 1px 중립 구분선·focus·차트 마커만 단면 허용 (html-engine.md §6 "Border / Accent Style Rules")
- Plain Language (쉬운 글쓰기) — 모든 설명 문장은 중학생 이해 수준으로 쓴다: 짧은 문장, 쉬운 낱말, 전문용어 첫 등장 시 한 줄 풀이, 비유·예시. ID·코드·수치는 그대로 (html-engine.md §0.6, doc-engine.md §8, GK-06 `plain-language-middle-school` 검사)
- Use `/u-output` to regenerate HTML from existing `docs/` without re-running phase logic

## Command Options (All Phase Skills)

| Option | Default | Description |
|--------|---------|-------------|
| `--auto` | ON | No questions, proceed automatically |
| `--loop [N]` | OFF (default N=5) | Gatekeeper-driven iteration. N = criteria count (1-11, default 5). avg < 95 → retry, max 3 |
| `--app {name}` | — | Target app name |
| `--diagram {mode}` | `svg` | Diagram rendering: `svg` (all SVG), `mermaid` (all Mermaid), `all` (SVG + Mermaid UML fallback) |

## Reference Files

For detailed specifications, consult:
- **`references/doc-engine.md`** — Document lifecycle, template rendering, JSON companion details
- **`references/html-engine.md`** — HTML conversion pipeline, SVG generation, Mermaid integration
- **`references/dep-engine.md`** — Dependency graph structure, cascade rules
- **`references/digest-engine.md`** — Dropzone scanning, hash comparison, digest format
- **`references/router.md`** — Intent classification patterns, command dispatch rules
