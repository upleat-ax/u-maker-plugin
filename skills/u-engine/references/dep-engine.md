# dep-engine Reference

The dep-engine manages the global dependency graph stored in `data/links.json`. It tracks how digest items, SSoT documents, and individual document items relate to each other through directional edges. This graph enables traceability, cascade propagation (when upstream changes ripple downstream), orphan detection, and cross-reference validation.

## 1. links.json Schema

The dependency graph is stored as a single JSON file at `data/links.json`, following `_meta/schemas/links.schema.json`.

### Top-Level Structure

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T10:00:00Z",
  "nodes": [],
  "edges": []
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Schema version for migration compatibility |
| `lastUpdated` | string (ISO-8601) | Yes | Timestamp of the most recent graph modification |
| `nodes` | array | Yes | All nodes in the dependency graph |
| `edges` | array | Yes | All directed edges connecting nodes |

### Initialization

When a project is first created via `/u-init`, `data/links.json` is initialized as:

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-04-03T10:00:00Z",
  "nodes": [],
  "edges": []
}
```

## 2. Node Types

Every node in the graph represents a traceable artifact in the u-maker system. There are three node types.

### Type: `digest`

Represents a refined analysis file produced by digest-engine from raw dropzone input.

```json
{
  "id": "digest:rfp-document",
  "type": "digest",
  "path": "data/digest/rfp-document.json"
}
```

- **id**: Prefixed with `digest:` followed by the base filename (without extension)
- **path**: Relative path from `.u-maker/` root to the digest JSON file
- **itemId**: Not used for digest nodes (omitted or null)

### Type: `doc`

Represents a complete SSoT document (the `.md` + `.json` pair).

```json
{
  "id": "doc:my-app/plan/srs",
  "type": "doc",
  "path": "docs/my-app/plan/srs.md"
}
```

- **id**: Prefixed with `doc:` followed by `{app}/{phase}/{docType}`
- **path**: Relative path to the `.md` file
- **itemId**: Not used for doc nodes (omitted or null)

### Type: `item`

Represents a single identifiable item within a document (a requirement, entity, screen, test case, etc.).

```json
{
  "id": "item:FR-010",
  "type": "item",
  "path": "docs/my-app/plan/srs.md",
  "itemId": "FR-010"
}
```

- **id**: Prefixed with `item:` followed by the item's ID
- **path**: Relative path to the document containing this item
- **itemId**: The item's ID within its document (e.g., FR-010, ENT-020, SC-030)

### Node ID Conventions

| Node Type | ID Format | Example |
|-----------|-----------|---------|
| digest | `digest:{filename}` | `digest:rfp-v2` |
| doc | `doc:{app}/{phase}/{docType}` | `doc:my-app/plan/srs` |
| item | `item:{ITEM-ID}` | `item:FR-010` |

### Node Uniqueness

Every node `id` MUST be unique within the graph. If a duplicate is detected during insertion, the existing node is updated rather than creating a second entry.

## 3. Edge Types

Edges are directed connections from one node to another. Each edge has a `relation` type that describes the nature of the dependency.

### Relation: `derives`

Indicates that the target was derived from the source. Used when higher-level artifacts produce lower-level ones.

```json
{
  "from": "digest:rfp-document",
  "to": "item:FR-010",
  "relation": "derives"
}
```

Typical `derives` chains:

```
digest → FR (functional requirement)
digest → NFR (non-functional requirement)
digest → STK (stakeholder)
FR → US (user story)
US → FT (feature)
FR → ENT (entity, via ERD)
FR → API (API endpoint)
FR → SC (screen)
```

### Relation: `implements`

Indicates that the target implements the source specification. Used when design or code artifacts realize a requirement.

```json
{
  "from": "item:FR-010",
  "to": "item:SC-010",
  "relation": "implements"
}
```

Typical `implements` chains:

```
FR → SC (screen implements requirement)
US → SC (screen implements user story)
FT → code file (code implements feature)
API → code file (code implements API endpoint)
ENT → DB migration (migration implements entity)
```

### Relation: `tests`

Indicates that the target tests/validates the source. Used when test cases verify features.

```json
{
  "from": "item:FT-010",
  "to": "item:TC-010",
  "relation": "tests"
}
```

Typical `tests` chains:

```
FT → TC (test case tests feature)
US → TC (test case validates user story)
API → TC (test case validates API endpoint)
```

### Relation: `references`

A general-purpose relation indicating that the target references the source without a strict derivation or implementation relationship.

```json
{
  "from": "item:SC-010",
  "to": "item:API-010",
  "relation": "references"
}
```

Typical `references` usages:

```
SC → API (screen references API endpoint)
SC → ENT (screen references entity for data display)
DS → SC (design system token referenced by screen)
TC → SC (test case references screen under test)
```

### Edge Summary Table

| Relation | Meaning | From Types | To Types |
|----------|---------|------------|----------|
| derives | Target was produced from source | digest, item | item, doc |
| implements | Target realizes source specification | item | item |
| tests | Target validates/verifies source | item | item |
| references | Target references source (general) | item, doc | item, doc |

## 4. Cascade Propagation Rules

When a node changes (content updated, status changed, or deleted), the dep-engine propagates the change through the graph to affected downstream nodes.

### Change Detection

A node is considered "changed" when:

1. Its source file hash differs from the previously recorded hash
2. Its status transitions (e.g., Draft → Review, Review → Draft)
3. Its content is explicitly updated via `/u-update`
4. Its source digest is re-analyzed (new hash)

### Propagation Algorithm

```
function propagate(changedNodeId):
    mark changedNodeId as "dirty"
    queue = [changedNodeId]

    while queue is not empty:
        current = queue.dequeue()
        outgoing = findEdges(from: current)

        for each edge in outgoing:
            target = edge.to
            if target is not already "dirty":
                mark target as "dirty"
                queue.enqueue(target)

    return all "dirty" nodes
