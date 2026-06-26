# Changelog

All notable changes to u-maker-plugin.

## [4.0.0-alpha.27] — 2026-06-26

**Single-side accent border ban is now gate-ENFORCED, not just documented: GK-07 gains a `no-single-side-accent-border` check, and the rule is wired into every HTML generator + the report agent.**

The "한쪽 border만 강조 금지" rule has existed in `html-engine.md` since `4.0.0-alpha.23` and the shipped templates already comply — but it was a generation-time guideline with **no verification step**, so a decorative single-side border could still slip into HTML output (e.g. an agent injecting `border-left: 4px solid {accent}` or a color-bar `active` state) without being caught. This release gives the ban teeth and closes the coverage gaps the user asked to exclude.

### Changed

- **`_meta/schemas/gate-rules.json` — GK-07 (Visual Adequacy) gains the `no-single-side-accent-border` check** and an expanded description: emphasis must use a full 4-side `border` + background tint + `font-weight`; decorative single-side `border-left/right/top/bottom` bars and color-bar active states are a violation. Neutral 1px dividers, focus rings, and chart/timeline data markers remain allowed. Violations now cost GK-07 score → can drop a doc below the pass (95) / deploy (98) thresholds.
- **`skills/u-engine/references/html-engine.md` §Border/Accent — promoted to a HARD RULE** explicitly scoped to **all** HTML output (document output, wireframe, design system, reports, roadmap) and cross-linked to the GK-07 enforcement check (violation ⇒ 감점/FAIL).
- **Generation-time reinforcement at the two riskiest free-form HTML paths** — `skills/u-output/SKILL.md` Step 3 and `agents/u-agent-report.md` Step 4 now call out the single-side accent border ban inline (with the 4-side border + bg-tint + weight alternative), so the agent applies it while emitting markup rather than relying solely on reading the full engine reference.
- **`skills/u-gatekeeping/references/doc-scoring.md` — GK-07 row** updated to name the single-side accent border ban.
- **No template changes needed** — an audit of all `_meta/templates/*.html` + skill templates (output, split, daily-report, design-system, wireframe, roadmap) confirmed every existing single-side border is a **neutral** divider or an **allowed** Gantt/chart data-marker; none are decorative accent bars. The change is enforcement + visibility, not a template fix.

## [4.0.0-alpha.26] — 2026-06-26

**Side-effect gate de-noised a THIRD time + an emphasized impact banner: in `auto` it now fires ONLY on a behavior-MODIFYING fix to shared, implemented code — purely additive edits pass silently — and every prompt leads with `⚠️ SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음`.**

The `4.0.0-alpha.25` gate required two signals — *already-implemented* (git-tracked + clean) **AND** *depended-upon* (imported by another file). But in a settled repo almost every meaningful file is **both** tracked+clean **and** imported somewhere, so the gate still fired on the first touch of nearly every shared file. This release adds the missing discriminator the user asked for — *"fix하는 경우에만 … 사이드이펙트가 있을 수 있는 경우에만 물어본다"* — distinguishing a **fix that changes existing behavior** from **forward construction that merely adds code**: a third signal **(C) MODIFYING** gates only when the edit rewrites/deletes existing lines, while **purely additive** insertions to a shared file (which leave every existing line dependents rely on intact) now pass freely. It also makes the impact **unmistakable**: every approval prompt leads with an emphasized side-effect banner.

### Changed

- **`hooks/on-edit-guard.js` — `auto` mode now requires THREE signals, not two.** A file is gated only when it is **(A) already-implemented** (git-tracked AND clean vs HEAD) **AND (B) has dependents** (≥1 other source file imports/references it) **AND (C) the edit MODIFIES existing code** rather than purely adding to it. (C) is computed from the tool input: **Edit/MultiEdit** are additive iff every `new_string` contains its `old_string` verbatim (an insertion around untouched code); **Write** is additive iff the new content contains the entire existing file verbatim (append/prepend/wrap); **Bash** mutations (`sed -i` / redirect / `rm` / `mv` / interpreter writes) are inherently modifying. **Purely additive** edits to shared, implemented files now pass freely — forward construction in an existing file no longer prompts. Only a genuine behavior-changing fix to depended-upon code is gated.
- **Emphasized impact banner on every prompt.** The native approval prompt (`permissionDecisionReason`) and the injected `systemMessage` now **lead with** `⚠️  SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음  ⚠️`, then name the affected dependents — so it is immediately clear the change can ripple into other features/UI (사용자 지시: *"사이드이펙트 영향도가 있다는 강조된 표현을 꼭 보여주도록"*).
- **`strict` mode unchanged in spirit** — still gates EVERY change (add *or* modify) to EVERY existing file (no implemented/dependent/additive checks; `git apply`/`patch` also gated), for git-less projects or maximum caution. **`off` unchanged.**
- **Known boundary (new, documented, by design):** **Boundary 3 — the additive/modifying split is structural.** An insertion that still alters runtime behavior for existing callers (e.g. an early `return` / guard clause spliced into a function) reads as *additive* and passes silently. That residual **behavior-delta** remains the agent's responsibility under the `/u-dev` Step 0.5 impact analysis. (Boundary 2 stands: HTTP API routes / DB schema / env contracts are cross-feature surfaces the import-graph heuristic does not detect.)
- **Docs realigned to the NEW / IN-PROGRESS / IMPLEMENTED·LEAF / IMPLEMENTED·SHARED·(ADDITIVE|MODIFYING) model** — `skills/u-dev/references/change-safety.md` (purpose, gate-mode table, §1 ADDITIVE/MODIFYING split + Boundary 3, §2/§4 scoped to MODIFYING + banner), `skills/u-dev/SKILL.md` Step 0.5, `agents/u-agent-dev.md`, `skills/u-build/SKILL.md`, `agents/u-agent-build.md`, `skills/u-dev/references/code-gen-rules.md`, and the `hooks/hooks.json` description.

## [4.0.0-alpha.25] — 2026-06-26

**Side-effect gate de-noised again: it now fires only on fixes to already-implemented code THAT OTHER CODE DEPENDS ON — not on every committed file.**

The `4.0.0-alpha.24` gate scoped to *already-implemented* (git-tracked + clean) files. But in a settled repo **almost every file is tracked + clean**, so "already-implemented" effectively meant "everything" and the gate fired on nearly every edit. This release adds the missing discriminator the user asked for — *"fix하는 경우에만 다른 기능이나 UI/UX에 사이드이펙트가 있을지 검토하고, 사이드이펙트가 있을 수 있는 경우에만 물어본다"*: a fix is only gated when the file is **depended upon** (imported/referenced by another source file), so changing it can actually ripple into other features. Self-contained **leaf** files (standalone pages, framework entries, tests, modules nothing imports) now pass freely.

### Changed

