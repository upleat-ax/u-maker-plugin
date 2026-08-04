# /u-tools-figma Integration — Auto-Delegation

> How other PBGD skills detect and delegate to `/u-tools-figma`. Authoritative spec: `skills/u-plan/references/figma-analysis.md` PART II §12.

## Delegators

| Caller | Detection trigger | Delegation |
|--------|-------------------|------------|
| `/u-prepare` | Dropzone scan finds any `.figma-link`, `.figma-make-link`, or `figma.com` URL reference | Call `/u-tools-figma --app {app} [--loop]` before finishing Preparation |
| `/u-analyze` | About to process a file whose path ends `.figma-link` / `.figma-make-link` | Delegate that file's analysis to `/u-tools-figma`; skip in `/u-analyze`'s own loop |
| `/u-reverse` | User passed `--figma {url}` or project root contains `figma-link.json` | Call `/u-tools-figma --app {app} --url {url}` before code-reverse extraction so the digest is seeded |
| `/u-design` | User asked to "sync from Figma" or `data/figma/manifest.json` is older than any referenced Figma file | Call `/u-tools-figma --verify` first; if coverage stale, call `/u-tools-figma --refresh-comments` |

## Pass-through parameters

Every delegator must forward `--app` and `--loop` verbatim. Additional params:

- `--auto` → pass through so `/u-tools-figma` skips interactive confirmation.
- `--scenario` (from `/u-prepare`) → not passed (scenario is Preparation-internal).

## Non-delegation cases

`/u-tools-figma` must **not** be auto-delegated when:

- The user explicitly passed `--no-figma` to the calling skill.
- The Figma MCP server is unavailable and the environment is `--auto` — instead, log a blocker and halt the caller so the user can decide.

## Loop semantics under delegation

When the caller runs with `--loop`, the delegation chain looks like:

```
/u-prepare --loop
  └─ /u-tools-figma --loop            ← covers Figma digest coverage
  └─ /u-analyze                 ← covers non-Figma sources (if any)
  └─ 요구사항 협의
```

Each invoked skill runs its own gatekeeper loop. The outer `/u-prepare` loop re-enters only if its own quality check fails — not if an inner skill's loop exhausted retries (that's surfaced as a caller-level blocker).

## Manifest-first semantics

Before extracting, any delegator must check `data/figma/manifest.json`:

- If all referenced frames are `done` and unchanged → skip extraction; proceed.
- If any are `stale` or `pending` → delegate to `/u-tools-figma`.

This avoids redundant Figma MCP calls when a prior run already produced the needed digests.

## Error propagation

If `/u-tools-figma` returns an error status, the delegating skill:

1. Surfaces the error without masking it.
2. Does not proceed to its next step unless `--continue-on-figma-error` is set.
3. Writes the error into the caller's state file (`.state/{caller}-state.json`) so resumption can pick up where it stopped.
