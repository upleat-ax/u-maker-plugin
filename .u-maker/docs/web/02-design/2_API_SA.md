---
document: "2_API_SA"
title: "u-maker Plugin Automation Interface Contract"
owner: "u-SA"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/web/01-plan/1_SRS_RA.md"
  - ".u-maker/docs/common/02-design/2_ERD_SA.md"
  - ".u-maker/docs/web/02-design/2_Screen_UX.md"
  - ".u-maker/docs/web/03-dev/3_Code_DV.md"
external_links: []
---

# u-maker Plugin Automation Interface Contract

- **Owner**: u-SA
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [SRS](../01-plan/1_SRS_RA.md), [ERD](../../common/02-design/2_ERD_SA.md), [Screen Design](2_Screen_UX.md), [Code Record](../03-dev/3_Code_DV.md)

> 이 저장소에는 HTTP API route가 없으므로, 계약 문서는 로컬 명령/훅/스크립트 인터페이스를 API 관점으로 정의한다.

## 1. Interface Overview

| Interface | Entry Point | Purpose | FT Mapping | Output |
|---|---|---|---|---|
| CLI | `./deploy_local.sh` | 배포/점검/정리 | FT-0010 | stdout log, symlink/cache state |
| Skill | `/u-skill-init [path] [--lang]` | 기존 프로젝트 분석과 SSoT 초안 생성 | FT-0020 | `.u-maker/docs/**`, config update |
| Hook | `node hooks/session-start.js` | 문서 구조 생성/복구 | FT-0080 | JSON success payload |
| Hook | `node scripts/prompt-docs-first-guard.js` | 새 요구사항 감지 및 docs-first 차단 | FT-0040 | systemMessage JSON |
| Script | `python3 scripts/validate-ssot.py` | 문서 무결성 검증 | FT-0050 | terminal report + JSON result |
| Script | `python3 scripts/check-exit-criteria.py` | 종료 조건 점검 | FT-0060 | terminal report + JSON result |

## 2. Interface Details

### 2.1 `./deploy_local.sh`

| Item | Value |
|---|---|
| Input | `--check`, `--clean`, default deploy |
| Side Effects | plugin cache sync, marketplace registration, skill/agent symlink creation |
| Success | 대상 CLI 홈 경로에 링크/캐시가 생성됨 |
| Failure Cases | 권한 부족, 경로 없음, JSON 파싱 실패 |

### 2.2 `/u-skill-init`

| Item | Value |
|---|---|
| Input | project path, optional `--lang` |
| Read Targets | `README.md`, `.u-maker/u-maker.config.json`, `skills/`, `agents/`, `hooks/`, `lib/`, `scripts/`, `templates/`, `_refer/` |
| Output | draft SSoT docs, `_links.json`, config metadata |
| Failure Cases | 기존 docs 덮어쓰기 충돌, 분석 대상 부족, 언어 옵션 오류 |

### 2.3 `validate-ssot.py`

| Item | Value |
|---|---|
| Input | optional docs root path |
| Checks | phase dirs 존재, header fields, related docs links |
| Current Note | v2 구조와 flat dir 기대치가 혼재하므로 호환 디렉토리 필요 |

### 2.4 `check-exit-criteria.py`

| Item | Value |
|---|---|
| Input | optional docs root path |
| Checks | critical/major defect count, FR implemented, build success |
| Dependencies | `4_Report_QA.md`, `1_SRS_RA.md`, build command availability |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-SA | Contract documented for non-HTTP automation interfaces |