- **`hooks/on-edit-guard.js` — `auto` mode now requires TWO signals, not one.** A file is gated only when it is **(A) already-implemented** (git-tracked AND clean vs HEAD) **AND (B) has dependents** (≥1 other source file imports/references it). (B) is a reverse-dependency scan via `git grep` over a quoted module-specifier whose last path segment matches the file's module name (basename without extension; parent-dir name for `index.*`; framework entries like `page`/`route`/`layout`/`middleware`/`_app` are treated as leaves since they are loaded by convention, not imported). **Leaf** implemented files (no importers) now pass freely — a fix there cannot side-effect other features. The native approval prompt now **names the affected dependents** (e.g. *"2 other file(s) import/reference it: src/App.tsx, …"*) so approval is informed.
- **`strict` mode unchanged** — still gates every existing file (incl. `git apply`/`patch`), for git-less projects or maximum caution. **`off` unchanged.**
- **`auto` no longer gates `git apply` / `patch`** — their targets live in the patch body, so the blast radius is unknowable; gating them was pure noise. They remain gated in `strict`. (`sed -i` / `perl -i` / redirects / `rm` / `mv` / `cp`·`tee`·`dd` destinations / `git rm`·`checkout --`·`restore` / interpreter inline writes are still resolved to concrete targets and gated only when the target is implemented·shared.)
- **Known boundary (documented, by design):** the dependent check is an **import-graph heuristic**. Cross-feature contracts not expressed as imports — **HTTP API routes, DB schema/migrations, env contracts** — do NOT trip the guard; they remain the agent's responsibility under the `/u-dev` Step 0.5 change-safety protocol.
- **Docs realigned to the NEW / IN-PROGRESS / IMPLEMENTED·LEAF / IMPLEMENTED·SHARED model** — `skills/u-dev/references/change-safety.md` (purpose, gate-mode table, §1 LEAF/SHARED classification + Boundary 2, §2/§4 scoped to SHARED), `skills/u-dev/SKILL.md` Step 0.5, `agents/u-agent-dev.md` (Step 0.5 + Side-Effect Safety FAIL), `skills/u-build/SKILL.md`, `agents/u-agent-build.md`, `skills/u-dev/references/code-gen-rules.md`, and the `hooks/hooks.json` description.

## [4.0.0-alpha.24] — 2026-06-25

**Side-effect gate de-noised: it now fires only on FIXES to already-implemented code, not on every edit.**

The `4.0.0-alpha.23` side-effect gate asked for approval before modifying **any** existing file, so during normal development it fired on almost everything. It now scopes to the user's actual intent — *"버그나 이미 구현된 기능이나 UI/UX를 fix하는 경우에만"* — by detecting "already-implemented" automatically via git.

### Changed

- **`hooks/on-edit-guard.js` — gate scope narrowed to ALREADY-IMPLEMENTED code.** A file is gated only when it is git-**tracked AND clean vs HEAD** (committed/shipped). **NEW (untracked)** and **IN-PROGRESS (dirty/uncommitted)** files now pass freely — so forward construction and iterating on a file you just created are no longer interrupted. Touching committed code (a bug fix / change to a shipped feature or UI) still gates. No-git / not-a-repo → not gated (favor low friction; use `strict` for git-less projects).
- **New `U_MAKER_EDIT_GATE` env switch** — `auto` (default, fix-only), `strict` (every existing file = the alpha.23 behavior), `off` (disabled).
- **Bash false-positives fixed** — `install` removed from the in-place verb set (it matched package managers: `pip install -r requirements.txt`, `npm/cargo install …`); `cp` / `tee` / `dd` now gate only their **write destination**, not read-only sources/stdin (`cp shipped.ts /tmp/x` no longer fires on `shipped.ts`). Redirects, `rm` / `mv` / `sed -i` / `perl -i` / `git rm|checkout --|restore`, `git apply` / `patch`, and interpreter inline writes remain covered.
- **Docs realigned to the NEW / IN-PROGRESS / IMPLEMENTED model** — `skills/u-dev/references/change-safety.md` (classification + gate-mode table + boundary note), `skills/u-dev/SKILL.md` Step 0.5, `agents/u-agent-dev.md`, `skills/u-build/SKILL.md`, `agents/u-agent-build.md`, `skills/u-dev/references/code-gen-rules.md`, and the `hooks/hooks.json` description.

## [4.0.0-alpha.23] — 2026-06-22

**Three gatekeeping hardenings: (1) HTML 산출물에서 '한쪽 border만 강조' 장식 스타일 전면 금지, (2) 개발 시 기존 코드 수정에 대한 strict·adversarial 사이드이펙트 게이트(사용자 승인 필수, especially 버그 수정), (3) Figma/참고자료 ↔ 구현 pixel-perfect 일치성 게이트(GK-12).**

### Added

- **Side-effect gatekeeping (GOAL 2) — `hooks/on-edit-guard.js` (NEW, PreToolUse) + `skills/u-dev/references/change-safety.md` (NEW)** — a strict, default-deny gate that forces explicit **user approval** before any modification of **existing** code in a u-maker project (Edit/Write/MultiEdit and mutating Bash: `sed -i` / redirects / `rm` / `mv` …). The guard is wired **directly** in `hooks/hooks.json` as a new `PreToolUse` entry (matcher `Write|Edit|MultiEdit|Bash`), NOT through `_dispatch.js` (whose contract is "never block"). It emits `permissionDecision: "ask"` (native user confirmation) unless a fresh per-file approval marker exists under `.u-maker/.state/edit-approvals/{sha1(path)}.json` (session-TTL allowlist, `U_MAKER_EDIT_APPROVAL_TTL_MIN`, default 480m). NEW files, `.u-maker/**`, non-u-maker projects, and read-only Bash are out of scope. `change-safety.md` defines the agent-side protocol: NEW-vs-EXISTING classification → blast-radius/impact analysis → adversarial self-review → mandatory `AskUserQuestion` → approval marker → scope-lock. Applies especially to **bug fixes**.
- **Design Conformance gate (GOAL 3) — GK-12 in `_meta/schemas/gate-rules.json`** — a 12th gatekeeper criterion ("Design Conformance / 디자인 일치성") asserting the implemented UI is **pixel-perfect** to the Figma source of truth + ingested reference materials (token/layout/variant/text parity, reference-rule coverage, zero drift). Pixel-perfect GATE thresholds **SSIM ≥ 0.99 / pixel ≤ 1% / bounds ± 1px** (stricter than the Build-phase 0.95/5%/±2px). Added to `gates.gatekeeping-to-deploy.required` (`design-conformance-pass`); N/A-auto-pass only when no Figma/reference provenance exists.
- **`skills/u-tools-browser` Step 6g (screen/route ↔ Figma frame parity)** with its new reference **`skills/u-tools-browser/references/visual-verify-screens.md`**, and **`skills/u-gatekeeping` Step 2.5 (Design Conformance)** which delegates screen parity to that step — closes the screen-level parity gap (only DS-level 6e + component-level 6f existed) and makes Gatekeeping (not just transient Build-phase state) the durable owner of conformance via `.u-maker/.state/design-conformance.json`.

### Changed

