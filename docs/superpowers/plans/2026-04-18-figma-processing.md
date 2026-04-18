# Figma Processing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `/u-figma` command family (scan/extract/status/verify/sync/skip/ingest) with `u-agent-figma`, manifest-first coverage ledger, variant-exhaustive detection, dense-frame chunking, 3-tier comments, and auto-delegation from `/u-plan` and `/u-design`.

**Architecture:** Phase 1–6 pipeline inside `u-agent-figma` (scan → gate → extract → verify → aggregate → sync). Single `manifest.json` is source of truth; per-frame digests isolated; aggregate.json rolls up for downstream. Pure-JS utility modules under `skills/u-figma/lib/` for variant detection, dedup, density, REST client — testable with `node --test`.

**Tech Stack:** Claude Code plugin (agents + skills + hooks), Node.js CommonJS (built-in `node --test`), JSON Schema (existing `_meta/schemas/` pattern), optional `ajv` for schema validation. No bundler.

**Authoritative spec:** `skills/u-plan/references/figma-analysis.md` PART II (§7–§14). Every task references the relevant spec section.

**Ordering principle:** bottom-up (lib → schema → command skill → agent → integration). Each phase ends with a commit; each phase's tests must pass before advancing.

---

## File Structure (all new unless marked)

```
skills/u-figma/                                NEW
  SKILL.md                                     router + /u-figma entry
  references/
    manifest-schema.md                         human-readable schema doc (→ §8)
    variant-detection.md                       human-readable algorithm (→ §7)
    pipeline.md                                phase-by-phase (→ §10)
    comments-fallback.md                       3-tier (→ §11)
    integration.md                             plan/design wiring (→ §12)
  lib/
    variant-detect.js                          four-source union + completeness checks
    density.js                                 isDense() + chunking decision
    comment-dedup.js                           3-tier merge + priority
    comment-rest.js                            Figma REST client (PAT)
    frame-classifier.js                        contentType delegation (reuses PART I §2.1)
    coverage.js                                coverageWarnings computation
    manifest.js                                load/save/atomic writes
    hash.js                                    canonical node-tree hash
  tests/
    fixtures/
      component-set.mock.json
      naming-variant.mock.json
      positional-cluster.mock.json
      suffix-variant.mock.json
      dense-frame.mock.json
      comments-rest.mock.json
      sticky-notes.mock.json
    variant-detect.test.js
    density.test.js
    comment-dedup.test.js
    comment-rest.test.js
    coverage.test.js
    hash.test.js
    manifest.test.js

agents/
  u-agent-figma.md                             NEW — scan/extract/verify owner

_meta/schemas/
  figma-manifest.schema.json                   NEW
  figma-aggregate.schema.json                  NEW
  config.schema.json                           MODIFY — add figma block
  digest.schema.json                           MODIFY — add annotations[]

hooks/
  on-dropzone-figma-link.js                    NEW — detect *.figma-link → trigger ingest

skills/u-plan/
  SKILL.md                                     MODIFY — delegate section
  references/
    figma-analysis.md                          DONE (PART II already committed)

skills/u-design/
  SKILL.md                                     MODIFY — delegate section

package.json                                   NEW — minimal, add ajv devDep + test script
.gitignore                                     MODIFY — add .u-maker/secrets.local.json
```

---

## Phase 0 — Bootstrap

### Task 0.1: Project package.json + test runner

**Files:**
- Create: `package.json`
- Modify: `.gitignore`

- [ ] **Step 1: Write package.json**

```json
{
  "name": "u-maker-plugin",
  "version": "3.5.0",
  "private": true,
  "description": "u-maker PDCA SSoT Claude Code plugin",
  "scripts": {
    "test": "node --test skills/**/tests/*.test.js",
    "test:figma": "node --test skills/u-figma/tests/*.test.js",
    "validate:schemas": "node _meta/scripts/validate-schemas.js"
  },
  "devDependencies": {
    "ajv": "^8.17.1",
    "ajv-formats": "^3.0.1"
  }
}
```

- [ ] **Step 2: Verify Node version**

Run: `node --version`
Expected: `v20.x` or newer (built-in `node --test` requires >= 18).

- [ ] **Step 3: Install deps**

Run: `npm install`
Expected: creates `node_modules/` with ajv. No other changes.

- [ ] **Step 4: Append .gitignore rules**

Append to `.gitignore`:
```
node_modules/
.u-maker/secrets.local.json
skills/u-figma/tests/.tmp/
```

- [ ] **Step 5: Smoke-test the runner**

Create placeholder `skills/u-figma/tests/smoke.test.js`:
```js
const { test } = require('node:test');
const assert = require('node:assert');
test('runner works', () => assert.strictEqual(1 + 1, 2));
```

Run: `npm run test:figma`
Expected: `# pass 1  # fail 0`. Delete `smoke.test.js` after.

- [ ] **Step 6: Commit**

```bash
git add package.json package-lock.json .gitignore
git commit -m "chore(figma): bootstrap package.json with node:test runner"
```

---

## Phase 1 — Schemas

### Task 1.1: Manifest schema

**Files:**
- Create: `_meta/schemas/figma-manifest.schema.json`
- Create: `skills/u-figma/tests/fixtures/manifest-valid.json`
- Create: `skills/u-figma/tests/fixtures/manifest-invalid-missing-required.json`
- Create: `skills/u-figma/tests/manifest.test.js`

- [ ] **Step 1: Write schema (spec §8.2)**

Create `_meta/schemas/figma-manifest.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "figma-manifest.schema.json",
  "title": "Figma Manifest",
  "description": "Inventory + coverage ledger for a Figma file. See skills/u-plan/references/figma-analysis.md §8.",
  "type": "object",
  "required": ["schemaVersion", "fileKey", "figmaUrl", "scan", "stats", "pages"],
  "properties": {
    "schemaVersion": { "const": "1.0" },
    "fileKey": { "type": "string", "minLength": 1 },
    "fileName": { "type": "string" },
    "figmaUrl": { "type": "string", "format": "uri" },
    "figmaFileUrl": { "type": "string", "format": "uri" },
    "scan": {
      "type": "object",
      "required": ["scannedAt", "scannedBy", "mcpServer", "scope"],
      "properties": {
        "scannedAt": { "type": "string", "format": "date-time" },
        "scannedBy": { "type": "string" },
        "mcpServer": { "enum": ["figma-mcp-go", "plugin_figma"] },
        "scope": { "enum": ["file", "page", "frame"] }
      }
    },
    "stats": {
      "type": "object",
      "required": ["totalPages", "totalFrames", "totalComponentSets", "totalVariants", "extractStatus"],
      "properties": {
        "totalPages": { "type": "integer", "minimum": 0 },
        "totalFrames": { "type": "integer", "minimum": 0 },
        "totalComponentSets": { "type": "integer", "minimum": 0 },
        "totalVariants": { "type": "integer", "minimum": 0 },
        "totalComments": { "type": "integer", "minimum": 0 },
        "extractStatus": {
          "type": "object",
          "required": ["pending", "in_progress", "done", "failed", "skipped"],
          "properties": {
            "pending": { "type": "integer", "minimum": 0 },
            "in_progress": { "type": "integer", "minimum": 0 },
            "done": { "type": "integer", "minimum": 0 },
            "failed": { "type": "integer", "minimum": 0 },
            "skipped": { "type": "integer", "minimum": 0 }
          }
        }
      }
    },
    "pages": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["pageId", "pageName", "pageIndex", "hash", "frames"],
        "properties": {
          "pageId": { "type": "string" },
          "pageName": { "type": "string" },
          "pageIndex": { "type": "integer", "minimum": 0 },
          "hash": { "type": "string", "pattern": "^sha256:[0-9a-f]{64}$" },
          "frames": {
            "type": "array",
            "items": { "$ref": "#/$defs/frame" }
          }
        }
      }
    },
    "componentSets": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["nodeId", "name", "variants"],
        "properties": {
          "nodeId": { "type": "string" },
          "name": { "type": "string" },
          "pageId": { "type": "string" },
          "variants": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["nodeId", "label", "status"],
              "properties": {
                "nodeId": { "type": "string" },
                "label": { "type": "string" },
                "properties": { "type": "object" },
                "status": { "$ref": "#/$defs/status" }
              }
            }
          }
        }
      }
    },
    "comments": {
      "type": "object",
      "properties": {
        "source": { "type": "string" },
        "fetchedAt": { "type": "string", "format": "date-time" },
        "counts": { "type": "object" },
        "unresolved": { "type": "integer", "minimum": 0 },
        "path": { "type": "string" },
        "patConfigured": { "type": "boolean" },
        "warnings": { "type": "array", "items": { "type": "string" } }
      }
    },
    "coverageWarnings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type"],
        "properties": {
          "type": { "enum": ["orphan-base", "state-gap", "naming-inconsistency", "extreme-density", "empty-component-set", "scan-error"] }
        }
      }
    },
    "retry": {
      "type": "object",
      "required": ["maxAttempts", "backoffSeconds"],
      "properties": {
        "maxAttempts": { "type": "integer", "minimum": 1 },
        "backoffSeconds": { "type": "array", "items": { "type": "integer", "minimum": 0 } }
      }
    }
  },
  "$defs": {
    "status": { "enum": ["pending", "in_progress", "done", "failed", "skipped", "removed"] },
    "frame": {
      "type": "object",
      "required": ["nodeId", "name", "nodeType", "bbox", "nodeCount", "hash", "status"],
      "properties": {
        "nodeId": { "type": "string" },
        "name": { "type": "string" },
        "nodeType": { "type": "string" },
        "bbox": {
          "type": "object",
          "required": ["x", "y", "w", "h"],
          "properties": {
            "x": { "type": "number" },
            "y": { "type": "number" },
            "w": { "type": "number", "minimum": 0 },
            "h": { "type": "number", "minimum": 0 }
          }
        },
        "nodeCount": { "type": "integer", "minimum": 0 },
        "textNodeCount": { "type": "integer", "minimum": 0 },
        "depth": { "type": "integer", "minimum": 0 },
        "variantOf": {
          "oneOf": [
            { "type": "null" },
            {
              "type": "object",
              "required": ["baseName", "detectionSource"],
              "properties": {
                "baseName": { "type": "string" },
                "baseNodeId": { "type": "string" },
                "stateLabel": { "type": ["string", "null"] },
                "detectionSource": { "enum": ["component-set", "naming-pattern", "positional", "suffix-marker"] }
              }
            }
          ]
        },
        "detectedContentTypes": {
          "type": "array",
          "items": { "enum": ["screen-design", "screen-planning", "diagram", "annotation", "specification", "design-tokens", "assets", "prototype"] }
        },
        "denseness": { "enum": ["normal", "dense", "extreme"] },
        "hash": { "type": "string", "pattern": "^sha256:[0-9a-f]{64}$" },
        "status": { "$ref": "#/$defs/status" },
        "digestPath": { "type": "string" },
        "screenshotPath": { "type": "string" },
        "extractedAt": { "type": ["string", "null"], "format": "date-time" },
        "extractionAttempts": { "type": "integer", "minimum": 0 },
        "errorPath": { "type": ["string", "null"] },
        "subFrameChunks": {
          "oneOf": [
            { "type": "null" },
            {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["chunkId", "name", "digestPath", "status"],
                "properties": {
                  "chunkId": { "type": "string" },
                  "name": { "type": "string" },
                  "digestPath": { "type": "string" },
                  "status": { "$ref": "#/$defs/status" }
                }
              }
            }
          ]
        }
      }
    }
  }
}
```

- [ ] **Step 2: Write valid fixture**

Create `skills/u-figma/tests/fixtures/manifest-valid.json` with minimum valid data:

```json
{
  "schemaVersion": "1.0",
  "fileKey": "abc123",
  "figmaUrl": "https://www.figma.com/design/abc123/Test",
  "scan": {
    "scannedAt": "2026-04-18T10:00:00.000Z",
    "scannedBy": "u-figma@3.5.0",
    "mcpServer": "figma-mcp-go",
    "scope": "file"
  },
  "stats": {
    "totalPages": 1,
    "totalFrames": 1,
    "totalComponentSets": 0,
    "totalVariants": 0,
    "totalComments": 0,
    "extractStatus": { "pending": 1, "in_progress": 0, "done": 0, "failed": 0, "skipped": 0 }
  },
  "pages": [
    {
      "pageId": "0:1",
      "pageName": "Page 1",
      "pageIndex": 0,
      "hash": "sha256:0000000000000000000000000000000000000000000000000000000000000000",
      "frames": [
        {
          "nodeId": "1:2",
          "name": "Login",
          "nodeType": "FRAME",
          "bbox": { "x": 0, "y": 0, "w": 1440, "h": 900 },
          "nodeCount": 10,
          "hash": "sha256:1111111111111111111111111111111111111111111111111111111111111111",
          "status": "pending"
        }
      ]
    }
  ]
}
```

- [ ] **Step 3: Write invalid fixture (missing required)**

Create `skills/u-figma/tests/fixtures/manifest-invalid-missing-required.json`:

```json
{
  "schemaVersion": "1.0",
  "fileKey": "abc"
}
```

- [ ] **Step 4: Write failing test**

Create `skills/u-figma/tests/manifest.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const path = require('path');
const fs = require('fs');
const Ajv = require('ajv').default;
const addFormats = require('ajv-formats').default;

const schema = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../../../_meta/schemas/figma-manifest.schema.json'), 'utf8')
);
const ajv = new Ajv({ strict: false });
addFormats(ajv);
const validate = ajv.compile(schema);

test('accepts valid manifest fixture', () => {
  const fixture = require('./fixtures/manifest-valid.json');
  const ok = validate(fixture);
  assert.strictEqual(ok, true, JSON.stringify(validate.errors));
});

test('rejects manifest missing required fields', () => {
  const fixture = require('./fixtures/manifest-invalid-missing-required.json');
  const ok = validate(fixture);
  assert.strictEqual(ok, false);
});
```

