---
name: u-agent-sa
description: |
  Agent SA(Software Architect)에게 직접 작업을 요청한다. SRS, ERD, API Contract 작성 등.
  Triggers: /u-agent-sa, SA에게, 아키텍처, software architect, srs, 소프트웨어 요구사항, erd, api contract, openapi, 데이터 모델, fr 도출, us 도출, ft 도출, 트레이서빌리티
model: sonnet
user-invocable: true
argument-hint: "[task description]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-sa
---

# u-agent-sa

## Purpose

`u-agent-sa` 에이전트를 호출하여 사용자가 요청한 SA(Software Architect) 작업을 수행한다.
소프트웨어 요구사항 명세, 데이터 모델 설계, API Contract 정의, 추적성 매트릭스 관리를 담당한다.

## Scope

- SRS (Software Requirements Specification) — 기능/비기능 요구사항 상세 명세
- ERD (Entity-Relationship Diagram) — 엔티티 관계 정의, Mermaid 다이어그램 포함
- API Contract (OpenAPI 3.0) — 엔드포인트, 요청/응답 스키마 정의
- USR/FR/US/FT 도출 — 4-Tier ID 계층 구조에 따른 요구사항 분해 및 매핑
- 추적성 매트릭스 — USR→FR→US→FT 상하위 연결 검증

## Flow

1. 사용자 요청을 분석하여 수행할 SA 작업 유형을 결정한다.
2. `.u-maker/u-maker.config.json`에서 프로젝트 컨텍스트와 tech stack을 확인한다.
3. 관련 상위 문서(공통 요구사항, 로드맵)를 읽어 컨텍스트를 파악한다.
4. 요청된 문서를 생성하거나 갱신한다.
5. 동명의 `.json` 파일을 동일 경로에 함께 저장한다.
6. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/common/01-plan/1_SRS_SA.md` + `.json`
- `.u-maker/docs/common/02-design/2_ERD_SA.md` + `.json`
- `.u-maker/docs/common/02-design/2_APIContract_SA.md` + `.json`

## When NOT to use

- 화면 설계 → `/u-agent-ux` 사용
- 코드 구현 → `/u-agent-dv-fe` 또는 `/u-agent-dv-be` 사용
- 프로젝트 기획/백로그 관리 → `/u-agent-ra` 사용

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- ERD는 Mermaid 다이어그램으로 표현 (UML CDN 허용)
- FT는 Feature(구현 단위)의 약자; Functional Test로 절대 표기 금지
- Post-Execution Summary Box 출력 필수
