---
name: u-check
description: "Alias of /u-gatekeeping. Use when the user asks to 'check', '/u-check'. Routes directly to /u-gatekeeping (PBGD Gatekeeping phase: doc scoring + runtime QA)."
version: 4.0.0
triggers:
  - "/u-check"
  - "check phase"
---

# u-check — Alias for /u-gatekeeping

`/u-check [--auto] [--loop] [--app {name}] [--only doc|qa]`

**This skill is a thin alias of `/u-gatekeeping`.** It exists for backward compatibility with v3.x users. All arguments are forwarded unchanged.

**PBGD Phase:** Gatekeeping (via alias)
**Target skill:** `/u-gatekeeping`

## Behavior

1. Print a one-line alias notice: `"/u-check is an alias of /u-gatekeeping. Forwarding…"`
2. Invoke `/u-gatekeeping` with the same arguments.
3. Return `/u-gatekeeping`'s result unchanged.

## Migration cheatsheet

| v3.x invocation | v4.0 equivalent |
|-----------------|-----------------|
| `/u-check` | `/u-gatekeeping` |
| `/u-check --loop` | `/u-gatekeeping --loop` |

## See also

- `/u-gatekeeping` — The canonical command (doc scoring + runtime QA).
- `/u-qa` — Alias that scopes to runtime QA.
