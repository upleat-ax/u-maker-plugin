# backend-detection — Browser Backend & Port Resolution

Detailed protocol for selecting a browser-automation backend and resolving the dev-server port for `u-tools-browser`. Load this when implementing or debugging Steps 0/3 of the main workflow.

## Tool Detection (Step 0)

Before Step 1 of the main workflow, verify that a browser backend is reachable. Check in this order:

1. Check the shell for `agent-browser`:
   ```bash
   command -v agent-browser >/dev/null 2>&1 && echo "Installed" || echo "NOT INSTALLED"
   ```
   If installed → use **agent-browser CLI** (primary).
2. Else if `mcp__plugin_playwright_playwright__browser_navigate` is listed in the available tools → proceed with **Playwright MCP** (fallback).
3. Else if `mcp__plugin_chrome-devtools-mcp_chrome-devtools__navigate_page` is available → proceed with **chrome-devtools MCP** (last resort).
4. Else → inform user:
   > "No browser automation backend available. Install the `agent-browser` CLI, or enable the `plugin_playwright` plugin as a fallback."
   Then HALT.

## Port Detection (Step 3)

Priority (u-maker-specific):

1. **Explicit argument** — caller passed `--port {N}` → use it.
2. **`.u-maker/data/ports.json`** — if exists, look up `{app}` → port.
3. **`apps/{app}/package.json`** — `dev` script `--port` flag.
4. **`.env`, `.env.local`, `.env.development`** inside `apps/{app}/` — `PORT=` line.
5. **`AGENTS.md` / `CLAUDE.md`** — regex `(port\s*[:=]\s*|localhost:)(\d{4,5})`.
6. **Default per app:**
   - `web` → 3000
   - `admin` → 3001
   - `backend` → 2920
   - `storybook` → 6006
   - Unknown → 3000

```bash
# Reference snippet
PORT="${EXPLICIT_PORT:-}"
[ -z "$PORT" ] && [ -f ".u-maker/data/ports.json" ] && PORT=$(jq -r ".apps.${APP} // empty" .u-maker/data/ports.json)
[ -z "$PORT" ] && PORT=$(grep -Eo '\-\-port[= ]+[0-9]{4,5}' apps/${APP}/package.json 2>/dev/null | grep -Eo '[0-9]{4,5}' | head -1)
[ -z "$PORT" ] && PORT=$(grep -h '^PORT=' apps/${APP}/.env* 2>/dev/null | tail -1 | cut -d= -f2)
PORT="${PORT:-3000}"
echo "Using dev server port: $PORT"
```
