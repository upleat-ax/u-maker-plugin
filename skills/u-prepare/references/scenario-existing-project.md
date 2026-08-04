# Scenarios B1 & B2 — Existing Project

> Detailed flows for `/u-prepare` when the project root already contains source code. PBGD Plan.Prepare, v4.0.

## 1. Two variants

| Variant | When to use |
|---------|-------------|
| **B1** — existing + dropzone | You have supplementary docs/links (design docs, spec PDFs, Figma) that describe the system; ingest those alongside. Reverse-engineering from code is optional/skipped. |
| **B2** — existing + reverse | You have source code but no written specs. Derive the digest directly from the codebase by reverse-engineering structure, endpoints, data models, UI screens. |

The two are **not mutually exclusive** — users can run B1 first and later run `/u-reverse` to augment the digest.

## 2. Scenario B1 flow

```
┌─ Step 1. /u-prepare-foldertree {app-name}
│
├─ Step 2. Prompt user to populate dropzone with supplementary docs
│    "Drop any existing specs/docs/Figma links describing this
│     system into .u-maker/data/dropzone/."
│
├─ Step 3. /u-analyze --app {app-name}
│    extracts digest from dropzone contents
│
├─ Step 4. 요구사항 협의 — with emphasis on reconciling observed
│    vs. documented behavior (ask: "Does this spec still match
│    the code? What drifted?")
│
└─ Step 5. Preparation summary
```

**Tip:** Users in B1 benefit from adding `.code-link` or `.dir-link` descriptors that point to specific modules in the codebase, so the digest can cross-reference code → spec.

## 3. Scenario B2 flow

```
┌─ Step 1. /u-prepare-foldertree {app-name}
│
├─ Step 2. (skip dropzone — or allow optional token-light hints)
│
├─ Step 3. /u-reverse --app {app-name}
│    analyzes source code, extracts:
│      · entity models → digest businessRules / domainRules
│      · API routes → digest workflows + endpoints
│      · UI routes/pages → digest screenDescriptions
│      · README and inline docs → digest summary + keywords
│    writes data/digest/reverse/*.digest.json
│
├─ Step 4. 요구사항 협의 — surface gaps where the code shows
│    behavior but the rationale isn't documented anywhere
│
└─ Step 5. Preparation summary
```

## 4. Choosing between B1 and B2

`/u-prepare` auto-detects and prompts:

```
Existing source detected. How would you like to prepare?
  (1) B1 — I'll drop docs/specs/Figma into data/dropzone/
  (2) B2 — Reverse-engineer the code into a digest now
  (3) Both — B1 first, then B2 to augment
```

## 5. Hand-off

Both variants end with `data/digest/` populated. `/u-plan` treats B1 and B2 digests identically, except that B2-origin digests are flagged with `sourceType: "reverse"` for downstream traceability.