- [ ] **Step 5: Run tests**

Run: `npm run test:figma`
Expected: both tests pass. If fixture-valid fails, print `validate.errors` — fix schema or fixture until alignment.

- [ ] **Step 6: Commit**

```bash
git add _meta/schemas/figma-manifest.schema.json skills/u-figma/tests/
git commit -m "feat(figma): add manifest schema + validation tests"
```

### Task 1.2: Aggregate schema

**Files:**
- Create: `_meta/schemas/figma-aggregate.schema.json`
- Create: `skills/u-figma/tests/fixtures/aggregate-valid.json`
- Create: `skills/u-figma/tests/aggregate.test.js`

- [ ] **Step 1: Write schema**

Create `_meta/schemas/figma-aggregate.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "figma-aggregate.schema.json",
  "title": "Figma Aggregate Roll-up",
  "description": "Downstream-facing roll-up from per-frame digests. See figma-analysis.md §10.5 / §12.1.",
  "type": "object",
  "required": ["fileKey", "scannedAt", "screenDescriptions"],
  "properties": {
    "fileKey": { "type": "string" },
    "figmaUrl": { "type": "string", "format": "uri" },
    "scannedAt": { "type": "string", "format": "date-time" },
    "screenDescriptions": { "type": "array" },
    "businessRules": { "type": "array" },
    "processingRules": { "type": "array" },
    "domainRules": { "type": "array" },
    "validationRules": { "type": "array" },
    "permissionRules": { "type": "array" },
    "uiSpecifications": { "type": "array" },
    "dataRules": { "type": "array" },
    "commonRules": { "type": "array" },
    "decisions": { "type": "array" },
    "stateTransitions": { "type": "array" },
    "componentSets": { "type": "array" },
    "designTokens": { "type": "object" },
    "assets": { "type": "object" },
    "prototype": { "type": "object" },
    "crossRefs": { "type": "array" },
    "acceptanceHints": { "type": "array" }
  }
}
```

- [ ] **Step 2: Valid fixture**

Create `skills/u-figma/tests/fixtures/aggregate-valid.json`:

```json
{
  "fileKey": "abc123",
  "figmaUrl": "https://www.figma.com/design/abc123/Test",
  "scannedAt": "2026-04-18T10:00:00.000Z",
  "screenDescriptions": []
}
```

- [ ] **Step 3: Test**

Create `skills/u-figma/tests/aggregate.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const Ajv = require('ajv').default;
const addFormats = require('ajv-formats').default;

const schema = JSON.parse(fs.readFileSync(path.join(__dirname, '../../../_meta/schemas/figma-aggregate.schema.json'), 'utf8'));
const ajv = new Ajv({ strict: false });
addFormats(ajv);
const validate = ajv.compile(schema);

test('accepts valid aggregate', () => {
  const f = require('./fixtures/aggregate-valid.json');
  assert.strictEqual(validate(f), true, JSON.stringify(validate.errors));
});
```

- [ ] **Step 4: Run and commit**

Run: `npm run test:figma` (all prior tests still pass).
```bash
git add _meta/schemas/figma-aggregate.schema.json skills/u-figma/tests/aggregate.test.js skills/u-figma/tests/fixtures/aggregate-valid.json
git commit -m "feat(figma): add aggregate schema + tests"
```

### Task 1.3: Extend digest schema with annotations[] (spec §11.7)

**Files:**
- Modify: `_meta/schemas/digest.schema.json`

- [ ] **Step 1: Inspect existing digest schema**

Run: `cat _meta/schemas/digest.schema.json | head -80`
Locate the `properties` block.

- [ ] **Step 2: Add `annotations[]` under `properties`**

Add inside `"properties": {…}` (top-level, alphabetically near other arrays):

```json
"annotations": {
  "type": "array",
  "description": "Comments/annotations attached to the source — deduped from REST (Tier 1), dev-annotations (Tier 2), and sticky/section heuristic (Tier 3). See figma-analysis.md §11.",
  "items": {
    "type": "object",
    "required": ["id", "source", "message"],
    "properties": {
      "id": { "type": "string" },
      "source": { "enum": ["rest-api", "dev-annotation", "section-heuristic", "sticky-heuristic"] },
      "message": { "type": "string" },
      "author": { "type": "string" },
      "createdAt": { "type": "string", "format": "date-time" },
      "resolved": { "type": "boolean" },
      "nodeRef": { "type": "string" },
      "thread": { "type": "array" }
    }
  }
}
```

- [ ] **Step 3: Verify existing tests still pass**

Run: `npm test`
Expected: all tests pass (no regressions).

- [ ] **Step 4: Commit**

```bash
git add _meta/schemas/digest.schema.json
git commit -m "feat(figma): extend digest schema with annotations[]"
```

---

## Phase 2 — Variant Detection Library

Spec §7. Pure JS module with exhaustive tests.

### Task 2.1: `extractBase()` — name pattern parser (spec §7.2)

**Files:**
- Create: `skills/u-figma/lib/variant-detect.js`
- Create: `skills/u-figma/tests/variant-detect.test.js`

- [ ] **Step 1: Write failing tests**

Create `skills/u-figma/tests/variant-detect.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { extractBase } = require('../lib/variant-detect');

test('slash-separated state', () => {
  assert.deepStrictEqual(extractBase('Login / Error'), { base: 'Login', state: 'Error' });
});
test('middle-dot separator', () => {
  assert.deepStrictEqual(extractBase('Login · Loading'), { base: 'Login', state: 'Loading' });
});
test('hyphen separator', () => {
  assert.deepStrictEqual(extractBase('Login - Disabled'), { base: 'Login', state: 'Disabled' });
});
test('underscore state suffix', () => {
  assert.deepStrictEqual(extractBase('Login_error'), { base: 'Login', state: 'error' });
});
test('paren state', () => {
  assert.deepStrictEqual(extractBase('Login (empty)'), { base: 'Login', state: 'empty' });
});
test('bracket state', () => {
  assert.deepStrictEqual(extractBase('Login [disabled]'), { base: 'Login', state: 'disabled' });
});
test('no state returns base unchanged', () => {
  assert.deepStrictEqual(extractBase('Dashboard'), { base: 'Dashboard', state: null });
});
test('underscore NOT a state keyword stays base', () => {
  assert.deepStrictEqual(extractBase('user_profile'), { base: 'user_profile', state: null });
});
```

- [ ] **Step 2: Run — tests fail (module not found)**

Run: `npm run test:figma`
Expected: fails with `Cannot find module '../lib/variant-detect'`.

- [ ] **Step 3: Implement minimum**

Create `skills/u-figma/lib/variant-detect.js`:

```js
'use strict';

const STATE_KEYWORDS = 'default|hover|pressed|disabled|error|loading|empty|success|focus';

const PATTERNS = [
  { re: /^(.+?)\s*\/\s*(.+)$/, base: 1, state: 2 },
  { re: /^(.+?)\s*·\s*(.+)$/, base: 1, state: 2 },
  { re: /^(.+?)\s*-\s*(.+)$/, base: 1, state: 2 },
  { re: new RegExp(`^(.+?)_(${STATE_KEYWORDS})$`, 'i'), base: 1, state: 2 },
  { re: /^(.+?)\s*\((.+)\)$/, base: 1, state: 2 },
  { re: /^(.+?)\s*\[(.+)\]$/, base: 1, state: 2 }
];

function extractBase(frameName) {
  for (const p of PATTERNS) {
    const m = frameName.match(p.re);
    if (m) return { base: m[p.base].trim(), state: m[p.state].trim() };
  }
  return { base: frameName, state: null };
}

module.exports = { extractBase };
```

- [ ] **Step 4: Run — tests pass**

Run: `npm run test:figma`
Expected: all 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/u-figma/lib/variant-detect.js skills/u-figma/tests/variant-detect.test.js
git commit -m "feat(figma): variant name pattern parser (extractBase)"
```

### Task 2.2: Positional cluster detection (spec §7.3)

**Files:**
- Modify: `skills/u-figma/lib/variant-detect.js`
- Modify: `skills/u-figma/tests/variant-detect.test.js`
- Create: `skills/u-figma/tests/fixtures/positional-cluster.mock.json`

- [ ] **Step 1: Write fixture**

Create `skills/u-figma/tests/fixtures/positional-cluster.mock.json`:

```json
{
  "frames": [
    { "nodeId": "1:10", "name": "Login", "bbox": { "x": 0, "y": 0, "w": 400, "h": 600 } },
    { "nodeId": "1:11", "name": "Login", "bbox": { "x": 450, "y": 0, "w": 400, "h": 600 } },
    { "nodeId": "1:12", "name": "Login", "bbox": { "x": 900, "y": 0, "w": 400, "h": 600 } },
    { "nodeId": "1:20", "name": "Dashboard", "bbox": { "x": 0, "y": 800, "w": 1200, "h": 900 } }
  ]
}
```

- [ ] **Step 2: Write failing test**

Append to `skills/u-figma/tests/variant-detect.test.js`:

```js
const { detectPositionalVariants } = require('../lib/variant-detect');

test('3 horizontally adjacent same-base frames are a variant cluster', () => {
  const { frames } = require('./fixtures/positional-cluster.mock.json');
  const clusters = detectPositionalVariants(frames);
  assert.strictEqual(clusters.length, 1);
  assert.strictEqual(clusters[0].base, 'Login');
  assert.deepStrictEqual(clusters[0].frameIds.sort(), ['1:10', '1:11', '1:12']);
});

test('single frame with unique base is not a cluster', () => {
  const frames = [{ nodeId: '1:20', name: 'Dashboard', bbox: { x: 0, y: 0, w: 100, h: 100 } }];
  assert.deepStrictEqual(detectPositionalVariants(frames), []);
});
```

- [ ] **Step 3: Run — fail**

Expected: `detectPositionalVariants is not a function`.

- [ ] **Step 4: Implement**

Append to `skills/u-figma/lib/variant-detect.js`:

```js
function detectPositionalVariants(frames) {
  const byBase = new Map();
  for (const f of frames) {
    const { base } = extractBase(f.name);
    if (!byBase.has(base)) byBase.set(base, []);
    byBase.get(base).push(f);
  }

  const clusters = [];
  for (const [base, group] of byBase) {
    if (group.length < 2) continue;
    const sorted = [...group].sort((a, b) => a.bbox.x - b.bbox.x);
    const avgWidth = sorted.reduce((s, f) => s + f.bbox.w, 0) / sorted.length;
    const adjacent = sorted.every((f, i) => {
      if (i === 0) return true;
      const prev = sorted[i - 1];
      const gap = f.bbox.x - (prev.bbox.x + prev.bbox.w);
      return gap <= 1.5 * avgWidth;
    });
    const sameY = sorted.every(f => Math.abs(f.bbox.y - sorted[0].bbox.y) <= 50);
    if (adjacent && sameY) {
      clusters.push({ base, frameIds: sorted.map(f => f.nodeId) });
    }
  }
  return clusters;
}

module.exports.detectPositionalVariants = detectPositionalVariants;
```

- [ ] **Step 5: Run — pass**

Run: `npm run test:figma`
Expected: tests pass.

- [ ] **Step 6: Commit**

```bash
git add skills/u-figma/lib/variant-detect.js skills/u-figma/tests/variant-detect.test.js skills/u-figma/tests/fixtures/positional-cluster.mock.json
git commit -m "feat(figma): positional-cluster variant detection"
```

### Task 2.3: Four-source union + dedup (spec §7.1)

**Files:**
- Modify: `skills/u-figma/lib/variant-detect.js`
- Modify: `skills/u-figma/tests/variant-detect.test.js`
- Create: `skills/u-figma/tests/fixtures/component-set.mock.json`

- [ ] **Step 1: Write fixture**

Create `skills/u-figma/tests/fixtures/component-set.mock.json`:

```json
{
  "componentSets": [
    {
      "nodeId": "5:100",
      "name": "Button",
      "variants": [
        { "nodeId": "5:101", "label": "Primary/Default", "properties": { "style": "Primary", "state": "Default" } },
        { "nodeId": "5:102", "label": "Primary/Hover", "properties": { "style": "Primary", "state": "Hover" } }
      ]
    }
  ],
  "frames": [
    { "nodeId": "6:200", "name": "Login / Default", "bbox": { "x": 0, "y": 0, "w": 100, "h": 100 } },
    { "nodeId": "6:201", "name": "Login / Error", "bbox": { "x": 0, "y": 0, "w": 100, "h": 100 } },
    { "nodeId": "6:300", "name": "Card_error", "bbox": { "x": 0, "y": 0, "w": 100, "h": 100 } }
  ]
}
```

- [ ] **Step 2: Write failing test**

Append:

```js
const { unionVariants } = require('../lib/variant-detect');

test('unions four sources + dedupes by nodeId', () => {
  const fx = require('./fixtures/component-set.mock.json');
  const result = unionVariants({
    componentSets: fx.componentSets,
    frames: fx.frames
  });
  const ids = result.map(v => v.nodeId).sort();
  // 2 component-set variants + 2 naming-pattern + 1 suffix-marker = 5
  assert.strictEqual(ids.length, 5);
  const bySource = {};
  for (const v of result) bySource[v.variantOf.detectionSource] = (bySource[v.variantOf.detectionSource] || 0) + 1;
  assert.strictEqual(bySource['component-set'], 2);
  assert.strictEqual(bySource['naming-pattern'], 2);
  assert.strictEqual(bySource['suffix-marker'], 1);
});
```

- [ ] **Step 3: Run — fail**

Expected: `unionVariants is not a function`.

- [ ] **Step 4: Implement**

Append to `variant-detect.js`:

```js
const SUFFIX_MARKER_RE = new RegExp(`^(.+?)[_\\-\\s]?\\(?(${STATE_KEYWORDS})\\)?$`, 'i');

