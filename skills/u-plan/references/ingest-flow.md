# Ingest Flow Reference

> Detailed specification for dropzone scanning, file analysis, digest generation, and incremental processing within the u-plan skill.

## 1. Overview

The ingest flow is the first step of the Plan phase. It transforms raw, unstructured files placed in `data/dropzone/` into structured digest JSON files stored in `data/digest/`. Each digest file conforms to `_meta/schemas/digest.schema.json` and captures extracted requirements, constraints, stakeholders, domain terms, workflows, and pain points. The digest layer serves as the canonical intermediate representation between raw input and SSoT documents.

The ingest pipeline follows a deterministic sequence: scan, hash, diff, analyze, write digest, update index. It is designed to be idempotent -- running the pipeline multiple times on unchanged files produces no side effects.

## 2. Dropzone File Type Handling

The `data/dropzone/` directory accepts files recursively in any folder structure. The ingest engine handles each file type with a type-specific extraction strategy:

### 2.1 Markdown (.md, .mdx)

Markdown files are the simplest to process. The engine reads them directly, preserving heading structure for section-aware extraction. Headings map to logical sections (requirements, constraints, etc.) when they match known patterns such as "Requirements", "Constraints", "Stakeholders", "User Stories", or similar domain vocabulary.

### 2.2 PDF (.pdf)

PDF files are processed by extracting text content page by page. The engine uses structured text extraction, preserving paragraph boundaries and table structures where possible. For PDFs with embedded tables, the engine attempts tabular extraction to identify structured data such as requirement lists, stakeholder matrices, or constraint tables. Scanned PDFs (image-only) are handled via OCR-aware extraction: the engine flags them with `"ocrRequired": true` in the digest and extracts whatever text is available, noting low-confidence sections.

### 2.3 Word Documents (.docx, .doc)

DOCX files are parsed by extracting paragraphs, tables, and heading styles. The engine maps Word heading levels (Heading 1, Heading 2, etc.) to a logical outline structure, similar to Markdown. Tables are extracted as structured arrays. Embedded images are noted in the digest metadata but not analyzed unless they are diagrams with embedded text. Legacy `.doc` format is converted to plain text with best-effort paragraph detection.

### 2.4 Spreadsheets (.xlsx, .csv)

Spreadsheets are treated as structured tabular data. Each sheet (for XLSX) or file (for CSV) is processed independently. The engine identifies header rows by heuristic (first row with non-empty cells that appear to be labels) and extracts rows as key-value records. Common patterns detected include: requirement lists (columns: ID, Title, Description, Priority), stakeholder lists (Name, Role, Department), and constraint tables (Type, Description, Impact).

### 2.5 Images (.png, .jpg, .jpeg, .svg, .webp)

Image files are cataloged in the digest with metadata (filename, dimensions, format) but analyzed only at a high level. For SVG files, embedded text elements are extracted. For raster images, the engine records the file reference and flags it for manual review. If the image appears to be a wireframe, flowchart, or diagram (detected by filename patterns like `wireframe-`, `flow-`, `diagram-`), the digest notes the probable content type for downstream reference.

### 2.6 Plain Text (.txt, .log)

Plain text files are read directly. The engine applies line-based segmentation, looking for section breaks (blank lines, separator characters like `---` or `===`) to split content into logical chunks for analysis.

### 2.8 Figma Links (.figma-link, direct URL)

Figma links are processed through a dedicated multi-step analysis pipeline. A single Figma frame can contain heterogeneous content: screen designs, wireframes, diagrams, annotations, design tokens, assets, and prototype interactions. The engine classifies each content region within the frame and applies type-specific extraction using Figma MCP tools.

**MCP Server Priority:**
1. **`figma-mcp-go`** (primary) — local MCP, connects to Figma desktop app, full tool set (`get_node`, `scan_nodes_by_types`, `get_variable_defs`, `get_styles`, `get_reactions`, etc.)
2. **Figma Official MCP** (fallback) — remote REST API via `https://mcp.figma.com/mcp`, requires authentication, compensates missing tools via file-level queries

**Input methods:**
- **File-based:** A `.figma-link` file in `data/dropzone/` containing the Figma URL
- **Direct URL:** User provides a Figma link during `/u-ingest` conversation

**Key capabilities:**
- Content type auto-detection (screen-design, screen-planning, diagram, annotation, **specification**, design-tokens, assets, prototype)
- Mixed frame handling — multiple content types extracted and cross-referenced from a single frame
- Variable and style extraction for design system token mapping
- Prototype reaction extraction for screen flow derivation
- **Rich planning content extraction** — 기업용 시스템 Figma는 단순 UI 디자인이 아닌 **화면기획서** 역할을 겸하므로, 비즈니스 로직·도메인 규칙·처리방법·공통규칙·상태전이·권한규칙·검증규칙·화면별 상세 설명 등을 구조화하여 추출 (figma-analysis.md § 3.4, § 3.8, § 4.3 참조)

