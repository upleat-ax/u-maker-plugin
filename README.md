# UMAKER Plugin v4.1.0-alpha.1

PBGD-based SSoT (Single Source of Truth) plugin for Claude Code.

Drop planning materials, and it automatically performs Preparation → Plan → Build → Gatekeeping → Deploy.

**29 Skills** (incl. 3 aliases) · **10 Agents** · **4 PBGD Phases** (Plan · Build · Gatekeeping · Deploy) · **12 Gate Criteria** (11 doc-quality via `--loop [N]`, default 5 · + GK-12 Design Conformance, Figma/reference ↔ implementation pixel-perfect) · **Pass ≥ 95** · **Deploy-gate ≥ 98**

## Architecture: skills server (v4.1+) — 한국어

v4.1부터 umaker는 **스킬 정의(frontmatter)와 스킬 본문(body)을 분리**합니다.

- **이 플러그인**에는 각 `um-*` 스킬의 **frontmatter(트리거/설명)만** 담긴 스텁 `SKILL.md`가 들어 있습니다.
- **스킬 본문과 참조 자료(`references/*`, `_meta/*` 템플릿·스키마)**는 **u-maker terminal 앱에 내장된 skills server**가 HTTP로 제공합니다.
  - 기본 주소: `http://127.0.0.1:8765`
  - 디스커버리 파일: `~/.config/u-maker/skills-server.json` (`baseUrl`/`port` 확인)
- 따라서 `um-*` 스킬을 실행하려면 **u-maker terminal 앱이 실행 중이어야 합니다.** 앱이 꺼져 있으면 스킬 스텁이 본문을 가져오지 못해 실행이 실패합니다.
- 스킬 실행 흐름: 스텁이 `skills-server.json`에서 `baseUrl`을 읽고 (없으면 `http://127.0.0.1:8765` 폴백) → `{baseUrl}/skills/um-<name>/SKILL.md`를 가져와 본문을 실행하며, `references/*`·`_meta/*`도 같은 base로 해석합니다.

## Documentation

