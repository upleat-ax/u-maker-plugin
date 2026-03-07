---
document: "2_Screen_UX"
title: "u-maker Plugin Screen Design"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
app: "web"
related_docs:
  - ".u-maker/docs/web/01-plan/1_IA_RA.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
  - ".u-maker/docs/web/04-check/4_Case_QA.md"
external_links: []
---

# u-maker Plugin Screen Design

- **Owner**: u-UX
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [IA](../01-plan/1_IA_RA.md), [API Contract](2_API_SA.md), [QA Cases](../04-check/4_Case_QA.md)

> 여기서 Screen은 브라우저 페이지가 아니라 slash command 결과, hook 출력, 문서 뷰 등 사용자가 인지하는 interaction surface를 뜻한다.

## 1. Screen Definition

| Screen ID | Name | Goal | Menu ID | Primary Interfaces |
|---|---|---|---|---|
| S-0010 | Command Entry Surface | phase 명령과 agent 명령을 선택한다 | MN-PLAN-0010 | README, slash commands |
| S-0020 | Deployment Surface | 배포/점검/정리 결과를 확인한다 | MN-BOOT-0010 | `deploy_local.sh` |
| S-0030 | Existing Repo Init Report | repo scan 결과와 생성 문서를 확인한다 | MN-BOOT-0020 | `/u-skill-init` |
| S-0040 | Phase Orchestration Workspace | plan/design/do 명령과 관련 문서를 탐색한다 | MN-DES-0010, MN-DO-0010 | skills, templates, docs |
| S-0050 | Validation Review Surface | build, validate, QA 결과를 검토한다 | MN-CHK-0010, MN-UTIL-0010 | validation scripts, QA docs |
| S-0060 | Status and Iteration Dashboard | phase, iteration, backlog, retrospective를 추적한다 | MN-ACT-0010 | config, index, iteration log |

## 2. Key Elements

| Screen | Element | Description |
|---|---|---|
| S-0010 | CommandBlock | 사용 가능한 명령 예시를 보여준다 |
| S-0020 | SyncResultTable | 어떤 디렉토리에 무엇이 설치되었는지 보여준다 |
| S-0030 | GeneratedFileList | 새로 생성된 문서와 누락된 분석 대상을 보여준다 |
| S-0040 | DocRegistryTable | phase별 문서 현황을 표로 정리한다 |
| S-0050 | IssueList | 실패 원인과 조치 우선순위를 표시한다 |
| S-0060 | GateSummary | 현재 phase와 다음 phase 진입 조건을 요약한다 |

## 3. Access Model

| Screen | Access |
|---|---|
| S-0010 | 모든 사용자 |
| S-0020 | 플러그인 배포 권한이 있는 사용자 |
| S-0030 | 저장소 쓰기 권한이 있는 사용자 |
| S-0040 | PM/RA/SA/UX/DV 역할 |
| S-0050 | QA/RA/maintainer |
| S-0060 | PM/RA/maintainer |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-UX | Screen model adapted for terminal and markdown interactions |
