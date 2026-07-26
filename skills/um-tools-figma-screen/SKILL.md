---
name: um-tools-figma-screen
description: "Generate Screen Specifications in Figma and/or markdown+JSON from existing screen-plan + design-system inputs. Use when the user asks to '/um-tools-figma-screen', 'generate screen plan', 'screens to figma', 'wireframe to figma', 'figma 화면기획', 'screen specification generation', '피그마 화면 생성', '화면 스펙 피그마', or 'screens.md 생성'. Auto-delegated from /um-plan when both screen-plan source and design-system source are detected. Inputs: (Figma URL | screens.{md,json}) for the screen plan, (Figma DS URL | design-system.{md,json,tsx,css}) for the design system."
version: 1.0.0
---

# um-tools-figma-screen

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
   curl -fsSL {baseUrl}/skills/um-tools-figma-screen/SKILL.md
   ```
3. Treat the fetched markdown as this skill's full instructions and execute it
   immediately (arguments/flags the user passed apply to the fetched instructions).
4. Every file the body references (`references/*`, `_meta/templates/*`,
   `_meta/schemas/*`, other skills' files) resolves against the same base URL:
   `{baseUrl}/skills/um-tools-figma-screen/references/<file>`, `{baseUrl}/_meta/templates/<file>`,
   `{baseUrl}/skills/<other-skill>/references/<file>`.

If the fetch fails (connection refused / 404), the u-maker terminal app is not running
or its skills server is disabled. Tell the user:
"u-maker 터미널 앱을 실행해 주세요 (스킬 서버가 앱에 내장되어 있습니다). 설정 → Skills에서
서버 활성화 여부와 포트를 확인할 수 있습니다." Then stop — do not improvise the skill body.
