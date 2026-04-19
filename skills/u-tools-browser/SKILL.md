---
name: u-tools-browser
description: "This skill should be used when any u-maker command needs browser automation — E2E test execution (Playwright), screen capture for reports, dev-server verification, visual regression, or live-render inspection. All u-maker phase skills MUST route browser work through this engine instead of calling MCP browser tools directly."
version: 1.0.0
triggers:
  - "u-tools-browser"
  - "browser automation"
  - "e2e test"
  - "E2E"
  - "headless browser"
  - "screen capture"
  - "Playwright 캡처"
  - "브라우저 자동화"
---

# u-tools-browser — Unified Browser Automation Engine

Shared browser-automation engine for all u-maker phase skills. Provides a single entry point for E2E test execution, screen capture, dev-server verification, and visual-regression checks so that port detection, screenshot paths, and failure-handling stay consistent across `/u-gatekeeping`, `/u-report-weekly`, `/u-dev`, and `/u-wireframe`.

**Primary Agent:** u-agent-pm (dispatches), u-agent-qa / u-agent-dev / u-agent-report (consumers)
**Engine Dependencies:** (none — leaf engine)

## Use Browser Automation Only Through This Engine

All u-maker interactions with the browser MUST go through the protocol in this skill. Do **not** call the underlying MCP tools (`mcp__plugin_playwright_playwright__*`, `mcp__plugin_chrome-devtools-mcp_*`) directly from a phase skill. Centralising it here keeps:

- Port detection consistent across apps (web/admin/backend)
- Screenshots written under `.u-maker/.state/screenshots/{date}/…`
- Failure triage (fix / todo / skip) identical everywhere
- Headed vs headless mode asked once per session

If the platform offers multiple ways to control a browser, always pick **agent-browser CLI** first, **Playwright MCP** as fallback, **chrome-devtools MCP** only if both are unavailable.

## Prerequisites

- Local dev server running on the target app's port (web 3000, admin 3001, backend 2920 by default)
- `agent-browser` CLI installed (primary); Playwright MCP (`mcp__plugin_playwright_playwright__*` tools) as fallback
- Git repository initialised (required for scope detection by diff)

### Tool Detection

Before step 1, verify that a browser backend is reachable. Check in this order:

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

## Workflow

### Step 1: Determine Test Scope

Decide which routes / screens to exercise. Inputs come from the caller:

| Caller context | Scope source |
|----------------|--------------|
| PR number provided | `gh pr view {N} --json files -q '.files[].path'` |
| `--branch {name}` | `git diff --name-only main...{name}` |
| `/u-gatekeeping` runtime QA | All TCs with `type=e2e` from `docs/{app}/gatekeeping/testcases.json` |
| `/u-report-weekly` capture | `output/{app}/design/screens/*.html` + `output/{app}/design/wireframes/*.html` (최대 3개씩) + live dev URLs |
| `/u-dev` visual verify | Screens listed in `docs/{app}/design/Screen.json` with `status=implemented` |
| No context | `git diff --name-only main...HEAD` |

### Step 2: Map Files → Routes

When scope comes from a file diff, translate paths to URLs:

| File Pattern | Route(s) |
|--------------|----------|
| `apps/web/src/app/**/page.tsx` | Corresponding App Router route |
| `apps/admin/src/app/**/page.tsx` | Admin dashboard route |
| `apps/backend/src/**/*.controller.ts` | `/v1/{resource}` API endpoints (use `browser_navigate` + network trace) |
| `packages/ui-*/src/components/**/*.tsx` | All pages rendering the component (fallback: Storybook at port 6006) |
| `apps/*/src/features/**/*.tsx` | Pages using the feature |
| `apps/*/src/app/layout.tsx` | All routes (smoke-test homepage at minimum) |
| `packages/tokens/src/**/*.css` | Visual regression on key pages |

### Step 3: Detect Dev Server Port

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

### Step 4: Ask Browser Mode (skippable with `--auto`)

Unless caller passed `--auto` or `--headless`, ask via `AskUserQuestion`:

```
Do you want to watch the browser run?
1. Headed (watch)   — visible window, slower but observable
2. Headless (faster) — background, faster, default for CI
```

Store the choice; pass the appropriate headed flag to the active backend (`--headed` for agent-browser CLI, `headless: false` for Playwright MCP) when the user picks option 1.

Caller override hints:
- `/u-gatekeeping --auto` → headless always
- `/u-report-weekly` → headless always (no interactivity)
- `/u-dev --verify` → ask (default headed for human review)

### Step 5: Verify Server is Running

Navigate to the root URL and assert it responds:

```
mcp__plugin_playwright_playwright__browser_navigate
  url: http://localhost:${PORT}

mcp__plugin_playwright_playwright__browser_snapshot
```

