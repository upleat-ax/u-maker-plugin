---
name: u-skill-dev
description: |
  DO Phase 실행. API Contract 기반으로 FE/BE 병렬 개발을 수행한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-dev, do phase, 개발, 구현, 코딩, development, implement, 개발 단계, coding, build feature, 기능 구현, FE 개발, BE 개발, frontend, backend
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
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-ux: u-maker:u-agent-ux
  u-agent-dv-fe: u-maker:u-agent-dv-fe
  u-agent-dv-be: u-maker:u-agent-dv-be
---

# DO Phase

> API Contract 기반으로 UX/FE/BE 병렬 개발을 수행한다.

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app (e.g., `/u-skill-dev web`) |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Execution Sequence

1. `u-agent-ux`: Screen/UI 구현
   - Screen 구현 (`{app}/03-dev/3_Screen_UX.md`)
   - UI Components 구현 (`common/03-dev/3_UIComponents_UX.md`)
   - Design Token 정의 (`common/03-dev/3_DesignToken_UX.md`)
2. `u-agent-dv-fe`: Frontend 개발
   - Next.js App Router + react-query
   - Storybook 컴포넌트 문서화
3. `u-agent-dv-be`: Backend 개발
   - API Routes 구현 (2_API_SA Contract 기반)
   - Prisma/Drizzle ORM
4. 병렬 개발: UX/FE/BE는 API Contract를 기준으로 독립 개발
5. `{app}/03-dev/3_Code_DV.md` 갱신: 구현 현황 기록

## Gate → CHECK

코드 구현 완료 + `bun run build` 성공

## Rules

- 기술 스택 10가지 규칙 강제 (상세: `tech-stack-rules.md`). 위반 시 거부
- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
