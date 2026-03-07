---
document: "3_Code_DV"
title: "u-maker Plugin Code Record"
owner: "u-DV-FE"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/common/02-design/2_ERD_SA.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/web/04-check/4_Case_QA.md"
external_links: []
---

# u-maker Plugin Code Record

- **Owner**: u-DV-FE
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [ERD](../../common/02-design/2_ERD_SA.md), [API Contract](../02-design/2_API_SA.md), [Screen Design](../02-design/2_Screen_UX.md), [QA Cases](../04-check/4_Case_QA.md)

## 1. Repository Structure

| Path | Purpose |
|---|---|
| `.claude-plugin/` | plugin metadata |
| `skills/` | user-invocable skill definitions |
| `agents/` | specialist agent instructions |
| `hooks/` | session/start/stop integration |
| `scripts/` | validation, init, guard, state save |
| `lib/` | state, gate, doc tracking logic |
| `templates/` | SSoT templates |
| `_refer/` | policy/reference docs |

## 2. File Mapping

### 2.1 Feature -> Code

| Feature | Primary Files |
|---|---|
| FT-0010 Local Deploy Flow | `deploy_local.sh`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` |
| FT-0020 Existing Repo Init | `skills/u-skill-init/SKILL.md`, `.u-maker/u-maker.config.json`, `.u-maker/docs/**` |
| FT-0030 Phase Skill Catalog | `skills/u-skill-*/SKILL.md`, `agents/*.md` |
| FT-0040 Prompt Guard | `scripts/prompt-docs-first-guard.js`, `scripts/pre-write-guard.js` |
| FT-0050 SSoT Validation | `scripts/validate-ssot.py`, `lib/doc-tracker.js` |
| FT-0060 Gate Evaluation | `scripts/check-exit-criteria.py`, `lib/gate.js`, `lib/state.js` |
| FT-0080 Session Bootstrap | `hooks/session-start.js`, `hooks/hooks.json` |

### 2.2 Concept Entity -> File

| Entity | Implementation Source |
|---|---|
| PROJECT_CONFIG | `.u-maker/u-maker.config.json` |
| DOCUMENT_RECORD | `.u-maker/docs/**` |
| PHASE_GATE | `.u-maker/u-maker.config.json`, `lib/gate.js` |
| HOOK_CONFIG | `hooks/hooks.json` |
| SKILL_DEFINITION | `skills/*/SKILL.md` |
| AGENT_PROFILE | `agents/*.md` |

## 3. Build / Validation Commands

| Command | Purpose |
|---|---|
| `./deploy_local.sh` | deploy plugin locally |
| `./deploy_local.sh --check` | inspect deployment state |
| `python3 scripts/validate-ssot.py .u-maker/docs` | validate docs |
| `python3 scripts/check-exit-criteria.py .u-maker/docs` | evaluate completion criteria |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-DV-FE | Code inventory created from repository scan |
