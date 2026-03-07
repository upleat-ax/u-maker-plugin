---
name: u-skill-wireframe
description: |
  화면 와이어프레임을 HTML로 생성하거나 갱신한다. u-agent-ux 에이전트가 담당한다.
  IA, Screen 문서를 참고하여 HTML/CSS로 레이아웃을 시각화한다.
  각 화면 요소에는 floating 어노테이션 패널이 포함된다 --
  관련 요구사항(FR), 플로우(SC/User Flow), 조건(Business Rule), 요소 설명을 표시한다.
  Triggers: /u-skill-wireframe, HTML 와이어프레임, wireframe generate
model: sonnet
user-invocable: true
argument-hint: "[app] <all|screen-id>"
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
  - u-maker:u-agent-ux
---

# u-agent-wireframe

`u-agent-ux` 에이전트를 호출하여 HTML 와이어프레임을 생성/갱신한다.

## Output

`.u-maker/docs/{app}/02-design/2_Screen_Wireframes/`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
