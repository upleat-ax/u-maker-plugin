---
name: u-ssot
description: "Alias of /u-doc. Use when the user asks to '/u-ssot', 'u-ssot', 'SSoT 정리', 'SSoT에 추가', 'ssot ingest', or 'ssot reorganize'. Routes directly to /u-doc (SSoT ingest + document reorganization). All arguments are forwarded unchanged."
version: 4.0.0
---

# u-ssot — Alias for /u-doc

`/u-ssot [input…] [--app {name}] [--reorg] [--dry-run] [--force]`

**This skill is a thin alias of `/u-doc`.** It exists for discoverability — users who think in terms of "SSoT" reach for `/u-ssot`, while those thinking "document" reach for `/u-doc`. Both are the same skill. All arguments are forwarded unchanged.

**Target skill:** `/u-doc`

## Behavior

When invoked:

1. Print a one-line alias notice: `"/u-ssot is an alias of /u-doc. Forwarding…"`
2. Invoke `/u-doc` with the same arguments.
3. Return `/u-doc`'s result unchanged.

## What /u-doc does

- **Ingest** — 입력(파일/이미지/링크/텍스트)을 `data/dropzone/`에 정규화 + digest 생성 + 배치 제안(SSoT 문서는 직접 수정하지 않음).
- **Reorganize** — `.u-maker/docs`·`output`·`reports`를 표준 구조·네이밍에 맞게 재정리(docs는 `git mv`+`links.json`, output·reports는 재생성).

## See also

- `/u-doc` — the canonical command (full documentation in `skills/u-doc/SKILL.md`).
- `/u-analyze` — dropzone 배치 스캔 → digest.
- `/u-plan` · `/u-design` — 배치 제안을 실제 SSoT 문서로 반영.