```

### Cascade Rules by Relation Type

| Relation | Cascade Behavior |
|----------|-----------------|
| `derives` | Target MUST be re-evaluated. If source digest changes, derived requirements may need update. If FR changes, derived US/FT should be reviewed. |
| `implements` | Target SHOULD be reviewed. If the specification changes, the implementation may be out of sync. |
| `tests` | Target MUST be re-evaluated. If the feature changes, test cases may need update. |
| `references` | Target is FLAGGED for review. No automatic re-generation, but a warning is surfaced. |

### Cascade Severity Levels

| Level | Action | Triggered By |
|-------|--------|--------------|
| MUST re-generate | Automatically re-invoke the generating agent | `derives` from changed digest |
| MUST re-evaluate | Flag for gatekeeper re-scoring | `derives` from changed item, `tests` from changed item |
| SHOULD review | Add to improvement items list | `implements` from changed spec |
| FLAG | Surface warning in `/u-status` | `references` from changed item |

### Status Cascade

When a document's status changes from Final back to Draft (due to upstream changes):

1. Set the document's frontmatter `Status: Draft` and JSON companion `status: "Draft"`
2. Find all downstream documents via `derives` and `implements` edges
3. If any downstream document is `Final`, change it to `Review` (not Draft — it needs re-evaluation, not regeneration)
4. Log the cascade chain in `.state/loop-state.json` for traceability

## 5. Orphan Detection

Orphan detection identifies nodes and edges that are disconnected or invalid.

### Orphan Node Types

| Orphan Type | Description | Detection Rule |
|-------------|-------------|----------------|
| Unreachable item | An item node with no incoming edges | `item` node where no edge has `to == node.id` |
| Leaf without test | A FT (feature) item with no outgoing `tests` edge | `item:FT-*` where no edge has `from == node.id && relation == "tests"` |
| Dangling doc | A doc node whose file no longer exists on disk | `doc` node where `path` file is missing |
| Dangling digest | A digest node whose source file was removed from dropzone | `digest` node where source no longer exists |

### Orphan Detection Algorithm

```
function detectOrphans():
    orphans = []

    for each node in nodes:
        // Check file existence
        if not fileExists(node.path):
            orphans.add({ node, reason: "file-missing" })
            continue

        // Check unreachable items
        if node.type == "item":
            incomingEdges = findEdges(to: node.id)
            if incomingEdges.length == 0 and node.itemId not starts with "STK":
                orphans.add({ node, reason: "unreachable" })

        // Check untested features
        if node.type == "item" and node.itemId starts with "FT":
            testEdges = findEdges(from: node.id, relation: "tests")
            if testEdges.length == 0:
                orphans.add({ node, reason: "untested-feature" })

    // Check dangling edges
    for each edge in edges:
        fromNode = findNode(edge.from)
        toNode = findNode(edge.to)
        if fromNode is null:
            orphans.add({ edge, reason: "from-node-missing" })
        if toNode is null:
            orphans.add({ edge, reason: "to-node-missing" })

    return orphans
```

### Orphan Resolution

| Orphan Type | Resolution |
|-------------|------------|
| file-missing | Remove the node and all connected edges from links.json |
| unreachable | Flag for review — the item may need a `derives` edge from a digest or parent item |
| untested-feature | Flag for `/u-check` — test cases need to be created |
| from-node-missing | Remove the edge from links.json |
| to-node-missing | Remove the edge from links.json |

## 6. Graph Validation

Graph validation ensures the integrity and consistency of the entire dependency graph. It is invoked during `/u-gate` (GK-11: Cross-Reference) and can be triggered explicitly via `/u-sync`.

### Validation Checks

#### Check 1: Node-File Consistency

For every node in `nodes`, verify that the referenced file exists:

```
for each node in nodes:
    assert fileExists(node.path), "Node {node.id} references missing file {node.path}"
