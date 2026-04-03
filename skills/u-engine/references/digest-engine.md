# digest-engine Reference

The digest-engine transforms raw input files from the dropzone into structured, machine-readable digest JSON files. It handles file detection, content analysis, SHA-256 hashing for change detection, index management, and incremental re-analysis.

## 1. Dropzone Scanning

The dropzone (`data/dropzone/`) is the entry point for all raw project input. Users place files here (RFP documents, meeting notes, screenshots, design files, etc.) and digest-engine processes them into structured digests.

### Scanning Algorithm

```
function scanDropzone():
    dropzonePath = "data/dropzone/"
    indexPath = "data/digest/_index.json"
    index = loadIndex(indexPath)

    files = listFiles(dropzonePath, recursive: true)

    for each file in files:
        relativePath = file.relativeTo(dropzonePath)
        hash = computeSHA256(file)
        existingEntry = index.find(e => e.sourcePath == relativePath)

        if existingEntry is null:
            // New file — needs analysis
            addToIndex(index, {
                sourcePath: relativePath,
                sourceHash: hash,
                status: "pending",
                addedAt: now(),
                analyzedAt: null,
                digestPath: null
            })
        else if existingEntry.sourceHash != hash:
            // Changed file — needs re-analysis
            existingEntry.sourceHash = hash
            existingEntry.status = "pending"
            existingEntry.analyzedAt = null
        // else: unchanged — skip

    // Check for removed files
    for each entry in index:
        if not fileExists(dropzonePath + entry.sourcePath):
            entry.status = "removed"

    saveIndex(index, indexPath)
    return index.filter(e => e.status == "pending")
```

### Scan Triggers

| Trigger | When |
|---------|------|
| `/u-plan` invocation | Before plan phase begins, scan for new/changed inputs |
| `/u-ingest` invocation | Explicit ingest command, always scans dropzone |
| Hook: `on-dropzone-added` | When a file is added to `data/dropzone/` via Write tool |

### Supported File Locations

```
data/dropzone/                    # Flat files
data/dropzone/rfp/                # Subdirectory grouping
data/dropzone/meeting-notes/      # Subdirectory grouping
data/dropzone/designs/            # Subdirectory grouping
```

The scanner recurses into all subdirectories. Hidden files (starting with `.`) and system files are ignored.

## 2. File Type Detection

The digest-engine identifies file types to determine the appropriate analysis strategy.

### Supported File Types

| Extension(s) | Category | Analysis Strategy |
|--------------|----------|-------------------|
| `.md`, `.txt` | Text document | Direct text extraction and NLP analysis |
| `.pdf` | PDF document | Text extraction from pages, table detection |
| `.docx` | Word document | Structured text extraction, heading detection |
| `.xlsx`, `.csv` | Spreadsheet | Row/column parsing, data model inference |
| `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp` | Image | Visual analysis — wireframes, mockups, diagrams |
| `.svg` | Vector graphic | SVG content analysis, diagram element extraction |
| `.html` | Web page | HTML parsing, content extraction |
| `.json` | Structured data | Direct JSON parsing and schema inference |
| `.yaml`, `.yml` | Structured data | YAML parsing and schema inference |
| `.pptx` | Presentation | Slide content extraction, text and image analysis |

### Detection Algorithm

```
function detectFileType(filePath):
    extension = filePath.extension().toLowerCase()

    typeMap = {
        ".md": "text", ".txt": "text",
        ".pdf": "pdf",
        ".docx": "word",
        ".xlsx": "spreadsheet", ".csv": "spreadsheet",
        ".png": "image", ".jpg": "image", ".jpeg": "image",
        ".gif": "image", ".webp": "image",
        ".svg": "vector",
        ".html": "webpage",
        ".json": "structured-data", ".yaml": "structured-data", ".yml": "structured-data",
        ".pptx": "presentation"
    }

    return typeMap[extension] or "unknown"
```

### Unknown File Types

Files with unrecognized extensions are logged with `status: "skipped"` in the index. They are not analyzed but their presence is recorded.

## 3. SHA-256 Hash Computation

Every source file in the dropzone is hashed using SHA-256 to enable change detection without reading entire file contents.

### Hash Computation

```
function computeSHA256(filePath):
    content = readFileAsBytes(filePath)
    return sha256(content).toHexString()
```

### Hash Usage

| Purpose | How Hash Is Used |
|---------|-----------------|
| New file detection | File exists in dropzone but has no entry in `_index.json` |
| Change detection | File exists in index but hash differs from stored `sourceHash` |
| Skip unchanged | File exists in index AND hash matches stored `sourceHash` → skip |
| Digest validation | Digest file's `sourceHash` matches current dropzone file hash |

### Hash Storage

The hash is stored in two places:

1. **`_index.json`**: In the entry's `sourceHash` field, updated on every scan
2. **Digest JSON**: In the `sourceHash` field, set at analysis time

If `_index.json` hash differs from the digest file's `sourceHash`, the file has changed since the last analysis and needs re-processing.

## 4. _index.json Management

The `_index.json` file at `data/digest/_index.json` is the master registry of all dropzone files and their processing status.

