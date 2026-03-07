---
document: "2_RTM_RA"
title: "u-maker Plugin Requirements Traceability Matrix"
owner: "u-RA"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
related_docs:
  - ".u-maker/docs/web/01-plan/1_SRS_RA.md"
  - ".u-maker/docs/web/01-plan/1_IA_RA.md"
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
  - ".u-maker/docs/common/02-design/2_ERD_SA.md"
  - ".u-maker/docs/web/04-check/4_Case_QA.md"
external_links: []
---

# u-maker Plugin Requirements Traceability Matrix

- **Owner**: u-RA
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [SRS](../../web/01-plan/1_SRS_RA.md), [IA](../../web/01-plan/1_IA_RA.md), [Screen](../../web/02-design/2_Screen_UX.md), [API](../../web/02-design/2_API_SA.md), [ERD](2_ERD_SA.md), [QA Cases](../../web/04-check/4_Case_QA.md)

## 1. Coverage Summary

| App | FR | US | FT | Coverage |
|---|---:|---:|---:|---|
| web | 8 | 5 | 8 | Draft baseline, manually review after implementation |

## 2. RTM Matrix

| FR-ID | US-ID | FT-ID | MN-ID | Screen | Interface | ERD | Code | QA | Status |
|---|---|---|---|---|---|---|---|---|---|
| FR-0010 | US-0010 | FT-0010 | MN-BOOT-0010 | S-0020 | CLI `deploy_local.sh` | PLUGIN_MANIFEST | `deploy_local.sh` | TC-0010 | Covered |
| FR-0020 | US-0010 | FT-0020 | MN-BOOT-0020 | S-0030 | `/u-skill-init` | PROJECT_CONFIG, DOCUMENT_RECORD | `skills/u-skill-init/SKILL.md` | TC-0020 | Covered |
| FR-0030 | US-0020 | FT-0030 | MN-PLAN-0010 | S-0010 | slash commands | DOCUMENT_RECORD | `skills/u-skill-plan/*` | TC-0030 | Covered |
| FR-0040 | US-0030 | FT-0040 | MN-UTIL-0010 | S-0050 | `prompt-docs-first-guard.js` | DOCUMENT_RECORD | `scripts/prompt-docs-first-guard.js` | TC-0040 | Covered |
| FR-0050 | US-0020 | FT-0050 | MN-UTIL-0020 | S-0060 | `validate-ssot.py` | DOCUMENT_RECORD | `scripts/validate-ssot.py` | TC-0050 | Covered |
| FR-0060 | US-0020 | FT-0060 | MN-UTIL-0030 | S-0060 | `check-exit-criteria.py` | PHASE_GATE | `scripts/check-exit-criteria.py`, `lib/gate.js` | TC-0060 | Covered |
| FR-0070 | US-0040 | FT-0070 | MN-DES-0010 | S-0040 | templates + guides | SKILL_DEFINITION | `templates/**`, `_refer/**` | TC-0070 | Partial |
| FR-0080 | US-0050 | FT-0080 | MN-ACT-0010 | S-0060 | state save and iteration logs | PROJECT_CONFIG, DOCUMENT_RECORD | `scripts/stop-state-save.js`, `lib/state.js` | TC-0080 | Covered |

## 3. Known Gaps

| Gap ID | Description | Action |
|---|---|---|
| GAP-0010 | `web` 스코프가 실제 웹앱이 아니라 논리적 interaction surface임 | README 및 후속 문서에서 동일 설명 유지 |
| GAP-0020 | validator가 구형 flat phase dir도 기대함 | 호환용 root phase dir를 유지하거나 validator 정합화 필요 |
| GAP-0030 | 실제 HTTP API와 DB 스키마가 없음 | automation interface / conceptual ERD 체계로 유지 |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-RA | Initial RTM mapped from repository assets |
