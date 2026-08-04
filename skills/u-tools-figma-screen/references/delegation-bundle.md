# Delegation Bundle — u-tools-figma-screen → figma:figma-generate-design

The exact payload contract `/u-tools-figma-screen` hands off to the `figma:figma-generate-design` skill for Figma writes. Keeping this contract stable lets the figma plugin upgrade independently as long as it accepts this shape.

## 1. Why a bundle (not a free-form prompt)

The figma plugin's `figma-generate-design` skill is general-purpose; it discovers components by walking the file. That discovery is expensive (often 5–15 `use_figma` calls) and frequently mis-detects when an app has many sibling components. By passing a **pre-resolved DS hints object** plus a **structured section plan**, we:

1. Skip Tier 1+2 of the plugin's discovery (it can fall back if hints are stale).
2. Guarantee the same component / variant choices the doc layer made.
3. Make the run repeatable — the same bundle always produces the same Figma output.

## 2. Bundle shape

```ts
type DelegationBundle = {
  // Required — where to write
  targetFile: {
    fileKey: string;                  // e.g., "abc123def456"
    nodeId?: string;                  // e.g., "42:1138" for an existing parent frame
    pageName?: string;                // create or use an existing page
  };

  // Required — what to build
  sectionPlan: Array<{
    scId: string;                     // e.g., "SC-010"
    name: string;                     // human-readable screen name
    route?: string;                   // app route, used in annotations
    viewport: { width: number; height: number };  // default 1440x900
    components: Array<{
      key: string;                    // logical component id, matches dsHints.components[].key
      anchor?: { x: number; y: number };  // optional explicit placement
      props?: Record<string, unknown>;     // values for TEXT / BOOLEAN / INSTANCE_SWAP props
      variant?: Record<string, string>;    // e.g., { size: "lg", state: "default" }
    }>;
    states?: Array<{                  // captured as variants of the screen frame
      name: string;                   // "Default" | "Loading" | "Error" | …
      overrides?: Array<{ componentKey: string; props: Record<string, unknown> }>;
    }>;
    annotations?: {
      businessProcess?: string;       // multi-line markdown rendered into Description panel
      validations?: Array<{ field: string; rule: string; message: string }>;
      apis?: Array<{ apiId: string; method: string; path: string }>;
    };
  }>;

  // Optional but strongly recommended — pre-resolved DS map
  dsHints?: {
    fileKey?: string;                 // if DS is in a separate file
    tokens: {
      color: Record<string, string>;        // semantic name → hex / OKLCH
      spacing: Record<string, number>;      // semantic name → px
      type: Record<string, { family: string; size: number; weight: number; lineHeight: number }>;
      radius: Record<string, number>;
      shadow: Record<string, string>;        // CSS shadow string
      motion: Record<string, string>;        // duration + easing
      breakpoint: Record<string, number>;
      zIndex: Record<string, number>;
    };
    components: Array<{
      key: string;                    // matches sectionPlan.components[].key
      figmaKey?: string;              // canonical Figma component key, when known
      name: string;                   // human-readable
      props: Array<{ name: string; type: "TEXT" | "BOOLEAN" | "INSTANCE_SWAP"; default?: unknown }>;
      variants?: Array<{ axis: string; values: string[] }>;
    }>;
  };

  // Optional — flow / prototype data (used to wire reactions if present)
  flow?: Array<{
    sourceScId: string;
    targetScId: string;
    trigger: "click" | "hover" | "after-delay" | "submit";
    triggerNode?: string;             // logical node name on source screen
  }>;

  // Required — telemetry only
  skillNames: "u-tools-figma-screen";

  // Optional — operational
  options?: {
    overwriteExisting?: boolean;      // default false; when false, append next to existing frames
    writePage?: "create-new" | "use-existing" | "reuse-or-create";  // default "reuse-or-create"
    sectionGap?: number;              // px between screen frames; default 80
    runId: string;                    // mirrors `.u-maker/.state/figma-screen-run.json` runId
  };
};
```

## 3. What we expect back

```ts
type DelegationResult = {
  ok: boolean;
  pageId: string;
  pageName: string;
  generated: Array<{
    scId: string;
    figmaNodeId: string;              // e.g., "1138:42"
    figmaUrl: string;                 // deep link with file + node-id
    componentBindingsResolved: number;
    componentBindingsStubbed: number; // count where DS hint had no figmaKey, plugin fell back to discovery
    durationMs: number;
  }>;
  warnings: Array<{
    scId?: string;
    code: "ds-hint-stale" | "component-not-found" | "variant-not-found" | "image-fill-skipped" | string;
    message: string;
  }>;
  errors: Array<{
    scId?: string;
    message: string;
    recoverable: boolean;
  }>;
};
```

If `ok === false` and any error has `recoverable: true`, the wrapper retries that specific screen with `options.overwriteExisting = true` once. If still failing, the screen is added to `todos.json` (priority p1) and the run continues with the remaining screens.

## 4. Bundle lifecycle in storage

The exact bundle handed to the plugin is persisted under `.u-maker/.state/figma-screen-bundles/{runId}.json`. This makes the run reproducible — passing `--rerun {runId}` re-issues the same bundle. The result is persisted alongside as `{runId}.result.json`.

## 5. Bundle versioning

The bundle shape is versioned. When the plugin's expected shape changes:

1. Bump `_bundleVersion` (top-level field, optional in v1, required from v1.1).
2. Old bundles in `.u-maker/.state/figma-screen-bundles/` are migrated lazily on first re-use.
3. The plugin announces its accepted versions; if the accepted set excludes the wrapper's emit version, the wrapper writes the bundle as v1 and warns the user.

v1 (current): `_bundleVersion` omitted ⇒ implied v1.

## 6. What this skill does NOT delegate

- **Markdown / JSON emission** (Step 3a) — handled in-process, no plugin call.
- **Conflict resolution** — happens before the bundle is built; the plugin sees only the resolved, conflict-free section plan.
- **Visual verification** — delegated to `/u-tools-browser` after the figma plugin returns, not to the figma plugin itself.
- **DS generation** — that's `/u-tools-figma-ds`'s job.
