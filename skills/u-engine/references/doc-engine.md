# doc-engine Reference

The doc-engine is the core document management engine for u-maker. It handles the entire lifecycle of SSoT (Single Source of Truth) documents: creation, reading, updating, and deletion. Every document in the u-maker system passes through doc-engine operations.

## 1. Document Lifecycle

Every SSoT document progresses through three statuses:

```
Draft → Review → Final
```

### Status Definitions

| Status | Meaning | Allowed Transitions |
|--------|---------|---------------------|
| Draft | Initial creation or active editing. Content is being generated or modified. | → Review |
| Review | Content is complete and awaiting validation by u-agent-gatekeeper. | → Final, → Draft (if rejected) |
| Final | Gatekeeper approved (avg score >= 95). Document is locked for the current phase. | → Draft (only via explicit `/u-update`) |

### Transition Rules

1. **Draft → Review**: Automatic when the phase skill completes document generation. The skill sets `status: Review` in both `.md` frontmatter and `.json` companion.
2. **Review → Final**: Set by u-agent-gatekeeper when scoring passes (avg >= 95). The gatekeeper updates both `.md` and `.json` status fields.
3. **Review → Draft**: Set by u-agent-gatekeeper when scoring fails (avg < 95). Improvement items are attached and the phase skill re-processes.
4. **Final → Draft**: Only via explicit `/u-update` command with `--force` or when a dependency changes upstream (cascade from dep-engine).

## 2. Template Rendering

All documents are generated from templates stored in `_meta/templates/`. Templates use Mustache-style placeholders for dynamic content.

### Template Location

```
_meta/templates/{docType}.template.md     (standard documents)
_meta/templates/{docType}.template.html   (HTML-first documents)
```

Available templates:

| Template File | Document Type | Output Path | Pipeline |
|---------------|---------------|-------------|----------|
| `srs.template.md` | Software Requirements Specification | `docs/{app}/plan/srs.md` | Standard (MD→JSON→HTML) |
| `ia.template.md` | Information Architecture | `docs/{app}/plan/ia.md` | Standard |
| `erd.template.md` | Entity-Relationship Diagram | `docs/{app}/design/erd.md` | Standard |
| `api.template.md` | API Contract | `docs/{app}/design/api.md` | Standard |
| `screens.template.md` | Screen Specification | `docs/{app}/design/screens.md` | Standard |
| `design-system.template.html` | Design System | `out/{app}/design/design-system.html` | **HTML-first** (HTML→MD+JSON) |
| `design-system.template.md` | Design System (derived) | `docs/{app}/design/design-system.md` | Derived from HTML |
| `testcase.template.md` | Test Cases | `docs/{app}/check/testcases.md` | Standard |
| `test-results.template.md` | Test Results | `docs/{app}/check/test-results.md` | Standard |

### Design System: HTML-First Exception

The Design System is the only SSoT document that uses an **HTML-first pipeline**. Instead of the standard `template.md → MD → JSON → HTML` flow, it follows:

```
template.html → HTML (primary) → MD + JSON (derived)
```

1. **Phase A (Primary):** Load `design-system.template.html`, render CSS custom properties and component showcases with actual token values, write to `out/{app}/design/design-system.html`
2. **Phase B (Derive MD):** Parse CSS variables and component classes from the HTML, generate token tables and component specs, write `docs/{app}/design/design-system.md` with a `Source:` frontmatter field pointing to the HTML
3. **Phase C (Derive JSON):** Extract items from the HTML, build `design-system.json` with a `source` field pointing to the HTML

When updating the Design System, always edit the HTML first, then re-derive MD and JSON. The HTML is the single source of truth for visual language definitions.

### Mustache Placeholder Syntax

Templates use `{{placeholder}}` for simple values and `{{#section}}...{{/section}}` for repeated blocks.

#### Simple Placeholders

```markdown
| Project Name | {{projectName}} |
| Description  | {{description}} |
| Owner        | {{owner}} |
| Status       | {{status}} |
| Version      | {{version}} |
| Last Updated | {{date}} |
```

