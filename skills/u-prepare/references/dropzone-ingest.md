# Dropzone Ingest Rules

> Rules for adding files and links into `.u-maker/data/dropzone/` as part of `/u-prepare`. Governs what the user can drop and how non-file sources (URLs, Figma links) are represented. PBGD Plan.Prepare, v4.0.

## 1. Accepted sources

### 1.1 File drops

Place any of these directly into `.u-maker/data/dropzone/` (any subdirectory):

| Extension | Handled by `/u-analyze` |
|-----------|-------------------------|
| `.md`, `.mdx` | Text + heading-aware extraction |
| `.pdf` | Page-by-page text + table extraction |
| `.docx`, `.doc` | Paragraph + heading + table extraction |
| `.xlsx`, `.csv` | Tabular ingest; header-row detection |
| `.txt`, `.log` | Line-based segmentation |
| `.png`, `.jpg`, `.jpeg`, `.svg`, `.webp` | Catalog + embedded text (SVG only by default) |

See `skills/u-analyze/references/digest-extraction.md` for the full per-type extraction strategy.

### 1.2 Link descriptors

For non-file sources (URLs, Figma designs, external documents), create a descriptor file in `data/dropzone/links/`:

**`.figma-link`** (Figma designs/boards/make):

```
https://figma.com/design/{fileKey}/{fileName}?node-id={nodeId}
```

One URL per line. `/u-analyze` reads these via the Figma MCP and emits `sourceType: "figma-frame"` digest entries.

**`.url`** (plain web pages):

```
url: https://example.com/spec-page
title: Optional human-friendly title
fetchedAt: optional-iso-date
```

**`.code-link`** (reference to a local code path, used in B1/B2):

```
path: src/modules/orders/
description: Order processing logic. Cross-ref with digest-req-001.
```

### 1.3 Unsupported drops

Files with extensions not in the accepted list (e.g., `.pptx`, `.zip`, `.exe`) are **not rejected** — they are tracked in `_index.json` with `status: "skipped"` and a reason field, so the user is aware they were ignored.

## 2. Organization conventions

Users are free to use any subdirectory structure under `data/dropzone/`. Recommended convention:

```
data/dropzone/
├── rfp/              # RFPs, proposals
├── specs/            # Existing specs, design docs
├── meetings/         # Meeting notes
├── links/            # .figma-link, .url, .code-link descriptors
└── misc/             # Unsorted
```

The mirror path is preserved when digests are written to `data/digest/`, so organizing dropzone inputs helps keep the digest navigable.

## 3. Size limits

- Files > 100 MB use composite hashing (first 1 MB + size + mtime) instead of full-file SHA-256, to keep scans fast.
- Files > 50,000 extracted characters are chunked for analysis (see `digest-extraction.md` §3).

## 4. What NOT to drop

- **Secrets / credentials** — the dropzone is not encrypted; the digest is plain JSON.
- **Binary build artifacts** — irrelevant, wastes hash time.
- **Source code** — belongs outside `.u-maker/`; reference via `.code-link` or use `/u-reverse` in Scenario B2.

## 5. Hand-off to `/u-analyze`

`/u-prepare` calls `/u-analyze` automatically after dropzone ingest completes. The user can also invoke `/u-analyze` directly at any time to re-process the current dropzone contents.