If navigation fails (connection refused / timeout):

```
Server not running on port ${PORT}.

Please start your development server:
- Web / Admin: `bun run dev --filter={app}`
- Backend:     `bun run dev --filter=backend`
- Storybook:   `bun run storybook --filter=ui-common`

Then re-run this command, or pass `--port <port>` to override.
```

HALT — do not continue.

### Step 6: Execute the Browser Operation

Branch by caller intent:

#### 6a. E2E Test Execution (`/u-gatekeeping`)

```bash
bun run test:e2e --filter={app}
```

Results are parsed into `docs/{app}/gatekeeping/test-results.json` per `u-gatekeeping/references/test-execution.md`. When a test fails, drop to Step 8 for failure handling.

For interactive debugging of a single TC:
```
browser_navigate  url: http://localhost:${PORT}/{route}
browser_snapshot             # get element refs
browser_click    ref: @e1
browser_fill_form fields: [...]
browser_wait_for text: "..."
```

#### 6b. Screen Capture (`/u-report-weekly`, `/u-dev --verify`)

For each target URL:

```
browser_navigate       url: <target>
browser_wait_for       text: <stable selector>  # or time: 1000
browser_take_screenshot path: .u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-{slug}.png
```

- Full-page: pass `fullPage: true`
- File naming: `{app}-{page-slug}.png` (kebab-case slug from route)
- Base64 embed: read PNG back → base64 → inline in HTML report

#### 6c. Visual Verify Against Screen.md (`/u-dev`)

1. Load expected layout from `docs/{app}/design/Screen.json` (fields: components, viewport, criticalText)
2. Navigate to implemented route
3. `browser_snapshot` → collect interactive elements
4. Assert each `components[*].key` is present in the snapshot
5. Assert `criticalText[*]` appears in page text
6. Record diff as `.u-maker/.state/visual-verify/{app}-{screen}.json`

#### 6d. Wireframe Preview (`/u-wireframe`)

Open a local wireframe file in the browser for human review:

```
browser_navigate url: file://{absolute-path-to-output}/design/wireframes/{screen}.html
```

#### 6e. Design System HTML Verification (`/u-design` Step 4a)

Verify the HTML-first DS artifact (`out/{app}/design/design-system.html`) renders correctly. Runs against `file://` (no dev server required).

