---
name: u-qa
description: "Alias of /u-gatekeeping --only qa. Use when the user asks to '/u-qa', 'u-maker QA', 'u-qa runtime QA', 'u-maker QA 실행', or 'u-maker 런타임 테스트'. Routes directly to /u-gatekeeping scoped to the runtime-QA sub-phase."
version: 4.0.0
---

# u-qa — Alias for /u-gatekeeping --only qa

`/u-qa [--auto] [--loop] [--app {name}]`

**This skill is a thin alias of `/u-gatekeeping --only qa`.** It runs the Runtime QA sub-phase only (testcase design, execution, results) and skips the 11-criteria doc scoring. For backward compatibility with v3.x users who used `/u-qa` as a shortcut.

**PBGD Phase:** Gatekeeping.RuntimeQA (via alias)
**Target skill:** `/u-gatekeeping --only qa`

## Behavior

1. Print a one-line alias notice: `"/u-qa is an alias of /u-gatekeeping --only qa. Forwarding…"`
2. Invoke `/u-gatekeeping --only qa` with the remaining arguments.
3. Return its result unchanged.

## See also

- `/u-gatekeeping` — Full Gatekeeping phase (doc scoring + runtime QA).
- `/u-check` — Alias that covers the full Gatekeeping phase.
