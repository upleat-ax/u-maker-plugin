---
name: u-skill-ux-figma
description: |
  설정된 디자인 도구(pencil/figma/stitch)를 사용하여 화면을 시각적으로 디자인한다.
  u-maker.config.json의 designTool.tool 설정에 따라 적절한 MCP를 사용한다.
  2_Screen_Wireframes/ 의 HTML 와이어프레임을 참조하여 각 화면의 디자인 파일을 생성하며,
  관련된 wireframe 번호(S-NNNN)를 명시한다.
  IA, Screen, DesignToken, UIComponents, Wireframe 문서를 참고하여 디자인 파일에 반영한다.
  Args: `[app] <all|system|S-NNNN>` — 앱 + 대상 화면/시스템
  Triggers: /u-skill-ux-figma, pencil, figma, stitch, 디자인 시각화, 화면 디자인, 컴포넌트 디자인, design system visual,
  screen visual, ui design, pen file, pencil design, figma design, stitch design, 화면 설계, 와이어프레임 디자인, wireframe design, 화면 시각화, screen design
user-invocable: true
argument-hint: "[app] <all|system|S-NNNN|component-id>"
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
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
  - ${PLUGIN_ROOT}/_refer/mermaid-guide.md
agents:
  u-agent-ux-ds: u-maker:u-agent-ux-ds
---

# Visual UX Design

> 설정된 디자인 도구(pencil/figma/stitch)를 사용하여 화면을 시각적으로 디자인한다.
> `u-maker.config.json`의 `designTool.tool` 값에 따라 pencil.dev, Figma, 또는 Stitch MCP를 사용한다.
> 2_Screen_Wireframes/ 의 HTML 와이어프레임을 참조하여 각 화면의 디자인 파일을 생성하며,
> 관련된 wireframe 번호(S-NNNN)를 명시한다.

## Syntax

/u-agent-ux-design [app] [target]

- [target]: all (기본값) | system | S-NNNN | <ComponentName>

## Output Files

| Target | Output | Content |
|--------|--------|---------|
| system | .u-maker/docs/common/02-design/design-system.pen | 디자인 시스템 전체 |
| all | .u-maker/docs/{app}/02-design/{app}.pen | 앱별 전체 화면 |
| component | .u-maker/docs/common/02-design/components.pen | UI 컴포넌트 |

## Reference Documents

1. IA: .u-maker/docs/{app}/01-plan/1_IA_RA.md
2. Screen Design: .u-maker/docs/{app}/02-design/2_Screen_UX.md
3. Wireframes: .u-maker/docs/{app}/02-design/2_Screen_Wireframes/{S-NNNN}.html
4. DesignToken: .u-maker/docs/common/03-dev/3_DesignToken_UX.md
5. UIComponents: .u-maker/docs/common/03-dev/3_UIComponents_UX.md
6. UXGuide: .u-maker/docs/common/02-design/2_UXGuide_UX.md

## Flow

1. 출력 경로 결정 (.u-maker/docs/{app}/02-design/)
2. App context 결정
3. target 파싱
4. 2_Screen_Wireframes/ 내 HTML 와이어프레임 확인
5. u-agent-ux → pencil.dev MCP 활용
6. Summary Box 출력

## Rules

- 결과물은 .u-maker/docs/{app}/02-design/ 에 앱당 1개 .pen 파일로 저장
- u_design 또는 u-design 폴더는 절대 사용하지 않음
- 모든 디자인 요소는 documentLanguage 설정을 따름
- 각 프레임에 wireframe 번호(S-NNNN) 명시
- Post-Execution Summary Box 출력 필수