#### Repeated Sections

```markdown
{{#requirements}}
| {{id}} | {{title}} | {{description}} | {{priority}} | {{status}} | {{tracedFrom}} |
{{/requirements}}
```

#### Conditional Sections

```markdown
{{#hasUserStories}}
## User Stories
{{#userStories}}
### {{id}}: {{title}}
- **As a** {{actor}}
- **I want to** {{action}}
- **So that** {{benefit}}
{{/userStories}}
{{/hasUserStories}}
```

### Rendering Procedure

1. Load template file from `_meta/templates/{docType}.template.md`
2. Prepare context object from classified data, digest data, or upstream documents
3. Replace all `{{placeholder}}` tokens with actual values
4. Expand all `{{#section}}...{{/section}}` blocks with array data
5. Remove any unresolved placeholders (replace with empty string)
6. Write rendered content to target path

## 3. JSON Companion Generation

Every `.md` SSoT document MUST have a corresponding `.json` companion file at the same path with the same base name. The JSON companion follows `_meta/schemas/doc-companion.schema.json`.

### Companion File Pairing

```
docs/{app}/plan/srs.md     ↔  docs/{app}/plan/srs.json
docs/{app}/design/erd.md   ↔  docs/{app}/design/erd.json
docs/{app}/check/testcases.md  ↔  docs/{app}/check/testcases.json
```

### JSON Companion Schema

```json
{
  "docType": "srs",
  "app": "my-app",
  "status": "Draft",
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T10:00:00Z",
  "items": [
    {
      "id": "FR-010",
      "type": "functional-requirement",
      "title": "User Registration",
      "description": "System shall allow new users to register...",
      "status": "Draft",
      "priority": "Must",
      "tracedFrom": ["USR-010"],
      "tracedTo": ["US-010", "US-020"]
    }
  ],
  "crossRefs": [
    {
      "from": "FR-010",
      "to": "US-010",
      "relation": "derives"
    }
  ]
}
```

### Generation Rules

1. **Extract all identifiable items** from the rendered `.md` — every row in a table with an ID column, every heading with an ID prefix, every list item with an ID pattern.
2. **Populate the `items` array** with each extracted item. Every item MUST have `id`, `type`, `title`, and `status` at minimum.
3. **Build `crossRefs` array** by scanning `tracedFrom` and `tracedTo` fields in items. Each cross-reference becomes a directional edge.
4. **Set metadata fields**: `docType`, `app`, `status` (matching frontmatter), `version`, `lastUpdated`.
5. **Validate against schema**: The generated JSON MUST pass validation against `_meta/schemas/doc-companion.schema.json`.

### Synchronization Verification

After any document write or update, doc-engine MUST verify synchronization:

**Standard documents (MD is source of truth):**
1. Parse all IDs from the `.md` document (table rows, headings, list items)
2. Compare with `items[].id` in the `.json` companion
3. Verify status fields match between frontmatter and JSON
4. Verify version fields match
5. If any mismatch is found, regenerate the `.json` from the `.md` as the source of truth

**Design System (HTML is source of truth):**
1. Parse all CSS custom properties from the HTML `:root` block
2. Parse all component classes (`.ds-*`) from the HTML `<style>` block
3. Compare tokens/components with MD tables and JSON items
4. Verify status and version fields match across HTML metadata, MD frontmatter, and JSON
5. If any mismatch is found, regenerate `.md` and `.json` from the HTML as the source of truth

## 4. ID Auto-Assignment

All IDs in u-maker documents follow the 10-increment convention for easy insertion.

### ID Format

```
{TYPE}-{NNN}
```

- **TYPE**: 2-4 uppercase letters identifying the item type
- **NNN**: Zero-padded 3-digit number, incrementing by 10

### ID Type Prefixes