### Schema

```json
{
  "version": "1.0.0",
  "lastScanned": "2026-04-03T10:00:00Z",
  "entries": [
    {
      "sourcePath": "rfp-v2.pdf",
      "sourceHash": "a1b2c3d4e5f6...",
      "status": "done",
      "addedAt": "2026-04-03T09:00:00Z",
      "analyzedAt": "2026-04-03T09:05:00Z",
      "digestPath": "data/digest/rfp-v2.json",
      "fileType": "pdf",
      "fileSize": 245760
    },
    {
      "sourcePath": "meeting-notes/kickoff.md",
      "sourceHash": "f6e5d4c3b2a1...",
      "status": "pending",
      "addedAt": "2026-04-03T10:00:00Z",
      "analyzedAt": null,
      "digestPath": null,
      "fileType": "text",
      "fileSize": 4096
    }
  ]
}
```

### Entry Fields

| Field | Type | Description |
|-------|------|-------------|
| `sourcePath` | string | Relative path from `data/dropzone/` |
| `sourceHash` | string | SHA-256 hash of the source file |
| `status` | enum | `pending`, `processing`, `done`, `failed`, `removed`, `skipped` |
| `addedAt` | string (ISO-8601) | When the file was first detected in the dropzone |
| `analyzedAt` | string or null | When the analysis was last completed (null if not yet analyzed) |
| `digestPath` | string or null | Relative path to the generated digest JSON (null if not yet analyzed) |
| `fileType` | string | Detected file type category |
| `fileSize` | number | File size in bytes |

### Status Lifecycle

```
pending → processing → done
                     → failed (analysis error)
pending → skipped (unsupported file type)
done → pending (source file changed, re-analysis needed)
any → removed (source file deleted from dropzone)
```

### Status Transition Rules

| From | To | Trigger |
|------|----|---------|
| (new) | `pending` | File detected in dropzone scan with no existing entry |
| `pending` | `processing` | Analysis begins for this file |
| `processing` | `done` | Analysis completes successfully, digest written |
| `processing` | `failed` | Analysis encounters an error |
| `done` | `pending` | Source file hash changed (file was modified) |
| `pending` | `skipped` | File type is unsupported |
| any | `removed` | Source file no longer exists in dropzone |

### Index Operations

```
function loadIndex(path):
    if not fileExists(path):
        return { version: "1.0.0", lastScanned: null, entries: [] }
    return parseJSON(readFile(path))

function saveIndex(index, path):
    index.lastScanned = now()
    writeFile(path, toJSON(index, indent: 2))

function findEntry(index, sourcePath):
    return index.entries.find(e => e.sourcePath == sourcePath)

function addToIndex(index, entry):
    index.entries.push(entry)

function updateEntry(index, sourcePath, updates):
    entry = findEntry(index, sourcePath)
    Object.assign(entry, updates)
```

## 5. digest.json Structure

Each analyzed file produces a digest JSON file following `_meta/schemas/digest.schema.json`. The digest contains structured, machine-readable analysis of the raw input.

### Digest File Location

Digest files mirror the dropzone directory structure under `data/digest/`:

```
data/dropzone/rfp-v2.pdf        → data/digest/rfp-v2.json
data/dropzone/notes/kickoff.md  → data/digest/notes/kickoff.json
```

### Complete Digest Structure

```json
{
  "sourceFile": "rfp-v2.pdf",
  "sourceHash": "a1b2c3d4e5f6789...",
  "analyzedAt": "2026-04-03T09:05:00Z",
  "summary": "Request for Proposal for a customer management platform with CRM integration, multi-tenant support, and real-time analytics dashboard.",
  "keywords": ["CRM", "multi-tenant", "analytics", "dashboard", "REST API"],
  "requirements": [
    {
      "id": "REQ-001",
      "type": "functional",
      "title": "User Registration",
      "description": "The system shall allow new users to register with email and password, including email verification.",
      "priority": "Must"
    },
    {
      "id": "REQ-002",
      "type": "non-functional",
      "title": "Response Time",
      "description": "All API endpoints shall respond within 200ms at p95 under normal load.",
      "priority": "Should"
    }
  ],
  "constraints": [
    "Must deploy on AWS",
    "Must support PostgreSQL 14+",
    "Budget: $50,000 for MVP"
  ],
  "domainTerms": [
    {
      "term": "Tenant",
      "definition": "An isolated organizational unit within the multi-tenant system"
    },
    {
      "term": "Lead",
      "definition": "A potential customer in the sales pipeline"
    }
  ],
  "stakeholders": [
    {
      "name": "John Kim",
      "role": "Product Owner",
      "needs": "Real-time visibility into sales pipeline metrics"
    }
  ],
  "painPoints": [
    "Current system requires manual data entry between CRM and analytics tools",
    "No mobile access for field sales representatives"
  ],
  "workflows": [
    {
      "name": "Lead Qualification",
      "steps": [
        "Sales rep captures lead via web form or mobile app",
        "System auto-assigns lead score based on criteria",
        "Manager reviews leads with score > 70",
        "Qualified leads are converted to opportunities"
      ]
    }
  ]
}
```