| Language | Link |
|----------|------|
| 한국어 | [README (Korean)](https://umaker.upleat.ai/README.ko.html) |
| English | [README (English)](https://umaker.upleat.ai/README.en.html) |
| 시작하기 | [GET STARTED](https://umaker.upleat.ai/GET_STARTED.html) |

## Quick Start (PBGD)

```bash
# Install
claude plugin add upleat-ax/umaker-plugin

# A. 새 프로젝트를 처음부터 시작할 때 → /um-createproject
/um-createproject my-app          # Turborepo+Bun 모노레포 스캐폴딩 + /um-prepare 자동 실행

# B. 기존 프로젝트 또는 맨손으로 시작할 때 → /um-prepare (or /um-init alias)
/um-prepare my-app                # foldertree + dropzone + analyze (or reverse) + 요구사항 협의

# Core pipeline
/um-plan [app]                    # Plan: SRS + IA
/um-wireframe [app]               # (optional) per-screen HTML wireframes
/um-build [app]                   # Build: Design (ERD/API/Screens/DS) ↔ Dev (FE/BE/DB) orchestrator
/um-gatekeeping [app]             # Gatekeeping: doc scoring + runtime QA
/um-deploy [app]                  # Deploy: interactive target + artifact selection (≥ 98 gate)

# Or run everything unattended:
/um-loop [app]
```

### Command aliases (backward-compat)

| Alias | Routes to |
|-------|-----------|
| `/um-init` | `/um-prepare` |
| `/um-check` | `/um-gatekeeping` |
| `/um-qa` | `/um-gatekeeping --only qa` |
| `/um-ssot` | `/um-doc` |

### Granular commands inside Preparation

| Command | Role |
|---------|------|
| `/um-prepare-foldertree` | `.u-maker/` folder/state scaffolding only |
| `/um-analyze` | Dropzone → digest |
| `/um-reverse` | Reverse-engineer existing code → digest |

### SSoT ingest & document management

Cross-cutting SSoT document utilities — not bound to a phase, callable any time.

| Command | Role |
|---------|------|
| `/um-doc` (`= /um-ssot`) | **Ingest** — normalize a file/image/link/text into `data/dropzone/`, generate a digest, and suggest placement (does *not* edit SSoT docs directly). **Reorg** (`--reorg`) — move/rename misplaced `docs/` files (git mv + `links.json`) and regenerate `output/` + `reports/` |

### External-tool skills (`um-tools-*`)

Wrappers around external programs/services. All umaker phase skills route through these instead of calling the underlying tools directly.

| Command | External tool | Used by |
|---------|--------------|---------|
| `/um-tools-figma` | Figma API / Plugin (read-only analyzer) | `/um-prepare`, `/um-analyze`, `/um-reverse`, `/um-design` (auto-delegated on Figma sources) |
| `/um-tools-figma-screen` | `figma:figma-generate-design` (writer) | `/um-plan` Step 2.5 (auto), `/um-design` Step 4.5 (opt-in), `/um-build` (gap-fill) |
| `/um-tools-figma-ds` | `figma:figma-generate-library` (writer) | `/um-analyze` Step 2.4 (auto on DS code), `/um-design` Step 4.5 (opt-in) |
| `/um-tools-browser` | agent-browser CLI → Playwright MCP → chrome-devtools MCP | `/um-gatekeeping` (E2E), `/um-report-weekly` (capture), `/um-dev --verify`, `/um-wireframe --preview` |
| `/um-tools-git-pr` | git + `gh` CLI + GitHub API | Standalone PR generator — intelligent grouping + **v5.1 Completeness Policy** (guarantees `git status` clean; `.gitignore`'d files excluded) + table-based confirmation UI |

### Rule packs (external reference integrations)

Authoritative rule sets applied automatically during code/design generation.

| Rule pack | Source | Applied in |
|-----------|--------|-----------|
| `fe-rules.md` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) — react-best-practices (70) + composition-patterns (9) | `/um-dev` Step 1 (FE generation) |
| `design-system-rules.md` | [dylantarre/design-system-skills](https://github.com/dylantarre/design-system-skills) — 28 skills (tokens, patterns, a11y, frameworks, tools, docs) | `/um-design` Step 4 (DS HTML-first), `/um-build` Step 3 (ping-pong gap routing) |
| Browser engine | [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) — `test-browser` pattern | `/um-tools-browser` 9-step protocol |

### Reporting & roadmap

Cross-cutting output skills (HTML reports). All render under `.u-maker/reports/`.

| Command | Role |
|---------|------|
| `/um-output` (`= /um-html`) | Existing docs (`.md` + `.json`) → HTML output |
| `/um-report-daily` | Daily report — git + meetings + stats |
| `/um-report-weekly` | Weekly report — per-app FR/US/FT/TC/SC trends + charts |
| `/um-reports-roadmap` | Code+git → interactive editable Gantt roadmap (scope analysis + team-capacity estimate + risk analysis) in the reference roadmap style |

## PBGD Phases

| Phase | Sub-phases | Skills | Gates |
|-------|-----------|--------|-------|
| **Plan** | Prepare (foldertree + dropzone + analyze/reverse + 요구사항) ↔ Plan (SRS + IA + optional wireframe) | `um-prepare`, `um-prepare-foldertree`, `um-analyze`, `um-reverse`, `um-plan`, `um-wireframe` | SRS + IA Final |
| **Build** | UI Design ↔ Development | `um-build`, `um-design`, `um-dev` | Design docs Final + code-complete |
| **Gatekeeping** | Doc Scoring + Runtime QA | `um-gatekeeping` (+ aliases `um-check`, `um-qa`) | Pass ≥ 95 · Deploy-gate ≥ 98 |
| **Deploy** | CI/CD | `um-deploy` | Interactive target + artifacts, continuous regeneration |

## Migrating from v4.0 (u-maker)

- Plugin renamed `u-maker` → `umaker`; every skill `/u-*` → `/um-*`; agents `u-agent-*` → `um-agent-*`.
- Skill bodies moved out of this repo into the u-maker terminal app's embedded skills server (see the Architecture section above). `_meta/` templates/schemas are vendored into the terminal app as well.
- Per-project data is unchanged: `.u-maker/` directories, `U_MAKER_*`/`UMAKER_*` environment variables, and doc structures all keep working as-is.
- Install scripts clean up legacy `u-maker` artifacts (`u-maker__*` symlinks, `cache/u-maker`, `u-maker@u-maker` registry entries) automatically on upgrade.

## Migrating from v3.x (PDCA)

- `Plan → Design → Dev → Check → Ship` has been replaced by `Plan → Build → Gatekeeping → Deploy`.
- `u-init` renamed to `um-prepare-foldertree`; new `um-init` is an alias of `/um-prepare`.
- `u-check` renamed to `um-gatekeeping`; `/um-check` remains as alias.
- `um-deploy` is NEW (was implicit in "Ship").
- Doc output paths for Gatekeeping moved from `docs/{app}/check/` to `docs/{app}/gatekeeping/`; `/um-prepare-foldertree --migrate` handles the rename on v3→v4 upgrade.

See [CHANGELOG.md](./CHANGELOG.md) for full migration details.

## License

Proprietary - Copyright (c) 2026 U PLEAT
