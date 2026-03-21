---
name: u-skill-erd
description: |
  ERD(Entity-Relationship Diagram) 문서를 생성하거나 갱신한다. u-agent-sa 에이전트가 담당한다.
  Triggers: /u-skill-erd, ERD, erd, 데이터 모델, data model, entity relationship, 엔티티 관계도, 스키마 설계, schema design, 테이블 설계, table design, db 설계, database diagram
model: sonnet
user-invocable: true
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
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  u-agent-sa: u-maker:u-agent-sa
---

# u-skill-erd

## Purpose

`u-agent-sa` 에이전트를 호출하여 ERD(Entity-Relationship Diagram) 문서를 생성하거나 갱신한다.
데이터 모델 설계를 Mermaid 다이어그램과 함께 명세화한다.

## Scope

- 엔티티 정의 — 테이블명, 필드명, 데이터 타입, 제약조건
- 관계 정의 — 1:1, 1:N, N:M 관계 및 외래키
- Mermaid `erDiagram` 블록 생성
- 기존 ERD와 차이 비교 및 변경 이유 기록

## Flow

1. `.u-maker/u-maker.config.json`에서 DB 종류(PostgreSQL, MySQL 등)와 ORM을 확인한다.
2. 기존 `2_ERD_SA.md`가 있으면 읽어 현재 상태를 파악한다.
3. 사용자 요청 또는 SRS를 기반으로 엔티티와 관계를 도출한다.
4. Mermaid `erDiagram` 문법으로 ERD를 작성한다.
5. 엔티티별 필드 상세 명세표를 함께 작성한다.
6. `2_ERD_SA.md`를 생성/갱신하고 동명의 `.json`을 저장한다.
7. Post-Execution Summary Box를 출력한다.

## Output

- `.u-maker/docs/common/02-design/2_ERD_SA.md` + `.json`

## Rules

- ERD는 반드시 Mermaid `erDiagram` 블록 포함 (Mermaid CDN 허용)
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