### Field Extraction Rules

| Field | Extraction Method | Required |
|-------|-------------------|----------|
| `sourceFile` | Relative path from dropzone | Yes |
| `sourceHash` | SHA-256 hash at analysis time | Yes |
| `analyzedAt` | Timestamp when analysis completed | Yes |
| `summary` | Concise 1-3 sentence summary of the document | Yes |
| `keywords` | Top 5-15 domain keywords extracted from content | Yes |
| `requirements` | Identified requirements (functional and non-functional) | No (array, may be empty) |
| `constraints` | Technical, budget, or timeline constraints | No (array, may be empty) |
| `domainTerms` | Domain-specific terminology with definitions | No (array, may be empty) |
| `stakeholders` | Identified stakeholders with roles and needs | No (array, may be empty) |
| `painPoints` | Current pain points or problems described | No (array, may be empty) |
| `workflows` | Business workflows or processes described | No (array, may be empty) |

### Requirement ID Convention in Digests

Requirements extracted in the digest phase use temporary `REQ-{NNN}` IDs (1-increment). These are provisional and are re-assigned as proper `FR-{NNN}` or `NFR-{NNN}` IDs (10-increment) when the doc-engine generates the SRS document.

## 6. Mirror-Tree Creation

The digest directory mirrors the dropzone directory structure to maintain organizational correspondence.

### Mirror Rules

1. For every file in `data/dropzone/`, the digest output goes to the same relative path under `data/digest/`, with the extension changed to `.json`.
2. Subdirectories are created as needed:

```
data/dropzone/                     data/digest/
  rfp-v2.pdf              →         rfp-v2.json
  meeting-notes/                     meeting-notes/
    kickoff.md             →           kickoff.json
    sprint-1-review.md     →           sprint-1-review.json
  designs/                           designs/
    homepage-wireframe.png →           homepage-wireframe.json
```

3. Directory creation is automatic — if the directory does not exist, create it before writing the digest file.

### Mirror Verification

```
function verifyMirror():
    issues = []

    for each entry in _index.json where status == "done":
        expectedDigestPath = mirrorPath(entry.sourcePath)
        if entry.digestPath != expectedDigestPath:
            issues.add("Index path mismatch: {entry.digestPath} != {expectedDigestPath}")
        if not fileExists(expectedDigestPath):
            issues.add("Digest file missing: {expectedDigestPath}")

    return issues
```

## 7. Incremental Re-Analysis

The digest-engine supports incremental re-analysis, processing only files that have changed since the last analysis. This avoids redundant processing of unchanged files.

### Incremental Analysis Algorithm

```
function analyzeIncremental():
    // Step 1: Scan dropzone for new/changed files
    pendingFiles = scanDropzone()  // Returns entries with status: "pending"

    if pendingFiles.length == 0:
        log("No new or changed files. Skipping analysis.")
        return

    log("Found {pendingFiles.length} files to analyze.")

    // Step 2: Process each pending file
    for each entry in pendingFiles:
        entry.status = "processing"
        saveIndex()

        try:
            // Step 3: Analyze the file
            digest = analyzeFile(entry.sourcePath, entry.fileType)

            // Step 4: Write digest JSON
            digestPath = mirrorPath(entry.sourcePath)
            ensureDirectory(dirname(digestPath))
            writeFile(digestPath, toJSON(digest, indent: 2))

            // Step 5: Update index entry
            entry.status = "done"
            entry.analyzedAt = now()
            entry.digestPath = digestPath
            saveIndex()

            // Step 6: Update links.json
            nodeId = "digest:" + basenameWithoutExt(entry.sourcePath)
            depEngine.addNode(nodeId, "digest", digestPath)

        catch (error):
            entry.status = "failed"
            entry.error = error.message
            saveIndex()
            log("Failed to analyze {entry.sourcePath}: {error.message}")

    // Step 7: Handle removed files
    removedEntries = index.entries.filter(e => e.status == "removed")
    for each entry in removedEntries:
        // Remove digest file
        if entry.digestPath and fileExists(entry.digestPath):
            deleteFile(entry.digestPath)

        // Remove from links.json
        nodeId = "digest:" + basenameWithoutExt(entry.sourcePath)
        depEngine.removeNode(nodeId)

        // Remove from index
        index.entries = index.entries.filter(e => e != entry)

    saveIndex()
```

### Re-Analysis Triggers

| Trigger | Scope |
|---------|-------|
| Source file hash changed | Single file re-analysis |
| `/u-ingest --force` | Full re-analysis of all files (ignore hashes) |
| Digest schema version upgrade | Full re-analysis to apply new schema fields |

### Performance Considerations

1. **Hash-first comparison**: Always compare hashes before reading file content. SHA-256 comparison is O(1) versus full content comparison.
2. **Parallel analysis**: Multiple pending files MAY be analyzed in parallel if they are independent (no cross-references between raw files).
3. **Lazy directory creation**: Only create mirror directories when a digest file is about to be written.
4. **Index persistence**: Save `_index.json` after each file's analysis completes (not in batch) to ensure crash recovery.
