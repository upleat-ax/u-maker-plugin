# SRS Specification Reference

> Detailed rules for generating the Software Requirements Specification (SRS) document, including the 4-tier hierarchy, ID conventions, MoSCoW priority system, traceability chains, and JSON companion structure.

## 1. Overview

The SRS is the primary deliverable of the Plan phase. It captures all functional requirements, non-functional requirements, user stories, and features derived from the aggregated digest data. The SRS serves as the single source of truth for what the system must do and acts as the foundation for all downstream documents (IA, ERD, API, Screens, Design System).

The SRS is always produced as a pair: `srs.md` (human-readable Markdown) and `srs.json` (machine-readable companion conforming to `_meta/schemas/doc-companion.schema.json`). Both files must be kept in strict sync -- any item present in one must exist in the other.

## 2. The 4-Tier Hierarchy

The SRS organizes requirements in a strict 4-tier hierarchy with full traceability:

```
FR (Functional Requirement)
 └─ US (User Story)
     └─ FT (Feature)
```

Additionally, NFR (Non-Functional Requirement) exists as a parallel tier at the same level as FR but does not participate in the US→FT chain.

### 2.1 Tier Definitions

**FR (Functional Requirement):** A high-level statement of what the system must do. Each FR describes a distinct capability area. FRs are technology-agnostic and focus on business outcomes. Examples: "The system shall allow users to register accounts", "The system shall process payments via multiple gateways".

**NFR (Non-Functional Requirement):** A quality attribute or constraint on how the system operates. NFRs cover performance, security, usability, reliability, scalability, and compliance. Each NFR must specify a measurable metric. Examples: "Page load time shall not exceed 2 seconds (P95)", "System shall maintain 99.9% uptime".

**US (User Story):** A specific user-facing scenario derived from an FR. Written in the canonical format: "As a {actor}, I want to {action}, so that {benefit}". Each US must trace back to exactly one FR via the `tracedFrom` field. A single FR typically produces 2-8 user stories.

**FT (Feature):** A concrete, implementable unit of work derived from a US. Features are the granular building blocks that developers work on. Each FT must trace back to exactly one US. FTs have story point estimates and represent the smallest unit of deliverable functionality. A single US typically produces 1-5 features.

### 2.2 Traceability Rules

1. Every US must have exactly one `tracedFrom` reference pointing to an FR ID.
2. Every FT must have exactly one `tracedFrom` reference pointing to a US ID.
3. Every FR should have at least one US traced to it (orphan FRs are flagged as warnings).
4. Every US should have at least one FT traced to it (orphan USs are flagged as warnings).
5. Cross-tier tracing is forbidden: an FT must not trace directly to an FR.
6. The `tracedTo` field is the inverse of `tracedFrom` and must be auto-populated. For example, if US-010 has `tracedFrom: ["FR-010"]`, then FR-010 must have `tracedTo: ["US-010"]`.

## 3. ID 10-Increment Convention

All IDs in the SRS follow the 10-increment pattern:

| Prefix | Example Sequence | Pattern |
|--------|-----------------|---------|
| FR | FR-010, FR-020, FR-030 | `FR-\d{3}` |
| NFR | NFR-010, NFR-020, NFR-030 | `NFR-\d{3}` |
| US | US-010, US-020, US-030 | `US-\d{3}` |
| FT | FT-010, FT-020, FT-030 | `FT-\d{3}` |
| STK | STK-010, STK-020, STK-030 | `STK-\d{3}` |

### 3.1 Why 10-Increment

The 10-increment system reserves gaps for future insertions. When a new requirement needs to be inserted between FR-010 and FR-020, it receives ID FR-015. This avoids renumbering all subsequent items, which would break cross-references across documents.

### 3.2 Insertion Rules

- **Between existing IDs:** Use the midpoint. Between FR-010 and FR-020, insert FR-015. Between FR-010 and FR-015, insert FR-012.
- **After the last ID:** Continue the 10-increment sequence. After FR-030, the next is FR-040.
- **Minimum gap:** Never insert an ID that creates a gap smaller than 1 (no fractional IDs). If the space between two IDs is exhausted, trigger a global renumber operation (documented in the changelog).

