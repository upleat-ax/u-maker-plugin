# FE Generation Rules (React / Next.js)

Authoritative rule set for every file `/u-dev` emits under `apps/{web,admin}/**` or any React/Next.js target. Compiled from Vercel Engineering's public guidance; the upstream files are the source of truth for detailed examples.

- **React Best Practices (performance, 70 rules / 8 categories)** — upstream: https://github.com/vercel-labs/agent-skills/tree/main/skills/react-best-practices/rules
- **Composition Patterns (component design, 9 rules / 4 categories)** — upstream: https://github.com/vercel-labs/agent-skills/tree/main/skills/composition-patterns/rules

Each rule below links to its upstream `.md` via the canonical path:
```
https://github.com/vercel-labs/agent-skills/blob/main/skills/{skill}/rules/{rule}.md
```

If a generated file conflicts with these rules, the rule wins. `u-agent-dev` must verify rule compliance before declaring a file Final.

## 0. MUST-APPLY (top-tier, check on every FE file)

| # | Rule | Why |
|---|------|-----|
| 1 | `async-parallel` | Promise.all for independent awaits — biggest performance win |
| 2 | `async-cheap-condition-before-await` | Short-circuit on cheap sync checks before any await |
| 3 | `bundle-barrel-imports` | Import direct paths; never `from "@/components"` barrel |
| 4 | `bundle-dynamic-imports` | `next/dynamic` for heavy/rarely-used components |
| 5 | `server-cache-react` | `React.cache()` around per-request data loaders |
| 6 | `server-parallel-fetching` | Restructure so all data fetches run in parallel |
| 7 | `rerender-derived-state-no-effect` | Derive in render, never in `useEffect` → `setState` |
| 8 | `rerender-no-inline-components` | Declare components at module scope, not inside another component |
| 9 | `rendering-conditional-render` | `cond ? <A/> : null` — never `cond && <A/>` (avoids `0`/empty render) |
| 10 | `architecture-avoid-boolean-props` | Compose variants, don't add `isPrimary`/`isLarge` booleans |
| 11 | `architecture-compound-components` | `<Tabs>`, `<Tabs.List>`, `<Tabs.Panel>` for multi-part widgets |
| 12 | `state-lift-state` | Siblings share state via a common Provider, never via props drilling or duplicated `useState` |
| 13 | `react19-no-forwardref` | React 19+ only — drop `forwardRef`; use `ref` as a normal prop and `use()` over `useContext()` |
| 14 | `client-swr-dedup` | SWR (or TanStack Query with `queryKey` hashing) for dedup + revalidation |
| 15 | `server-serialization` | Strip server-only fields before passing data to Client Components |
| 16 | `style-no-single-side-accent-border` | 한쪽 border만 강조하는 장식/active 스타일 금지 — 카드·콜아웃 좌측 액센트 바, nav/tab active 컬러 바, 컬러 heading 밑줄 모두 금지. 전체 border + 배경 틴트 + `font-weight`로 강조. 1px 중립 divider·focus ring·차트 마커만 단면 허용 (html-engine.md §6) |

---

## A. React Best Practices

Priority buckets follow upstream `_sections.md`. Prefix matches rule filenames.

### A1. Eliminating Waterfalls — CRITICAL (`async-*`)

| Rule | One-liner |
|------|-----------|
| `async-cheap-condition-before-await` | Test cheap sync conditions before any `await` |
| `async-defer-await` | Move `await` into the branch that actually consumes it |
| `async-parallel` | `Promise.all([...])` for independent ops |
| `async-dependencies` | Use `better-all` pattern for partial dependencies |
| `async-api-routes` | Kick off promises early, await at response-write time |
| `async-suspense-boundaries` | Wrap streamable UI in `<Suspense>` to unblock shell |

### A2. Bundle Size — CRITICAL (`bundle-*`)

| Rule | One-liner |
|------|-----------|
| `bundle-barrel-imports` | Import the exact path, not a barrel file |
| `bundle-analyzable-paths` | Keep import paths statically analyzable (no dynamic concat) |
| `bundle-dynamic-imports` | `next/dynamic` for heavy client-only modules |
| `bundle-defer-third-party` | Load analytics/logging/experiments after hydration |
| `bundle-conditional` | `import()` only when the feature is active |
| `bundle-preload` | Preload on hover/focus/viewport-enter for perceived speed |

