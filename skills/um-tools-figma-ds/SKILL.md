---
name: um-tools-figma-ds
description: "Generate a Figma design system (Variables, styles, master components) from existing DS-applied source code (.tsx + .json + .css). Use when the user asks to '/um-tools-figma-ds', 'code to figma ds', 'design system to figma', 'figma 디자인시스템 생성', 'DS to Figma', 'tokens to Figma', '코드에서 피그마 DS', '디자인시스템 피그마 동기화', or '피그마 변수 생성'. Auto-delegated from /um-analyze when DS source code is detected, and from /um-design Step 4.5 for outbound sync. Delegates Figma writes to figma:figma-generate-library; never calls use_figma directly."
version: 1.0.0
---

# um-tools-figma-ds

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
   curl -fsSL {baseUrl}/skills/um-tools-figma-ds/SKILL.md
   ```
3. Treat the fetched markdown as this skill's full instructions and execute it
   immediately (arguments/flags the user passed apply to the fetched instructions).
4. Every file the body references (`references/*`, `_meta/templates/*`,
   `_meta/schemas/*`, other skills' files) resolves against the same base URL:
   `{baseUrl}/skills/um-tools-figma-ds/references/<file>`, `{baseUrl}/_meta/templates/<file>`,
   `{baseUrl}/skills/<other-skill>/references/<file>`.

If the fetch fails (connection refused / 404), the u-maker terminal app is not running
or its skills server is disabled. Tell the user:
"u-maker 터미널 앱을 실행해 주세요 (스킬 서버가 앱에 내장되어 있습니다). 설정 → Skills에서
서버 활성화 여부와 포트를 확인할 수 있습니다." Then stop — do not improvise the skill body.