1. **Load expected inventory** from `docs/{app}/design/design-system.json`:
   - `tokens[]` — every token row (color / spacing / type / shadow / radius / motion / breakpoint / z-index)
   - `components[]` — every component (CMP-xxx) with variants and states
   - `themes[]` — should include `light` and `dark` (per `design-system-rules.md` §0#11)
2. **Navigate** the static HTML:
   ```
   browser_navigate url: file://{absolute-path-to-out}/design/design-system.html
   browser_wait_for text: <DS title from JSON>
   ```
3. **Token render check** — query the rendered `:root` CSS variables via `browser_evaluate`:
   ```js
   () => {
     const cs = getComputedStyle(document.documentElement);
     const sample = {};
     // sample at least 1 token per scale
     ['--color-primary-500','--space-4','--radius-md','--shadow-md','--font-base','--motion-base'].forEach(k => {
       sample[k] = cs.getPropertyValue(k).trim();
     });
     return sample;
   }
   ```
   Compare every sampled value to the JSON expectation. Missing or empty → record under `mismatches[]`.
4. **Component showcase check** — for each `components[*]`, assert the live showcase exists:
   ```
   browser_snapshot                                                  # collect element refs
   ```
   Verify a `[data-cmp-id="CMP-{nnn}"]` (or fallback `data-component={key}`) element is present and visible. For each `variants[*]` and `states[*]`, verify the `[data-variant=...]` / `[data-state=...]` selector exists.
5. **Dark-mode toggle** — flip `[data-theme="dark"]` via `browser_evaluate`:
   ```js
   () => { document.documentElement.dataset.theme = 'dark'; }
   ```
   Re-sample the same tokens (Step 3). Assert at least the semantic-layer tokens differ from light. Take a second screenshot.
6. **Accessibility audit** (mandatory per `design-system-rules.md` §0#7) — when running on chrome-devtools MCP, request a Lighthouse a11y audit:
   ```
   mcp__plugin_chrome-devtools-mcp_chrome-devtools__lighthouse_audit  categories: ["accessibility"]
   ```
   When running on Playwright MCP, run an axe-core injection via `browser_evaluate`. WCAG-AA contrast violations and missing focus indicators are recorded under `a11yViolations[]`.
7. **Screenshots** — full-page light + dark, written to:
   - `.u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-design-system-light.png`
   - `.u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-design-system-dark.png`
8. **Diff record** — write the verification result to `.u-maker/.state/visual-verify/{app}-design-system.json`:
   ```json
   {
     "verifiedAt": "ISO-8601",
     "html": "out/{app}/design/design-system.html",
     "expectedTokens": N,
     "renderedTokens": M,
     "missingTokens": [],
     "expectedComponents": K,
     "renderedComponents": L,
     "missingComponents": [],
     "darkModeToggled": true,
     "a11yViolations": [],
     "screenshots": ["…light.png","…dark.png"],
     "result": "pass|partial|fail"
   }
   ```

#### 6f. Component Implementation Verification (`/u-dev` Step 1.5)

Verify directly-implemented FE components render correctly against their Screen.json + design-system.json specs. Requires a dev server (Storybook on port 6006 OR app routes on the app port).

1. **Choose render target** (priority):
   1. Storybook on port 6006 (`packages/ui-*/.storybook` exists) — use `iframe.html?id={story-id}` deep links.
   2. App route (`apps/{app}/src/app/**/page.tsx` rendering the component).
   3. Static demo file (`apps/{app}/public/_demo/{cmp-id}.html`) if neither of the above is available.
2. **Per-component loop** — load the component list from `docs/{app}/design/design-system.json` `components[]`. For each `CMP-{nnn}`:
   - Navigate to its render target.
   - `browser_snapshot` to collect element refs.
   - Assert prop default values render (text content, icon presence, default variant CSS class).
   - For each `variants[*]` / `states[*]` combination: navigate to the variant URL (Storybook story ID `cmp-{nnn}--{variant}-{state}`), screenshot it, assert variant-specific selectors.
3. **Token binding check** — for each rendered component, sample the resolved fill / border / spacing via `browser_evaluate`:
   ```js
   (selector) => {
     const el = document.querySelector(selector);
     if (!el) return null;
     const cs = getComputedStyle(el);
     return { bg: cs.backgroundColor, fg: cs.color, padding: cs.padding, radius: cs.borderRadius };
   }
   ```
   Compare to the expected token resolution from `design-system.json`. Drift → record under `tokenDrift[]`.
4. **Figma diff (optional, when `figmaKey` present)** — if `components[*].figmaKey` is set in `design-system.json` AND `mcp__plugin_figma_figma__get_screenshot` is reachable, fetch the Figma component screenshot and pixel-diff against the implementation screenshot. Diff > 10% → log to `figmaDiff[]`.
5. **Per-component a11y** — same audit pattern as Step 6e.6, scoped to the component subtree.
6. **Screenshots** — `.u-maker/.state/screenshots/{YYYY-MM-DD}/{app}-cmp-{nnn}-{variant}-{state}.png`
7. **Diff record** — write `.u-maker/.state/visual-verify/{app}-components.json`:
   ```json
   {
     "verifiedAt": "ISO-8601",
     "renderTarget": "storybook|app|demo",
     "totalComponents": K,
     "verified": L,
     "tokenDrift": [{ "cmpId": "CMP-010", "variant": "primary", "field": "bg", "expected": "...", "actual": "..." }],
     "figmaDiff": [{ "cmpId": "CMP-020", "diffPct": 14.2, "screenshot": "..." }],
     "a11yViolations": [],
     "result": "pass|partial|fail"
   }
   ```

### Step 7: Human Verification (only when flow requires it)

Pause for confirmation when the journey crosses an external boundary:

| Flow | Question |
|------|----------|
| OAuth | "Please sign in with {provider} and confirm the redirect returned to the app." |
| Payments | "Complete the sandbox purchase and confirm order appears in dashboard." |
| Email | "Check inbox for `{subject}` and confirm content." |
| SMS | "Confirm receipt of the verification code." |
| External APIs | "Confirm the {service} integration responded successfully." |

Use `AskUserQuestion`:

```
Human Verification Needed
This scenario requires {flow}. Please:
1. {Action}
2. {Verify}

Did it work correctly?
  Yes — continue testing
  No  — describe the issue
```

### Step 8: Handle Failures

When a step fails (assertion, navigation, timeout):

1. Capture an error screenshot:
   ```
   browser_take_screenshot  path: .u-maker/.state/screenshots/errors/{YYYY-MM-DD}-{slug}.png  fullPage: true
   ```
2. Collect console + network evidence:
   ```
   browser_console_messages
   browser_network_requests
   ```
3. Ask the caller via `AskUserQuestion`:
   ```
   Test Failed: {route}
   Issue: {description}
   Console errors: {n}

   How to proceed?
     Fix now  — investigate and patch
     Create todo — defer via /u-gatekeeping todo with priority p1
     Skip     — record as skipped, continue
   ```
4. Per choice:
   - **Fix now** → debug → propose patch → re-run Step 6 for that route only
   - **Create todo** → append to `.u-maker/.state/todos.json` with `priority=p1`, `source=u-tools-browser`, `route={route}`
   - **Skip** → mark result `skipped` and continue

### Step 9: Summary Output

After all operations finish, emit a summary in caller-appropriate format:

```markdown
## Browser Run Summary

**Caller:** {skill-name}
**Scope:** {scope description}
**Server:** http://localhost:{PORT}
**Mode:** {headed | headless}

### Operations: {count}

| Route | Operation | Status | Artifact |
|-------|-----------|--------|----------|
| `/users` | capture | Pass | screenshots/2026-04-19/web-users.png |
| `/checkout` | e2e | Fail | errors/2026-04-19-checkout-oauth.png |

### Console Errors: {count}
- {list}

### Human Verifications: {count}
- OAuth: Confirmed
- Email: Confirmed

### Failures: {count}
- `/checkout` — `FT-120` assertion timeout on `[data-testid=confirm]`

### Created Todos: {count}
- p1 — u-tools-browser — /checkout — OAuth redirect loop

### Result: {PASS | FAIL | PARTIAL}
```

The calling phase skill consumes this summary (not the raw MCP output) and integrates it into its own artifact (test-results, weekly report, etc.).

## Consumer Integration Table

| Caller Skill | Entry Step | Primary Operation | Artifact Path |
|--------------|------------|-------------------|---------------|
| `/u-gatekeeping` (runtime QA) | Step 6a | E2E via `bun run test:e2e` | `docs/{app}/gatekeeping/test-results.{md,json}` |
| `/u-report-weekly` | Step 6b | Screen capture | `.u-maker/.state/screenshots/{date}/{app}-{page}.png` |
| `/u-report-daily` | Step 6b | Live URL capture (optional) | `.u-maker/.state/screenshots/{date}/{app}-*.png` |
| `/u-dev --verify` (screen-level) | Step 6c | Visual verify vs Screen.json | `.u-maker/.state/visual-verify/{app}-{screen}.json` |
| `/u-wireframe --preview` | Step 6d | Open wireframe HTML | — |
| `/u-output --verify` | Step 6c | Assert generated HTML renders | `.u-maker/.state/visual-verify/{app}-index.json` |
| `/u-design` Step 4a (auto) | **Step 6e** | DS HTML token + component + dark + a11y verification | `.u-maker/.state/visual-verify/{app}-design-system.json` |
| `/u-dev` Step 1.5 (auto) | **Step 6f** | Per-component visual + token-binding + (optional) Figma diff + a11y | `.u-maker/.state/visual-verify/{app}-components.json` |

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--auto` | OFF | Skip headed/headless prompt, use headless |
| `--headed` | OFF | Force headed mode |
| `--headless` | OFF | Force headless mode |
| `--port {N}` | — | Override dev-server port |
| `--app {name}` | — | Scope to a single app (required for multi-app ops) |
| `--route {path}` | — | Scope to a single route |
| `--no-screenshot` | OFF | Skip screenshot steps (6b) |
| `--retry {N}` | 2 | Retry count for flaky steps |

## Anti-patterns

- ❌ Phase skill directly calling `mcp__plugin_playwright_playwright__browser_navigate`
- ❌ Mixing multiple backends (agent-browser CLI + Playwright MCP + chrome-devtools MCP) in the same run
- ❌ Writing screenshots outside `.u-maker/.state/screenshots/`
- ❌ Running E2E tests without first verifying the dev server via Step 5
- ❌ Hard-coding port 3000 for backend (should be 2920)
- ✅ Load `u-tools-browser`, follow Steps 1→9, consume the summary

## Error Handling

| Condition | Action |
|-----------|--------|
| No browser backend available | Ask user to install the `agent-browser` CLI (or the `plugin_playwright` plugin as fallback), HALT |
| Dev server not responding on detected port | Print start-command hints (Step 5), HALT |
| MCP timeout (>30s) during navigation | Retry once; if second timeout, record as failure (Step 8) |
| Screenshot write fails (disk / perms) | Fallback to `/tmp/{uuid}.png`, warn user, continue |
| Caller passed conflicting `--headed` + `--headless` | Error: "Mutually exclusive flags", HALT |

## Reference

Adapted from the [test-browser skill](https://github.com/EveryInc/compound-engineering-plugin/blob/main/plugins/compound-engineering/skills/test-browser/SKILL.md) pattern (compound-engineering plugin). Core differences:

- Backend priority: agent-browser CLI > Playwright MCP > chrome-devtools MCP
- Port defaults follow u-maker convention (web 3000 / admin 3001 / backend 2920)
- Artifacts live under `.u-maker/.state/` instead of a free-form path
- Scope mapping aligned with Turborepo `apps/*` + `packages/*` layout from `/u-createproject`