### A3. Server-Side Performance — HIGH (`server-*`)

| Rule | One-liner |
|------|-----------|
| `server-auth-actions` | Authenticate Server Actions like API routes |
| `server-cache-react` | `React.cache()` for per-request memoization |
| `server-cache-lru` | LRU (`@vercel/functions` or `lru-cache`) for cross-request caching |
| `server-dedup-props` | Don't double-serialize the same object into RSC props |
| `server-hoist-static-io` | Hoist static I/O (fonts, logos, config) to module scope |
| `server-no-shared-module-state` | No mutable module-level state tied to a single request |
| `server-serialization` | Minimize payload from Server → Client Components |
| `server-parallel-fetching` | Refactor component tree so fetches run concurrently |
| `server-parallel-nested-fetching` | `Promise.all(items.map(fetchOne))` for per-item chains |
| `server-after-nonblocking` | `after()` for logging / revalidation that must not block the response |

### A4. Client-Side Data Fetching — MEDIUM-HIGH (`client-*`)

| Rule | One-liner |
|------|-----------|
| `client-swr-dedup` | SWR for dedup + revalidation; or TanStack Query with stable `queryKey` |
| `client-event-listeners` | Dedupe global listeners; one handler per event family |
| `client-passive-event-listeners` | `{ passive: true }` on scroll/touch listeners |
| `client-localstorage-schema` | Version the schema, minimize stored bytes |

### A5. Re-render Optimization — MEDIUM (`rerender-*`)

| Rule | One-liner |
|------|-----------|
| `rerender-defer-reads` | Don't subscribe to state only read in callbacks — use `useRef` or `useLatest` |
| `rerender-memo` | Wrap expensive subtrees in `React.memo` |
| `rerender-memo-with-default-value` | Hoist default non-primitive props to module scope |
| `rerender-dependencies` | Prefer primitive deps in `useMemo`/`useEffect` |
| `rerender-derived-state` | Subscribe to the derived boolean, not the raw value |
| `rerender-derived-state-no-effect` | Derive state inline during render, never via `useEffect → setState` |
| `rerender-functional-setstate` | `setState(prev => …)` for stable callbacks |
| `rerender-lazy-state-init` | `useState(() => heavy())` for expensive initial values |
| `rerender-simple-expression-in-memo` | Don't `useMemo` a primitive expression |
| `rerender-split-combined-hooks` | Split a hook whose deps are independent |
| `rerender-move-effect-to-event` | Move interaction logic from `useEffect` to the handler |
| `rerender-transitions` | `startTransition` around non-urgent updates |
| `rerender-use-deferred-value` | `useDeferredValue` to keep inputs responsive |
| `rerender-use-ref-transient-values` | `useRef` for values that change frequently and don't render |
| `rerender-no-inline-components` | Declare components at module scope only |

### A6. Rendering Performance — MEDIUM (`rendering-*`)

| Rule | One-liner |
|------|-----------|
| `rendering-animate-svg-wrapper` | Animate a `div` wrapper, not the `<svg>` itself |
| `rendering-content-visibility` | `content-visibility: auto` for long off-screen lists |
| `rendering-hoist-jsx` | Hoist static JSX outside the component body |
| `rendering-svg-precision` | Round SVG coordinates to 2 decimals max |
| `rendering-hydration-no-flicker` | Inline `<script>` for client-only preferences to avoid flicker |
| `rendering-hydration-suppress-warning` | `suppressHydrationWarning` only for expected mismatches |
| `rendering-activity` | `<Activity>` for show/hide that preserves state |
| `rendering-conditional-render` | Ternary for conditional render — never `&&` on numeric/possibly-falsy values |
| `rendering-usetransition-loading` | `useTransition` over isolated `isLoading` state |
| `rendering-resource-hints` | `ReactDOM.preload`/`preinit` for critical assets |
| `rendering-script-defer-async` | `defer` or `async` on `<script>` tags |

### A7. JavaScript Performance — LOW-MEDIUM (`js-*`)