### 3.3 ID Regex Validation

All IDs must match the pattern `^[A-Z]{2,4}-\d{3}$`. The doc-companion schema enforces this pattern. IDs that do not match are rejected during validation.

## 4. MoSCoW Priority System

Every FR, NFR, US, and FT must have a priority from the MoSCoW framework:

| Priority | Definition | Target Allocation |
|----------|-----------|-------------------|
| **Must** | Non-negotiable for this release. The system does not function without it. | 60% of total items |
| **Should** | Important but not critical. Can be deferred to the next iteration if necessary. | 20% of total items |
| **Could** | Desirable. Included only if time and resources allow. | 15% of total items |
| **Won't** | Explicitly out of scope for this release. Documented for future consideration. | 5% of total items |

### 4.1 Priority Inheritance

When an FR has priority `Must`, all of its child US items should default to `Must` unless explicitly overridden. Similarly, FTs inherit priority from their parent US by default. This inheritance is a default, not a constraint -- individual items can be reprioritized.

### 4.2 Priority Validation

The SRS generator emits a warning if:
- More than 80% of items are `Must` (scope creep risk).
- No items are `Won't` (suggests incomplete scope definition).
- A child item has higher priority than its parent (e.g., a `Must` FT under a `Could` US).

## 5. Acceptance Criteria Format

Each User Story (US) must include at least one acceptance criterion. Acceptance criteria are written as testable checkbox items:

```markdown
- [ ] Given {precondition}, when {action}, then {expected result}
- [ ] {Simple declarative statement that can be verified}
```

### 5.1 Rules for Acceptance Criteria

1. Each criterion must be independently testable (no compound criteria with AND/OR).
2. Criteria must be specific and measurable -- avoid vague terms like "fast", "user-friendly", "seamless".
3. Minimum 1 criterion per US, recommended 3-5.
4. Each criterion should map to at least one test case in the Gatekeeping phase (Runtime QA sub-phase).
5. Use the Given/When/Then format for behavioral criteria and simple declarative format for state-based criteria.

## 6. Stakeholder Mapping

Stakeholders are identified from digest data and recorded in Section 2 of the SRS.

### 6.1 Stakeholder Fields

| Field | Description | Example |
|-------|-----------|---------|
| ID | STK-010, STK-020, ... | STK-010 |
| Name | Role or person name | Product Owner |
| Role | Decision Maker / User / Sponsor / Developer / Regulator | Decision Maker |
| Department | Organizational unit | Product Team |
| Needs | What this stakeholder requires from the system | Feature prioritization dashboard |

### 6.2 Stakeholder Derivation

Stakeholders are extracted from digest files where they appear in `stakeholders` arrays. The aggregation engine merges stakeholders by name, combining roles and needs from multiple sources. If a person is mentioned in multiple documents with different roles, all roles are captured (comma-separated).

### 6.3 Stakeholder-to-FR Mapping

Each FR should note which stakeholder(s) it serves. This mapping is captured in the `srs.json` via the `crossRefs` array with relation type `"stakeholder-needs"`.

## 7. Constraint Categorization

Constraints from digest data are organized into categories in Section 7 of the SRS:

| Category | Examples |
|----------|---------|
| **Technical** | Technology stack mandates, browser support, API version requirements |
| **Business** | Budget limits, timeline deadlines, regulatory compliance |
| **Operational** | Deployment environments, monitoring requirements, SLA targets |
| **Security** | Authentication standards, data encryption requirements, audit logging |
| **Legal** | GDPR compliance, data residency, licensing restrictions |

Each constraint is prefixed with its category in bold: `- **Technical**: Must support Chrome, Firefox, Safari, Edge (latest 2 versions)`.

## 8. Glossary Extraction

The glossary (Section 8 of the SRS) is automatically populated from `domainTerms` across all digest files.

### 8.1 Extraction Rules

