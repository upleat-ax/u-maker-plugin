# U-MAKER Plugin v4.0.0-alpha.10

PBGD-based SSoT (Single Source of Truth) plugin for Claude Code.

Drop planning materials, and it automatically performs Preparation → Plan → Build → Gatekeeping → Deploy.

**27 Skills** (incl. 3 aliases) · **10 Agents** · **4 PBGD Phases** (Plan · Build · Gatekeeping · Deploy) · **11 Gate Criteria** (configurable via `--loop [N]`, default 5) · **Pass ≥ 95** · **Deploy-gate ≥ 98**

## Documentation

| Language | Link |
|----------|------|
| 한국어 | [README (Korean)](https://umaker.upleat.ai/README.ko.html) |
| English | [README (English)](https://umaker.upleat.ai/README.en.html) |
| 시작하기 | [GET STARTED](https://umaker.upleat.ai/GET_STARTED.html) |

## Quick Start (PBGD)

```bash
# Install
claude plugin add upleat-ax/u-maker-plugin

# A. 새 프로젝트를 처음부터 시작할 때 → /u-createproject
/u-createproject my-app          # Turborepo+Bun 모노레포 스캐폴딩 + /u-prepare 자동 실행

# B. 기존 프로젝트 또는 맨손으로 시작할 때 → /u-prepare (or /u-init alias)
/u-prepare my-app                # foldertree + dropzone + analyze (or reverse) + 요구사항 협의

# Core pipeline
/u-plan [app]                    # Plan: SRS + IA
/u-wireframe [app]               # (optional) per-screen HTML wireframes
/u-build [app]                   # Build: Design (ERD/API/Screens/DS) ↔ Dev (FE/BE/DB) orchestrator
/u-gatekeeping [app]             # Gatekeeping: doc scoring + runtime QA
/u-deploy [app]                  # Deploy: interactive target + artifact selection (≥ 98 gate)

# Or run everything unattended:
/u-loop [app]
```

### Command aliases (backward-compat)

| Alias | Routes to |
|-------|-----------|
| `/u-init` | `/u-prepare` |
| `/u-check` | `/u-gatekeeping` |
| `/u-qa` | `/u-gatekeeping --only qa` |

### Granular commands inside Preparation

| Command | Role |
|---------|------|
| `/u-prepare-foldertree` | `.u-maker/` folder/state scaffolding only |
| `/u-analyze` | Dropzone → digest |
| `/u-reverse` | Reverse-engineer existing code → digest |

### External-tool skills (`u-tools-*`)

Wrappers around external programs/services. All u-maker phase skills route through these instead of calling the underlying tools directly.

| Command | External tool | Used by |
|---------|--------------|---------|
| `/u-tools-figma` | Figma API / Plugin (read-only analyzer) | `/u-prepare`, `/u-analyze`, `/u-reverse`, `/u-design` (auto-delegated on Figma sources) |
| `/u-tools-figma-screen` | `figma:figma-generate-design` (writer) | `/u-plan` Step 2.5 (auto), `/u-design` Step 4.5 (opt-in), `/u-build` (gap-fill) |
| `/u-tools-figma-ds` | `figma:figma-generate-library` (writer) | `/u-analyze` Step 2.4 (auto on DS code), `/u-design` Step 4.5 (opt-in) |
| `/u-tools-browser` | agent-browser CLI → Playwright MCP → chrome-devtools MCP | `/u-gatekeeping` (E2E), `/u-report-weekly` (capture), `/u-dev --verify`, `/u-wireframe --preview` |
| `/u-tools-git-pr` | git + `gh` CLI + GitHub API | Standalone PR generator with intelligent grouping |

### Rule packs (external reference integrations)

Authoritative rule sets applied automatically during code/design generation.

| Rule pack | Source | Applied in |
|-----------|--------|-----------|
| `fe-rules.md` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) — react-best-practices (70) + composition-patterns (9) | `/u-dev` Step 1 (FE generation) |
| `design-system-rules.md` | [dylantarre/design-system-skills](https://github.com/dylantarre/design-system-skills) — 28 skills (tokens, patterns, a11y, frameworks, tools, docs) | `/u-design` Step 4 (DS HTML-first), `/u-build` Step 3 (ping-pong gap routing) |
| Browser engine | [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) — `test-browser` pattern | `/u-tools-browser` 9-step protocol |

## PBGD Phases

| Phase | Sub-phases | Skills | Gates |
|-------|-----------|--------|-------|
| **Plan** | Prepare (foldertree + dropzone + analyze/reverse + 요구사항) ↔ Plan (SRS + IA + optional wireframe) | `u-prepare`, `u-prepare-foldertree`, `u-analyze`, `u-reverse`, `u-plan`, `u-wireframe` | SRS + IA Final |
| **Build** | UI Design ↔ Development | `u-build`, `u-design`, `u-dev` | Design docs Final + code-complete |
| **Gatekeeping** | Doc Scoring + Runtime QA | `u-gatekeeping` (+ aliases `u-check`, `u-qa`) | Pass ≥ 95 · Deploy-gate ≥ 98 |
| **Deploy** | CI/CD | `u-deploy` | Interactive target + artifacts, continuous regeneration |

## Migrating from v3.x (PDCA)

- `Plan → Design → Dev → Check → Ship` has been replaced by `Plan → Build → Gatekeeping → Deploy`.
- `u-init` renamed to `u-prepare-foldertree`; new `u-init` is an alias of `/u-prepare`.
- `u-check` renamed to `u-gatekeeping`; `/u-check` remains as alias.
- `u-deploy` is NEW (was implicit in "Ship").
- Doc output paths for Gatekeeping moved from `docs/{app}/check/` to `docs/{app}/gatekeeping/`; `/u-prepare-foldertree --migrate` handles the rename on v3→v4 upgrade.

See [CHANGELOG.md](./CHANGELOG.md) for full migration details.

## License

Proprietary - Copyright (c) 2026 U PLEAT
