---
name: u-init
description: "Alias of /u-prepare. Use when the user asks to '/u-init', 'u-maker init', 'u-maker initialize project', 'u-maker 초기화', or 'u-maker 프로젝트 시작'. Routes directly to /u-prepare (Preparation umbrella)."
version: 4.0.0
---

# u-init — Alias for /u-prepare

`/u-init [--app {name}] [--loop] [--scenario {A|B1|B2}] [--migrate]`

**This skill is a thin alias of `/u-prepare`.** It exists for backward compatibility with v3.x users and for discoverability (many users reach for `/u-init` when starting). All arguments are forwarded unchanged.

**PBGD Phase:** Plan.Prepare (umbrella, via alias)
**Target skill:** `/u-prepare`

## Behavior

When invoked:

1. Print a one-line alias notice: `"/u-init is an alias of /u-prepare. Forwarding…"`
2. Invoke `/u-prepare` with the same arguments.
3. Return `/u-prepare`'s result unchanged.

## Why an alias

- v3.x users and external docs reference `/u-init` extensively; breaking the command would cause churn.
- `/u-init` remains the most discoverable entry point for new users.
- The v3.x "initialize project folder" semantics have moved to the granular `/u-prepare-foldertree`; users who want only that step should invoke it directly.

## Migration cheatsheet

| v3.x invocation | v4.0 equivalent |
|-----------------|-----------------|
| `/u-init my-app` | `/u-prepare my-app` (full umbrella — recommended) |
| `/u-init my-app` (foldertree only) | `/u-prepare-foldertree my-app` |
| `/u-init --migrate` | `/u-prepare --migrate` (forwarded to foldertree) |

## See also

- `/u-prepare` — Preparation umbrella (the canonical command).
- `/u-prepare-foldertree` — Granular foldertree/state scaffolding only.
- `/u-analyze` — Dropzone → digest analysis.
- `/u-reverse` — Reverse-engineer existing code.
