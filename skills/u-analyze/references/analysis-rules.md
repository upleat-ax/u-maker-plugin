# Analysis Rules Reference

> Semantic extraction rules for `/u-analyze`. Describes *what* to extract from each source type and *how* to reconcile conflicts across multiple sources. See `digest-extraction.md` for the mechanical pipeline (scan / hash / chunk / write).

## 1. Extraction targets (per source)

Every digest aims to populate as many of these fields as the source supports:

| Field | Extraction signal |
|-------|-------------------|
| `summary` | Top-level abstract of the document's purpose (1–3 sentences) |
| `keywords` | Terminology repeated ≥ 3 times that appears load-bearing |
| `requirements[]` | Imperative sentences ("must", "shall", "should"), numbered lists titled "Requirements", row-oriented spreadsheets with a Priority column |
| `constraints[]` | "Must support X", "Budget: Y", "Deadline: Z", compliance mentions |
| `stakeholders[]` | Role titles, org charts, "as a {role}" user stories |
| `domainTerms[]` | Glossary sections, terms defined inline ("SKU means …"), acronyms |
| `workflows[]` | Step-numbered procedures, "Then → Next →" flows, sequence diagrams |
| `painPoints[]` | "Currently", "today", negative phrasing about existing state |

Figma sources additionally populate the rich planning fields (`businessRules`, `decisions`, `domainRules`, `processingRules`, `commonRules`, `stateTransitions`, `validationRules`, `permissionRules`, `uiSpecifications`, `dataRules`, `screenDescriptions`) per `_meta/schemas/digest.schema.json` and `figma-analysis.md`.

## 2. ID conventions within digests

- Digest-level IDs use `digest-{type}-NNN` format, sequential 1-increment (e.g., `digest-req-001`).
- Digest IDs are **temporary** — they are remapped to the 10-increment SSoT format (FR-010, NFR-010, etc.) during SRS generation by `/u-plan`.
- Never reuse a digest ID across files; prefix with a source-unique short hash when needed for global uniqueness.

## 3. Aggregation & conflict resolution

When `/u-plan` loads multiple digests to build the SRS, it applies these rules (originally from `ingest-flow.md` §7):

- **Requirements:** dedup by title similarity > 0.85; merge keeping higher priority and more detailed description.
- **Constraints:** dedup by exact string; flag near-duplicates for manual review.
- **Domain Terms:** merge case-insensitively; if definitions conflict, preserve both with source attribution.
- **Stakeholders:** merge by name; combine roles and needs when they differ.
- **Pain Points:** collect as-is; similarity-based dedup.
- **Workflows:** merge by name; union the steps when the same workflow appears in multiple sources.

### 3.1 Conflict log

When conflicting data is detected (e.g., different priorities for the same requirement):

1. Record both versions in a conflict log (`data/digest/_conflicts.json`).
2. Default resolution: prefer the digest whose source has the later `analyzedAt` timestamp.
3. Surface the conflict in the generated SRS as a comment block (`<!-- CONFLICT: … -->`).

## 4. Fail-open vs fail-safe

- **Individual file failure** → fail-open: record `status: "error"` in `_index.json` and continue.
- **Pipeline infrastructure failure** (disk full, permission denied on the dropzone root) → fail-safe: abort the whole run, leave `_index.json` in its previous consistent state.

## 5. See also

- `digest-extraction.md` — mechanical pipeline (scan/hash/chunk/write).
- `_meta/schemas/digest.schema.json` — authoritative schema for digest files.
- `skills/u-plan/references/srs-spec.md` — downstream consumer rules for SRS ID remap.
- `skills/u-plan/references/figma-analysis.md` — Figma-specific extraction (PART I).
