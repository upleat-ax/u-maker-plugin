# Token Extraction — u-tools-figma-ds

How `/u-tools-figma-ds` reads tokens from source code and normalises them into the W3C tokens spec shape consumed by `figma:figma-generate-library`.

## 1. Supported input formats

### 1a. W3C Design Tokens (preferred)

`.tokens.json` files matching the [W3C Design Tokens Community Group spec](https://design-tokens.github.io/community-group/format/). Identified by the presence of `$value` and `$type` keys.

```json
{
  "color": {
    "primary": {
      "500": { "$value": "oklch(0.62 0.18 250)", "$type": "color" }
    }
  }
}
```

Direct pass-through with no transformation other than nesting normalisation.

### 1b. Style Dictionary

`.tokens.json` files with the older Style Dictionary shape (no `$value`):

```json
{
  "color": { "primary": { "500": { "value": "#3b82f6" } } }
}
```

Migration:
- `value` → `$value`
- Inferred `$type` from category name (`color` → `color`, `space` → `dimension`, `font` → `typography`, etc.)
- Hex colors converted to OKLCH and stored alongside hex (`$extensions: { hex: "#3b82f6" }`)

### 1c. CSS custom properties

`.css` files containing custom properties on `:root` (or `[data-theme="..."]` for mode overrides):

```css
:root {
  --color-primary-500: #3b82f6;
  --space-4: 16px;
  --radius-md: 8px;
}

[data-theme="dark"] {
  --color-primary-500: #60a5fa;
}
```

Parse rules:
- Custom property names are tokenised by `-` (`--color-primary-500` → `color.primary.500`).
- Type inferred by **prefix lookup**:

  | Prefix | `$type` |
  |--------|---------|
  | `color` | `color` |
  | `space`, `gap`, `inset`, `padding`, `margin` | `dimension` |
  | `font-size`, `text` | `dimension` (with `fontSize` extension) |
  | `font-family` | `fontFamily` |
  | `font-weight` | `fontWeight` |
  | `line-height` | `number` |
  | `radius`, `rounded` | `dimension` |
  | `shadow` | `shadow` |
  | `motion`, `duration`, `ease` | `duration` / `cubicBezier` |
  | `bp`, `breakpoint` | `dimension` |
  | `z`, `z-index` | `number` |
  | (unmatched) | `string` (logged to `unresolvedTypes[]`) |

- `[data-theme="..."]` selectors become **modes** on the same variable:
  ```json
  { "color": { "primary": { "500": { "$value": { "light": "#3b82f6", "dark": "#60a5fa" }, "$type": "color" } } } }
  ```

### 1d. Tailwind config

`tailwind.config.{js,ts}` `theme.extend` blocks become primitive tokens. Custom Tailwind plugins exposing tokens are not auto-detected in v1; they must be exported to `.tokens.json` first.

### 1e. shadcn / next-forge layout

When `apps/{app}/src/styles/tokens.css` (or `globals.css`) is present alongside `tailwind.config.{js,ts}`, treat the CSS file as authoritative for runtime values and the Tailwind config as authoritative for naming. Conflicts are reported to the user.

## 2. Normalisation contract

The output of Step 1 is a single normalised tree:

```ts
type NormalisedTokens = {
  meta: {
    schema: "w3c-tokens@1";
    sources: Array<{ tier: number; path: string }>;
    extractedAt: string;        // ISO-8601
    runId: string;
  };
  collections: {
    primitive: TokenGroup;       // raw values
    semantic: TokenGroup;        // aliases into primitive, mode-aware
    component: TokenGroup;       // aliases into semantic, per-component
  };
  modes: Array<"light" | "dark" | string>;
  unresolvedTypes: Array<{ path: string; raw: string; reason: string }>;
};

type TokenGroup = {
  [category: string]: {
    [name: string]: {
      $value: string | number | { [mode: string]: string | number };
      $type: "color" | "dimension" | "number" | "string" | "shadow" | "duration" | "cubicBezier" | "fontFamily" | "fontWeight" | "typography";
      $description?: string;
      $extensions?: Record<string, unknown>;
    };
  };
};
```

## 3. Layer assignment

The 3-layer architecture from `design-system-rules.md` §1:

- **Primitive** — single mode, raw value. No alias. Examples: `color.blue.500`, `space.4`, `radius.md`.
- **Semantic** — aliased to primitive, mode-aware. Examples: `color.bg.surface`, `color.fg.muted`, `space.gutter`.
- **Component** — aliased to semantic. Examples: `button.bg.default`, `card.padding.x`.

Heuristics for assignment when source code doesn't make it explicit:

- Names with a numeric scale step (`primary.500`, `space.4`) → primitive.
- Names with semantic intent (`bg.surface`, `text.muted`, `border.subtle`) → semantic.
- Names prefixed by a component (`button.*`, `card.*`, `input.*`) → component.

When the heuristic is ambiguous, the token defaults to primitive and a warning is logged.

## 4. Mode handling

- `light` is always present (treated as the default mode for primitives).
- `dark` is added when source code shows any `[data-theme="dark"]` block, `.dark` Tailwind class overrides, or W3C tokens with a `dark` mode key.
- Custom modes (`high-contrast`, `brand-x`) are passed through verbatim and shown to the user in the summary table.

Primitives stay single-mode. Mode overrides ONLY apply to semantic and component tokens — enforced by the rule pack §3.

## 5. 10-scale validation

Before emitting the bundle, validate that all 10 scales required by `design-system-rules.md` §2 are present:

| Scale | Minimum members |
|-------|-----------------|
| color (OKLCH 50–950) | 7 step values per ramp |
| spacing | 8 steps (0, 1, 2, 3, 4, 6, 8, 12 minimum) |
| type (font sizes) | 6 sizes (xs, sm, base, lg, xl, 2xl minimum) |
| shadow | 4 levels (sm, md, lg, xl) |
| radius | 4 levels (sm, md, lg, full) |
| breakpoint | 4 (sm, md, lg, xl) |
| motion (duration) | 3 (fast, base, slow) |
| z-index | 5 (base, dropdown, modal, toast, max) |
| responsive type | clamp() values present for at least 3 sizes |
| line-height | 3 (tight, base, loose) |

Missing scales are listed in the run summary; the user is asked whether to (a) abort, (b) auto-fill from defaults, (c) continue with the partial set. Default = (b).