function unionVariants({ componentSets = [], frames = [] }) {
  const out = [];
  const seen = new Set();

  // A. COMPONENT_SET
  for (const cs of componentSets) {
    for (const v of cs.variants || []) {
      if (seen.has(v.nodeId)) continue;
      seen.add(v.nodeId);
      out.push({
        nodeId: v.nodeId,
        name: v.label,
        variantOf: {
          baseName: cs.name,
          baseNodeId: cs.nodeId,
          stateLabel: v.label,
          detectionSource: 'component-set'
        }
      });
    }
  }

  // B. Naming pattern
  for (const f of frames) {
    if (seen.has(f.nodeId)) continue;
    const { base, state } = extractBase(f.name);
    if (state && state.length > 0 && base !== f.name) {
      // Only "naming-pattern" when the regex path is NOT the underscore-state-suffix path
      // (that is source D). We distinguish by checking whether the separator is a "soft" one.
      const isSoftSep = /[\/·\-()\[\]]/.test(f.name) && !/^.+_[a-zA-Z]+$/.test(f.name);
      if (isSoftSep) {
        seen.add(f.nodeId);
        out.push({
          nodeId: f.nodeId,
          name: f.name,
          variantOf: { baseName: base, stateLabel: state, detectionSource: 'naming-pattern' }
        });
      }
    }
  }

  // C. Positional cluster
  const clusters = detectPositionalVariants(frames);
  for (const c of clusters) {
    for (const id of c.frameIds) {
      if (seen.has(id)) continue;
      seen.add(id);
      const f = frames.find(x => x.nodeId === id);
      out.push({
        nodeId: id,
        name: f.name,
        variantOf: { baseName: c.base, stateLabel: null, detectionSource: 'positional' }
      });
    }
  }

  // D. Suffix marker
  for (const f of frames) {
    if (seen.has(f.nodeId)) continue;
    const m = f.name.match(SUFFIX_MARKER_RE);
    if (m) {
      seen.add(f.nodeId);
      out.push({
        nodeId: f.nodeId,
        name: f.name,
        variantOf: { baseName: m[1].replace(/[_\-\s]$/, ''), stateLabel: m[2].toLowerCase(), detectionSource: 'suffix-marker' }
      });
    }
  }

  return out;
}

module.exports.unionVariants = unionVariants;
```

- [ ] **Step 5: Run — pass**

Run: `npm run test:figma`
Expected: tests pass. If fails, inspect which source misclassifies and tighten the `isSoftSep` check.

- [ ] **Step 6: Commit**

```bash
git add skills/u-figma/lib/variant-detect.js skills/u-figma/tests/variant-detect.test.js skills/u-figma/tests/fixtures/component-set.mock.json
git commit -m "feat(figma): union four variant sources with dedup"
```

### Task 2.4: Completeness checks (spec §7.5)

**Files:**
- Modify: `skills/u-figma/lib/variant-detect.js`
- Modify: `skills/u-figma/tests/variant-detect.test.js`

- [ ] **Step 1: Write failing tests**

Append:

```js
const { checkCompleteness } = require('../lib/variant-detect');

test('orphan-base detected when two frames share LHS without variantOf', () => {
  const frames = [
    { nodeId: '1:10', name: 'Modal', bbox: { x: 0, y: 0, w: 100, h: 100 }, variantOf: null },
    { nodeId: '1:11', name: 'Modal', bbox: { x: 500, y: 800, w: 100, h: 100 }, variantOf: null }
  ];
  const warnings = checkCompleteness({ frames, componentSets: [] });
  const orphan = warnings.find(w => w.type === 'orphan-base');
  assert.ok(orphan, 'expected orphan-base warning');
  assert.strictEqual(orphan.baseName, 'Modal');
});

test('empty-component-set flagged when variants=0', () => {
  const warnings = checkCompleteness({
    frames: [],
    componentSets: [{ nodeId: '5:999', name: 'Empty', variants: [] }]
  });
  assert.ok(warnings.find(w => w.type === 'empty-component-set'));
});

test('state-gap when base has only Default', () => {
  const frames = [
    { nodeId: '1:1', name: 'Form / Default', bbox: { x: 0, y: 0, w: 100, h: 100 }, variantOf: { baseName: 'Form', stateLabel: 'Default' } }
  ];
  const warnings = checkCompleteness({ frames, componentSets: [] });
  assert.ok(warnings.find(w => w.type === 'state-gap'));
});

test('naming-inconsistency when slash and hyphen mixed in same page', () => {
  const frames = [
    { nodeId: '1:1', name: 'A / Default', pageId: 'p1', bbox: { x: 0, y: 0, w: 100, h: 100 } },
    { nodeId: '1:2', name: 'B - Error', pageId: 'p1', bbox: { x: 0, y: 0, w: 100, h: 100 } }
  ];
  const warnings = checkCompleteness({ frames, componentSets: [] });
  assert.ok(warnings.find(w => w.type === 'naming-inconsistency'));
});
```

- [ ] **Step 2: Run — fail**

Expected: `checkCompleteness is not a function`.

- [ ] **Step 3: Implement**

Append to `variant-detect.js`:

```js
function checkCompleteness({ frames, componentSets }) {
  const warnings = [];

  // 1. Empty component-sets
  for (const cs of componentSets || []) {
    if (!cs.variants || cs.variants.length === 0) {
      warnings.push({ type: 'empty-component-set', componentSetId: cs.nodeId, name: cs.name });
    }
  }

  // 2. Orphan base
  const baseGroups = new Map();
  for (const f of frames) {
    const { base } = extractBase(f.name);
    if (!baseGroups.has(base)) baseGroups.set(base, []);
    baseGroups.get(base).push(f);
  }
  for (const [base, group] of baseGroups) {
    if (group.length < 2) continue;
    const allOrphans = group.every(f => !f.variantOf);
    if (allOrphans) {
      warnings.push({
        type: 'orphan-base',
        baseName: base,
        frameIds: group.map(f => f.nodeId),
        reason: 'two+ frames share LHS but no variantOf'
      });
    }
  }

  // 3. State gap: base with only "Default"
  const knownStates = new Map();
  for (const f of frames) {
    if (!f.variantOf || !f.variantOf.stateLabel) continue;
    const base = f.variantOf.baseName;
    if (!knownStates.has(base)) knownStates.set(base, new Set());
    knownStates.get(base).add(f.variantOf.stateLabel.toLowerCase());
  }
  const expectedExtras = ['error', 'loading', 'empty'];
  for (const [base, states] of knownStates) {
    const hasOnlyDefault = states.size === 1 && [...states][0] === 'default';
    if (hasOnlyDefault) {
      warnings.push({
        type: 'state-gap',
        baseName: base,
        presentStates: ['Default'],
        missingSuspected: expectedExtras.map(s => s[0].toUpperCase() + s.slice(1))
      });
    }
  }

  // 4. Naming inconsistency per page
  const byPage = new Map();
  for (const f of frames) {
    const pid = f.pageId || 'unknown';
    if (!byPage.has(pid)) byPage.set(pid, { slash: 0, hyphen: 0 });
    if (f.name.includes(' / ')) byPage.get(pid).slash++;
    else if (f.name.includes(' - ')) byPage.get(pid).hyphen++;
  }
  for (const [pid, c] of byPage) {
    if (c.slash > 0 && c.hyphen > 0) {
      warnings.push({ type: 'naming-inconsistency', scope: pid, detail: `${c.slash} slash + ${c.hyphen} hyphen` });
    }
  }

  return warnings;
}

module.exports.checkCompleteness = checkCompleteness;
```

- [ ] **Step 4: Run — pass**

Run: `npm run test:figma`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/u-figma/lib/variant-detect.js skills/u-figma/tests/variant-detect.test.js
git commit -m "feat(figma): variant completeness warnings (orphan/state-gap/naming/empty-set)"
```

---

## Phase 3 — Density & Chunking

### Task 3.1: `isDense()` classifier (spec §10.3)

**Files:**
- Create: `skills/u-figma/lib/density.js`
- Create: `skills/u-figma/tests/density.test.js`

- [ ] **Step 1: Write failing tests**

Create `skills/u-figma/tests/density.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { classifyDensity } = require('../lib/density');

const base = { nodeCount: 10, textNodeCount: 5, depth: 3, bbox: { w: 1440, h: 900 } };

test('normal frame', () => {
  assert.strictEqual(classifyDensity(base), 'normal');
});
test('dense by nodeCount > 800', () => {
  assert.strictEqual(classifyDensity({ ...base, nodeCount: 900 }), 'dense');
});
test('extreme by nodeCount > 2000', () => {
  assert.strictEqual(classifyDensity({ ...base, nodeCount: 2100 }), 'extreme');
});
test('dense by textNodeCount > 150', () => {
  assert.strictEqual(classifyDensity({ ...base, textNodeCount: 200 }), 'dense');
});
test('dense by depth > 10', () => {
  assert.strictEqual(classifyDensity({ ...base, depth: 12 }), 'dense');
});
test('dense by bbox area > 4_000_000', () => {
  assert.strictEqual(classifyDensity({ ...base, bbox: { w: 2500, h: 2000 } }), 'dense');
});
test('extreme supersedes other dense signals', () => {
  assert.strictEqual(classifyDensity({ ...base, nodeCount: 5000, textNodeCount: 200 }), 'extreme');
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/density.js`:

```js
'use strict';

const DEFAULTS = {
  nodeCountThreshold: 800,
  textNodeThreshold: 150,
  depthThreshold: 10,
  areaThreshold: 4_000_000,
  extremeNodeCount: 2000
};

function classifyDensity(frame, cfg = {}) {
  const c = { ...DEFAULTS, ...cfg };
  if (frame.nodeCount > c.extremeNodeCount) return 'extreme';
  if (frame.nodeCount > c.nodeCountThreshold) return 'dense';
  if ((frame.textNodeCount ?? 0) > c.textNodeThreshold) return 'dense';
  if ((frame.depth ?? 0) > c.depthThreshold) return 'dense';
  const area = (frame.bbox?.w ?? 0) * (frame.bbox?.h ?? 0);
  if (area > c.areaThreshold) return 'dense';
  return 'normal';
}

module.exports = { classifyDensity, DEFAULTS };
```

- [ ] **Step 4: Run — pass**

Run: `npm run test:figma`
Expected: 7 density tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/u-figma/lib/density.js skills/u-figma/tests/density.test.js
git commit -m "feat(figma): density classifier (normal/dense/extreme)"
```

---

## Phase 4 — Comments

### Task 4.1: Hash helper (spec §2.4 canonicalize)

**Files:**
- Create: `skills/u-figma/lib/hash.js`
- Create: `skills/u-figma/tests/hash.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/hash.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { hashCanonical } = require('../lib/hash');