Apply in hot paths, skip for one-shot code.

| Rule | One-liner |
|------|-----------|
| `js-batch-dom-css` | Batch DOM/CSS writes via class swap or `cssText` |
| `js-cache-function-results` | Memoize pure-function results in a module-level `Map` |
| `js-cache-property-access` | Cache `obj.a.b.c` inside loops |
| `js-cache-storage` | Cache `localStorage`/`sessionStorage` reads |
| `js-combine-iterations` | One pass — merge filter+map+reduce chains |
| `js-early-exit` | Return early from guard branches |
| `js-flatmap-filter` | `flatMap` to map + filter in a single pass |
| `js-hoist-regexp` | Hoist `RegExp` outside loops |
| `js-index-maps` | Build a `Map` for repeated lookups |
| `js-length-check-first` | `arr.length === 0` before expensive equality |
| `js-min-max-loop` | Loop for min/max instead of `.sort()[0]` |
| `js-request-idle-callback` | `requestIdleCallback` for non-critical work |
| `js-set-map-lookups` | `Set`/`Map` for O(1) lookups |
| `js-tosorted-immutable` | `toSorted()` / `toReversed()` / `toSpliced()` for immutability |

### A8. Advanced Patterns — LOW (`advanced-*`)

Use only when needed, with care.

| Rule | One-liner |
|------|-----------|
| `advanced-effect-event-deps` | Don't put `useEffectEvent` output in `useEffect` deps |
| `advanced-event-handler-refs` | Store frequently-reassigned handlers in a ref |
| `advanced-init-once` | Module-level init runs once per app load |
| `advanced-use-latest` | `useLatest` for stable ref to the newest closure value |

---

## B. Composition Patterns

Applies to every shared/reusable component under `packages/ui-*/` and `apps/*/src/components/`.

### B1. Component Architecture — HIGH (`architecture-*`)

| Rule | One-liner |
|------|-----------|
| `architecture-avoid-boolean-props` | Don't accumulate `isPrimary`/`isLarge`/`isDisabled` — compose |
| `architecture-compound-components` | Use `<Parent>` + `<Parent.Child>` with shared Context for multi-part widgets |

### B2. State Management — MEDIUM (`state-*`)

| Rule | One-liner |
|------|-----------|
| `state-decouple-implementation` | Provider is the only place that knows how state is stored |
| `state-context-interface` | Provider exposes `{ state, actions, meta }` — consumers never branch on impl |
| `state-lift-state` | Sibling components share state via a Provider, not prop-drilling |

### B3. Implementation Patterns — MEDIUM (`patterns-*`)

| Rule | One-liner |
|------|-----------|
| `patterns-explicit-variants` | Ship `<ButtonPrimary>`/`<ButtonGhost>` — not `<Button variant="primary">` booleans |
| `patterns-children-over-render-props` | Use `children` for composition over `renderX` callbacks |

### B4. React 19 APIs — MEDIUM (`react19-*`)

> Apply **only** when the project targets React ≥ 19. For React 18 or earlier, skip this section.

| Rule | One-liner |
|------|-----------|
| `react19-no-forwardref` | No `forwardRef`; declare `ref` as a regular prop; use `use()` over `useContext()` |

---

## Integration with `/u-dev` FE generation

1. **Before writing any component file**, load this reference (`fe-rules.md`) into the generator context.
2. For every generated file, run a mental checklist against `§0 MUST-APPLY` (16 rules).
3. For hot-path code (lists, scroll handlers, forms with many inputs, data tables), also scan `§A5 / §A6 / §A7`.
4. For shared components under `packages/ui-*/`, additionally enforce `§B1–B3` (and `§B4` if React 19+).
5. On `u-agent-dev` self-review: if a generated file breaks a MUST-APPLY rule, regenerate before marking Final.
6. On `/u-gatekeeping` FE review: the gatekeeper uses this file as its rubric for FE-specific scoring.

## Version pinning

Upstream rules may evolve. This reference was compiled from:
- `vercel-labs/agent-skills` @ main (70-rule `react-best-practices` + 9-rule `composition-patterns`)
- Last sync: 2026-04-19

On major upstream change, re-sync and bump `u-dev` `version` in `SKILL.md`.