| Prefix | Item Type | Document |
|--------|-----------|----------|
| FR | Functional Requirement | SRS |
| NFR | Non-Functional Requirement | SRS |
| US | User Story | SRS |
| FT | Feature | SRS |
| STK | Stakeholder | SRS |
| IA | Information Architecture Item | IA |
| ENT | Entity | ERD |
| REL | Relationship | ERD |
| API | API Endpoint | API |
| SC | Screen | Screens |
| DS | Design System Token | Design System |
| CMP | Component | Design System |
| TC | Test Case | Test Cases |

### Auto-Assignment Algorithm

1. Scan existing items of the same type in the document
2. Find the maximum existing ID number (e.g., FR-030 → 30)
3. Assign next ID as max + 10 (e.g., FR-040)
4. If no existing items, start at `{TYPE}-010`

### Insertion Between Existing IDs

When inserting between existing items (e.g., between FR-010 and FR-020):

1. Use the midpoint: FR-015
2. If midpoint is taken, use next available: FR-011, FR-012, etc.
3. Never renumber existing IDs — this would break cross-references in `data/links.json`

## 5. Frontmatter Schema

Every SSoT `.md` document begins with YAML frontmatter delimited by `---`:

```yaml
---
Owner: {agent-name}
Status: {Draft|Review|Final}
Version: {semver}
Last Updated: {ISO-8601 date}
Related Docs: [{comma-separated doc references}]
App: {app-name}
---
```

### Frontmatter Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Owner | string | Yes | The agent that last wrote this document (e.g., u-agent-plan) |
| Status | enum | Yes | Current lifecycle status: Draft, Review, or Final |
| Version | string | Yes | Semantic version (e.g., 1.0.0). Major for restructure, minor for content addition, patch for fixes |
| Last Updated | string | Yes | ISO-8601 date-time of last modification |
| Related Docs | array | Yes | List of related document references (e.g., [srs.md, ia.md]) |
| App | string | Yes | Target application name |

### Frontmatter Parsing

1. Read lines between first `---` and second `---`
2. Parse as YAML key-value pairs
3. Validate all required fields are present
4. Validate Status is one of the allowed enum values
5. Return parsed object for use in JSON companion generation and dep-engine updates

## 6. Version Management

Document versions follow semantic versioning (semver) within the u-maker context.

### Version Numbering

```
MAJOR.MINOR.PATCH
```

| Segment | When to Increment | Example |
|---------|-------------------|---------|
| MAJOR | Document structure changes (sections added/removed, template change) | 1.0.0 → 2.0.0 |
| MINOR | New items added (new FRs, new entities, new screens) | 1.0.0 → 1.1.0 |
| PATCH | Existing item modified (description updated, priority changed) | 1.0.0 → 1.0.1 |

### Version Update Rules

1. **On document creation**: Set version to `1.0.0`
2. **On item addition via `/u-add`**: Increment MINOR (1.0.0 → 1.1.0)
3. **On item update via `/u-update`**: Increment PATCH (1.0.0 → 1.0.1)
4. **On template-driven regeneration**: Increment MAJOR (1.2.3 → 2.0.0)
5. **On gatekeeper rejection → rework**: Increment PATCH
6. **On gatekeeper approval**: No version change (status changes to Final)

### Version in JSON Companion

The `version` field in the JSON companion MUST always match the `Version` field in the `.md` frontmatter. When either is updated, the other MUST be updated in the same operation.

## 7. Document Operations Summary

### Create (C)

```
Input:  docType, app, context data
Steps:  Load template → Render → Write .md → Generate .json → Update links.json
Output: docs/{app}/{phase}/{docType}.md + .json
```

### Read (R)

```
Input:  docType, app (or full path)
Steps:  Read .md → Parse frontmatter → Return content + metadata
Output: Document content object
```

### Update (U)

```
Input:  docType, app, changes
Steps:  Read current .md → Apply changes → Increment version → Write .md → Regenerate .json → Update links.json
Output: Updated docs/{app}/{phase}/{docType}.md + .json
```

### Delete (D)

```
Input:  docType, app
Steps:  Remove .md → Remove .json → Remove nodes/edges from links.json → Verify no orphan references
Output: Cleaned file system and dependency graph
```
