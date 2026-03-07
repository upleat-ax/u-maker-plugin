---
document: "1_Common_RA"
title: "u-maker Plugin Common Rules"
owner: "u-RA"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-07"
related_docs:
  - ".u-maker/docs/common/01-plan/1_Roadmap_PM.md"
  - ".u-maker/docs/web/01-plan/1_SRS_RA.md"
  - ".u-maker/docs/web/02-design/2_API_SA.md"
external_links: []
---

# u-maker Plugin Common Rules

- **Owner**: u-RA
- **Status**: Draft
- **Version**: v0.1.0
- **Last Updated**: 2026-03-07
- **Related Docs**: [Roadmap](1_Roadmap_PM.md), [SRS](../../web/01-plan/1_SRS_RA.md), [API Contract](../../web/02-design/2_API_SA.md)

## 1. Execution Trust Model

| Role | Description | Primary Responsibility |
|---|---|---|
| Workspace Maintainer | 플러그인을 배포하고 config를 관리하는 사용자 | 배포, 상태 확인, 루프 제어 |
| Specialist Agent | `u-agent-*` 로 표현되는 역할 프롬프트 | 문서/구현/검증 단위 작업 |
| Orchestrator Skill | `u-skill-*` 명령 세트 | phase 흐름과 문서 생성 순서 제어 |
| Hook Runtime | Claude/Codex/Gemini 세션 훅 | 구조 보정, Docs-First 차단, 종료 상태 저장 |

## 2. Common Business Rules

| ID | Rule | Scope |
|---|---|---|
| BR-0010 | SSoT 문서는 `.u-maker/docs/` 하위에만 생성한다. | all docs |
| BR-0020 | 초기 생성 문서 상태는 항상 `Draft`이다. | all docs |
| BR-0030 | 새 기능 요청은 문서 스킬 선행 후 구현한다. | user prompt routing |
| BR-0040 | 앱 목록이 config에 없으면 `web`을 기본값으로 간주한다. | state/doc resolution |
| BR-0050 | Gate 판정은 공통 문서 + 모든 app 문서 상태를 함께 본다. | phase transition |

## 3. Security and Safety Policy

- 훅과 스크립트는 로컬 파일시스템 범위에서 동작한다.
- `pre-write-guard.js`는 SSoT 문서 경로 위반과 금지된 tech stack 패턴을 차단한다.
- `prompt-docs-first-guard.js`는 새 요구사항 감지 시 즉시 문서 명령을 우선 제안한다.
- destructive git 명령은 정책상 금지되며, 사용자 승인 없는 덮어쓰기를 지양한다.

## 4. Glossary

| Term | Definition |
|---|---|
| SSoT | Single Source of Truth. 문서와 구현의 기준 레이어 |
| PDCA | Plan, Design, Do, Check, Act 반복 루프 |
| Gate | 상위 phase로 진입하기 전 만족해야 하는 조건 집합 |
| Interaction Surface | 웹 UI 대신 터미널, markdown, slash command, hook output 등 사용자 접점 |

## Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| v0.1.0 | 2026-03-07 | u-RA | Common rules extracted from current repository |
