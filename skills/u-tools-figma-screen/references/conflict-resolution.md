# Conflict Resolution — u-tools-figma-screen

How the skill reconciles disagreements between the resolved screen-plan source and the design-system source (and between Figma vs md within either input).

## 1. Conflict categories

| Category | Example | Detection |
|----------|---------|-----------|
| **Identity mismatch** | Same screen name, different SC ID across sources | Compare slugs `(app, kebab(name))` after ID stripping |
| **Component drift** | screens cite `Card.Compact`, DS only has `Card` | Set difference of `screensInput.components[].key` vs `dsInput.components[].key` |
| **Prop drift** | Component prop list differs between screens-side spec and DS-side spec | Set difference of `props[].name` per component |
| **Variant drift** | Variant `size: lg` requested by screens, missing in DS | Membership check on `dsInput.components[].variants[].values[]` |
| **Token drift** | Screen uses raw hex / px instead of token reference | Regex on resolved fills/strokes/spacing |
| **Validation drift** | `screensInput.validations[]` references a rule not codified in DS or SRS | Cross-reference into `srs.json` `validationRules[]` |
| **Flow drift** | Figma prototype has a transition not in `screens.json` `transitions[]` | Set difference of `transitions[].source-target` pairs |

## 2. Resolution strategies

### 2a. Auto mode (`--auto`)

Resolution is purely mechanical:

1. Apply `--prefer` (default `figma`) per-input.
2. For **coverage gaps** (DS missing component / variant), fall back to the screens-side spec but mark `coverageGaps[].action = "ds-missing-stub"` and create a `todos.json` entry (priority p2).
3. For **token drift**, replace raw values with the closest DS token (Euclidean distance for colors in OKLCH, nearest-step for spacing).
4. For **flow drift**, the union wins (additive); never delete a transition silently.
5. Log every resolution to `.u-maker/.state/figma-screen-conflicts.json`.

### 2b. Interactive mode (default)

When `conflicts[]` count is > 0:

1. If count ≤ 5 → present each conflict via `AskUserQuestion`:
   ```
   Conflict: SC-020 component list differs.
     Figma:  [Header, Stat, Stat, Chart, Footer]
     md:     [Header, Stat, Stat, Footer]
     Choose:
       1. Keep Figma  (5 components)
       2. Keep md     (4 components)
       3. Keep Figma but skip new component "Chart"
       4. Abort run
   ```
2. If count > 5 → present an aggregate prompt with up to 3 representative conflicts and ask for a global policy:
   ```
   {N} conflicts detected. Apply globally:
     1. Keep Figma everywhere
     2. Keep md everywhere
     3. Run interactively per-conflict (will take time)
     4. Abort
   ```
3. If count > 20 → force option 3 (per-conflict review). Mass-applying a global choice over many conflicts is dangerous and almost always wrong.

### 2c. Hybrid (`--prefer figma --auto-resolve token,prop`)

Reserved for v1.1 — users can list which categories use the auto strategy and which require interactive review. Not implemented in v1.

## 3. Conflict log format

```json
// .u-maker/.state/figma-screen-conflicts.json
{
  "runId": "20260419-152312-ab3f",
  "app": "myapp",
  "totalConflicts": 7,
  "totalGaps": 2,
  "resolutions": [
    {
      "screen": "SC-020",
      "category": "component-drift",
      "figma": ["Header", "Stat", "Stat", "Chart", "Footer"],
      "md": ["Header", "Stat", "Stat", "Footer"],
      "decision": "keep-figma",
      "reason": "--prefer figma (auto)"
    },
    {
      "screen": "SC-040",
      "category": "ds-missing-stub",
      "component": "Card.Compact",
      "decision": "stub-with-Card",
      "reason": "DS coverage gap; placeholder created",
      "todoId": "TD-2026-04-19-014"
    }
  ]
}
```

## 4. Idempotency

Re-running the skill with identical inputs MUST yield identical outputs (same SC IDs, same component bindings, same Figma node ordering). Conflict resolution decisions are persisted in `.u-maker/.state/figma-screen-conflicts.json` so a re-run with `--auto` re-applies the prior decision instead of re-prompting.

To force re-prompting after a manual edit, delete the corresponding entry from the conflict log (or pass `--force`).

## 5. Hard failures (abort regardless of mode)

The skill aborts and writes nothing when:

- A screen references an SRS `FR-ID` that does not exist
- DS coverage gap count > 50% of total components (the DS is too divergent to bind reliably — re-run `/u-tools-figma-ds` first)
- Figma source resolves to a file with no edit permission AND `--output` includes `figma`
- Conflict log has been hand-edited to introduce a circular dependency (component A bindings reference component B, which references A)

In each case the skill prints the reason, suggests the corrective action, and exits with non-zero status so callers (`/u-plan`, `/u-design`) can react.