**Output:** Standard digest JSON with extended `figmaMeta` and `sourceType: "figma-frame"` fields. `figmaMeta`에는 원본 Figma URL (`figmaUrl`, deep link 포함)이 반드시 포함된다. 추가로 digest에는 다음 필드가 포함되어 다운스트림(SRS, Screen Spec, Wireframe 등)에서 활용된다:

- `screenDescriptions` — 화면별 상세 설명 (purpose, components, linkedScreens)
- `businessRules`, `decisions`, `domainRules`, `processingRules`, `commonRules`
- `stateTransitions`, `validationRules`, `permissionRules`, `uiSpecifications`, `dataRules`
- `crossRefs`, `acceptanceHints`

> **완전성 원칙:** Figma 프레임의 모든 기획 텍스트는 digest에서 구조화되어 보존된다. digest 누락 = 다운스트림 복구 불가.

> **Full specification:** See `references/figma-analysis.md` for the complete detection algorithm, MCP tool mapping, extraction strategies, and digest output format.

### 2.9 Unsupported File Types

Files with unrecognized extensions (e.g., `.pptx`, `.zip`, `.exe`) are recorded in `_index.json` with status `skipped` and a reason field. They are not analyzed but their presence is tracked so the user can be notified.

## 3. Chunking Strategy for Large Files

Files exceeding a configurable threshold (default: 50,000 characters of extracted text) are split into chunks for analysis to maintain extraction quality.

### 3.1 Chunking Algorithm

1. **Section-based splitting (preferred):** If the file has identifiable sections (Markdown headings, Word heading styles, PDF page breaks), the engine splits at section boundaries. Each chunk retains its section heading for context.
2. **Paragraph-based splitting (fallback):** If no section markers are found, the engine splits at paragraph boundaries (double newlines), grouping paragraphs into chunks of approximately 10,000-15,000 characters.
3. **Fixed-size splitting (last resort):** If paragraphs are too long, the engine splits at the nearest sentence boundary within a 15,000-character window.

### 3.2 Chunk Overlap

Each chunk includes the last 200 characters of the previous chunk as context overlap. This ensures entities and requirements that span chunk boundaries are not lost.

### 3.3 Chunk Merging

After individual chunk analysis, the engine merges extracted items across chunks. Deduplication is performed on requirements by comparing title similarity (fuzzy match threshold > 0.85). Conflicting priorities or descriptions are resolved by keeping the version from the chunk with the most contextual detail.

## 4. Digest File Structure

Each source file produces exactly one digest file at `data/digest/{mirror-path}/{filename}.digest.json`. The mirror path preserves the subdirectory structure from `data/dropzone/`.

Example: `data/dropzone/rfp/main-rfp.pdf` produces `data/digest/rfp/main-rfp.pdf.digest.json`.

The digest file conforms to `_meta/schemas/digest.schema.json`:

```json
{
  "sourceFile": "rfp/main-rfp.pdf",
  "sourceHash": "sha256:a1b2c3d4...",
  "analyzedAt": "2026-04-03T10:30:00Z",
  "summary": "Main RFP document describing an e-commerce platform...",
  "keywords": ["e-commerce", "payment", "inventory", "user management"],
  "requirements": [
    {
      "id": "digest-req-001",
      "type": "functional",
      "title": "User Registration",
      "description": "System must support email and social login registration",
      "priority": "Must"
    }
  ],
  "constraints": ["Must support IE11", "Budget limit: $500K"],
  "domainTerms": [
    { "term": "SKU", "definition": "Stock Keeping Unit - unique product identifier" }
  ],
  "stakeholders": [
    { "name": "Product Owner", "role": "Decision Maker", "needs": "Feature prioritization" }
  ],
  "painPoints": ["Current system has 5+ second page load times"],
  "workflows": [
    {
      "name": "Checkout Flow",
      "steps": ["Add to cart", "Enter shipping", "Select payment", "Confirm order"]
    }
  ]
}
```

### 4.1 Digest ID Convention

Within digest files, requirement IDs use the `digest-req-NNN` format (sequential, 1-increment). These are temporary IDs -- they are remapped to the 10-increment format (FR-010, FR-020) during SRS generation. The digest layer intentionally avoids the 10-increment format to keep digest-level IDs independent of final SRS numbering.

## 5. The _index.json Lifecycle

The `data/digest/_index.json` file is the central registry for all dropzone files. It tracks processing status and enables incremental updates.

### 5.1 Structure

