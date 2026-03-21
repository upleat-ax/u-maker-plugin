---
name: u-skill-glossary
description: |
  용어 정의(Glossary) 문서를 생성하거나 갱신한다. u-agent-ra 에이전트가 담당한다.
  프로젝트에서 사용하는 도메인 용어, 약어, 기술 용어를 정의하고 통일한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-glossary, 용어 정의, 용어집, glossary, terminology, 용어 사전, 도메인 용어, domain terms, 약어 정의, abbreviation, 용어 통일, term standardization, 단어 정의
model: sonnet
user-invocable: true
argument-hint: "[app]"
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
  u-agent-ra: u-maker:u-agent-ra
---

# u-skill-glossary

`u-agent-ra` 에이전트를 호출하여 용어 정의(Glossary) 문서를 생성/갱신한다.

## Output

`.u-maker/docs/{app}/01-plan/1_Glossary_RA.md`

## Purpose

- 프로젝트 내 도메인 용어, 약어, 기술 용어의 정의를 단일 문서로 관리
- 팀원 간 용어 혼동 방지 및 커뮤니케이션 통일
- SRS, Screen, API 등 다른 SSoT 문서에서 참조하는 용어 기준점 역할

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Document Structure

```markdown
# Glossary — {Project Name}

## Meta
| Key | Value |
|-----|-------|
| Document ID | 1_Glossary_RA |
| Phase | PLAN |
| Owner | RA (Requirements Analyst) |
| Status | Draft / Reviewed / Approved |
| Last Updated | YYYY-MM-DD |

## Domain Terms (도메인 용어)

| ID | Term (EN) | Term (KO) | Definition | Context / Example | Related Docs |
|----|-----------|-----------|------------|-------------------|--------------|
| GL-0010 | ... | ... | ... | ... | FR-XXXX, FT-XXXX |

## Abbreviations (약어)

| Abbreviation | Full Name | Definition | Usage Context |
|-------------|-----------|------------|---------------|
| ... | ... | ... | ... |

## Technical Terms (기술 용어)

| ID | Term | Definition | Category | Related Docs |
|----|------|------------|----------|--------------|
| GT-0010 | ... | ... | Frontend / Backend / Infra / DB | ... |

## Change Log
| Date | Author | Description |
|------|--------|-------------|
```

## Rules

- 용어 ID는 `GL-{4자리숫자}` (도메인), `GT-{4자리숫자}` (기술) 형식
- 10단위 증분 (0010, 0020, 0030...)
- SRS, Screen 등 기존 문서에서 사용 중인 용어를 자동 수집하여 초안 작성
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