- **HTML: no single-side accent borders (GOAL 1)** — `skills/u-engine` (4.0.0 → 4.1.0): `references/html-engine.md` §6 gains a **"Border / Accent Style Rules"** section banning decorative/active single-side colored borders (좌측 액센트 바, nav/tab active 컬러 바, 컬러 heading 밑줄); 강조는 전체 4변 border + 배경 틴트 + `font-weight`로. Only **1px 중립 divider / focus ring / 차트·타임라인 마커** keep a single side. Mirrored in `SKILL.md` invariants, `u-design/references/design-system-rules.md` §0 (#16), and `u-dev/references/fe-rules.md` §0 (#16). Output templates brought into compliance: `_meta/templates/output-index.template.html`, `output-page.template.html`, `output-split-page.template.html`, and `skills/u-wireframe` (4.0.0 → 4.1.0) `references/wireframe-page.template.html` (nav-active bars → bg-fill+weight, colored h2 underline → 1px neutral, tab indicator → bg-fill). Repo docs `GET_STARTED.html` / `README.ko.html` / `README.en.html` fixed (callout/feature-card left-accent bars, nav-active bars, colored heading underlines).
- **`skills/u-dev` (4.1.0 → 4.2.0)** — new **Step 0.5: Side-Effect Gatekeeping** (mandatory hard gate before editing existing code) in `SKILL.md` + `agents/u-agent-dev.md` (§3 Step 0.5 + §4 Side-Effect Safety FAIL rules); `references/code-gen-rules.md` §7.1/§7.2 tightened so `--force` / "manual confirmation" defer to the mandatory approval gate.
- **`skills/u-build` (4.0.0 → 4.1.0)** + `agents/u-agent-build.md` — `--auto` explicitly does NOT bypass the side-effect gate; an unapproved side-effect is a first-class halt.
- **`skills/u-gatekeeping` (4.0.0 → 4.1.0)** + `agents/u-agent-gatekeeper.md` — adds GK-12 to the criteria table, scorecard, and per-criterion details (default 5, **max 12**; GK-12 always gates Deploy regardless of `--loop N`); `deploy-readiness.json` now carries `designConformance` and requires it `∈ {pass, na}` for `deployReady: true`. `agents/u-agent-qa.md` adds a 7th TC type **Design-Conformance** so parity is traceable through FR→US→FT→TC.
- **`skills/u-tools-browser` (1.0.0 → 1.1.0)** — Step 6g + consumer-table row; `references/visual-verify-ds.md` / `visual-verify-components.md` silent-skip tightened (Figma provenance present but un-round-tripped → `figmaSourceUnlinked` = GK-12 fail, not a silent pass).
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.22 → 4.0.0-alpha.23`.

## [4.0.0-alpha.22] — 2026-06-06

**Changed: project-scaffolded `DESIGN.md` now leads with a 디자인 의존 파이프라인 (`apps/* → ui-* → tokens`) — a 2-tier apps↔ui-* boundary with explicit Do/Don't, and `/u-dev` surfaces unbuildable-with-`ui-*` UI as a gap instead of emitting raw HTML.**

### Changed

- **`skills/u-createproject` (1.2.0 → 1.3.0) — DESIGN.md template (`references/scaffolding-spec.md` §7)** — new headline section **`## 0. 디자인 의존 파이프라인 (apps ↔ ui-* 경계)`** establishes that the code dependency flow applies to design too, as a two-tier model with **explicit Do ✅ / Don't ❌ blocks per tier**:
  - **`apps/*` (소비자)** — compose `ui-*` components only; variations via **props**; minimize raw HTML/CSS/inline style/`className`; semantic structural HTML (`<main>`/`<h1>`/`<p>`) is allowed and is *not* "raw HTML"; form·interactive elements and layout/visual inline `style` stay **hard-banned**. When `ui-*` **can't** express a screen, **stop and tell the user** + extend `ui-*` — never paper over the gap in `apps/*`.
  - **`packages/ui-*` (생산자)** — owns all visual styling; must comply with **both** design tokens (`var(--*)`) *and* the design-system doc; **CSS Modules (`*.module.css`) explicitly allowed in `ui-*`** (still pure CSS) alongside global `.css`.
- **Internal-consistency reconciliation (same file + `SKILL.md`)** — the soft "minimize" wording is preserved (not escalated to a ban); §5 `className` rule now scopes class composition as a **`ui-*`-internal** concern (apps don't pass `className` to override); the self-check checklist gains apps/*- and ui-*-tier items; the starter `apps/web/src/app/page.tsx` is annotated as an **intentional minimal placeholder**; CLAUDE.md summary, §3 의존 흐름, §4 기술 스택, §5 핵심 규칙, §10 금지사항 all updated to carry the pipeline + `ui-*`-only CSS-Modules allowance so no two lines contradict.
- **`skills/u-dev` (4.0.0 → 4.1.0)** — FE Step 1 gains rule #7: honor the `apps/* → ui-* → tokens` pipeline (project `DESIGN.md` §0 is the SSoT when present); when a screen needs UI `ui-*` can't express, extend `ui-*` or emit a `.state/build-gap-report.json` entry and **surface it to the user** for `/u-build` ping-pong — never silently emit raw HTML/inline style in `apps/*`.
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.21 → 4.0.0-alpha.22`.

## [4.0.0-alpha.20] — 2026-06-06

**Changed: `/u-createproject` now scaffolds a project-level `DESIGN.md` (디자인/UI 공통 룰), auto-loaded by both Claude Code (`@DESIGN.md` import) and Codex (`AGENTS.md` symlink).**

### Changed

- **`skills/u-createproject/SKILL.md` (1.1.0 → 1.2.0) + `references/scaffolding-spec.md`** — project scaffolding now generates a root **`DESIGN.md`** documenting the design/UI rules shared by every frontend app (`web`, `admin`). The template (§7, `{{PROJECT_NAME}}` substituted) is **adapted to the actually-scaffolded packages** — the source rules (written for a different `@hyunjin/ui-*` 3-app-group repo) were remapped to this scaffold's surfaces: `admin → @{{PROJECT_NAME}}/ui-backoffice (+ ui-common)`, `web → @{{PROJECT_NAME}}/ui-app (+ ui-common)`, `backend` UI-less; token references point at the real `@{{PROJECT_NAME}}/tokens` names (`var(--color-*|--spacing-*|--radius-*|--font-*|--shadow-*)`). Per the existing scaffold philosophy ("실제 스캐폴드된 구조만 기술 — 없는 컴포넌트를 강제하지 않음"), rules that would contradict the scaffold were reconciled rather than copied verbatim: the "no `className`/`style` prop" rule became "variations via `variant`/`size`/`tone` props; `className` only for token-based class composition" (matching the scaffolded `Button`); layout primitives (Container/Stack/Grid) are framed as "extract into `ui-common` when a pattern repeats" rather than mandated; `SSoT 우선` points at the flat `.u-maker/docs/` location. Wired into Step 1 (dir tree), Step 2 (root files #6/#7), and Step 10 (completion summary) so it lands in the first git commit (Step 6 `git add -A`).
- **Cross-agent auto-load wiring** — a standalone `DESIGN.md` is auto-discovered by *neither* Claude Code nor Codex, so it's now reliably reachable from both:
  - **Claude Code** — the CLAUDE.md template's 디자인시스템 section ends with a literal **`@DESIGN.md`** import line (Claude Code import syntax, max 4 hops), pulling DESIGN.md fully into context whenever the auto-loaded CLAUDE.md loads.
  - **Codex** — scaffolding now also creates **`AGENTS.md` as a symlink to `CLAUDE.md`** (`ln -s CLAUDE.md AGENTS.md`, after CLAUDE.md/DESIGN.md exist), since Codex auto-discovers `AGENTS.md` and does **not** read `CLAUDE.md`. Codex has no import syntax, so it reads DESIGN.md **on-demand** following the guide's "작업 전 DESIGN.md 반드시 참조" instruction. git tracks the symlink (Step 6 `git add -A`); Windows checkout needs `core.symlinks=true` (noted in §7 AGENTS.md).
- **`references/scaffolding-spec.md` — CLAUDE.md template** — the CLAUDE.md 디자인시스템 section is trimmed to a **pointer** to `DESIGN.md` (single source of truth), keeping a one-line summary; `DESIGN.md` in turn points back to `CLAUDE.md` for non-design rules. Avoids the two docs drifting. New `### AGENTS.md` subsection documents the symlink + cross-agent load behavior.
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.19 → 4.0.0-alpha.20`.

## [4.0.0-alpha.19] — 2026-06-05

**Added: `/u-reports-roadmap`. Removed: `/u-tools-jenkins-deploy` and `/u-meeting-report` skills.** Skill count 30 → 28 → 29.

### Added

- **`skills/u-reports-roadmap/`** — code-grounded interactive Gantt roadmap generator. Scans source code + git directly to scope the work (routes/screens, mock vs implemented, BE dependencies, branch/MR mining, churn), estimates a schedule from **measured git velocity modulated by team size** (dev/planner/designer counts — git-estimated then user-confirmed via `AskUserQuestion`), runs per-track **risk analysis**, and renders an **editable interactive Gantt HTML** in the reference roadmap style (vanilla CSS, light-only, draggable phase bars, milestone timeline, per-track positioning/highlights/risk notes, width switcher, localStorage autosave). Ships `assets/roadmap-template.html` (the reusable engine — copied then only its data block is edited; all calendar values derive from start+deadline via `buildTimeline()`) plus 4 references (scope-analysis, estimation-model, risk-analysis, html-template). Output: `.u-maker/reports/<date>/roadmap-<slug>-<deadline>.html` + sidecar `.data.json` for `--rerender`. Registered in `router.md`, `agents/u-agent-pm.md`, and `plugin.json` (dispatches to `u-agent-report`; prereq = source+git present).

### Removed

- **`skills/u-tools-jenkins-deploy/`** — Jenkins CI/CD setup skill removed. The `_meta/templates/u-maker-env.template` is slimmed accordingly: all Jenkins / Docker Hub / Git PAT / deploy-target SSH credential keys (consumed only by this skill) are dropped, leaving the `.u-maker/.env` scaffold header for future integrations. `/u-prepare-foldertree` still bootstraps `.u-maker/.env(.example)` from the (now-minimal) template.
- **`skills/u-meeting-report/`** — audio/text → meeting-minutes HTML skill removed.
- **References cleaned up** — removed routing entries from `skills/u-engine/references/router.md` (dispatch table, intent classification, skill map, prerequisites) and `agents/u-agent-pm.md`; updated `plugin.json` description (28 skills); removed command rows from `README.md` and the published HTML docs (`README.ko.html`, `README.en.html`, `GET_STARTED.html`). The deleted commands' history remains in earlier changelog entries (alpha.12).

## [4.0.0-alpha.18] — 2026-06-03

**Added: `/u-doc` (alias `/u-ssot`) — SSoT ingest + document reorganization. Changed: `/u-createproject` now scaffolds a project-specific `CLAUDE.md`.**

A new cross-cutting skill plus a scaffolding enhancement. Skill count 28 → 30.

### Added

- **`skills/u-doc/SKILL.md` (+ `references/ingest-rules.md`, `references/reorg-rules.md`)** — new two-mode SSoT helper.
  - **Ingest** — normalizes an arbitrary input (file / image / link / text) into `data/dropzone/`, reuses the `/u-analyze` digest pipeline (digest-engine), and **suggests** which app / SSoT doc / section it belongs to. Does **not** edit SSoT docs directly; actual document reflection stays with `/u-plan` · `/u-design` (chosen non-destructive policy). Figma sources auto-delegate to `/u-tools-figma`.
  - **Reorganize** — tidies `.u-maker/docs · output · reports` to the standard structure. Tree-aware: `docs/` (tracked SSoT) → `git mv` + `links.json` path sync; `output/` · `reports/` (gitignored, generated) → regenerate via `/u-output` · `/u-report` (no hand-move of artifacts). Always dry-run + confirm; never deletes.
  - Provides the previously-absent user entry point that `doc-engine.md` referenced as `/u-add` · `/u-update` (input side only — collection + placement suggestion).
- **`skills/u-ssot/SKILL.md`** — thin alias of `/u-doc` (mirrors the `/u-init` · `/u-check` · `/u-qa` stub pattern).

### Changed

- **`agents/u-agent-pm.md`** — registered `/u-doc` + `/u-ssot` in alias resolution (§1), the command routing table (§2), and global alias forwarding (§7, `/u-ssot → /u-doc`).
- **`skills/u-createproject/SKILL.md` (1.0.0 → 1.1.0) + `references/scaffolding-spec.md`** — project scaffolding now generates a project-specific **`CLAUDE.md`** agent guide (§7 template, `{{PROJECT_NAME}}` substituted), wired into Step 2 so it lands in the first git commit. The guide documents only the actually-scaffolded structure (web:3000 / admin:3001 / backend:2920, ui-common/ui-backoffice/ui-app, Clean Architecture, conventions, prohibitions). Also fixed the starter `page.tsx` inline-style padding (`.page-main` class) so the scaffold obeys the layout rule its own generated CLAUDE.md mandates.
- **`.claude-plugin/plugin.json`** — version `4.0.0-alpha.17 → 4.0.0-alpha.18`; description skill count 28 → 30, `/u-doc` + `/u-ssot` listed.

### Notes

- `/u-doc` Ingest is intentionally non-destructive (digest + placement suggestion only); it overlaps `/u-analyze` for digest generation and reuses that logic rather than reimplementing it.
- Reorganize `output/` ↔ `out/` root: `doc-engine.md` uses a legacy `out/` path for design-system while the standard is `output/`. The drift-detector treats both roots as valid and confirms before moving, to avoid false positives. Reconciling the source inconsistency is tracked separately.
- The `/u-doc` skill and the `/u-createproject` CLAUDE.md change are independent features and may ship as separate PRs.

## [4.0.0-alpha.17] — 2026-06-02

**Fixed: `deploy_local` — Windows install + duplicate skill symlinks.**

Maintenance release. No new commands or plugin-wide functional changes.

### Fixed

- **`deploy_local.bat`** — repaired Windows install: a `PATH` clobber and a `cmd` parenthesis parse error that broke the installer.
- **`deploy_local.sh`** — removed legacy `u-maker__*` skill symlinks that duplicated the plugin's own skill entries (see PR [#90](https://github.com/thinoo-v2/u-maker-plugin/pull/90)).

## [4.0.0-alpha.16] — 2026-05-24

**Changed: `/u-tools-git-pr` v5.1 — guaranteed clean working tree + table-based confirmation UI.**

Two refinements to the standalone PR generator skill. No new commands, no plugin-wide functional changes.

### Changed

- **`skills/u-tools-git-pr/SKILL.md` (v5.0.0 → v5.1.0)** — adds **Completeness Policy** at the top: the skill must terminate with `git status --porcelain` empty. `.gitignore`'d files are excluded automatically (git default — `--ignored` flag explicitly forbidden); `git add -A` / `git add .` forbidden in favor of per-group explicit file lists.
- **New Step 5.5: Verify Working Tree (safety net)** inserted between the group loop (Step 5) and the summary (Step 6). After the user-selected groups are processed, `git status --porcelain` is re-checked regardless of branch state. If files remain (e.g., partial `[3]` selection, unclassified paths on a feature branch with uncommitted local changes), a structured multiline-box prompt asks the user `[1] commit leftovers as misc PR (recommended)` or `[2] terminate with files retained`. The `misc` path creates a `chore/misc-leftover-{ts}` branch and re-verifies after commit. `--dry-run` shows the leftover count without executing.
- **Step 6 summary** now prints `Working tree clean ✓` when post-5.5 status is empty, or `Working tree has {N} uncommitted files (user-skipped)` when the user chose `[2]`.
- **`skills/u-tools-git-pr/references/confirmation-ux.md`** — full rewrite from ASCII-box prompts to a **table-based UI**. Groups now use `A`/`B`/`C` letter labels (consistent with the `3 A,B` partial-selection grammar). Stats line uses `M`/`A`/`D` shorthand; recommended strategy is surfaced inline. Adds an explicit **Edge cases** section (lone `Y` no longer auto-accepts; undefined labels re-prompt; single-group `3 ...` input re-confirms) and a `Dry-run summary` trace block aligned with the new Step 4 → Step 5 → Step 5.5 flow.

### Notes

- Partial-selection `[3] A,C` behavior changed: previously the unselected files were left in the working tree; now they are routed to Step 5.5 for misc-commit confirmation. Default policy is "no leftover files."
- Skill-level version bump only (`5.0.0 → 5.1.0` in skill frontmatter); plugin version follows the standard alpha increment.
- Feature-branch users with both committed-since-divergence changes **and** uncommitted local edits will now see the Step 5.5 sweep run unconditionally — surfacing the uncommitted files instead of silently leaving them.

## [4.0.0-alpha.15] — 2026-05-24

**Bugfix: plugin hook loader.** Restores reactive hooks that were silently failing to load since the Claude Code plugin hook schema migration. No user-facing functional changes; this only re-enables the four PostToolUse hooks that maintain `.u-maker/data/digest/_index.json`, doc↔JSON sync flags, loop-state thresholds, and deploy-staleness manifest.

### Fixed

- **`hooks/hooks.json`** — migrated from the legacy custom array format (`[{event, tool[], pattern, script, timeout(ms)}]`) to Claude Code's current plugin hook schema (event-keyed record with `matcher` + `command` shape). Single `PostToolUse` / `Write|Edit|MultiEdit` matcher routes all four hooks; timeouts converted ms → s. The plugin loader had been erroring at session start (`expected record, received array`), suppressing every hook.

### Added

- **`hooks/_dispatch.js`** — new shim that bridges Claude Code's stdin-JSON subprocess contract to the existing CommonJS hook modules (`on-dropzone-added.js`, `on-doc-change.js`, `on-gate-result.js`, `on-deploy-state.js`). Reads `tool_input.file_path` and `CLAUDE_PROJECT_DIR` from the hook payload, requires the legacy module, and invokes it with `({filePath, projectRoot})`. Always exits 0 — reactive hooks never block the agent. Per-hook path filtering inside each `on-*.js` is preserved unchanged.

### Notes

- Tested end-to-end via dispatcher: `on-dropzone-added` produces the expected `_index.json` (sha256 + status:pending) for a sample dropzone write. Mismatched path / empty stdin / non-matching tool name all exit 0 silently.
- No script bodies were modified — this release is purely a wiring fix.
- See PR [#89](https://github.com/thinoo-v2/u-maker-plugin/pull/89) for full diff and root-cause writeup.

## [4.0.0-alpha.14] — 2026-05-24

**Internal: CI/CD automation — Release + Vercel deploy GitHub Actions workflows.**

No user-facing plugin changes. Adds GitHub Actions to automate the release flow that previously required running `deploy_github.sh` + `deploy_vercel.sh` by hand. This is the first release executed end-to-end through the new pipeline.

### Added

- **`.github/workflows/release.yml`** — on `git push origin v*` (tag push): build `u-maker-plugin-${TAG}.zip` → GitHub Release on this repo (via `softprops/action-gh-release`) → force-sync README + HTML + install scripts to `upleat-ax/u-maker-plugin` → GitHub Release on the public repo with the same zip.
- **`.github/workflows/vercel-deploy.yml`** — on `main` push touching `README*.html` / `GET_STARTED.html` / `.claude-plugin/plugin.json` / the workflow file itself, plus manual `workflow_dispatch`: copy the 3 HTML docs + project link → `vercel pull` → `vercel deploy --prod` → curl-verify each public URL on `umaker.upleat.ai`.
- **`.github/AUTOMATION.md`** — maintainer guide covering both workflows, required secrets (`UPLEAT_PUBLISH_TOKEN`, `VERCEL_TOKEN`), the standard release flow after automation, the local fallback scripts, and what is still manual (CHANGELOG narrative, catalog table rows, SVG layer breakdown).

### Removed

- **`.github/workflows/publish.yml`** — superseded by `release.yml`. The old workflow only mirrored README + install scripts on tag push without building a zip or creating a Release.

### Notes

- Required secret `VERCEL_TOKEN` was added to repo settings; existing `UPLEAT_PUBLISH_TOKEN` is reused for the public-repo sync.
- Local scripts `deploy_github.sh` / `deploy_vercel.sh` remain as authoritative fallbacks; the workflows mirror their logic rather than extend it. Keep them in sync if you change the publishable file set.
- Post-automation standard release flow (see AUTOMATION.md):
  1. Edit `CHANGELOG.md` + bump `plugin.json` + sync README/HTML version strings.
  2. Open a PR, merge to main — `vercel-deploy.yml` refreshes `umaker.upleat.ai` automatically.
  3. `git tag -a vX.Y.Z` + `git push origin vX.Y.Z` — `release.yml` handles zip + both Releases + public-repo sync automatically.

## [4.0.0-alpha.13] — 2026-05-24

**Changed: 28-skill quality review fixes — sanitize, trigger hardening, progressive disclosure, Korean coverage, official-schema compliance.**

Comprehensive cleanup pass on all 28 skills following a multi-agent (5 reviewer) quality review. Touches every `skills/*/SKILL.md`, sanitizes `u-meeting-report/AGENTS.md`, and introduces 14 new `references/*.md` files for progressive disclosure. Plugin remains backward-compatible — no command renames, no behaviour changes; only documentation, frontmatter, and split-file organization.

### Fixed (Critical)

- **`skills/u-meeting-report/`** — frontmatter `name` was incorrectly `the-voice-meeting` (a separate system skill) → corrected to `u-meeting-report`. All 9 internal references to `~/.claude/skills/the-voice-meeting/...` (scripts, assets, `.env`) replaced with `${CLAUDE_PLUGIN_ROOT}/skills/u-meeting-report/...`. Removed `/Users/thinoo/...` absolute path leak from `AGENTS.md`. The plugin's bundled `scripts/`, `assets/`, and `references/` for this skill are now actually consumed; the plugin is standalone-portable.
- **`skills/u-wireframe/SKILL.md`** — frontmatter `version: 3.2.0` → `4.0.0` (matches all peer phase skills).

### Changed (High)

- **Generic trigger hijack mitigation (6 skills)** — replaced overly-broad triggers that intercepted unrelated input with `u-maker`/`Turborepo` prefix qualifiers:
  - `u-qa`: `"QA"` → `"u-maker QA"`, `"u-qa runtime QA"`
  - `u-init`: `"initialize"` → `"u-maker init"`, `"u-maker initialize project"`
  - `u-check`: `"check phase"` → `"u-maker check"`, `"u-maker gatekeeping check"`
  - `u-createproject`: Korean generic `"프로젝트 생성"`/`"새 프로젝트"`/`"모노레포 생성"` → `"u-maker 프로젝트 생성"`/`"Turborepo 모노레포 스캐폴드"` etc.
  - `u-loop`: `"auto loop"`/`"full pipeline"` → `"u-maker auto loop"`/`"u-maker full pipeline"`
  - `u-tools-browser`: added missing `"playwright"`, `"agent-browser"`, `"screenshot"`, `"visual regression"`, `"a11y audit"`, `"figma parity"` so DS verify / capture flows match correctly.
- **`skills/u-engine/SKILL.md`** — description rewritten as internal-only (`INTERNAL INFRASTRUCTURE — not directly invoked by users`) to prevent LLM auto-invocation. 50-line `HTML Generation Protocol` body collapsed into pointer to existing `references/html-engine.md`. 110 → 68 lines.
- **Progressive disclosure refactor (6 large skills → 14 new `references/*.md`)** — total 2,050 → 1,339 lines (-35%):

  | Skill | Before | After | Δ | new refs |
  |---|---:|---:|---:|---:|
  | `u-tools-browser` | 501 | 305 | -39% | 4 (`backend-detection`, `visual-verify-ds`, `visual-verify-components`, `failure-handling`) |
  | `u-prepare-foldertree` | 285 | 126 | -56% | 2 (`foldertree-layout`, `migration-rules`) |
  | `u-output` | 286 | 175 | -39% | 2 (`screens-rendering`, `erd-rendering`) — folder newly created |
  | `u-tools-jenkins-deploy` | 365 | 309 | -15% | 3 (`credentials`, `nginx-tls`, `jenkins-gotchas`) |
  | `u-tools-git-pr` | 301 | 189 | -37% | 2 (`classification-rules`, `confirmation-ux`) |
  | `u-wireframe` | 312 | 235 | -25% | 1 (`wireframe-rendering-rules`) |

### Added

- **Korean trigger coverage** — 22 skills enriched. 26/28 skills are now Korean-searchable in addition to English (e.g., `"u-maker 기획"`, `"와이어프레임 생성"`, `"u-maker 배포"`, `"피그마 분석"`). `u-engine` is internal-only by design; `u-meeting-report` is covered via description-only Korean keywords.

### Changed (Frontmatter standardization)

- **All 26 skills** with a non-standard `triggers:` array migrated to the **official Claude Code schema** (`name`/`description`/`version` only). Every trigger keyword (English + Korean) was preserved by integrating them into `description` as quoted strings, matching the convention of all 5 official `plugin-dev/*` skills. Max resulting description length: 637 chars (`u-tools-browser`). This guarantees skill matching works even if the runtime ignores the non-spec `triggers:` field. `u-engine` and `u-meeting-report` were already description-only.

### Notes

- File stats: 43 files changed in PR #85, +1,118 / −1,019.
- Smoke test (manual, post-merge): in a fresh Claude Code session, type `/u-` to confirm all 28 skills autocomplete without duplicates, and try Korean phrases (`"u-maker 기획"`, `"와이어프레임 생성"`, `"회의록 작성"`) to confirm description-only matching.
- No migration required for existing projects — only documentation/frontmatter changed; no command renames or behavior changes.

## [4.0.0-alpha.12] — 2026-05-23

**Added: `.u-maker/.env` credential file + `/u-tools-jenkins-deploy` skill.**

Introduces a project-local credential file at `.u-maker/.env` (gitignored) for skills that need to authenticate to external systems, and ports the `u-tools-jenkins-deploy` skill into the plugin as the inaugural consumer.

### Added

- **`_meta/templates/u-maker-env.template`** — `.env.example` content. Enumerates credential keys consumed by skills: Jenkins (`JENKINS_URL`/`JENKINS_USER`/`JENKINS_TOKEN`, plus optional `JENKINS_SSH_*`), Docker Hub (`DOCKERHUB_NAMESPACE`/`DOCKERHUB_USER`/`DOCKERHUB_TOKEN`), Git host PAT (`GIT_HOST_USER`/`GIT_HOST_PAT`), and deploy-target SSH (`DEPLOY_TARGET_HOST`/`DEPLOY_TARGET_USER`/`DEPLOY_TARGET_PASS`/`DEPLOY_TARGET_PORT`). Empty values mean "ask interactively when needed."
- **`/u-prepare-foldertree` Step 1.5.1** — On fresh init, writes `.u-maker/.env.example` and bootstraps `.u-maker/.env` from the template (never overwrites an existing `.env`). Migration path (Step 2.3) does the same for legacy projects.
- **`/u-prepare-foldertree` Step 1.7** — Adds `.u-maker/.env` to the project `.gitignore` so secrets never land in git. `.env.example` is committed.
- **`skills/u-tools-jenkins-deploy/`** (new) — Jenkins CI/CD setup skill ported from `~/.claude/skills/u-maker__u-tools-jenkins-deploy/`. Same Phase 1–8 pipeline (Jenkinsfile generation → credential registration → job creation → nginx + TLS → webhook/polling → first build) plus a new **Phase 0** that loads `.u-maker/.env` and resolves Jenkins/Docker Hub/Git/target-SSH credentials before prompting. Precedence: CLI flag → `.u-maker/.env` → interactive prompt. Templates (`Jenkinsfile`, `Dockerfile`, `Dockerfile.dockerignore`, `nginx-server-block`) ship under `templates/`.

### Why

Without `.u-maker/.env`, every Jenkins / Docker Hub / SSH setup forced the user to paste tokens and passwords directly into chat — captured in transcripts, easily leaked, and re-asked on every session. A project-local, gitignored env file lets users set credentials once and have skills consume them on demand. The `/u-tools-jenkins-deploy` skill is the first consumer; subsequent skills can extend the same file rather than each inventing their own location.

### Notes

- `.u-maker/.env.example` is committed verbatim from `_meta/templates/u-maker-env.template`. Adding a new key for another skill = edit the template; future `/u-prepare-foldertree` runs propagate it to new projects.
- Existing projects pick up the file on the next `/u-prepare-foldertree --migrate` (or any rerun — Step 2.3 is idempotent).

## [4.0.0-alpha.5] — 2026-04-19

**Changed: Figma parity is now a mandatory hard gate.**

When a Design System originated from Figma (extracted via `/u-tools-figma-ds` or registered with `dsFileKey` in `data/figma/manifest.json`) and is implemented as HTML/CSS, the browser MUST verify identity with Figma. Previously this was an opt-in pixel diff; now it is a non-skippable parity check that blocks `/u-design` and `/u-dev` from completing on failure.

### Changed

- `/u-tools-browser` Step 6e (DS HTML Verification) — added sub-step **6e.8 Figma parity check (mandatory)**:
  - Pulls Figma reference screenshots via `mcp__plugin_figma_figma__get_screenshot` and Variable defs via `get_variable_defs`.
  - Token parity: every Figma Variable mapped to a CSS variable must match (color ΔE < 1 in OKLCH; dimensions ±0.5 px).
  - Per-frame screenshot diff: SSIM ≥ 0.95 AND pixel diff ≤ 5 %.
  - Coverage parity: every Figma component ↔ every `CMP-{nnn}` in the HTML.
  - Unauthenticated Figma session → HALT (never silent skip). Override with `--no-figma-parity` (logged).
  - `result` rules tightened: any parity failure forces top-level `result == "fail"` (cannot be downgraded to `partial`).
- `/u-tools-browser` Step 6f (Component Verification) — Figma diff promoted from "optional" to **mandatory** when `components[*].figmaKey` is set:
  - Per-variant / per-state pixel diff (SSIM ≥ 0.95, pixel diff ≤ 5 %, bounds ±2 px).
  - Token resolution parity against Figma Variable bindings.
  - Same HALT-on-unauthenticated rule as Step 6e.
- `/u-tools-browser` Options — added `--no-figma-parity`, `--figma-diff-threshold {pct}` (default 5), `--figma-ssim-threshold {0..1}` (default 0.95).
- `/u-tools-browser` Anti-patterns — explicit prohibitions: silently skipping parity, downgrading parity failure to `partial`, try/catch-ing the parity check away.
- `/u-design` Step 4a.10 — promoted to **hard gate**. On parity `fail`, re-runs Steps 4a.3–9 (max 3 retries); never proceeds to Step 4b without parity pass. `partial` allowed only for non-parity issues.
- `/u-dev` Step 1.5 — promoted to **hard gate**. On parity `fail`, re-runs Step 1 for failing components only (max 3 retries); never proceeds to Step 2 (BE) without parity pass.

### Rationale

When the user describes the workflow as "extract DS from Figma → implement in HTML/CSS → verify identical", the browser is the only authority that can confirm "identical". Anything weaker (token-only diff, manual review) misses CSS specificity, browser rendering quirks, and unbound hardcoded values. Making the gate mandatory ensures the implemented DS cannot ship with silent visual drift from its Figma source.

### Added

- `--no-figma-parity` flag for explicit, audited overrides (e.g., when intentionally diverging).
- Per-component diff PNG triplets (figma / impl / diff) under `.u-maker/.state/visual-verify/diffs/`.

## [4.0.0-alpha.4] — 2026-04-19

**Added: Browser-driven visual verification for HTML-first DS and implemented components.**

After `/u-design` Step 4a writes `out/{app}/design/design-system.html` and after `/u-dev` Step 1 generates FE components, the browser now verifies them automatically — no manual "open the file and look" loop.

### Added

- `/u-tools-browser` Step 6e — **Design System HTML Verification**. Opens the static `design-system.html` via `file://`, samples every `:root` CSS variable, asserts every `CMP-{nnn}` showcase + variant + state selector is present, toggles `[data-theme="dark"]`, runs a Lighthouse / axe-core a11y audit, and captures full-page light + dark screenshots. Result persisted at `.u-maker/.state/visual-verify/{app}-design-system.json`.
- `/u-tools-browser` Step 6f — **Component Implementation Verification**. Renders each `CMP-{nnn}` in Storybook (preferred) or the app, samples computed styles, asserts variant/state selectors, optionally pixel-diffs against the linked Figma component (when `figmaKey` is set), runs per-subtree a11y audit. Result at `.u-maker/.state/visual-verify/{app}-components.json`.

### Wired

- `/u-design` Step 4a.10 — auto-delegates to `/u-tools-browser` Step 6e after `design-system.html` is written. On `result == "fail"` (missing tokens, broken dark mode, WCAG-AA contrast violation), re-runs Steps 4a.3–9 with the diff as improvement list (max 3 retries).
- `/u-dev` Step 1.5 — auto-delegates to `/u-tools-browser` Step 6f after FE components are generated. On `result == "fail"`, re-runs Step 1 for failing components only (max 3 retries). Skipped when `--only be|db` or zero FE files changed.
- `/u-tools-browser` Consumer Integration Table — two new rows for the 6e / 6f entries.

### Notes

- Both verifications are **mandatory** under default mode (`--auto` runs them headless). The `--no-screenshot` flag suppresses captures but still runs the assertions.
- The Figma diff sub-step in 6f is **opt-in** — only runs when `mcp__plugin_figma_figma__get_screenshot` is reachable AND `components[*].figmaKey` is populated by `/u-tools-figma-ds`.

## [4.0.0-alpha.3] — 2026-04-19

**Added: Figma writer skills.**

Adds two new write-side skills under the `u-tools-*` namespace, complementing the existing read-only `/u-tools-figma` analyzer. Both delegate Figma mutations to the `figma` plugin (`figma:figma-generate-design`, `figma:figma-generate-library`) so u-maker stays as the orchestration layer.

### Added

- `/u-tools-figma-screen` — Screen-spec writer. Inputs: (Figma URL │ `screens.{md,json}`) + (Figma DS URL │ `design-system.{md,json,tsx,css}`). Outputs: Figma frames, `screens.md+json`, or both. Source-resolution matrix, conflict log under `.u-maker/.state/figma-screen-conflicts.json`, idempotent `--rerun` via persisted bundles. References: `source-resolution.md`, `conflict-resolution.md`, `delegation-bundle.md`.
- `/u-tools-figma-ds` — Code → Figma design-system writer. Input: `.tsx + .json + .css` (W3C tokens / Style Dictionary / CSS custom properties / Tailwind config). Output: Figma Variables (3 layers, light/dark modes, 10 scales) + master components + variants. References: `token-extraction.md`, `component-extraction.md`, `delegation-bundle.md`.

### Wired

- `/u-plan` Step 2.5 — auto-delegates to `/u-tools-figma-screen --output md` when both a screen-plan source and a design-system source are detected after IA generation. Pre-populates `screens.{md,json}` so `/u-design` Step 3 verifies-and-finalises instead of generating from scratch.
- `/u-analyze` Step 2.4 — auto-delegates to `/u-tools-figma-ds` when DS-applied source code (token files, `packages/tokens`, `packages/ui-*`) is detected in dropzone. Falls back to `--dry-run` when Figma is unauthenticated; bundle persisted for later replay.
- `/u-design` Step 4.5 — opt-in outbound sync to Figma for both screens (`/u-tools-figma-screen --output figma --prefer md`) and DS (`/u-tools-figma-ds`). Doc completion never blocks on Figma availability.

### Changed

- `.claude-plugin/plugin.json` — version `4.0.0-alpha.2` → `4.0.0-alpha.3`; skill count 25 → 27; description updated to mention the writer skills.
- README.md, README.ko.html, README.en.html, GET_STARTED.html — `u-tools-*` tables expanded with the two new entries.

### Removed

- `u-maker__u-ocean-wireframe2figma` — separately-installed legacy skill removed from `~/.claude/skills/` (the new u-tools-figma-screen replaces it).

## [4.0.0-alpha.1] — 2026-04-18

**Breaking change: PDCA → PBGD workflow migration.**

The plugin has been restructured from a 5-phase PDCA pipeline (Plan / Design / Dev / Check / Ship) to a 4-phase PBGD pipeline (Plan / Build / Gatekeeping / Deploy). This is a breaking change; follow the migration steps below when upgrading a v3.x project.

### Phase restructuring

| v3.x (PDCA) | v4.0 (PBGD) | Notes |
|-------------|-------------|-------|
| Plan (Steps 1–2: dropzone + digest) | `Plan.Prepare` (new) | Extracted into `/u-prepare` umbrella and `/u-analyze` skill |
| Plan (Steps 3–5: SRS + IA) | `Plan.Plan` | `/u-plan` scope narrowed to SRS/IA generation |
| (implicit) Wireframe | `Build.UIDesign` companion | `/u-wireframe` now prompted explicitly post-Plan (time-consuming) |
| Design | `Build.UIDesign` | Same doc outputs; new phase metadata |
| Dev | `Build.Development` | Same code outputs; new phase metadata |
| (implicit) Ping-pong | `Build` (umbrella) | New `/u-build` orchestrator with design↔dev ping-pong |
| Check | `Gatekeeping` | Renamed; now explicitly covers doc scoring + runtime QA |
| Ship | `Deploy` (new, expanded) | New `/u-deploy` with interactive target + artifact selection |

### Added

- `/u-prepare` — Preparation umbrella (foldertree + dropzone + analyze/reverse + 요구사항 협의).
- `/u-analyze` — Discrete dropzone → digest analysis skill (extracted from `/u-plan` Steps 1–2).
- `/u-build` — Build-phase orchestrator (design ↔ dev ping-pong).
- `/u-deploy` — Deploy-phase skill (interactive target + artifact selection, ≥ 98 gate, continuous regeneration).
- `/u-tools-figma` — Comprehensive Figma analyzer skill (pages + variants + assets + components + comments, semantic extraction). Auto-delegated from `/u-prepare`, `/u-analyze`, `/u-reverse`, `/u-design` on Figma sources. **Note:** v4.0.0-alpha.1 ships the reduced extraction path; full 6-phase pipeline (schema-strict manifest + 4-source variant detection) scheduled for the first post-GA release. Downstream consumers must tolerate `source.pipeline == "reduced"` digests (see `agents/u-agent-figma.md` §10).
- `u-agent-build` — Build-phase orchestrator agent.
- `u-agent-deploy` — Deploy-phase agent.
- `u-agent-figma` — Figma analyzer agent (reduced path in alpha).
- `_meta/schemas/deploy-manifest.schema.json` — Deploy manifest authoritative schema.
- `_meta/templates/{deploy-runbook,ci-github-actions,ci-vercel,ci-docker,env,release-notes,smoke-test}` — Deploy-phase templates.
- `hooks/on-deploy-state.js` — Continuous regeneration: marks deploy artifacts stale on SSoT drift.
- `.state/deploy-readiness.json` — Written by Gatekeeping after every run; read by Deploy as gate input.
- Schema additions: `workflow.phases` in config, `deployThreshold: 98` in gate-rules, phase/sub-phase enums in doc-companion and links.

### Renamed

- `skills/u-init/` → `skills/u-prepare-foldertree/` (granular `.u-maker` scaffolding only).
- `skills/u-check/` → `skills/u-gatekeeping/` (covers doc scoring + runtime QA).
- Output path: `docs/{app}/check/` → `docs/{app}/gatekeeping/` (migration handled by `/u-prepare-foldertree --migrate`).

### Alias layer (backward-compat)

- `/u-init` is now an **alias** of `/u-prepare` (the umbrella).
- `/u-check` is now an **alias** of `/u-gatekeeping`.
- `/u-qa` is now an **alias** of `/u-gatekeeping --only qa`.

Alias SKILL.md files print a one-line forwarding notice and route to the canonical command.

### Changed

- `/u-plan` scope narrowed: dropzone scanning + digest generation moved to `/u-analyze`. `/u-plan` now requires `data/digest/` to be populated.
- `u-agent-plan` now owns both Preparation sub-phase (via `/u-prepare`) and Plan sub-phase (via `/u-plan`).
- `u-agent-qa` renamed scope: Runtime QA sub-phase of Gatekeeping (formerly Check phase).
- `u-agent-gatekeeper` now emits `.state/deploy-readiness.json` after every run with both `passThreshold` (95) and `deployThreshold` (98) status.
- `u-agent-pm` rewritten with PBGD state machine + transition guards + alias resolution table.
- `u-loop` rewritten for PBGD sequence (Prepare → Plan → Build → Gatekeeping → Deploy) with `--skip-deploy` option.
- `hooks/on-gate-result.js` emits deploy-readiness regardless of loopActive state.
- `.claude-plugin/plugin.json`: version bumped; description and keywords updated for PBGD.

### Removed / Deprecated

- `skills/u-plan/references/ingest-flow.md` deleted — content moved to `skills/u-analyze/references/digest-extraction.md` and `analysis-rules.md`.
- `x-deprecated-pdca` block in `gate-rules.json` documents the retired PDCA gate names (no runtime effect).

### Migration checklist for v3.x projects

1. Back up `.u-maker/` (automatic via `/u-prepare-foldertree --migrate`).
2. Run `/u-prepare-foldertree --migrate` on the project root to rename `docs/{app}/check/` → `docs/{app}/gatekeeping/` and update `u-maker.config.json` to v4.0 schema.
3. Re-run `/u-analyze` if your dropzone state was mid-analysis before the upgrade.
4. Any custom scripts referencing `/u-init`, `/u-check`, `/u-qa` continue to work (aliases). Update to canonical names at your leisure.
5. Any custom tooling referencing `docs/{app}/check/` must be updated to `docs/{app}/gatekeeping/`.

---

## [3.4.10] — 2026-04-18

Final PDCA release. See git history for details.
