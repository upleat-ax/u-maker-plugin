---
name: um-doc
description: "This skill should be used when the user asks to '/um-doc', '/um-ssot', 'um-doc', 'um-ssot', wants to add/ingest input (a file, image, link, or text) into the SSoT docs ('SSoT에 추가', '문서에 추가', '이 자료 넣어줘', 'ingest this', 'add to docs'), or wants to tidy/reorganize the .u-maker document tree ('문서 정리', '문서 재정리', '폴더 정리', 'docs 정리', 'reorganize docs', 'tidy .u-maker'). Two modes: (1) Ingest — normalize an input into data/dropzone/, generate a digest, and suggest where it belongs (does NOT edit SSoT docs directly); (2) Reorganize — move/rename misplaced docs/ files (git mv + links.json) and regenerate output/ + reports/ to match the standard structure."
version: 4.0.0
---

# um-doc

The operational instructions for this skill are **not stored in this plugin**. They are
served by the u-maker terminal app's embedded skills server.

**Execute this skill as follows:**

1. Resolve the base URL. Read the FIRST of these discovery files that exists and
   use its `baseUrl` value:
   - `$XDG_CONFIG_HOME/u-maker/skills-server.json` (when `XDG_CONFIG_HOME` is set)
   - `~/.config/u-maker/skills-server.json` (Linux)
   - `~/Library/Application Support/u-maker/skills-server.json` (macOS)
   - `%APPDATA%\u-maker\skills-server.json` (Windows)
   If none exist, use `http://127.0.0.1:8765`.
2. Fetch the skill body:
   ```bash
   curl -fsSL {baseUrl}/skills/um-doc/SKILL.md
   ```
3. Treat the fetched markdown as this skill's full instructions and execute it
   immediately (arguments/flags the user passed apply to the fetched instructions).
4. Every file the body references (`references/*`, `_meta/templates/*`,
   `_meta/schemas/*`, other skills' files) resolves against the same base URL:
   `{baseUrl}/skills/um-doc/references/<file>`, `{baseUrl}/_meta/templates/<file>`,
   `{baseUrl}/skills/<other-skill>/references/<file>`.

If the fetch fails (connection refused / 404), the u-maker terminal app is not running
or its skills server is disabled. Tell the user:
"u-maker 터미널 앱을 실행해 주세요 (스킬 서버가 앱에 내장되어 있습니다). 설정 → Skills에서
서버 활성화 여부와 포트를 확인할 수 있습니다." Then stop — do not improvise the skill body.
