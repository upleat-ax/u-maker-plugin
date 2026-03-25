---
name: u-skill-ux-designsystem
description: |
  설정된 디자인 도구(pencil/figma/stitch)를 사용해 컴포넌트, 디자인 시스템, 화면을 시각적으로 구성하고 업데이트한다.
  u-maker.config.json의 designTool.tool 설정에 따라 pencil.dev, Figma MCP, 또는 Stitch MCP를 사용한다.
  IA, Screen, DesignToken, UIComponents 문서를 참고하여 디자인 파일에 반영한다.
  Args: `[app] [screen-id|component|all]` — 앱 + 대상 지정
  Triggers: /u-skill-ux-designsystem, pencil, figma, stitch, 디자인 시각화, 화면 디자인, 컴포넌트 디자인, design system visual,
  screen visual, ui design, pen file, pencil design, figma design, stitch design, 디자인 시스템, design system, UI 컴포넌트, 화면 구성, 비주얼 디자인
model: sonnet
user-invocable: true
argument-hint: "[app] [screen-id|component|all]"
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

# u-skill-ux-designsystem

`u-agent-ux-ds` 에이전트를 호출하여 설정된 디자인 도구로 컴포넌트, 디자인 시스템, 화면을 시각적으로 구성/업데이트한다.

## Design Tool

`u-maker.config.json`의 `designTool.tool` 값에 따라 사용할 도구가 결정된다:
- `pencil` (기본값): pencil.dev MCP → `.pen` 파일
- `figma`: Figma MCP → Figma 파일
- `stitch`: Stitch MCP → `.stitch` 파일

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Flow

1. `u-maker.config.json`의 `designTool.tool` 값 확인 (pencil/figma/stitch)
2. App context 결정 + target 파싱 (all/screen-id/component)
3. 참조 문서 수집:
   - IA (`1_IA_RA.md`), Screen (`2_Screen_UX.md`), UXGuide (`2_UXGuide_UX.md`)
   - DesignToken (`3_DesignToken_UX.md`), UIComponents (`3_UIComponents_UX.md`)
   - Wireframes (`2_Screen_Wireframes/*.html`)
4. `u-agent-ux-ds` 호출 → 설정된 MCP로 시각적 디자인 생성/갱신
5. 결과물을 `.u-maker/docs/{app}/02-design/`에 저장
6. Post-Execution Summary Box 출력

## Output

| Target | Output Path | Content |
|--------|-------------|---------|
| system | `.u-maker/docs/common/02-design/design-system.pen` | 디자인 시스템 전체 |
| all | `.u-maker/docs/{app}/02-design/{app}.pen` | 앱별 전체 화면 |
| component | `.u-maker/docs/common/02-design/components.pen` | UI 컴포넌트 |
| S-NNNN | `.u-maker/docs/{app}/02-design/{app}.pen` (해당 프레임) | 특정 화면 |

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- 결과물은 `.u-maker/docs/{app}/02-design/`에 앱당 1개 `.pen` 파일로 저장
- `u_design` 또는 `u-design` 폴더는 절대 사용하지 않음
- 모든 디자인 요소는 `documentLanguage` 설정을 따름
- 각 프레임에 wireframe 번호(S-NNNN) 명시
- Post-Execution Summary Box 출력 필수