test('same logical content → same hash regardless of key order', () => {
  const a = { x: 1, y: [{ a: 1, b: 2 }] };
  const b = { y: [{ b: 2, a: 1 }], x: 1 };
  assert.strictEqual(hashCanonical(a), hashCanonical(b));
});
test('different content → different hash', () => {
  assert.notStrictEqual(hashCanonical({ x: 1 }), hashCanonical({ x: 2 }));
});
test('returns sha256:<64 hex>', () => {
  assert.match(hashCanonical({}), /^sha256:[0-9a-f]{64}$/);
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/hash.js`:

```js
'use strict';
const crypto = require('crypto');

function canonicalize(v) {
  if (v === null || typeof v !== 'object') return v;
  if (Array.isArray(v)) return v.map(canonicalize);
  return Object.keys(v).sort().reduce((acc, k) => {
    acc[k] = canonicalize(v[k]);
    return acc;
  }, {});
}

function hashCanonical(obj) {
  const c = canonicalize(obj);
  const s = JSON.stringify(c);
  return 'sha256:' + crypto.createHash('sha256').update(s).digest('hex');
}

module.exports = { hashCanonical, canonicalize };
```

- [ ] **Step 4: Run — pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/hash.js skills/u-figma/tests/hash.test.js
git commit -m "feat(figma): canonical JSON hash helper"
```

### Task 4.2: Comment dedup (spec §11.6)

**Files:**
- Create: `skills/u-figma/lib/comment-dedup.js`
- Create: `skills/u-figma/tests/comment-dedup.test.js`

- [ ] **Step 1: Failing test**

Create `skills/u-figma/tests/comment-dedup.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { dedupComments } = require('../lib/comment-dedup');

test('REST wins over sticky when message+node match', () => {
  const rest = [{ id: 'r1', source: 'rest-api', message: 'Check this flow', nodeRef: '1:2' }];
  const sticky = [{ id: 's1', source: 'sticky-heuristic', message: 'Check this flow', nodeRef: '1:2' }];
  const out = dedupComments({ rest, annotations: [], heuristic: sticky });
  assert.strictEqual(out.length, 1);
  assert.strictEqual(out[0].source, 'rest-api');
});
test('distinct messages preserved', () => {
  const rest = [{ id: 'r1', source: 'rest-api', message: 'A', nodeRef: '1:2' }];
  const sticky = [{ id: 's1', source: 'sticky-heuristic', message: 'B', nodeRef: '1:2' }];
  const out = dedupComments({ rest, annotations: [], heuristic: sticky });
  assert.strictEqual(out.length, 2);
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/comment-dedup.js`:

```js
'use strict';
const crypto = require('crypto');

const PRIORITY = { 'rest-api': 4, 'dev-annotation': 3, 'section-heuristic': 2, 'sticky-heuristic': 1 };

function keyOf(c) {
  const ref = c.nodeRef || (c.x != null ? `${c.x},${c.y}` : '');
  return crypto.createHash('md5').update((c.message || '').trim() + '|' + ref).digest('hex');
}

function dedupComments({ rest = [], annotations = [], heuristic = [] }) {
  const merged = new Map();
  for (const list of [rest, annotations, heuristic]) {
    for (const c of list) {
      const k = keyOf(c);
      const existing = merged.get(k);
      if (!existing || PRIORITY[c.source] > PRIORITY[existing.source]) merged.set(k, c);
    }
  }
  return Array.from(merged.values());
}

module.exports = { dedupComments, keyOf };
```

- [ ] **Step 4: Run — pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/comment-dedup.js skills/u-figma/tests/comment-dedup.test.js
git commit -m "feat(figma): 3-tier comment dedup with priority"
```

### Task 4.3: Figma REST client (spec §11.2)

**Files:**
- Create: `skills/u-figma/lib/comment-rest.js`
- Create: `skills/u-figma/tests/comment-rest.test.js`

- [ ] **Step 1: Failing tests (use global fetch mocking)**

Create `skills/u-figma/tests/comment-rest.test.js`:

```js
const { test, mock } = require('node:test');
const assert = require('node:assert');
const { fetchComments, resolvePAT } = require('../lib/comment-rest');

test('fetches with X-Figma-Token header', async () => {
  const calls = [];
  global.fetch = async (url, opts) => {
    calls.push({ url, opts });
    return {
      ok: true,
      status: 200,
      json: async () => ({ comments: [{ id: '1', message: 'hi', user: { handle: 'alice' }, created_at: '2026-04-18T00:00:00Z', resolved_at: null, client_meta: { node_id: '1:2' } }] })
    };
  };
  const out = await fetchComments({ fileKey: 'abc', pat: 'figd_token' });
  assert.strictEqual(calls[0].url, 'https://api.figma.com/v1/files/abc/comments');
  assert.strictEqual(calls[0].opts.headers['X-Figma-Token'], 'figd_token');
  assert.strictEqual(out.total, 1);
  assert.strictEqual(out.comments[0].source, 'rest-api');
});

test('rate-limit retry with exponential backoff', async (t) => {
  let n = 0;
  global.fetch = async () => {
    n++;
    if (n < 3) return { ok: false, status: 429, headers: new Map() };
    return { ok: true, status: 200, json: async () => ({ comments: [] }) };
  };
  const out = await fetchComments({ fileKey: 'abc', pat: 'x', waitMs: () => 0 });
  assert.strictEqual(n, 3);
  assert.strictEqual(out.total, 0);
});

test('resolvePAT reads env var', () => {
  process.env.FIGMA_PAT = 'env-tok';
  assert.strictEqual(resolvePAT({ envName: 'FIGMA_PAT', secretsPath: '/nowhere' }), 'env-tok');
  delete process.env.FIGMA_PAT;
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/comment-rest.js`:

```js
'use strict';
const fs = require('fs');

const DEFAULT_BACKOFF = [0, 2000, 8000];

function resolvePAT({ envName = 'FIGMA_PAT', secretsPath } = {}) {
  if (envName && process.env[envName]) return process.env[envName];
  if (secretsPath && fs.existsSync(secretsPath)) {
    try {
      const obj = JSON.parse(fs.readFileSync(secretsPath, 'utf8'));
      if (obj.figmaPat) return obj.figmaPat;
    } catch (_) {}
  }
  return null;
}

async function fetchComments({ fileKey, pat, backoffMs = DEFAULT_BACKOFF, waitMs = ms => new Promise(r => setTimeout(r, ms)) }) {
  if (!pat) throw new Error('Figma PAT not configured');
  const url = `https://api.figma.com/v1/files/${fileKey}/comments`;
  let lastErr;
  for (let attempt = 0; attempt < backoffMs.length; attempt++) {
    if (backoffMs[attempt]) await waitMs(backoffMs[attempt]);
    const res = await fetch(url, { headers: { 'X-Figma-Token': pat } });
    if (res.ok) {
      const body = await res.json();
      const comments = (body.comments || []).map(c => ({
        id: c.id,
        source: 'rest-api',
        message: c.message,
        author: c.user?.handle,
        createdAt: c.created_at,
        resolvedAt: c.resolved_at,
        parentId: c.parent_id,
        clientMeta: c.client_meta || null,
        nodeRef: c.client_meta?.node_id ?? null,
        thread: []
      }));
      return {
        fetchedAt: new Date().toISOString(),
        source: 'rest-api',
        total: comments.length,
        unresolved: comments.filter(c => !c.resolvedAt).length,
        comments
      };
    }
    lastErr = new Error(`HTTP ${res.status}`);
    if (res.status !== 429 && res.status !== 503) break;
  }
  throw lastErr || new Error('Unknown fetch failure');
}

module.exports = { fetchComments, resolvePAT };
```

- [ ] **Step 4: Run — pass**

Run: `npm run test:figma`
Expected: all 3 REST tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/u-figma/lib/comment-rest.js skills/u-figma/tests/comment-rest.test.js
git commit -m "feat(figma): REST client for Figma comments (PAT, retry, normalize)"
```

### Task 4.4: Sticky-note heuristic (spec §11.5)

**Files:**
- Modify: `skills/u-figma/lib/comment-dedup.js` (add `detectStickyNotes`) — OR create separate module
- Create: `skills/u-figma/lib/comment-heuristic.js`
- Create: `skills/u-figma/tests/comment-heuristic.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/comment-heuristic.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { detectStickyNotes } = require('../lib/comment-heuristic');

const STICKY_YELLOW = { r: 1.0, g: 0.92, b: 0.23, a: 1 };

test('detects saturated yellow sticky outside main screens', () => {
  const nodes = [
    {
      nodeId: 's1', type: 'FRAME', bbox: { x: 2000, y: 500, w: 180, h: 120 },
      fills: [{ type: 'SOLID', color: STICKY_YELLOW }],
      children: [{ type: 'TEXT', characters: 'remember to confirm with PM' }]
    }
  ];
  const mainScreens = [{ bbox: { x: 0, y: 0, w: 1440, h: 900 } }];
  const out = detectStickyNotes(nodes, mainScreens);
  assert.strictEqual(out.length, 1);
  assert.strictEqual(out[0].source, 'sticky-heuristic');
});

test('ignores large frames', () => {
  const nodes = [{
    nodeId: 'big', type: 'FRAME', bbox: { x: 0, y: 0, w: 1200, h: 800 },
    fills: [{ type: 'SOLID', color: STICKY_YELLOW }],
    children: [{ type: 'TEXT', characters: 'x' }]
  }];
  assert.strictEqual(detectStickyNotes(nodes, []).length, 0);
});

test('ignores non-sticky color', () => {
  const nodes = [{
    nodeId: 'grey', type: 'FRAME', bbox: { x: 2000, y: 500, w: 100, h: 100 },
    fills: [{ type: 'SOLID', color: { r: 0.5, g: 0.5, b: 0.5, a: 1 } }],
    children: [{ type: 'TEXT', characters: 'x' }]
  }];
  assert.strictEqual(detectStickyNotes(nodes, []).length, 0);
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/comment-heuristic.js`:

```js
'use strict';

function isInside(bbox, outer) {
  return bbox.x >= outer.x && bbox.y >= outer.y &&
         bbox.x + bbox.w <= outer.x + outer.w &&
         bbox.y + bbox.h <= outer.y + outer.h;
}

function isStickyColor(fill) {
  if (!fill || fill.type !== 'SOLID' || !fill.color) return false;
  const { r, g, b } = fill.color;
  // saturation heuristic: max-min > 0.3
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  if (max - min < 0.3) return false;
  // yellow (r,g high,b low) OR pink (r high, b high-ish) OR cyan/blue (b high)
  const yellow = r > 0.7 && g > 0.7 && b < 0.5;
  const pink = r > 0.8 && g < 0.7 && b > 0.5;
  const blue = b > 0.7 && r < 0.6;
  return yellow || pink || blue;
}

function detectStickyNotes(nodes, mainScreens) {
  const result = [];
  for (const n of nodes) {
    if (n.type !== 'FRAME' && n.type !== 'RECTANGLE') continue;
    if (n.bbox.w > 300 || n.bbox.h > 300) continue;
    if (!n.children || n.children.length !== 1) continue;
    if (n.children[0].type !== 'TEXT') continue;
    const fill = (n.fills || [])[0];
    if (!isStickyColor(fill)) continue;
    if (mainScreens.some(s => isInside(n.bbox, s.bbox))) continue;
    result.push({
      id: `sticky-${n.nodeId}`,
      source: 'sticky-heuristic',
      message: n.children[0].characters,
      nodeRef: n.nodeId
    });
  }
  return result;
}

module.exports = { detectStickyNotes, isStickyColor, isInside };
```

- [ ] **Step 4: Run — pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/comment-heuristic.js skills/u-figma/tests/comment-heuristic.test.js
git commit -m "feat(figma): sticky-note heuristic (Tier 3 fallback)"
```

---

## Phase 5 — Manifest I/O

### Task 5.1: Atomic manifest read/write (spec §8.5)

**Files:**
- Create: `skills/u-figma/lib/manifest.js`
- Create: `skills/u-figma/tests/manifest-io.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/manifest-io.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { loadManifest, saveManifest, updateFrameStatus } = require('../lib/manifest');

function tmpPath() {
  return path.join(os.tmpdir(), `u-figma-test-${Date.now()}-${Math.random()}.json`);
}

test('saveManifest writes atomically (temp + rename)', () => {
  const p = tmpPath();
  saveManifest(p, { schemaVersion: '1.0', fileKey: 'x', pages: [] });
  assert.ok(fs.existsSync(p));
  const loaded = loadManifest(p);
  assert.strictEqual(loaded.fileKey, 'x');
  fs.unlinkSync(p);
});

test('updateFrameStatus only touches frame status + extractedAt', () => {
  const p = tmpPath();
  saveManifest(p, {
    schemaVersion: '1.0', fileKey: 'x',
    pages: [{ pageId: 'p1', frames: [{ nodeId: '1:1', name: 'A', status: 'pending', extractionAttempts: 0 }] }]
  });
  updateFrameStatus(p, '1:1', { status: 'done', extractedAt: '2026-04-18T10:00:00Z', digestPath: 'frames/1-1.digest.json' });
  const after = loadManifest(p);
  const frame = after.pages[0].frames[0];
  assert.strictEqual(frame.status, 'done');
  assert.strictEqual(frame.digestPath, 'frames/1-1.digest.json');
  assert.strictEqual(frame.name, 'A'); // other fields preserved
  fs.unlinkSync(p);
});

test('loadManifest returns null for missing file', () => {
  assert.strictEqual(loadManifest('/nowhere/manifest.json'), null);
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/manifest.js`:

```js
'use strict';
const fs = require('fs');
const path = require('path');

function loadManifest(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function saveManifest(filePath, manifest) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tmp = filePath + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(manifest, null, 2));
  fs.renameSync(tmp, filePath);
}

function updateFrameStatus(filePath, nodeId, patch) {
  const m = loadManifest(filePath);
  if (!m) throw new Error(`manifest not found: ${filePath}`);
  for (const page of m.pages || []) {
    const frame = (page.frames || []).find(f => f.nodeId === nodeId);
    if (frame) {
      Object.assign(frame, patch);
      saveManifest(filePath, m);
      return;
    }
  }
  throw new Error(`frame ${nodeId} not in manifest`);
}

module.exports = { loadManifest, saveManifest, updateFrameStatus };
```

- [ ] **Step 4: Run — pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/manifest.js skills/u-figma/tests/manifest-io.test.js
git commit -m "feat(figma): atomic manifest read/write + partial frame update"
```

---

## Phase 6 — Skill Routers (LLM entry points)

LLM-executed skills. Each SKILL.md has frontmatter + clear instructions referencing the spec. No unit tests for markdown — smoke-tested in Phase 9.

### Task 6.1: `skills/u-figma/SKILL.md` — router

**Files:**
- Create: `skills/u-figma/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

Create `skills/u-figma/SKILL.md`:

```markdown
---
name: u-figma
description: "This skill should be used when the user asks to 'analyze figma', 'figma scan', 'extract figma', '/u-figma', provides a figma.com URL, or wants to process Figma files into SRS/IA/Screen Spec/Design System inputs. Handles manifest-first scan → extract → verify → sync pipeline."
version: 1.0.0
triggers:
  - "/u-figma"
  - "figma scan"
  - "figma extract"
  - "figma.com/design/"
  - "figma 분석"
---

# u-figma — Figma Processing

`/u-figma <sub-command> <url> [options]`

Manifest-first, variant-exhaustive, coverage-tracked Figma analysis pipeline. Authoritative design: `skills/u-plan/references/figma-analysis.md` PART II (§7–§14).

**Primary Agent:** u-agent-figma
**Engine Dependencies:** (none — self-contained)

## Sub-commands

| Sub | Purpose |
|---|---|
| `scan <url>` | Build inventory manifest only. No extraction. See spec §10.1 Phase 1. |
| `extract <url>` | Iterate pending frames. See spec §10.1 Phase 3. |
| `status <url>` | Print coverage report. See spec §8.6. |
| `verify <url>` | Post-hoc verification + auto-retry. See spec §10.1 Phase 4. |
| `sync <url>` | Propagate aggregate.json to SRS/Design System. See spec §12. |
| `skip <url>` | Mark a frame as skipped. See spec §8.3. |
| `ingest <url>` | End-to-end: scan + gate + extract + verify + sync. |

## Flags (common)

| Flag | Applies to | Meaning |
|---|---|---|
| `--scope file\|page\|frame` | scan | Restrict traversal scope |
| `--refresh` | scan, extract | Force re-hash and re-extract |
| `--page <id>`, `--frame <id>` | extract | Restrict extraction |
| `--retry-failed` | extract | Re-run only failed frames |
| `--limit N` | extract | Process at most N frames |
| `--to plan\|design\|both` | sync | Target docs |
| `--no-comments` | scan, ingest | Disable all comment tiers |
| `--reason "..."` | skip | Documented skip reason |

## Execution Flow

### 1. Server detection (spec §10.1 Phase 0)

1. Try `mcp__figma-mcp-go__get_node` — if available → primary.
2. Else try `mcp__plugin_figma_figma__authenticate` — authenticate, then use.
3. Else: fail with install guidance.

### 2. Delegate to u-agent-figma

All sub-commands spawn `u-agent-figma` with:
- resolved MCP server prefix
- URL + parsed `fileKey`, `pageId`, `nodeId`
- config from `.u-maker/u-maker.config.json` (`figma` block)
- manifest path `.u-maker/data/figma/<fileKey>/manifest.json`

The agent returns a summary; this skill renders the coverage report to the user.

### 3. Adaptive gate (spec §9.4)

On `ingest`: after Phase 1 (scan) completes, if manifest.stats.totalFrames > `figma.autoExtractThreshold` (default 80), prompt user [Y/S/M/N]. `scan` + `extract` direct calls bypass the gate.

## References

- `references/variant-detection.md` — four-source variant algorithm (spec §7)
- `references/manifest-schema.md` — manifest.json fields (spec §8)
- `references/pipeline.md` — 6-phase pipeline (spec §10)
- `references/comments-fallback.md` — 3-tier comments (spec §11)
- `references/integration.md` — /u-plan and /u-design wiring (spec §12)

## Library modules (lib/)

| Module | Spec | Purpose |
|---|---|---|
| `variant-detect.js` | §7 | 4-source union + completeness checks |
| `density.js` | §10.3 | normal/dense/extreme classification |
| `hash.js` | §2.4 | canonical node-tree hash |
| `manifest.js` | §8 | atomic read/write + partial update |
| `comment-rest.js` | §11.2 | Figma REST API client |
| `comment-heuristic.js` | §11.5 | sticky-note + section detection |
| `comment-dedup.js` | §11.6 | 3-tier merge with priority |
```

- [ ] **Step 2: Structural validation**

Run: `head -20 skills/u-figma/SKILL.md`
Expected: valid YAML frontmatter, `name: u-figma` present.

- [ ] **Step 3: Commit**

```bash
git add skills/u-figma/SKILL.md
git commit -m "feat(figma): u-figma skill router with 7 sub-commands"
```

### Task 6.2: Reference docs (human-readable extracts from spec)

**Files:**
- Create: `skills/u-figma/references/variant-detection.md`
- Create: `skills/u-figma/references/manifest-schema.md`
- Create: `skills/u-figma/references/pipeline.md`
- Create: `skills/u-figma/references/comments-fallback.md`
- Create: `skills/u-figma/references/integration.md`

- [ ] **Step 1: Each reference file is a redirect + relevant extract**

For each file above, the content is:

```markdown
# <Topic>

> Authoritative spec: `skills/u-plan/references/figma-analysis.md` §<N>. This file exists so the u-figma skill can load focused context without reading the full 1876-line spec.
```

Followed by the corresponding section copied from `figma-analysis.md` PART II:
- `variant-detection.md` ← §7 (full)
- `manifest-schema.md` ← §8 (full)
- `pipeline.md` ← §10 (full)
- `comments-fallback.md` ← §11 (full)
- `integration.md` ← §12 (full)

Read `skills/u-plan/references/figma-analysis.md` and copy each section. Do not paraphrase.

- [ ] **Step 2: Verify cross-links**

Run: `grep -c "figma-analysis.md" skills/u-figma/references/*.md`
Expected: each file references the spec at least once.

- [ ] **Step 3: Commit**

```bash
git add skills/u-figma/references/
git commit -m "feat(figma): focused reference docs for u-figma skill"
```

---

## Phase 7 — u-agent-figma

### Task 7.1: Agent markdown

**Files:**
- Create: `agents/u-agent-figma.md`

- [ ] **Step 1: Write agent**

Create `agents/u-agent-figma.md`:

```markdown
---
name: u-agent-figma
description: "Owns Figma manifest-first processing. Executes scan → extract → verify → aggregate in its own context window, shielding the main thread from per-frame iteration. Called by u-figma skill for all sub-commands."
tools: Read, Write, Edit, Glob, Grep, Bash, mcp__figma-mcp-go__*, mcp__plugin_figma_figma__*
color: purple
---

# u-agent-figma

Primary agent for the `/u-figma` command family. Isolated context lets the agent iterate 100+ frames without burdening the caller.

## Responsibilities

1. **MCP server resolution** — detect `figma-mcp-go` vs `plugin_figma`, set prefix for all subsequent tool calls. On auth-required flow, call `mcp__plugin_figma_figma__authenticate` then `complete_authentication`.
2. **Scan** — enumerate all pages → all frames per page → variant detection (via `skills/u-figma/lib/variant-detect.js`) → density classification → comment collection (3 tiers) → `manifest.json` atomic write.
3. **Extract** — iterate `status=pending` frames; per frame choose content-type strategy from PART I §3.1–§3.8; chunk if `denseness != normal`; write per-frame digest; update status atomically.
4. **Verify** — walk `coverageWarnings`, auto-retry failed frames once even without `--fix`, re-run variant completeness checks; write report.
5. **Aggregate** — merge per-frame digests into `aggregate.json` with cross-refs; ensure `componentSets[]` carries every variant.
6. **Sync** — on `--to plan`: mirror aggregate to `data/digest/figma_<fileKey>.digest.json`. On `--to design`: write `design-system-source.json`.
7. **Progress streaming** — emit per-frame status lines (see spec §10.4).

## Input

Invocation carries:
- `subCommand` — one of scan/extract/status/verify/sync/skip/ingest
- `figmaUrl`
- parsed `fileKey`, `pageId`, `nodeId`, `scope`
- `projectRoot` (absolute path to `.u-maker/`)
- `config` (subset of `u-maker.config.json` `figma` block)
- `options` (flags)

## Output

Returns a JSON summary:

```json
{
  "ok": true,
  "subCommand": "ingest",
  "manifestPath": ".u-maker/data/figma/<fileKey>/manifest.json",
  "aggregatePath": ".u-maker/data/figma/<fileKey>/aggregate.json",
  "stats": { "done": 247, "failed": 0, "variants": 89 },
  "warnings": [ ... ],
  "elapsedMs": 252000
}
```

## Library dependencies

All lib modules under `skills/u-figma/lib/`. The agent:

1. Requires modules via `require('<repo>/skills/u-figma/lib/variant-detect')` etc.
2. Uses Bash to invoke Node one-shots for heavy CPU work (clustering large frame sets).
3. Writes manifest through `manifest.js` exclusively (atomic guarantees).

## Content-type extraction strategies

Delegates to PART I of `skills/u-plan/references/figma-analysis.md`:
- `screen-design` → §3.1
- `screen-planning` → §3.2
- `diagram` → §3.3
- `annotation` → §3.4
- `design-tokens` → §3.5
- `assets` → §3.6
- `prototype` → §3.7
- `specification` → §3.8

## Failure handling

| Failure | Response |
|---|---|
| MCP not available | Return `{ "ok": false, "reason": "no-mcp" }` with install instructions. |
| REST 429 | Exponential backoff per spec §11 via `comment-rest.js`. |
| Single-frame extraction timeout | Mark frame `failed`, continue loop. Max 3 attempts then `failed` final. |
| Crash mid-extract | Next invocation reads `status=in_progress` frames, resets to `pending`. |
| PAT missing | Prompt once via AskUserQuestion; on skip, mark `comments.source=skipped`. |

## Spec reference

Every decision traces to `skills/u-plan/references/figma-analysis.md` PART II — do not deviate without updating that spec first.
```

- [ ] **Step 2: Validate frontmatter**

Run: `head -5 agents/u-agent-figma.md`
Expected: `---\nname: u-agent-figma\n...`.

- [ ] **Step 3: Commit**

```bash
git add agents/u-agent-figma.md
git commit -m "feat(figma): u-agent-figma dedicated agent"
```

---

## Phase 8 — Hooks & Config

### Task 8.1: Dropzone .figma-link auto-detect hook

**Files:**
- Create: `hooks/on-dropzone-figma-link.js`
- Modify: `hooks/hooks.json`

- [ ] **Step 1: Read existing hooks.json**

Run: `cat hooks/hooks.json`
Note the registration pattern.

- [ ] **Step 2: Write hook**

Create `hooks/on-dropzone-figma-link.js`:

```js
// on-dropzone-figma-link.js
// Trigger: *.figma-link or *.figma.txt file added to data/dropzone/
// Action: mark a trigger file so u-agent-plan knows to invoke /u-figma ingest.
'use strict';
const fs = require('fs');
const path = require('path');

module.exports = async function onDropzoneFigmaLink({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const dropzone = path.join(umaker, 'data', 'dropzone');
  if (!filePath.startsWith(dropzone)) return;

  const isLinkFile = filePath.endsWith('.figma-link') || filePath.endsWith('.figma.txt');
  if (!isLinkFile) return;

  const urlRaw = fs.readFileSync(filePath, 'utf8').trim();
  const match = urlRaw.match(/https:\/\/www\.figma\.com\/design\/([^\/\s?]+)/);
  if (!match) return;

  const triggersPath = path.join(umaker, 'data', 'figma', '_triggers.json');
  fs.mkdirSync(path.dirname(triggersPath), { recursive: true });

  let triggers = { pending: [] };
  if (fs.existsSync(triggersPath)) {
    triggers = JSON.parse(fs.readFileSync(triggersPath, 'utf8'));
  }
  const exists = triggers.pending.find(t => t.url === urlRaw);
  if (!exists) {
    triggers.pending.push({
      url: urlRaw,
      fileKey: match[1],
      sourceFile: path.relative(dropzone, filePath),
      addedAt: new Date().toISOString()
    });
    const tmp = triggersPath + '.tmp';
    fs.writeFileSync(tmp, JSON.stringify(triggers, null, 2));
    fs.renameSync(tmp, triggersPath);
  }
};
```

- [ ] **Step 3: Register in hooks.json**

Edit `hooks/hooks.json` to add an entry for `on-dropzone-figma-link.js` on the `Write` tool post event matching paths under `data/dropzone/`. Use the existing entry pattern for `on-dropzone-added.js` as a template.

- [ ] **Step 4: Manual smoke test**

Run:
```bash
mkdir -p /tmp/u-figma-smoke/.u-maker/data/dropzone
echo 'https://www.figma.com/design/abc123/Test' > /tmp/u-figma-smoke/.u-maker/data/dropzone/design.figma-link
node -e "require('./hooks/on-dropzone-figma-link')({ filePath: '/tmp/u-figma-smoke/.u-maker/data/dropzone/design.figma-link', projectRoot: '/tmp/u-figma-smoke' })"
cat /tmp/u-figma-smoke/.u-maker/data/figma/_triggers.json
```
Expected: `_triggers.json` created with one entry, `fileKey: "abc123"`.

Cleanup: `rm -rf /tmp/u-figma-smoke`.

- [ ] **Step 5: Commit**

```bash
git add hooks/on-dropzone-figma-link.js hooks/hooks.json
git commit -m "feat(figma): hook detects .figma-link in dropzone"
```

### Task 8.2: Config schema — figma block

**Files:**
- Modify: `_meta/schemas/config.schema.json`

- [ ] **Step 1: Read existing schema**

Run: `cat _meta/schemas/config.schema.json`
Identify top-level properties block.

- [ ] **Step 2: Add figma block**

Add under `"properties"`:

```json
"figma": {
  "type": "object",
  "description": "Configuration for /u-figma pipeline. See figma-analysis.md §12.7.",
  "properties": {
    "enabled": { "type": "boolean", "default": true },
    "autoExtractThreshold": { "type": "integer", "minimum": 1, "default": 80 },
    "maxChunkDepth": { "type": "integer", "minimum": 1, "default": 3 },
    "comments": {
      "type": "object",
      "properties": {
        "enabled": { "type": "boolean", "default": true },
        "heuristicTier3": { "type": "boolean", "default": true },
        "patEnv": { "type": "string", "default": "FIGMA_PAT" }
      }
    },
    "variants": {
      "type": "object",
      "properties": {
        "detectNamingPatterns": { "type": "boolean", "default": true },
        "detectPositional": { "type": "boolean", "default": true },
        "detectSuffix": { "type": "boolean", "default": true }
      }
    },
    "denseness": {
      "type": "object",
      "properties": {
        "nodeCountThreshold": { "type": "integer", "default": 800 },
        "textNodeThreshold": { "type": "integer", "default": 150 },
        "depthThreshold": { "type": "integer", "default": 10 }
      }
    },
    "retry": {
      "type": "object",
      "properties": {
        "maxAttempts": { "type": "integer", "minimum": 1, "default": 3 },
        "backoffSeconds": {
          "type": "array",
          "items": { "type": "integer", "minimum": 0 },
          "default": [0, 2, 8]
        }
      }
    },
    "integration": {
      "type": "object",
      "properties": {
        "autoTriggerFromPlan": { "type": "boolean", "default": true },
        "autoTriggerFromDesign": { "type": "boolean", "default": true },
        "preserveUserEdits": { "type": "boolean", "default": true }
      }
    }
  }
}
```

- [ ] **Step 3: Regression check**

Run: `npm test`
Expected: all existing schema tests pass (no regression).

- [ ] **Step 4: Commit**

```bash
git add _meta/schemas/config.schema.json
git commit -m "feat(figma): config schema block for /u-figma"
```

---

## Phase 9 — Integration with /u-plan and /u-design

### Task 9.1: `/u-plan` delegation section

**Files:**
- Modify: `skills/u-plan/SKILL.md`

- [ ] **Step 1: Read current file**

Run: `cat skills/u-plan/SKILL.md`

- [ ] **Step 2: Append delegation section**

Add after `## Execution Flow` → new subsection `### Step 0: Figma Triggers`:

```markdown
### Step 0: Figma Triggers (auto-delegation, spec §12.2)

1. Read `data/figma/_triggers.json` if present.
2. For each `pending` trigger:
   a. Invoke `/u-figma ingest <url> --to plan` (via u-agent-figma).
   b. On completion, move the trigger from `pending` to `processed` with `completedAt`.
3. After all figma ingestions complete, proceed to Step 1 (dropzone scan). The figma aggregate(s) are now mirrored at `data/digest/figma_<fileKey>.digest.json` and merged with other digests in Step 3 SRS generation.
4. Merge-priority rules (per spec §12.2.1): `businessRules`, `processingRules`, `screenDescriptions`, `validationRules`, `uiSpecifications` → Figma wins; `domainTerms`, `stakeholders` → other sources win; `stateTransitions` → union.
5. If `figma.integration.autoTriggerFromPlan == false`, skip this step.
```

- [ ] **Step 3: Commit**

```bash
git add skills/u-plan/SKILL.md
git commit -m "feat(figma): /u-plan delegates to /u-figma ingest"
```

### Task 9.2: `/u-design` delegation section

**Files:**
- Modify: `skills/u-design/SKILL.md`

- [ ] **Step 1: Read current file**

Run: `cat skills/u-design/SKILL.md`

- [ ] **Step 2: Append delegation section**

Add under `## Execution Flow` → new subsection `### Step 0: Figma Sync`:

```markdown
### Step 0: Figma Sync (auto-delegation, spec §12.3)

1. Read SRS `docs/{app}/plan/srs.json`.
2. If `designSystemSource` or `screenDesignSource` is a `figma:<url>` reference:
   a. Invoke `/u-figma sync <url> --to design`.
   b. Wait for `design-system-source.json` to be written under `data/figma/<fileKey>/`.
3. During DS generation: merge `aggregate.designTokens` into `:root` CSS variables; for every `aggregate.componentSets[]`, emit `CMP-xxx` entries preserving ALL variants.
4. For Screen Spec: use `aggregate.screenDescriptions[]` as base; for each `variantOf`, emit a state subsection.
5. If `figma.integration.autoTriggerFromDesign == false`, skip this step.
```

- [ ] **Step 3: Commit**

```bash
git add skills/u-design/SKILL.md
git commit -m "feat(figma): /u-design delegates to /u-figma sync"
```

---

## Phase 10 — Coverage Computation Helper

### Task 10.1: Coverage warnings aggregator

**Files:**
- Create: `skills/u-figma/lib/coverage.js`
- Create: `skills/u-figma/tests/coverage.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/coverage.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { computeCoverageReport } = require('../lib/coverage');

test('report aggregates status counts', () => {
  const m = {
    stats: { totalPages: 2, totalFrames: 3, totalVariants: 1, totalComponentSets: 0, totalComments: 0,
             extractStatus: { pending: 1, in_progress: 0, done: 2, failed: 0, skipped: 0 } },
    pages: [],
    coverageWarnings: [{ type: 'orphan-base', baseName: 'X' }]
  };
  const r = computeCoverageReport(m);
  assert.strictEqual(r.percentDone, Math.round(2 / 3 * 100));
  assert.strictEqual(r.warningCount, 1);
  assert.match(r.lines.join('\n'), /orphan-base/);
});
```

- [ ] **Step 2: Implement**

Create `skills/u-figma/lib/coverage.js`:

```js
'use strict';

function computeCoverageReport(manifest) {
  const s = manifest.stats || {};
  const es = s.extractStatus || {};
  const total = s.totalFrames || 0;
  const done = es.done || 0;
  const percentDone = total === 0 ? 0 : Math.round((done / total) * 100);
  const warnings = manifest.coverageWarnings || [];
  const warningGroups = warnings.reduce((acc, w) => {
    acc[w.type] = (acc[w.type] || 0) + 1;
    return acc;
  }, {});
  const lines = [
    `Pages:          ${s.totalPages}/${s.totalPages} enumerated`,
    `Frames:         ${total} total`,
    `Extracted:      ${done}/${total}  (${percentDone}%)`,
    `Variants:       ${s.totalVariants}`,
    `Comments:       ${s.totalComments || 0}`,
    `Warnings:       ${warnings.length} (${Object.entries(warningGroups).map(([k, v]) => `${k}:${v}`).join(', ')})`,
    `Failed:         ${es.failed || 0}`
  ];
  return { percentDone, warningCount: warnings.length, lines };
}

module.exports = { computeCoverageReport };
```

- [ ] **Step 3: Run — pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/coverage.js skills/u-figma/tests/coverage.test.js
git commit -m "feat(figma): coverage report computation helper"
```

---

## Phase 11 — Gatekeeper Gates

### Task 11.1: Add figma gates to gate-rules.json

**Files:**
- Modify: `_meta/schemas/gate-rules.json`

- [ ] **Step 1: Read current rules**

Run: `cat _meta/schemas/gate-rules.json | head -40`

- [ ] **Step 2: Append figma gates**

Add to the rules list (syntax follows existing pattern). New rule entries:

```json
{
  "id": "FIGMA-COV-001",
  "name": "Figma coverage gate",
  "description": "No failed frames in any figma manifest",
  "applies": "if-figma-present",
  "check": "manifest.stats.extractStatus.failed == 0"
},
{
  "id": "FIGMA-VAR-001",
  "name": "Variant completeness gate",
  "description": "No orphan-base or state-gap warnings beyond threshold",
  "applies": "if-figma-present",
  "check": "coverageWarnings.orphan-base + state-gap <= config.figma.maxCoverageWarnings"
},
{
  "id": "FIGMA-TRACE-001",
  "name": "Figma → SRS traceability",
  "description": "Every aggregate.screenDescriptions[] has a matching FR in SRS",
  "applies": "if-figma-present",
  "check": "screenDescriptions map to FR 1:1"
},
{
  "id": "FIGMA-FRESH-001",
  "name": "Sync freshness",
  "description": "SRS/Design System regenerated within N hours of aggregate.scannedAt",
  "applies": "if-figma-present",
  "check": "docs.generatedAt >= aggregate.scannedAt AND docs.generatedAt - aggregate.scannedAt <= 24h"
}
```

(The actual syntax depends on existing gate-rules.json shape — follow patterns present in the file; do not invent a new DSL.)

- [ ] **Step 3: Regression**

Run: `npm test`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add _meta/schemas/gate-rules.json
git commit -m "feat(figma): 4 gatekeeper gates (coverage, variant, traceability, freshness)"
```

---

## Phase 12 — Smoke Test with Golden Corpora

### Task 12.1: Corpus README + placeholder fixtures

**Files:**
- Create: `skills/u-figma/tests/corpora/README.md`
- Create: `skills/u-figma/tests/corpora/expected/`

- [ ] **Step 1: Document corpora**

Create `skills/u-figma/tests/corpora/README.md`:

```markdown
# Golden Corpora for /u-figma

Three user-supplied Figma URLs used as acceptance tests (spec §13.1).

| Corpus | URL | Primary content types | Purpose |
|---|---|---|---|
| hjw-spec | https://www.figma.com/design/rthR0h9cahAAFfWL1JyAMq/...?node-id=3163-50673 | screen-planning + annotation + specification | Validates planning-text coverage, business/processing rules |
| glife-screen | https://www.figma.com/design/dbzjO8T5hWQXvuNc6IiwIH/...?node-id=532-48007 | screen-design + prototype + annotation | Validates variants B/C/D + prototype reactions |
| glife-components | https://www.figma.com/design/LgSNuJWOrRx1K9iPVUgFKE/...?node-id=0-1 | design-tokens + assets + heavy COMPONENT_SET | Validates source A — every set's variants enumerated |

## Running

Against a real Figma MCP connection:

```bash
/u-figma ingest https://www.figma.com/design/rthR0h9cahAAFfWL1JyAMq/...?node-id=3163-50673
/u-figma status https://www.figma.com/design/rthR0h9cahAAFfWL1JyAMq/...?node-id=3163-50673
```

Expected (per spec §13.2):
- `manifest.stats.totalVariants >= expected[corpus].minVariants`
- `coverageWarnings[].type == "orphan-base"` count == 0
- Every COMPONENT_SET has `variants.length >= 1`
- REST comment count matches Figma 💬 UI (when PAT configured)

Kill mid-`extract`, re-run — no `done` frames are re-processed.

## Expected values

`expected/<corpus>.json` captures baseline counts. These are locked on first successful run:

```json
{
  "corpus": "glife-components",
  "minTotalFrames": 200,
  "minTotalVariants": 80,
  "minComponentSets": 30,
  "forbiddenWarnings": ["orphan-base"]
}
```
```

- [ ] **Step 2: Stub expected baseline files (empty, filled on first real run)**

Create `skills/u-figma/tests/corpora/expected/hjw-spec.json`:

```json
{
  "corpus": "hjw-spec",
  "minTotalFrames": 0,
  "minTotalVariants": 0,
  "minComponentSets": 0,
  "forbiddenWarnings": ["orphan-base"],
  "note": "Baseline locked after first successful manual run"
}
```

(Repeat for `glife-screen.json` and `glife-components.json` with the same shape.)

- [ ] **Step 3: Commit**

```bash
git add skills/u-figma/tests/corpora/
git commit -m "test(figma): corpus README + baseline stubs for 3 golden URLs"
```

### Task 12.2: Corpus runner helper (manual)

**Files:**
- Create: `skills/u-figma/tests/corpus-verify.js`

- [ ] **Step 1: Write verification script**

Create `skills/u-figma/tests/corpus-verify.js`:

```js
#!/usr/bin/env node
// corpus-verify.js
// Compare a manifest against expected/<corpus>.json after running /u-figma ingest manually.
// Usage: node corpus-verify.js <corpus> <path-to-manifest.json>
'use strict';
const fs = require('fs');
const path = require('path');

const [,, corpus, manifestPath] = process.argv;
if (!corpus || !manifestPath) {
  console.error('usage: corpus-verify.js <corpus> <manifest.json>');
  process.exit(2);
}

const expected = JSON.parse(fs.readFileSync(path.join(__dirname, 'corpora/expected', `${corpus}.json`), 'utf8'));
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

const failures = [];
const totals = manifest.stats || {};
if ((totals.totalFrames || 0) < expected.minTotalFrames) failures.push(`frames: ${totals.totalFrames} < ${expected.minTotalFrames}`);
if ((totals.totalVariants || 0) < expected.minTotalVariants) failures.push(`variants: ${totals.totalVariants} < ${expected.minTotalVariants}`);
if ((totals.totalComponentSets || 0) < expected.minComponentSets) failures.push(`componentSets: ${totals.totalComponentSets} < ${expected.minComponentSets}`);

for (const forbidden of expected.forbiddenWarnings || []) {
  const count = (manifest.coverageWarnings || []).filter(w => w.type === forbidden).length;
  if (count > 0) failures.push(`forbidden warning "${forbidden}" count=${count}`);
}

if (failures.length) {
  console.error(`CORPUS ${corpus} FAILED:`);
  for (const f of failures) console.error(`  - ${f}`);
  process.exit(1);
}
console.log(`CORPUS ${corpus} OK (frames=${totals.totalFrames}, variants=${totals.totalVariants}, sets=${totals.totalComponentSets})`);
```

- [ ] **Step 2: Make executable and commit**

```bash
chmod +x skills/u-figma/tests/corpus-verify.js
git add skills/u-figma/tests/corpus-verify.js
git commit -m "test(figma): corpus verify script for manual acceptance"
```

---

## Phase 14 — Common-Component Candidate Detection (spec §7.6)

### Task 14.1: Visual signature helper

**Files:**
- Create: `skills/u-figma/lib/visual-signature.js`
- Create: `skills/u-figma/tests/visual-signature.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/visual-signature.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { visualSignature } = require('../lib/visual-signature');

const cardA = {
  type: 'FRAME',
  fills: [{ type: 'SOLID', color: { r: 1, g: 1, b: 1, a: 1 } }],
  strokes: [],
  strokeWeight: 0,
  cornerRadius: 8,
  effects: [],
  layoutMode: 'VERTICAL',
  primaryAxisSizingMode: 'AUTO',
  counterAxisSizingMode: 'FIXED',
  paddingLeft: 16, paddingRight: 16, paddingTop: 16, paddingBottom: 16,
  itemSpacing: 8,
  children: [{ type: 'TEXT' }, { type: 'TEXT' }]
};
const cardB = { ...cardA, children: [{ type: 'TEXT' }, { type: 'TEXT' }] };
const cardDifferentPadding = { ...cardA, paddingLeft: 24 };

test('identical shape → identical signature', () => {
  assert.strictEqual(visualSignature(cardA), visualSignature(cardB));
});
test('different padding → different signature', () => {
  assert.notStrictEqual(visualSignature(cardA), visualSignature(cardDifferentPadding));
});
test('signature is sha256:<hex>', () => {
  assert.match(visualSignature(cardA), /^sha256:[0-9a-f]{64}$/);
});
test('children-shape uses type+count, not content', () => {
  const withDifferentTextContent = { ...cardA, children: [{ type: 'TEXT', characters: 'X' }, { type: 'TEXT', characters: 'Y' }] };
  assert.strictEqual(visualSignature(cardA), visualSignature(withDifferentTextContent));
});
```

- [ ] **Step 2: Run — fail**

Expected: `Cannot find module '../lib/visual-signature'`.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/visual-signature.js`:

```js
'use strict';
const { hashCanonical } = require('./hash');

function childrenShape(node) {
  const counts = {};
  for (const c of node.children || []) {
    counts[c.type] = (counts[c.type] || 0) + 1;
  }
  return counts;
}

function visualSignature(node) {
  const sig = {
    nodeType: node.type,
    fills: node.fills || [],
    strokes: node.strokes || [],
    strokeWeight: node.strokeWeight ?? 0,
    cornerRadius: node.cornerRadius ?? 0,
    effects: (node.effects || []).filter(e => e.visible !== false),
    layoutMode: node.layoutMode || null,
    primaryAxisSizingMode: node.primaryAxisSizingMode || null,
    counterAxisSizingMode: node.counterAxisSizingMode || null,
    paddingLeft: node.paddingLeft ?? 0,
    paddingRight: node.paddingRight ?? 0,
    paddingTop: node.paddingTop ?? 0,
    paddingBottom: node.paddingBottom ?? 0,
    itemSpacing: node.itemSpacing ?? 0,
    childrenShape: childrenShape(node)
  };
  return hashCanonical(sig);
}

function textStyleSignature(textNode) {
  return hashCanonical({
    fontFamily: textNode.style?.fontFamily ?? null,
    fontSize: textNode.style?.fontSize ?? null,
    fontWeight: textNode.style?.fontWeight ?? null,
    lineHeight: textNode.style?.lineHeight ?? null,
    letterSpacing: textNode.style?.letterSpacing ?? null
  });
}

module.exports = { visualSignature, textStyleSignature };
```

- [ ] **Step 4: Pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/visual-signature.js skills/u-figma/tests/visual-signature.test.js
git commit -m "feat(figma): visual and text-style signature helpers"
```

### Task 14.2: Candidate detector

**Files:**
- Create: `skills/u-figma/lib/candidate-detect.js`
- Create: `skills/u-figma/tests/candidate-detect.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/candidate-detect.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { detectCandidates } = require('../lib/candidate-detect');

function card(nodeId, pageId, padding = 16) {
  return {
    nodeId, pageId, name: 'Card', parentName: 'Dashboard',
    type: 'FRAME',
    fills: [{ type: 'SOLID', color: { r: 1, g: 1, b: 1, a: 1 } }],
    strokes: [], strokeWeight: 0, cornerRadius: 8, effects: [],
    layoutMode: 'VERTICAL', primaryAxisSizingMode: 'AUTO', counterAxisSizingMode: 'FIXED',
    paddingLeft: padding, paddingRight: padding, paddingTop: padding, paddingBottom: padding,
    itemSpacing: 8, children: [{ type: 'TEXT' }, { type: 'TEXT' }]
  };
}

test('visual-signature: 3+ identical frames → one candidate', () => {
  const nodes = [card('1:1', 'p1'), card('1:2', 'p1'), card('2:1', 'p2')];
  const result = detectCandidates(nodes, { components: [] }, { minOccurrences: 3 });
  assert.strictEqual(result.length, 1);
  assert.strictEqual(result[0].kind, 'visual-signature');
  assert.strictEqual(result[0].occurrences, 3);
});

test('below threshold → no candidate', () => {
  const nodes = [card('1:1', 'p1'), card('1:2', 'p1')];
  const result = detectCandidates(nodes, { components: [] }, { minOccurrences: 3 });
  assert.strictEqual(result.length, 0);
});

test('different padding → separate candidates, each below threshold → none', () => {
  const nodes = [card('1:1', 'p1', 16), card('1:2', 'p1', 24), card('2:1', 'p2', 32)];
  const result = detectCandidates(nodes, { components: [] }, { minOccurrences: 3 });
  assert.strictEqual(result.length, 0);
});

test('instance-repeat: INSTANCE sharing componentRef 3× → candidate kind=instance-repeat', () => {
  const instances = [
    { nodeId: '1:1', pageId: 'p1', name: 'Btn', type: 'INSTANCE', componentRef: 'ext-lib/Button', parentName: 'Form' },
    { nodeId: '1:2', pageId: 'p1', name: 'Btn', type: 'INSTANCE', componentRef: 'ext-lib/Button', parentName: 'Dialog' },
    { nodeId: '2:1', pageId: 'p2', name: 'Btn', type: 'INSTANCE', componentRef: 'ext-lib/Button', parentName: 'Header' }
  ];
  const result = detectCandidates(instances, { components: [] }, { minOccurrences: 3 });
  assert.strictEqual(result.length, 1);
  assert.strictEqual(result[0].kind, 'instance-repeat');
});

test('duplicate of existing DS is marked', () => {
  const nodes = [card('1:1', 'p1'), card('1:2', 'p1'), card('2:1', 'p2')];
  const existing = { components: [{ id: 'CMP-010', visualSignature: require('../lib/visual-signature').visualSignature(card('x', 'y')) }] };
  const result = detectCandidates(nodes, existing, { minOccurrences: 3 });
  assert.strictEqual(result[0].existingDsMatch, 'CMP-010');
  assert.match(result[0].status, /^duplicate-of-/);
});
```

- [ ] **Step 2: Run — fail**

Expected: module not found.

- [ ] **Step 3: Implement**

Create `skills/u-figma/lib/candidate-detect.js`:

```js
'use strict';
const { visualSignature, textStyleSignature } = require('./visual-signature');

function inferName(nodes) {
  const names = nodes.map(n => n.name || 'Pattern').filter(Boolean);
  if (names.length === 0) return 'Pattern';
  // Find common prefix by splitting on / or -
  const first = names[0].split(/[\/\-_·\s]/)[0].trim();
  if (first && names.every(n => n.startsWith(first))) return first;
  return names[0];
}

function generatePendingCmpId() {
  return 'CMP-pending-' + Math.random().toString(16).slice(2, 8);
}

function toLocation(n) {
  return { nodeId: n.nodeId, pageId: n.pageId, pageName: n.pageName, parentName: n.parentName };
}

function extractProps(n) {
  return {
    fills: n.fills,
    cornerRadius: n.cornerRadius,
    padding: {
      top: n.paddingTop, right: n.paddingRight, bottom: n.paddingBottom, left: n.paddingLeft
    },
    layoutMode: n.layoutMode
  };
}

function pickSignature(node) {
  if (node.type === 'INSTANCE' && node.componentRef) return `instance:${node.componentRef}`;
  if (node.type === 'FRAME' || node.type === 'RECTANGLE') return `visual:${visualSignature(node)}`;
  if (node.type === 'TEXT' && !node.styleId) return `text:${textStyleSignature(node)}`;
  return null;
}

function inferKind(sig) {
  if (sig.startsWith('instance:')) return 'instance-repeat';
  if (sig.startsWith('visual:')) return 'visual-signature';
  if (sig.startsWith('text:')) return 'text-style';
  return 'layout-pattern';
}

function findInDs(existingDs, sampleNode) {
  const sig = visualSignature(sampleNode);
  for (const cmp of (existingDs.components || [])) {
    if (cmp.visualSignature === sig) return cmp;
  }
  return null;
}

function detectCandidates(nodes, existingDs = { components: [] }, cfg = {}) {
  const minOccurrences = cfg.minOccurrences ?? 3;
  const sigMap = new Map();
  for (const n of nodes) {
    const sig = pickSignature(n);
    if (!sig) continue;
    if (!sigMap.has(sig)) sigMap.set(sig, []);
    sigMap.get(sig).push(n);
  }

  const out = [];
  for (const [sig, group] of sigMap) {
    if (group.length < minOccurrences) continue;
    const existing = findInDs(existingDs, group[0]);
    out.push({
      signature: sig,
      kind: inferKind(sig),
      occurrences: group.length,
      locations: group.map(toLocation),
      suggestedName: inferName(group),
      suggestedCmpId: existing ? existing.id : generatePendingCmpId(),
      sampleProps: extractProps(group[0]),
      confidence: sig.startsWith('instance:') ? 1.0 : 0.9,
      existingDsMatch: existing ? existing.id : null,
      status: existing ? `duplicate-of-${existing.id}` : 'pending-promotion'
    });
  }
  return out;
}

module.exports = { detectCandidates, pickSignature, inferKind, findInDs };
```

- [ ] **Step 4: Pass**

Run: `npm run test:figma`
Expected: 5 candidate tests pass.

- [ ] **Step 5: Commit**

```bash
git add skills/u-figma/lib/candidate-detect.js skills/u-figma/tests/candidate-detect.test.js
git commit -m "feat(figma): common-component candidate detector (4 sources + DS dedup)"
```

### Task 14.3: Aggregate integration — emit candidates

**Files:**
- Modify: `_meta/schemas/figma-aggregate.schema.json`

- [ ] **Step 1: Add `componentCandidates` to aggregate schema**

Add to `properties`:

```json
"componentCandidates": {
  "type": "array",
  "description": "Patterns repeated >= minOccurrences times, candidates for DS promotion. See figma-analysis.md §7.6, §12.10.",
  "items": {
    "type": "object",
    "required": ["signature", "kind", "occurrences", "suggestedName", "status"],
    "properties": {
      "signature": { "type": "string" },
      "kind": { "enum": ["instance-repeat", "visual-signature", "layout-pattern", "text-style"] },
      "occurrences": { "type": "integer", "minimum": 1 },
      "locations": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "nodeId": { "type": "string" },
            "pageId": { "type": "string" },
            "pageName": { "type": "string" },
            "parentName": { "type": "string" }
          }
        }
      },
      "suggestedName": { "type": "string" },
      "suggestedCmpId": { "type": "string" },
      "sampleProps": { "type": "object" },
      "confidence": { "type": "number", "minimum": 0, "maximum": 1 },
      "existingDsMatch": { "type": ["string", "null"] },
      "status": {
        "type": "string",
        "pattern": "^(pending-promotion|proposed|promoted|rejected|below-threshold|duplicate-of-.+)$"
      }
    }
  }
}
```

- [ ] **Step 2: Regression**

Run: `npm test`
Expected: existing aggregate fixture still validates.

- [ ] **Step 3: Commit**

```bash
git add _meta/schemas/figma-aggregate.schema.json
git commit -m "feat(figma): aggregate schema supports componentCandidates[]"
```

---

## Phase 15 — DS Promotion Pipeline + FE DS-First

### Task 15.1: DS manifest query helper

**Files:**
- Create: `skills/u-figma/lib/ds-query.js`
- Create: `skills/u-figma/tests/ds-query.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/ds-query.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { loadDs, findComponent, findProposal } = require('../lib/ds-query');
const fs = require('fs');
const path = require('path');
const os = require('os');

function tmpDir() { return fs.mkdtempSync(path.join(os.tmpdir(), 'ds-query-')); }

test('loadDs returns empty when missing', () => {
  assert.deepStrictEqual(loadDs('/nowhere'), { components: [] });
});

test('findComponent by id', () => {
  const ds = { components: [{ id: 'CMP-010', name: 'Button' }] };
  assert.strictEqual(findComponent(ds, { id: 'CMP-010' }).name, 'Button');
});

test('findComponent by intent+tag', () => {
  const ds = { components: [{ id: 'CMP-010', name: 'Button', tag: 'button', intents: ['primary-action'] }] };
  assert.strictEqual(findComponent(ds, { tag: 'button', intent: 'primary-action' }).id, 'CMP-010');
});

test('findProposal detects existing proposal file', () => {
  const dir = tmpDir();
  fs.mkdirSync(path.join(dir, 'proposals'), { recursive: true });
  fs.writeFileSync(path.join(dir, 'proposals', 'Card.md'), '# Proposal\n');
  assert.strictEqual(findProposal(dir, 'Card'), path.join(dir, 'proposals', 'Card.md'));
  assert.strictEqual(findProposal(dir, 'DoesNotExist'), null);
});
```

- [ ] **Step 2: Implement**

Create `skills/u-figma/lib/ds-query.js`:

```js
'use strict';
const fs = require('fs');
const path = require('path');

function loadDs(dsPath) {
  if (!fs.existsSync(dsPath)) return { components: [] };
  try {
    return JSON.parse(fs.readFileSync(dsPath, 'utf8'));
  } catch (_) {
    return { components: [] };
  }
}

function findComponent(ds, query) {
  const list = ds.components || [];
  if (query.id) return list.find(c => c.id === query.id) || null;
  if (query.tag || query.intent) {
    return list.find(c =>
      (!query.tag || c.tag === query.tag) &&
      (!query.intent || (c.intents || []).includes(query.intent))
    ) || null;
  }
  return null;
}

function findProposal(proposalsDir, name) {
  const p = path.join(proposalsDir, 'proposals', `${name}.md`);
  return fs.existsSync(p) ? p : null;
}

module.exports = { loadDs, findComponent, findProposal };
```

- [ ] **Step 3: Pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/ds-query.js skills/u-figma/tests/ds-query.test.js
git commit -m "feat(figma): DS query helper (components + proposals)"
```

### Task 15.2: Proposal generator

**Files:**
- Create: `skills/u-figma/lib/proposal-gen.js`
- Create: `skills/u-figma/tests/proposal-gen.test.js`

- [ ] **Step 1: Failing test**

Create `skills/u-figma/tests/proposal-gen.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { renderProposal } = require('../lib/proposal-gen');

test('renders proposal MD with source, occurrences, inferred API', () => {
  const md = renderProposal({
    suggestedName: 'Card',
    source: 'figma-candidate',
    occurrences: 7,
    locations: [{ pageName: 'Wireframes', parentName: 'Dashboard' }],
    sampleProps: { cornerRadius: 8, padding: { top: 16, right: 16, bottom: 16, left: 16 } },
    inferredProps: ['title', 'body']
  });
  assert.match(md, /# Proposal: Card/);
  assert.match(md, /\*\*Occurrences:\*\* 7/);
  assert.match(md, /title/);
  assert.match(md, /figma-candidate/);
});
```

- [ ] **Step 2: Implement**

Create `skills/u-figma/lib/proposal-gen.js`:

```js
'use strict';

function renderProposal({ suggestedName, source, occurrences, locations = [], sampleProps = {}, inferredProps = [], screenId = null }) {
  const lines = [
    `# Proposal: ${suggestedName}`,
    ``,
    `**Status:** Proposed`,
    `**Source:** ${source}` + (screenId ? ` (screen ${screenId})` : ''),
    `**Occurrences:** ${occurrences}`,
    ``,
    `## Usage locations`,
    ...locations.map(l => `- ${l.pageName || '?'} → ${l.parentName || '?'}`),
    ``,
    `## Inferred API`,
    `- Props: ${inferredProps.length ? inferredProps.join(', ') : '(to be determined)'}`,
    `- Variants: default (add more as needed)`,
    ``,
    `## Inferred tokens`,
    `- cornerRadius: ${sampleProps.cornerRadius ?? 'n/a'}`,
    `- padding: ${JSON.stringify(sampleProps.padding || {})}`,
    ``,
    `## Next steps`,
    `- [ ] Approve → merge into \`docs/common/design-system.json\``,
    `- [ ] Reject → mark \`status: "rejected"\``,
    `- [ ] Modify → edit this proposal, then approve`
  ];
  return lines.join('\n');
}

module.exports = { renderProposal };
```

- [ ] **Step 3: Pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/proposal-gen.js skills/u-figma/tests/proposal-gen.test.js
git commit -m "feat(figma): proposal markdown generator"
```

### Task 15.3: FE lint — forbidden pattern detector

**Files:**
- Create: `skills/u-figma/lib/fe-lint.js`
- Create: `skills/u-figma/tests/fe-lint.test.js`

- [ ] **Step 1: Failing tests**

Create `skills/u-figma/tests/fe-lint.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { lintFe } = require('../lib/fe-lint');

test('rejects arbitrary Tailwind px', () => {
  const src = `<div className="w-[321px] p-4">x</div>`;
  const errs = lintFe(src);
  assert.ok(errs.some(e => e.rule === 'arbitrary-value'));
});

test('rejects raw hex color', () => {
  const src = `<div style={{ color: '#3B82F6' }}>x</div>`;
  const errs = lintFe(src);
  assert.ok(errs.some(e => e.rule === 'raw-hex'));
});

test('rejects raw px in style', () => {
  const src = `<div style={{ padding: '17px' }}>x</div>`;
  const errs = lintFe(src);
  assert.ok(errs.some(e => e.rule === 'raw-px'));
});

test('accepts DS variables', () => {
  const src = `<div className="text-brand-primary p-md" style={{ color: 'var(--color-brand-primary)' }}>x</div>`;
  assert.strictEqual(lintFe(src).length, 0);
});

test('accepts runtime-computed inline style', () => {
  const src = 'const s = { transform: `translateX(${x}px)` };';
  assert.strictEqual(lintFe(src).length, 0);
});
```

- [ ] **Step 2: Implement**

Create `skills/u-figma/lib/fe-lint.js`:

```js
'use strict';

const RULES = [
  { rule: 'arbitrary-value', re: /className=["'`][^"'`]*\b(w|h|p|m|top|left|right|bottom)-\[[^\]]+\]/g },
  { rule: 'raw-hex', re: /(?:color|backgroundColor|borderColor)\s*:\s*['"`]#[0-9a-fA-F]{3,8}['"`]/g },
  { rule: 'raw-px', re: /(?:padding|margin|width|height|fontSize|borderRadius|gap)\s*:\s*['"`]\d+(?:px|rem|em)['"`]/g }
];

function lintFe(src) {
  const errors = [];
  for (const r of RULES) {
    let m;
    const re = new RegExp(r.re.source, r.re.flags);
    while ((m = re.exec(src)) !== null) {
      errors.push({ rule: r.rule, index: m.index, match: m[0] });
    }
  }
  return errors;
}

module.exports = { lintFe, RULES };
```

- [ ] **Step 3: Pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/fe-lint.js skills/u-figma/tests/fe-lint.test.js
git commit -m "feat(figma): FE lint for forbidden patterns (arbitrary/hex/px)"
```

### Task 15.4: DS coverage computation

**Files:**
- Create: `skills/u-figma/lib/ds-coverage.js`
- Create: `skills/u-figma/tests/ds-coverage.test.js`

- [ ] **Step 1: Failing test**

Create `skills/u-figma/tests/ds-coverage.test.js`:

```js
const { test } = require('node:test');
const assert = require('node:assert');
const { computeDsCoverage } = require('../lib/ds-coverage');

test('coverage = DS imports / total JSX elements', () => {
  const src = `
    import { Button } from '@/ds/button';
    import { Input } from '@/ds/input';
    function X() {
      return (
        <div>
          <Button>ok</Button>
          <Input />
          <span>raw</span>
          <p>also raw</p>
        </div>
      );
    }
  `;
  const cov = computeDsCoverage(src);
  assert.strictEqual(cov.dsElements, 2);
  assert.strictEqual(cov.totalElements, 5);
  assert.strictEqual(cov.percent, 40);
});
```

- [ ] **Step 2: Implement**

Create `skills/u-figma/lib/ds-coverage.js`:

```js
'use strict';

function computeDsCoverage(src) {
  const imports = new Set();
  const importRe = /import\s*\{([^}]+)\}\s*from\s*['"`]@\/ds\/[^'"`]+['"`]/g;
  let m;
  while ((m = importRe.exec(src)) !== null) {
    for (const name of m[1].split(',')) imports.add(name.trim());
  }

  const jsxRe = /<([A-Za-z][A-Za-z0-9_.-]*)/g;
  let total = 0;
  let ds = 0;
  while ((m = jsxRe.exec(src)) !== null) {
    total++;
    if (imports.has(m[1]) || m[1].startsWith('DS.')) ds++;
  }

  return {
    dsElements: ds,
    totalElements: total,
    percent: total === 0 ? 0 : Math.round((ds / total) * 100)
  };
}

module.exports = { computeDsCoverage };
```

- [ ] **Step 3: Pass; commit**

```bash
npm run test:figma
git add skills/u-figma/lib/ds-coverage.js skills/u-figma/tests/ds-coverage.test.js
git commit -m "feat(figma): DS coverage computation for generated FE"
```

### Task 15.5: `/u-dev` SKILL update — DS-first section

**Files:**
- Modify: `skills/u-dev/SKILL.md`

- [ ] **Step 1: Insert Step 0.5 DS-first contract into u-dev**

Locate `### Step 1: Generate FE Code` in `skills/u-dev/SKILL.md` and insert before it:

```markdown
### Step 0.5: Design-System-First Contract (spec §12.11)

Applies to all FE generation. Enforced for every JSX element produced.

1. **DS lookup first**: for every UI element needed, query `docs/common/design-system.json` via `skills/u-figma/lib/ds-query.js` (`findComponent({ id | tag+intent })`).
2. **If DS match**: emit `import { <Cmp> } from '@/ds/<cmp>'` + JSX that uses the component. Do not re-implement.
3. **If DS miss** → auto-extend proposal (`figma.dsEnforcement.level = "error"` default):
   a. Emit `<DS.Placeholder name="<Name>" reason="no DS match" screenId="<id>">` stub.
   b. Generate `docs/common/design-system/proposals/<Name>.md` via `skills/u-figma/lib/proposal-gen.js` with `source: "ds-gap"`.
   c. Append to `docs/{app}/dev/ds-gaps.md`:
      `| {screenId} | {Name} | {inferred props} | proposals/{Name}.md |`
   d. Return from `/u-dev` with `dsGapsFound: N`. User reviews + runs `/u-design --accept-proposals` + re-runs `/u-dev`.
4. **Lint gate** (applies after every file write): run `skills/u-figma/lib/fe-lint.js` → forbidden patterns (arbitrary px, raw hex, inline design tokens) fail the file unless `figma.dsEnforcement.level = "warn"`.
5. **Coverage measurement**: after Step 1, compute `skills/u-figma/lib/ds-coverage.js` per file, aggregate per-screen. Write `docs/{app}/dev/ds-coverage.md`. Fail `--loop` gate if < `figma.dsEnforcement.dsCoverageThreshold` (default 85).

Forbidden / Allowed catalog: see `skills/u-plan/references/figma-analysis.md` §12.11.2.
```

- [ ] **Step 2: Commit**

```bash
git add skills/u-dev/SKILL.md
git commit -m "feat(figma): /u-dev DS-first contract (auto-extend proposal + lint + coverage)"
```

### Task 15.6: Gate rules — DS gates

**Files:**
- Modify: `_meta/schemas/gate-rules.json`

- [ ] **Step 1: Append four gates from spec §12.12**

Add to gate-rules (pattern-match existing shape):

```json
{
  "id": "FIGMA-PROM-001",
  "name": "Promotion completeness",
  "description": "No componentCandidates with status=pending-promotion after sync",
  "applies": "if-figma-present",
  "check": "aggregate.componentCandidates all status != 'pending-promotion'"
},
{
  "id": "FIGMA-DS-COV-001",
  "name": "DS coverage",
  "description": "FE dsCoverage >= figma.dsEnforcement.dsCoverageThreshold",
  "applies": "if-app-has-fe",
  "check": "docs/{app}/dev/ds-coverage.md average percent >= threshold"
},
{
  "id": "FIGMA-DS-FORBID-001",
  "name": "Forbidden patterns absent",
  "description": "Generated FE passes fe-lint with zero errors",
  "applies": "if-app-has-fe",
  "check": "lintFe(generatedFiles) == []"
},
{
  "id": "FIGMA-DS-GAP-001",
  "name": "DS gaps documented",
  "description": "Every DS.Placeholder has a matching proposal file",
  "applies": "if-app-has-fe",
  "check": "every Placeholder.name → docs/common/design-system/proposals/<name>.md exists"
}
```

- [ ] **Step 2: Commit**

```bash
git add _meta/schemas/gate-rules.json
git commit -m "feat(figma): 4 DS gates (promotion, coverage, forbidden, gaps)"
```

### Task 15.7: Config schema — promotion + dsEnforcement

**Files:**
- Modify: `_meta/schemas/config.schema.json`

- [ ] **Step 1: Extend figma block**

Append inside `figma.properties`:

```json
"promotion": {
  "type": "object",
  "properties": {
    "minOccurrences": { "type": "integer", "minimum": 1, "default": 3 },
    "autoPromote": { "type": "boolean", "default": false },
    "duplicateSimilarityThreshold": { "type": "number", "minimum": 0, "maximum": 1, "default": 0.8 }
  }
},
"dsEnforcement": {
  "type": "object",
  "properties": {
    "level": { "enum": ["off", "warn", "error"], "default": "error" },
    "dsCoverageThreshold": { "type": "integer", "minimum": 0, "maximum": 100, "default": 85 }
  }
}
```

- [ ] **Step 2: Regression + commit**

```bash
npm test
git add _meta/schemas/config.schema.json
git commit -m "feat(figma): config schema for promotion + dsEnforcement"
```

---

## Phase 13 — Docs Update

### Task 13.1: README entry

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add /u-figma to the command list**

In the commands table (locate via `grep -n "/u-plan" README.md`), insert after existing entries:

```markdown
| `/u-figma <sub> <url>` | Process Figma files: scan inventory, extract per-frame digests, verify coverage, sync to plan/design docs. Auto-triggered by `/u-plan` when `.figma-link` files are in dropzone. See `skills/u-plan/references/figma-analysis.md` PART II. |
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs(figma): add /u-figma to README command list"
```

### Task 13.2: CHANGELOG / version bump (if existing pattern in repo)

**Files:**
- Modify: `package.json` (version → 3.5.0 if needed)
- Modify: any changelog file if present

- [ ] **Step 1: Check current version**

Run: `grep version package.json`

- [ ] **Step 2: Bump to 3.5.0**

- [ ] **Step 3: Commit**

```bash
git add package.json
git commit -m "chore: bump version to 3.5.0 for /u-figma feature"
```

---

## Self-Review Checklist (run before declaring done)

- [ ] Every task has exact file paths (no "the appropriate file").
- [ ] Every code step shows the code in full — no "add validation".
- [ ] Every test step shows expected output (PASS / FAIL / specific error message).
- [ ] Method names consistent across tasks: `extractBase`, `detectPositionalVariants`, `unionVariants`, `checkCompleteness`, `classifyDensity`, `hashCanonical`, `loadManifest`, `saveManifest`, `updateFrameStatus`, `dedupComments`, `fetchComments`, `resolvePAT`, `detectStickyNotes`, `computeCoverageReport`, `visualSignature`, `textStyleSignature`, `detectCandidates`, `pickSignature`, `inferKind`, `findInDs`, `loadDs`, `findComponent`, `findProposal`, `renderProposal`, `lintFe`, `computeDsCoverage`.
- [ ] Every spec section (§7–§14) has at least one task:
  - §7 → Tasks 2.1–2.4 (variant detection)
  - §7.6 → Tasks 14.1–14.3 (common-component candidates)
  - §8 → Tasks 1.1, 5.1, 10.1
  - §9 → Task 6.1
  - §10 → Tasks 3.1, 7.1
  - §11 → Tasks 4.1–4.4
  - §12 → Tasks 9.1, 9.2
  - §12.10 → Tasks 15.1, 15.2 (DS promotion)
  - §12.11 → Tasks 15.3, 15.4, 15.5 (FE DS-first)
  - §12.12 → Tasks 15.6, 15.7 (gates + config)
  - §13 → Tasks 12.1, 12.2
  - §14 → Task 13.1, 13.2
- [ ] Each phase ends with working, committed code (no half-states).
- [ ] No task references a symbol defined nowhere.

## Execution Checklist (for engineer)

1. Run from repo root: `/Users/thinoo/works/500.ai/u-maker-plugin`
2. Work phase by phase. Do not skip ahead.
3. Run `npm test` before the commit in each task — only commit when tests pass.
4. If a test reveals the spec is wrong, update the spec FIRST (`skills/u-plan/references/figma-analysis.md`), then adjust the task.
5. After Phase 12, run `/u-figma ingest <url>` manually on each corpus URL to lock real baseline numbers into `tests/corpora/expected/*.json`.
6. Do not deploy / release until every corpus passes `corpus-verify.js`.

## Out of scope (per spec §14.3)

- Figma plugin/extension
- Writing back to Figma (create annotations/comments)
- Cross-file team-library deep analysis
- Historical version diffing