```json
{
  "version": "4.0.0",
  "lastScanAt": "2026-04-03T10:30:00Z",
  "files": {
    "rfp/main-rfp.pdf": {
      "hash": "sha256:a1b2c3d4...",
      "status": "done",
      "analyzedAt": "2026-04-03T10:30:00Z",
      "digestPath": "rfp/main-rfp.pdf.digest.json"
    },
    "notes/meeting-notes.md": {
      "hash": "sha256:e5f6g7h8...",
      "status": "done",
      "analyzedAt": "2026-04-03T10:31:00Z",
      "digestPath": "notes/meeting-notes.md.digest.json"
    },
    "assets/logo.psd": {
      "hash": "sha256:i9j0k1l2...",
      "status": "skipped",
      "reason": "Unsupported file type: .psd"
    }
  }
}
```

### 5.2 Status Values

| Status | Meaning |
|--------|---------|
| `pending` | File detected, not yet analyzed |
| `processing` | Analysis in progress (crash recovery marker) |
| `done` | Successfully analyzed, digest file exists |
| `skipped` | File type not supported or file unreadable |
| `error` | Analysis attempted but failed (see `error` field) |

### 5.3 Lifecycle Events

1. **First scan:** All files are registered with `pending` status and their SHA-256 hash.
2. **Analysis start:** Status transitions to `processing`. If the process crashes, stale `processing` entries are re-queued on the next scan.
3. **Analysis complete:** Status becomes `done`, `analyzedAt` is set, `digestPath` points to the output file.
4. **Re-scan (file changed):** If the stored hash differs from the current file hash, the entry is reset to `pending` and the old digest is overwritten.
5. **Re-scan (file deleted):** If a file tracked in `_index.json` no longer exists in `data/dropzone/`, the entry is marked with `status: "removed"` and the digest file is retained (soft delete) until the next SRS generation cleans up orphaned digests.

## 6. Hash-Based Change Detection

Change detection uses SHA-256 hashing to determine whether a file has been modified since its last analysis.

### 6.1 Hash Computation

The hash is computed over the raw file bytes (not extracted text) to detect any modification, including metadata changes in binary formats. For very large files (> 100 MB), the engine computes a composite hash: SHA-256 of the first 1 MB + file size + last modification timestamp. This composite approach avoids re-reading entire large files while still catching modifications.

### 6.2 Comparison Flow

```
For each file in data/dropzone/:
  1. Compute current hash
  2. Look up file path in _index.json
  3. If not found → new file → status = pending
  4. If found and hash matches → skip (no changes)
  5. If found and hash differs → changed → status = pending, old digest queued for overwrite
```

### 6.3 Incremental Processing

Only files with `pending` or `error` status are processed in each pipeline run. This means that after the initial full scan, subsequent runs only process new or modified files, making the pipeline efficient for large dropzones with hundreds of files.

## 7. Digest Aggregation

Before SRS generation (Step 3 in the main flow), all digest files are loaded and aggregated into a unified dataset.

### 7.1 Aggregation Rules

- **Requirements:** All requirements from all digests are collected. Duplicates (same title, > 0.85 similarity) are merged, keeping the higher priority and the most detailed description.
- **Constraints:** All constraints are deduplicated by exact string match. Near-duplicates are flagged for manual resolution.
- **Domain Terms:** Terms are merged by case-insensitive term name. If definitions conflict, both are preserved with source file attribution.
- **Stakeholders:** Merged by name. Roles and needs are combined if they differ across sources.
- **Pain Points:** Collected as-is; deduplication by similarity.
- **Workflows:** Merged by workflow name. Steps are unioned if the same workflow appears in multiple sources.

### 7.2 Conflict Resolution

When two digest files provide conflicting information (e.g., different priorities for the same requirement), the aggregation engine:

1. Records both versions in an internal conflict log.
2. Applies the default resolution strategy: prefer the digest from the file with the later `analyzedAt` timestamp.
3. Flags the conflict in the generated SRS as a comment (e.g., `<!-- CONFLICT: priority differs between rfp/main.pdf (Must) and notes/meeting.md (Should) -->`).

## 8. Error Handling

### 8.1 Unreadable Files

If a file cannot be read (permission denied, corrupted binary, encoding errors), the engine:

1. Sets `_index.json` status to `error` with an `error` field containing the error message.
2. Logs the error to the session log.
3. Continues processing remaining files (fail-open for individual files, fail-safe for the pipeline).

### 8.2 Empty Files

Files with zero bytes or no extractable text are recorded with status `skipped` and reason `"Empty or no extractable content"`.

### 8.3 Encoding Issues

The engine attempts UTF-8 decoding first, then falls back to ISO-8859-1, then Windows-1252. If all fail, the file is marked as `error` with reason `"Unable to determine file encoding"`.

### 8.4 Partial Extraction

If a file is partially readable (e.g., a corrupted PDF where only some pages extract), the engine processes what it can, sets status to `done`, but adds a `warnings` array to the digest noting which sections or pages failed.
