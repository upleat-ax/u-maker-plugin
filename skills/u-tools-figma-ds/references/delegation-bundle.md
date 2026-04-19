# Delegation Bundle — u-tools-figma-ds → figma:figma-generate-library

The exact payload contract `/u-tools-figma-ds` hands off to the `figma:figma-generate-library` skill. Stable contract → independent plugin upgrades stay safe.

## 1. Bundle shape

```ts
type DelegationBundle = {
  // Required — destination
  targetFile: {
    fileKey: string;
    pageStrategy: "create-or-reuse" | "create-new" | "use-existing";
    pageNamePrefix?: string;          // default "DS"
  };

  // Required — what to do
  phases: Array<"foundations" | "components" | "integration">;
  themes: Array<"light" | "dark" | string>;

  // Required — pre-extracted tokens (W3C tokens spec shape)
  tokens: NormalisedTokens;            // see references/token-extraction.md §2

  // Required — pre-extracted, pre-ordered components (atoms → organisms)
  components: ExtractedComponent[];    // see references/component-extraction.md §5

  // Required — rule pack version (so the plugin can validate against the same checklist)
  rulePackVersion: string;             // e.g., "design-system-rules.md@v4.0"

  // Required — telemetry
  skillNames: "u-tools-figma-ds";

  // Optional — operational
  options?: {
    runId: string;
    askBeforeEachComponent?: boolean;  // default true (matches figma-generate-library Phase 3 checkpoint)
    overwriteExistingPages?: boolean;  // default false
    overwriteExistingComponents?: boolean;  // default false
    skipFoundationsIfPresent?: boolean;  // default true (idempotent re-runs)
  };
};
```

## 2. Plugin response

```ts
type DelegationResult = {
  ok: boolean;
  pages: Array<{ id: string; name: string; phase: "foundations" | "components" }>;
  variables: {
    collections: Array<{ id: string; name: string; modes: string[] }>;
    created: number;
    updated: number;
    skipped: number;
  };
  components: Array<{
    key: string;                       // matches ExtractedComponent.key
    figmaKey: string;                  // canonical Figma key
    figmaUrl: string;                  // deep link
    variantsCreated: number;
    propsCreated: number;
    bindingsResolved: number;
    bindingsStubbed: number;           // count of unresolved bindings the plugin had to fall back on
    screenshotPath?: string;           // PNG path for spot-check
    durationMs: number;
  }>;
  warnings: Array<{
    componentKey?: string;
    code: string;
    message: string;
  }>;
  errors: Array<{
    componentKey?: string;
    message: string;
    recoverable: boolean;
  }>;
};
```

## 3. Phase ordering enforcement

The plugin's `figma-generate-library` skill enforces:

```
DISCOVERY → FOUNDATIONS → FILE STRUCTURE → COMPONENTS → INTEGRATION + QA
```

The wrapper's `phases` parameter narrows which of these sections to execute, but the plugin will still run DISCOVERY (read-only) for context. If `phases` includes `components` but `foundations` is omitted, the plugin verifies the foundations are already present in the file; if missing, it errors with a clear message and the wrapper retries with `foundations` prepended.

## 4. Per-component checkpoints

When `options.askBeforeEachComponent` is true, the plugin pauses after each component and the wrapper surfaces a question:

```
Component "Button" generated:
  - 12 variants
  - 3 props
  - 18 bindings resolved, 0 stubbed
  - Screenshot: <path>

Continue to "Card"?
  1. Continue
  2. Pause and let me edit in Figma manually first
  3. Abort
```

When `--auto` is set, this is skipped; the wrapper persists the screenshots for end-of-run review instead.

## 5. Storage & reproducibility

- Bundle: `.u-maker/.state/figma-ds-bundles/{runId}.json`
- Result: `.u-maker/.state/figma-ds-bundles/{runId}.result.json`
- Rerun: `/u-tools-figma-ds --rerun {runId}` re-issues the same bundle with `overwriteExistingComponents: true`.

## 6. Versioning

Same scheme as `u-tools-figma-screen`'s bundle: optional `_bundleVersion` field, default v1. v1.1 will require it.

## 7. What this skill does NOT delegate

- **Token extraction** (Step 1) — pure source-code parsing, no Figma calls.
- **Component extraction** (Step 2) — same.
- **Doc layer sync** (Step 4) — happens in u-maker after the plugin returns.
- **Visual report HTML** (Step 5) — generated locally from screenshots.

## 8. Compatibility table

| u-tools-figma-ds version | figma plugin version | Bundle version |
|--------------------------|----------------------|----------------|
| 1.0.0 | ≥ 2.1.7 | v1 (implicit) |
| 1.1.0 (planned) | ≥ 2.2.0 | v1.1 (explicit) |

The wrapper checks the plugin's `figma:figma-generate-library` skill description for a version marker on Step 0; mismatches produce a soft warning.
