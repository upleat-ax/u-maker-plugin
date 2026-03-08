---
document: "1_SRS_RA"
title: "u-maker Plugin Software Requirements Specification"
owner: "u-SA"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/common/01-plan/1_Roadmap_PM.md"
  - ".u-maker/docs/web/01-plan/1_IA_RA.md"
  - ".u-maker/docs/common/02-design/2_ERD_SA.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
external_links: []
---

# u-maker Plugin SRS

- **Owner**: u-SA
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [Roadmap](../../common/01-plan/1_Roadmap_PM.md), [IA](1_IA_RA.md), [ERD](../../common/02-design/2_ERD_SA.md), [API Contract](../02-design/2_API_SA.md)

> `web` app scope는 실제 브라우저 앱이 아니라 slash command, hook output, markdown documents를 포함하는 논리적 interaction surface이다.

## 1. Background

이 저장소의 목적은 기존 코드베이스에 SSoT 문서 기반 PDCA 운영 체계를 강제하는 것이다. 사용자는 개별 기능 구현보다 앞서 문서 스킬과 에이전트를 호출해 계획과 설계를 먼저 고정해야 한다.

## 2. Functional Requirements (FR)

| FR-ID | Requirement | Description | Priority | USR Mapping | Implemented |
|---|---|---|---|---|---|
| FR-0010 | 플러그인 로컬 배포 | Claude/Codex/Gemini 환경에 플러그인을 동기화하고 상태를 점검한다. | Must | USR-0010 | Yes |
| FR-0020 | 기존 프로젝트 reverse engineering init | 현재 저장소를 스캔해 `.u-maker/docs` 초안을 생성한다. | Must | USR-0010 | Partial |
| FR-0030 | PDCA phase 문서 생성/호출 | plan/design/do/check/act 관련 문서 스킬을 제공한다. | Must | USR-0020 | Yes |
| FR-0040 | Docs-First guard | 새 기능 요청이 감지되면 문서 명령을 먼저 제안한다. | Must | USR-0020 | Yes |
| FR-0050 | SSoT 무결성 검증 | 헤더, 경로, 관련 문서 링크를 점검한다. | Must | USR-0020 | Yes |
| FR-0060 | Exit criteria 및 phase gate 판정 | build, defect, FR 구현 상태를 종합해 진행 가능 여부를 판단한다. | Must | USR-0020 | Yes |
| FR-0070 | 전문 에이전트/스킬 카탈로그 관리 | 역할별 에이전트와 스킬 정의를 저장소에서 유지한다. | Should | USR-0030 | Yes |
| FR-0080 | 세션 자동 구조 보정 | 세션 시작 시 `.u-maker/docs` 구조가 없으면 자동 보정한다. | Should | USR-0010 | Yes |

## 3. Non-Functional Requirements (NFR)

| NFR-ID | Category | Requirement | Target |
|---|---|---|---|
| NFR-0010 | Compatibility | macOS, Linux, WSL, Windows Git Bash 흐름을 최대한 지원 | `deploy_local.sh` OS 분기 |
| NFR-0020 | Safety | 사용자 승인 없는 destructive overwrite를 피함 | Draft 생성, guard 중심 |
| NFR-0030 | Traceability | 모든 핵심 산출물은 문서 경로와 코드 경로를 연결 | RTM/Index 유지 |
| NFR-0040 | Readability | 터미널/markdown 응답은 표, bullet, code block 위주 | UX guide 준수 |
| NFR-0050 | Determinism | 기본 app는 `web`, 기본 phase는 `plan`, 기본 loop status는 `STOPPED` | config/state 일관성 |

## 4. Users (USR)

| USR-ID | Role | Description |
|---|---|---|
| USR-0010 | Workspace Maintainer | 플러그인을 설치하고 현재 프로젝트에 적용하는 사용자 |
| USR-0020 | Process Owner | phase 전환, 문서 품질, 반복 주기를 관리하는 PM/RA |
| USR-0030 | Specialist Contributor | SA/UX/DV/QA 역할 문서와 코드를 보강하는 사용자 |

## 5. User Stories (US)

| US-ID | As a | I want to | So that | FR Mapping |
|---|---|---|---|---|
| US-0010 | Workspace Maintainer | 기존 저장소를 빠르게 초기 분석하고 문서화하고 싶다 | 수작업 없이 PDCA 루프를 시작할 수 있다 | FR-0010, FR-0020 |
| US-0020 | Process Owner | phase별 문서와 gate 상태를 명확히 관리하고 싶다 | 순서가 어긋난 구현을 줄일 수 있다 | FR-0030, FR-0050, FR-0060 |
| US-0030 | Process Owner | 기능 요청이 들어오면 문서 업데이트를 먼저 강제하고 싶다 | SSoT가 코드보다 뒤처지지 않는다 | FR-0040 |
| US-0040 | Specialist Contributor | 역할별 agent/skill 정의를 읽고 확장하고 싶다 | 저장소를 기능별로 유지보수할 수 있다 | FR-0070 |
| US-0050 | Workspace Maintainer | 새 세션에서도 문서 구조와 상태가 자동으로 복구되길 원한다 | 작업 컨텍스트를 빠르게 복구할 수 있다 | FR-0080 |

## 6. Features (FT)

| FT-ID | Feature | Description | US Mapping | Implemented |
|---|---|---|---|---|
| FT-0010 | Local Deploy Flow | 플러그인 배포, 체크, 정리 명령 | US-0010 | Yes |
| FT-0020 | Existing Repo Init | README/config/scripts를 스캔한 후 초안 문서 생성 | US-0010 | Partial |
| FT-0030 | Phase Skill Catalog | `/u-skill-plan`, `/u-skill-design`, `/u-skill-dev`, `/u-skill-check`, `/u-skill-act` | US-0020 | Yes |
| FT-0040 | Prompt Guard | 기능 추가 의도 감지와 문서 명령 제안 | US-0030 | Yes |
| FT-0050 | SSoT Validation | 문서 헤더/경로/관련 링크 검증 | US-0020 | Yes |
| FT-0060 | Gate Evaluation | phase gate 및 exit criteria 판정 | US-0020 | Yes |
| FT-0070 | Agent/Skill Registry | 역할 정의 및 스킬 카탈로그 저장 | US-0040 | Yes |
| FT-0080 | Session Bootstrap | 세션 시작 시 구조 생성/복구 | US-0050 | Yes |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-SA | Initial SRS reverse-engineered from current repository |
