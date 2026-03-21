---
name: u-skill-create-project
description: |
  새 프로젝트 초기화. Turborepo 모노레포 + .u-maker/docs SSoT 문서 구조를 생성한다.
  Args: `<project-name>` — 프로젝트 이름 (필수)
  Triggers: /u-skill-create-project, 프로젝트 생성, 프로젝트 시작, new project, create project, 새 프로젝트, 프로젝트 만들기, project setup, 프로젝트 셋업, initialize project, 모노레포 생성, monorepo setup
model: sonnet
user-invocable: true
argument-hint: "<project-name>"
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
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/tech-stack-rules.md
agents:
  u-agent-ra: u-maker:u-agent-ra
---

# u-skill-create-project

새 프로젝트를 초기화한다. Turborepo 모노레포 스캐폴딩 + `.u-maker/docs` SSoT 문서 구조를 생성한다.

## Execution Steps

1. **사용자 입력 확인**
   - `<project-name>` 필수. 미입력 시 AskUserQuestion으로 요청
   - 선택: 초기 앱 이름 (기본값: `web`), 추가 앱 목록

2. **Turborepo 모노레포 스캐폴딩** (`u-agent-ra`)
   - `bun create turbo@latest <project-name>` 실행
   - `apps/<app-name>/` — Next.js App Router 앱 생성
   - `packages/ui/` — 공유 UI 컴포넌트 패키지
   - `packages/config/` — 공유 설정 (tsconfig, eslint)
   - 기본 의존성에 `@tabler/icons-react` 포함

3. **`.u-maker/` 디렉토리 구조 생성** (`u-agent-ra`)
   ```
   .u-maker/
   ├── u-maker.config.json        # 프로젝트 설정
   ├── docs/
   │   ├── _links.json            # 추적성 매핑
   │   ├── common/                # 공용 문서
   │   │   ├── 01-plan/
   │   │   ├── 02-design/
   │   │   ├── 03-dev/
   │   │   ├── 04-check/
   │   │   └── 05-act/
   │   └── <app-name>/            # 앱별 문서
   │       ├── 01-plan/
   │       ├── 02-design/
   │       ├── 03-dev/
   │       └── 04-check/
   ├── scripts/
   └── templates/
   ```

4. **`u-maker.config.json` 초기화**
   ```json
   {
     "projectName": "<project-name>",
     "apps": ["<app-name>"],
     "techStack": { "frontend": "nextjs", "backend": "nextjs-api", "orm": "prisma" },
     "designTool": { "tool": "pencil", "supportedTools": ["pencil", "figma", "stitch"] },
     "documentPaths": { "root": ".u-maker/docs" },
     "iteration": { "current": 1, "maxIterations": 10 },
     "loopStatus": "IDLE",
     "documentLanguage": "ko"
   }
   ```

5. **초기 문서 생성** (`u-agent-ra`)
   - `common/01-plan/1_Index_PM.md` + `.json` — 문서 인덱스 (Draft)
   - `common/01-plan/1_Roadmap_PM.md` + `.json` — 로드맵 템플릿 (Draft)
   - `docs/_links.json` — 빈 추적성 매핑

6. **Post-Execution Summary Box 출력**

## Rules

- 모든 문서 생성 시 동명의 `.json` 파일을 동일 경로에 함께 생성 (스키마: `json-export.md`)
- 기존 디렉토리가 존재하면 덮어쓰지 않고 AskUserQuestion으로 확인
- Post-Execution Summary Box 출력 필수 (규격: `post-execution-summary.md`)
