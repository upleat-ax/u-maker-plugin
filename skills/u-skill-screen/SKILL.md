---
name: u-skill-screen
description: |
  화면 상세 설계 문서를 생성하거나 갱신한다. u-agent-ux 에이전트가 담당한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-screen, 화면 설계, wireframe, screen design
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
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  - u-maker:u-agent-ux
---

# u-agent-screen

`u-agent-ux` 에이전트를 호출하여 화면 설계 문서를 생성/갱신한다.

## Output

`.u-maker/docs/{app}/02-design/2_Screen_UX.md`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- **Tab 화면 분리 필수**: 화면 내에 Tab UI가 있는 경우, **각 탭을 별도 화면(S-NNNN)으로 설계**해야 한다
  - 부모 화면(S-NNNN): 전체 레이아웃 + Tab 네비게이션 구조 포함, 기본 탭 상태 표시
  - 자식 화면(S-NNNN-T1, S-NNNN-T2, ...): 각 탭별 고유 콘텐츠를 개별 화면으로 상세 설계
  - 각 탭 화면에도 **탭별 고유 UI 요소, 상태(State), 조건(Business Rule), 인터랙션**을 빠짐없이 명시
  - 탭 간 전환 시 데이터 유지/초기화 정책, 로딩 전략(lazy/eager)도 기술
- **조건별 화면 상태 명시 필수**: 권한, 데이터 유무, 상태값 등 **조건에 따라 화면이 달라지는 모든 케이스**를 States 섹션에 명확히 기술 (Empty, Loading, Error, 권한별 분기, 데이터 조건별 분기 등)
- Post-Execution Summary Box 출력 필수
