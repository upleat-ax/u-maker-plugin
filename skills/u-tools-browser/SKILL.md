---
name: u-tools-browser
description: "This skill should be used when any u-maker command needs browser automation. Use when the user asks to '/u-tools-browser', 'u-tools-browser', 'playwright', 'agent-browser', 'browser automation', 'e2e test', 'E2E', 'headless browser', 'screen capture', 'screenshot', 'visual regression', 'a11y audit', 'figma parity', 'Playwright 캡처', or '브라우저 자동화'. Covers E2E test execution (Playwright), screen capture for reports, dev-server verification, visual regression, or live-render inspection. All u-maker phase skills MUST route browser work through this engine instead of calling MCP browser tools directly."
version: 1.1.0
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

Before Step 1, verify that a browser backend is reachable. Priority: **agent-browser CLI > Playwright MCP > chrome-devtools MCP**. If none available, HALT with install instructions.

Full detection protocol → **see `references/backend-detection.md` § Tool Detection**.

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

Priority: `--port` arg > `.u-maker/data/ports.json` > `apps/{app}/package.json` dev script > `.env*` PORT line > `AGENTS.md/CLAUDE.md` regex > per-app defaults (web 3000 / admin 3001 / backend 2920 / storybook 6006).

Full priority list + bash snippet → **see `references/backend-detection.md` § Port Detection**.

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
- Storybook:   `bun run storybook --filter=ui-atomics`

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

Verifies the HTML-first DS artifact (`out/{app}/design/design-system.html`) renders correctly. Runs against `file://` (no dev server). 9 sub-steps: load inventory → navigate → token render → component showcase → dark-mode toggle → a11y audit → screenshots → **Figma parity (MANDATORY when `dsFileKey` set)** → diff record.

Full protocol (9 sub-steps + result rules + JSON schema) → **see `references/visual-verify-ds.md`**.

Output: `.u-maker/.state/visual-verify/{app}-design-system.json` with `result: pass | partial | fail`.

#### 6f. Component Implementation Verification (`/u-dev` Step 1.5)

Verifies implemented FE components against their `Screen.json` + `design-system.json` specs. Requires dev server (Storybook 6006 > app routes > static demo). 7 sub-steps: choose render target → per-component loop → token binding → **Figma parity (MANDATORY when `figmaKey` set)** → a11y → screenshots → diff record.

Full protocol → **see `references/visual-verify-components.md`**.

Output: `.u-maker/.state/visual-verify/{app}-components.json` with `result: pass | partial | fail`.

#### 6g. Screen / Route Implementation Verification (`/u-gatekeeping` Step 2.5)

Verifies a fully rendered app **route** against its Figma **frame** — the screen-level parity that 6e (DS) and 6f (components) do not cover. Requires the app dev server. For each `screens.json` item with `figmaUrl` set: navigate to the route, capture a full-page screenshot, fetch the Figma frame via `mcp__plugin_figma_figma__get_screenshot`, pixel-diff each labelled region, check critical text parity, and sample token resolution on key regions.

- **PIXEL-PERFECT gate thresholds** (stricter than the Build-phase 6e/6f defaults of SSIM 0.95 / 5 % / ±2 px): **SSIM ≥ 0.99, pixel diff ≤ 1 %, region bounds ± 1 px** (fixed gate default from `_meta/schemas/gate-rules.json` GK-12.thresholds; `--figma-ssim-threshold` / `--figma-diff-threshold` may only **tighten** it, never loosen).
- Mandatory whenever any screen carries `figmaUrl`; HALT (auth) or explicit recorded `--no-figma-parity` otherwise — never silently skip.

Full protocol → **see `references/visual-verify-screens.md`**. Output: `.u-maker/.state/visual-verify/{app}-screens.json` with per-screen `figmaParity{}` and `result: pass | fail`.

### Step 7: Human Verification (when flow requires it)

Pause for `AskUserQuestion` confirmation when the journey crosses an external boundary: OAuth, Payments, Email, SMS, External APIs.

Full prompts per flow → **see `references/failure-handling.md` § Step 7**.

### Step 8: Handle Failures

On assertion/navigation/timeout failures: capture error screenshot → collect console + network → ask user `Fix now / Create todo / Skip` → execute the choice.

Full protocol → **see `references/failure-handling.md` § Step 8**.

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
| `/u-gatekeeping` Step 2.5 (auto) | **Step 6g** | Per-screen route vs Figma frame **pixel-perfect** parity (GK-12) | `.u-maker/.state/visual-verify/{app}-screens.json` |

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
| `--no-figma-parity` | OFF | Explicitly skip Figma parity sub-steps (6e.8 / 6f.4 / **6g**). **Use only when intentionally diverging from Figma**; logged to the run summary so reviewers can see the override. Without this flag, Figma parity runs unconditionally whenever a Figma source is registered. **At the GK-12 GATE (6g) an override must be explicitly acknowledged and still blocks Deploy.** |
| `--figma-diff-threshold {pct}` | 5 | Pixel-diff threshold — **Build-phase default for 6e.8 / 6f.4 only**. The GK-12 **GATE (6g)** uses the fixed `gate-rules.json` GK-12.thresholds (≤ 1%); this flag may only **tighten** the gate, never loosen it. |
| `--figma-ssim-threshold {0..1}` | 0.95 | SSIM threshold — **Build-phase default for 6e.8 / 6f.4 only**. The GK-12 **GATE (6g)** uses the fixed GK-12.thresholds (≥ 0.99); this flag may only **tighten** (raise) it. |
| `--retry {N}` | 2 | Retry count for flaky steps |

## Anti-patterns

- ❌ Phase skill directly calling `mcp__plugin_playwright_playwright__browser_navigate`
- ❌ Mixing multiple backends (agent-browser CLI + Playwright MCP + chrome-devtools MCP) in the same run
- ❌ Writing screenshots outside `.u-maker/.state/screenshots/`
- ❌ Running E2E tests without first verifying the dev server via Step 5
- ❌ Hard-coding port 3000 for backend (should be 2920)
- ❌ **Silently skipping Figma parity when `dsFileKey` or `figmaKey` is set** — Steps 6e.8 / 6f.4 must run, HALT, or be explicitly overridden via `--no-figma-parity` (with the override recorded in the summary). Never `try/catch` the parity check away.
- ❌ Treating a Figma parity failure as `partial` — it MUST surface as `fail` so the caller (`/u-design`, `/u-dev`) re-iterates.
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
