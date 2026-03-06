---
name: u-skill-docs
description: |
  .u-maker/docs/ 내 전체 문서 트리를 조회한다.
  Triggers: /u-skill-docs, 문서 목록, 문서 조회, document list
user-invocable: true
argument-hint: "[list|update] [--phase <plan|design|do|check|act>] [--status <Draft|Review|Final>] [--app web]"
model: sonnet
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
  - ${PLUGIN_ROOT}/.u-maker/u-ssot.config.json
agents:
  - u-maker:u-agent-ra
---

# Document Management

> .u-maker/docs/ 내 전체 문서 트리를 조회하거나 메타데이터를 갱신한다.

## Syntax

/u-skill-docs list [--phase PLAN|DESIGN|DO|CHECK|ACT] [--status Draft|Review|Final] [--app <name>]
/u-skill-docs update [<doc-name|all>] [--status <val>] [--version <val>]
/u-skill-docs (인수 없음 = /u-skill-docs list)

## Document List Flow

1. .u-maker/u-ssot.config.json에서 apps 목록 확인
2. .u-maker/docs/ 디렉토리 스캔
3. 각 문서 YAML 헤더 파싱
4. Expected Document Matrix와 대조하여 누락 문서 탐지
5. 필터 옵션 적용
6. 구조화된 트리 출력

## Document Update Flow

**Mode A (인수 없음)**: 1_Index_PM.md 재동기화
**Mode B (문서 지정)**: YAML 헤더 수정 → Index 재동기화

## Status Transition Rules

| 현재 | 허용 전환 |
|------|-----------|
| Draft | → Review, → Final |
| Review | → Final, → Draft |
| Final | → Draft (경고 후), → Review |

## Rules

- u-agent-ra 에이전트가 담당
- iterations/ 아카이브 디렉토리는 목록에서 제외
- Post-Execution Summary Box 출력 필수