1. Terms are merged case-insensitively. "SKU" and "sku" are the same term.
2. If multiple definitions exist for the same term, the most detailed one is kept and others are noted as alternatives.
3. Abbreviations are expanded: if "SKU" appears with definition "Stock Keeping Unit", both the abbreviation and expansion are recorded.
4. Terms are sorted alphabetically in the rendered Markdown.
5. Domain terms referenced in FR/NFR/US descriptions should be linked to the glossary entry (using Markdown anchor syntax).

## 9. JSON Companion Structure (srs.json)

The `srs.json` file conforms to `_meta/schemas/doc-companion.schema.json` and contains:

```json
{
  "docType": "srs",
  "app": "my-app",
  "status": "Draft",
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T10:30:00Z",
  "items": [
    {
      "id": "FR-010",
      "type": "functional-requirement",
      "title": "User Registration",
      "description": "System must support email and social login registration",
      "status": "Draft",
      "priority": "Must",
      "tracedFrom": [],
      "tracedTo": ["US-010", "US-020"]
    },
    {
      "id": "US-010",
      "type": "user-story",
      "title": "Email Registration",
      "description": "As a visitor, I want to register with email...",
      "status": "Draft",
      "priority": "Must",
      "tracedFrom": ["FR-010"],
      "tracedTo": ["FT-010", "FT-020"]
    },
    {
      "id": "FT-010",
      "type": "feature",
      "title": "Registration Form UI",
      "description": "Email/password form with validation",
      "status": "Draft",
      "priority": "Must",
      "tracedFrom": ["US-010"],
      "tracedTo": []
    }
  ],
  "crossRefs": [
    {
      "from": "FR-010",
      "to": "STK-010",
      "relation": "stakeholder-needs"
    }
  ]
}
```

### 9.1 Item Type Values

| type | Used For |
|------|---------|
| `functional-requirement` | FR items |
| `non-functional-requirement` | NFR items |
| `user-story` | US items |
| `feature` | FT items |
| `stakeholder` | STK items |

### 9.2 Status Values

Items progress through: `Draft` → `Review` → `Approved` → `Implemented` → `Tested`. At SRS creation time, all items start as `Draft`. The document-level status follows the same `Draft` → `Review` → `Final` progression defined in doc-companion.schema.json.

### 9.3 Cross-References

The `crossRefs` array captures relationships that do not fit the traceability hierarchy, such as:
- `stakeholder-needs`: links an FR to the stakeholder it serves
- `constraint-applies`: links a constraint to the FRs it affects
- `duplicate-of`: marks items identified as duplicates during aggregation

## 10. SRS Sections Mapping to Template

The `_meta/templates/srs.template.md` defines the canonical section structure. Each section maps to specific digest data:

| Section | Source Data | Notes |
|---------|-----------|-------|
| 1. Project Overview | Config + digest summaries | Aggregated from project metadata |
| 2. Stakeholders | `digest.stakeholders` | Merged and deduplicated |
| 3. Functional Requirements | `digest.requirements` (type=functional) | Grouped and numbered |
| 4. Non-Functional Requirements | `digest.requirements` (type=non-functional) | Categorized |
| 5. User Stories | Derived from FRs | Auto-generated from FR descriptions |
| 6. Features | Derived from USs | Auto-generated from US acceptance criteria |
| 7. Constraints | `digest.constraints` | Categorized |
| 8. Glossary | `digest.domainTerms` | Alphabetically sorted |

## 11. Validation Checks

After SRS generation, the following validations are performed:

1. **ID uniqueness:** No duplicate IDs across all prefixes.
2. **Traceability completeness:** Every US traces to an FR, every FT traces to a US.
3. **No orphan items:** Every FR has at least one US (warning if not).
4. **Priority distribution:** MoSCoW percentages are within acceptable ranges.
5. **Acceptance criteria presence:** Every US has at least one criterion.
6. **JSON-Markdown sync:** Every item in `srs.json` has a corresponding entry in `srs.md` and vice versa.
7. **ID format:** All IDs match `^[A-Z]{2,4}-\d{3}$`.
8. **Link graph update:** `data/links.json` contains nodes and edges for all SRS items.
