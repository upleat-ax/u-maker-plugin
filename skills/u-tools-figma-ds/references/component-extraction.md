# Component Extraction — u-tools-figma-ds

How `/u-tools-figma-ds` reads UI components from source code and prepares them for `figma:figma-generate-library`.

## 1. Supported source patterns

### 1a. Function components with TypeScript types

```tsx
type ButtonProps = {
  label: string;
  onClick?: () => void;
  variant?: "primary" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  icon?: ReactNode;
};

export function Button({ label, variant = "primary", size = "md", disabled, icon }: ButtonProps) { /* ... */ }
```

Extraction:
- Component name from the export.
- Props from the type:

  | TS shape | Figma prop type | Notes |
  |----------|-----------------|-------|
  | `string` | `TEXT` | Default rendered as the placeholder string |
  | `boolean` | `BOOLEAN` | |
  | `ReactNode` / `JSX.Element` | `INSTANCE_SWAP` | Default to a placeholder icon component |
  | Union of string literals | Variant axis | Each literal becomes a variant value |
  | Function (`onClick`) | Skipped | Behaviour, not visual |
  | Object / array | Skipped | Too complex for v1 |

### 1b. `cva()` (class-variance-authority)

```ts
const button = cva("base-classes", {
  variants: {
    variant: { primary: "...", secondary: "...", ghost: "..." },
    size: { sm: "...", md: "...", lg: "..." }
  },
  defaultVariants: { variant: "primary", size: "md" }
});
```

Extraction:
- Each `variants` key becomes a Figma variant axis.
- `defaultVariants` populates the default variant.
- Class strings are resolved to tokens (Step 2.3 of token-extraction.md) and become Figma fill / stroke / radius bindings.

### 1c. `tv()` (tailwind-variants) and `tailwind-styled-component`

Same shape as `cva`, treated identically.

### 1d. Discriminated-union props

```tsx
type AlertProps = { kind: "info"; message: string }
                | { kind: "warning"; message: string; action: () => void }
                | { kind: "error"; message: string; details?: string };
```

Extraction:
- The discriminator key (`kind`) becomes a variant axis.
- Per-variant property differences are encoded as conditional sub-parts (booleans on the parent for `action`, `details`).

### 1e. Compound components

When multiple components are exported from the same file under a parent namespace:

```tsx
export const Tabs = ({ children }: { children: ReactNode }) => /* ... */;
Tabs.List = TabsList;
Tabs.Trigger = TabsTrigger;
Tabs.Content = TabsContent;
```

OR

```tsx
export { Tabs, TabsList, TabsTrigger, TabsContent };
```

Extraction:
- Group into a single Figma component-set whose variants encode the sub-part.
- Sub-parts that are not visually distinct (e.g., context providers) are skipped — detected by absence of any JSX rendering elements.
- Compound components are MANDATORY per `design-system-rules.md` §0#15 — flag in summary if any multi-part widget was emitted as separate Figma components rather than a compound set.

## 2. Source files to walk

In order:

1. Tier-3 paths (`packages/ui-*/src/components/**/*.tsx`).
2. Tier-5 paths (`apps/*/src/components/ui/**/*.tsx`) — typical shadcn / next-forge layout.
3. Any path passed to `--source` directly.

Files to **skip**:

- `*.stories.tsx` (Storybook stories are documentation, not source)
- `*.test.tsx` / `*.spec.tsx`
- `*.d.ts` (declaration files)
- Files with no default or named React component export

## 3. Token resolution

After extracting raw class strings or inline styles, resolve them back to tokens:

| Source | Resolution |
|--------|-----------|
| Tailwind class (e.g., `bg-primary-500`) | Look up in normalised tokens (Step 1 of token-extraction); bind variant to `color.primary.500` semantic token |
| CSS custom property reference (`var(--color-bg)`) | Direct lookup by name |
| Hex / rgb literal in inline style | Find closest token by Euclidean distance (OKLCH for colors); if > threshold, log to `unresolvedBindings[]` |
| Px literal for spacing / radius | Find nearest scale step; if > 1 step away, log to `unresolvedBindings[]` |

Threshold defaults:
- Color: ΔE > 5 in OKLCH
- Dimension: > 1 scale step

## 4. Component dependency ordering

Build order (atoms → molecules → organisms) is required by `figma-generate-library` Phase 3.

Heuristic:
- Build a directed graph: edge `A → B` if `A` imports `B` from the same `packages/ui-*`.
- Topological sort. Components with zero outgoing edges are atoms; iterate in topo order.
- Tie-break by name length (shorter = more atomic).

If the graph has a cycle (rare), break the cycle at the lowest-degree edge and warn the user.

## 5. Output shape

```ts
type ExtractedComponent = {
  key: string;                // logical id, e.g., "ui-buttons.button"
  name: string;               // human-readable, e.g., "Button"
  filePath: string;           // source file (relative to repo root)
  isCompound: boolean;
  subParts?: Array<{ name: string; key: string }>;  // when isCompound
  props: Array<{
    name: string;
    type: "TEXT" | "BOOLEAN" | "INSTANCE_SWAP";
    default?: unknown;
    description?: string;     // from JSDoc / TSDoc when present
  }>;
  variants: Array<{
    axis: string;             // e.g., "variant", "size"
    values: string[];
    default?: string;
  }>;
  bindings: Array<{
    target: "fill" | "stroke" | "radius" | "padding" | "gap" | "fontSize" | "lineHeight" | "shadow";
    tokenPath: string;        // e.g., "color.bg.primary" or "space.4"
    appliesWhen?: Record<string, string>;  // variant constraints, e.g., { variant: "primary" }
  }>;
  unresolvedBindings: Array<{
    target: string;
    rawValue: string;
    reason: string;
    suggestion?: string;      // closest token
  }>;
};
```

The full ordered list is persisted to `.u-maker/.state/figma-ds-components.{runId}.json` before delegation.

## 6. Skip / opt-out

A component file can opt out of extraction by adding a JSDoc tag at the top:

```tsx
/** @ds-skip Reason for skipping */
```

Common reasons: layout primitives that are pure flex wrappers, framework-specific composition helpers, internal-only utilities.

## 7. Naming convention enforcement

Components emitted to Figma follow `design-system-rules.md` §0#10 naming:

- PascalCase component names.
- Variants: `axis-name=value` lowercase (e.g., `variant=primary, size=md`).
- Compound sub-parts: `Parent / Sub` (slash-separated, capitalised).

Source-code names that violate (e.g., `my_button`) are converted with a warning.