```

#### Check 2: Item-Document Consistency

For every `item` node, verify the item ID exists in the referenced document:

```
for each node in nodes where node.type == "item":
    doc = readDocument(node.path)
    assert doc contains item with id == node.itemId,
        "Item {node.itemId} not found in {node.path}"
```

#### Check 3: Edge Endpoint Validity

For every edge, verify both endpoints exist as nodes:

```
for each edge in edges:
    assert findNode(edge.from) exists, "Edge from {edge.from} has no matching node"
    assert findNode(edge.to) exists, "Edge to {edge.to} has no matching node"
```

#### Check 4: Bidirectional Cross-Reference Consistency

For every cross-reference in a document's JSON companion, verify a corresponding edge exists in links.json:

```
for each doc companion .json:
    for each crossRef in companion.crossRefs:
        assert edgeExists(from: crossRef.from, to: crossRef.to),
            "CrossRef {crossRef.from} → {crossRef.to} missing from links.json"
```

And conversely, for every edge in links.json, verify the corresponding cross-reference exists in the relevant JSON companion.

#### Check 5: Acyclicity for `derives`

The `derives` relation MUST form a DAG (Directed Acyclic Graph). Cycles in derivation chains indicate circular dependencies:

```
function checkDerivesAcyclicity():
    derivesEdges = edges.filter(e => e.relation == "derives")
    visited = set()
    recursionStack = set()

    for each node in nodes:
        if node not in visited:
            if hasCycle(node, derivesEdges, visited, recursionStack):
                return FAIL("Cycle detected in derives chain")
    return PASS
```

#### Check 6: Coverage Completeness

Verify key traceability chains are complete:

```
- Every FR must derive at least one US
- Every US must derive at least one FT
- Every FT must have at least one TC (via "tests" edge)
- Every digest must derive at least one FR or NFR
```

### Validation Report

Graph validation produces a report with:

```json
{
  "timestamp": "2026-04-03T10:00:00Z",
  "totalNodes": 42,
  "totalEdges": 68,
  "checks": [
    { "name": "node-file-consistency", "status": "PASS", "issues": [] },
    { "name": "item-document-consistency", "status": "PASS", "issues": [] },
    { "name": "edge-endpoint-validity", "status": "FAIL", "issues": ["Edge to item:FR-999 has no matching node"] },
    { "name": "bidirectional-crossref", "status": "PASS", "issues": [] },
    { "name": "derives-acyclicity", "status": "PASS", "issues": [] },
    { "name": "coverage-completeness", "status": "WARN", "issues": ["FT-030 has no test case"] }
  ],
  "orphans": []
}
```

## 7. Graph Operations

### Add Node

```
function addNode(id, type, path, itemId?):
    if findNode(id) exists:
        updateNode(id, { path, itemId })
    else:
        nodes.push({ id, type, path, itemId })
    lastUpdated = now()
    writeLinksJson()
```

### Remove Node

```
function removeNode(id):
    nodes = nodes.filter(n => n.id != id)
    edges = edges.filter(e => e.from != id && e.to != id)
    lastUpdated = now()
    writeLinksJson()
```

### Add Edge

```
function addEdge(from, to, relation):
    if edgeExists(from, to, relation):
        return  // idempotent
    assert findNode(from) exists, "From node must exist"
    assert findNode(to) exists, "To node must exist"
    if relation == "derives":
        assert not createsCycle(from, to), "derives edges must not create cycles"
    edges.push({ from, to, relation })
    lastUpdated = now()
    writeLinksJson()
```

### Remove Edge

```
function removeEdge(from, to, relation?):
    if relation:
        edges = edges.filter(e => !(e.from == from && e.to == to && e.relation == relation))
    else:
        edges = edges.filter(e => !(e.from == from && e.to == to))
    lastUpdated = now()
    writeLinksJson()
```

### Query Upstream

Find all nodes that the given node depends on (traverse incoming edges):

```
function queryUpstream(nodeId, depth = Infinity):
    result = []
    queue = [nodeId]
    visited = set()
    currentDepth = 0

    while queue is not empty and currentDepth < depth:
        next = []
        for each id in queue:
            incoming = findEdges(to: id)
            for each edge in incoming:
                if edge.from not in visited:
                    visited.add(edge.from)
                    result.push({ node: findNode(edge.from), edge, depth: currentDepth + 1 })
                    next.push(edge.from)
        queue = next
        currentDepth++

    return result
```

### Query Downstream

Find all nodes that depend on the given node (traverse outgoing edges):

```
function queryDownstream(nodeId, depth = Infinity):
    result = []
    queue = [nodeId]
    visited = set()
    currentDepth = 0

    while queue is not empty and currentDepth < depth:
        next = []
        for each id in queue:
            outgoing = findEdges(from: id)
            for each edge in outgoing:
                if edge.to not in visited:
                    visited.add(edge.to)
                    result.push({ node: findNode(edge.to), edge, depth: currentDepth + 1 })
                    next.push(edge.to)
        queue = next
        currentDepth++

    return result
```
