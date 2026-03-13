---
name: u-skill-wireframe
description: |
  화면 와이어프레임을 HTML로 생성하거나 갱신한다. u-agent-ux 에이전트가 담당한다.
  IA, Screen 문서를 참고하여 HTML/CSS로 레이아웃을 시각화한다.
  각 화면 요소에는 floating 어노테이션 패널이 포함된다 --
  관련 요구사항(FR), 플로우(SC/User Flow), 조건(Business Rule), 요소 설명을 표시한다.
  Args: `[app] <all|screen-id>` — 앱 이름 + 대상 화면 (all=전체)
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
  - ${PLUGIN_ROOT}/_refer/html-wireframe-template.md
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

- **`html-wireframe-template.md` 표준을 엄격히 준수**
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- **어노테이션 마커 필수**: 모든 UI Elements에 원 숫자(①②③...) 마커 부착, 클릭 시 팝업으로 상세 정보 표시
- **팝업 내용**: 설명, 관련 요구사항(FR/US/FT), 비즈니스 룰, 흐름, 상태, 연결 화면 포함
- **Annotation Legend**: 각 와이어프레임 하단에 마커 범례 섹션 포함
- **index.html 필수**: 와이어프레임 생성/갱신 시 `index.html` + `index.json`도 항상 함께 생성/갱신
- index.html은 전체 화면 목록을 도메인별 그룹핑으로 표시하고 검색 기능 제공
- Post-Execution Summary Box 출력 필수
