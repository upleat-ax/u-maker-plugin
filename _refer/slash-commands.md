# Slash Commands Reference

> u-maker 플러그인의 모든 슬래시 커맨드(`/u-*`) 정의 및 동작 명세.

---

## 1. Lifecycle Commands

프로젝트 라이프사이클을 관리하는 핵심 커맨드.

### `/u-skill-create-project`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-create-project <project-name>` |
| **Description** | 새 프로젝트를 생성하고 .u-maker/docs/ 구조를 초기화한다 |
| **Calling Agents** | Orchestrator → `u-RA` |
| **Prerequisites** | None |
| **Output** | `.u-maker/docs/` 디렉토리 구조 생성, `1_Index_PM.md` 초기화, `.u-maker/u-maker.config.json` 초기화 |

### `/u-skill-init`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-init [project-path]` |
| **Description** | 기존 프로젝트의 리소스(package.json, 소스코드, DB 스키마, README 등)를 분석하여 SSoT 문서를 역공학으로 자동 생성한다 |
| **Calling Agents** | Orchestrator → `u-RA` → `u-SA` → `u-UX` → `u-PM` |
| **Prerequisites** | 프로젝트 파일 존재 (package.json 등) |
| **Output** | `.u-maker/docs/` 구조 생성, 분석 기반 SSoT 문서 자동 생성 (Draft), `.u-maker/u-maker.config.json` 업데이트 |

**Scan Targets**: package.json, README.md, 페이지/라우트 구조, API 라우트, Prisma/Drizzle 스키마, 컴포넌트 파일

**Difference from `/u-skill-create-project`**: 새 프로젝트를 스캐폴딩하는 것이 아니라, 기존 코드에서 정보를 추출하여 문서를 사전 작성한다. 모든 문서는 Draft 상태로 생성되어 사용자 검토가 필요하다.

### `/u-skill-plan`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-plan [app]` |
| **Description** | PLAN Phase를 실행한다. Roadmap, SRS, IA, Index를 순서대로 생성한다 |
| **Calling Agents** | Orchestrator → (`u-PM` ↔ `u-SA`) → `u-UX` → `u-PM` |
| **Prerequisites** | 프로젝트 생성 완료 (`.u-maker/docs/` 존재) |
| **Output** | `1_Roadmap_PM.md`, `1_SRS_RA.md`, `1_IA_RA.md`, `1_Index_PM.md` |

### `/u-skill-design`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-design [app]` |
| **Description** | DESIGN Phase를 실행한다. UXGuide, Screen, ScreenFlow, ERD, API Contract, RTM을 생성한다 |
| **Calling Agents** | Orchestrator → `u-UX` → `u-SA` → `u-RA` |
| **Prerequisites** | PLAN Gate 통과 (`1_Roadmap_PM`, `1_SRS_RA`, `1_IA_RA` 모두 Final) |
| **Output** | `2_UXGuide_UX.md`, `2_Screen_UX.md`, `2_ScreenFlow_UX.md`, `2_ERD_SA.md`, `2_API_SA.md`, `2_RTM_RA.md` |

### `/u-skill-dev`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-dev [app]` |
| **Description** | DO Phase를 실행한다. UX/Frontend/Backend 병렬 개발 |
| **Calling Agents** | Orchestrator → `u-UX` + `u-DV-FE` + `u-DV-BE` |
| **Prerequisites** | DESIGN Gate 통과 (`2_ERD_SA`, `2_RTM_RA`, `2_API_SA`, `2_Screen_UX`, `2_ScreenFlow_UX`, `2_UXGuide_UX` 모두 Final + u-RA 검수) |
| **Output** | 코드 파일 + `3_Screen_UX.md`, `3_UIComponents_UX.md`, `3_DesignToken_UX.md`, `3_Code_DV.md` |

### `/u-skill-check`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-check [app]` |
| **Description** | CHECK Phase를 실행한다. Unit+E2E 테스트 케이스 설계(상세 스텝), 실행, 결함 분석 |
| **Calling Agents** | Orchestrator → `u-QA` |
| **Prerequisites** | DO Gate 통과 (코드 구현 완료 + `bun run build` 성공) |
| **Output** | `4_Case_QA.md`, `4_Report_QA.md` |

### `/u-skill-act`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-act` |
| **Description** | ACT Phase를 실행한다. 백로그 정리, 회고, 데일리 리포트, 아카이브 |
| **Calling Agents** | Orchestrator → `u-RA` + `u-PM` |
| **Prerequisites** | CHECK Phase 완료 (종료 조건 미충족) |
| **Output** | `5_IterationLog_RA.md`, `5_Retrospective_PM.md`, `5_DailyReport_PM_yyyymmddhhmm.md` |

---

## 2. Auto-Loop Commands

PDCA 사이클 자동 반복을 제어하는 커맨드.

### `/u-skill-loop`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-loop` |
| **Description** | PDCA 사이클을 종료 조건 충족까지 자동 반복한다 |
| **Calling Agents** | Orchestrator (전체 에이전트 순차 호출) |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 전체 SSoT 문서 + 코드 + 테스트 결과 |

### `/u-skill-loop-from`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-loop-from <phase>` (plan / design / dev / check / act) |
| **Description** | 지정된 Phase부터 루프를 시작한다 |
| **Calling Agents** | Orchestrator (지정 Phase부터 에이전트 순차 호출) |
| **Prerequisites** | 선행 Phase 문서가 Final 상태 |
| **Output** | 지정 Phase부터의 SSoT 문서 |

### `/u-skill-stop`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-stop` |
| **Description** | 실행 중인 루프를 즉시 중단한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | 루프 실행 중 (`loopStatus = RUNNING`) |
| **Output** | 현재 상태 저장, 루프 상태 `PAUSED`로 변경 |

### `/u-skill-resume`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-resume` |
| **Description** | 중단된 루프를 재개한다 |
| **Calling Agents** | Orchestrator (중단 지점부터 에이전트 호출) |
| **Prerequisites** | 루프 중단 상태 (`loopStatus = PAUSED`) |
| **Output** | 루프 재개, 루프 상태 `RUNNING`으로 변경 |

---

## 3. Agent Direct Commands

특정 에이전트를 직접 호출하여 자유 형식 작업을 요청하는 커맨드.

### `/u-agent-pm`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-agent-pm [task description]` |
| **Description** | Agent PM(Product Manager)에게 직접 작업을 요청한다 |
| **Calling Agents** | `u-PM` |
| **Prerequisites** | None |
| **Output** | 요청에 따라 다름 |

### `/u-agent-ra`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-agent-ra [task description]` |
| **Description** | Agent RA(Requirements & Admin)에게 직접 작업을 요청한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | None |
| **Output** | 요청에 따라 다름 |

### `/u-agent-sa`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-agent-sa [task description]` |
| **Description** | Agent SA(Software Architect)에게 직접 작업을 요청한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | None |
| **Output** | 요청에 따라 다름 |

### `/u-agent-ux`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-agent-ux [task description]` |
| **Description** | Agent UX(UX Designer)에게 직접 작업을 요청한다 |
| **Calling Agents** | `u-UX` |
| **Prerequisites** | None |
| **Output** | 요청에 따라 다름 |

### `/u-agent-qa`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-agent-qa [task description]` |
| **Description** | Agent QA(Tester)에게 직접 작업을 요청한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | None |
| **Output** | 요청에 따라 다름 |

---

## 4. Document Management Commands

SSoT 문서 상태를 관리하고 검증하는 커맨드.

### `/u-skill-status`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-status` |
| **Description** | 현재 Iteration, Phase, 완료율, 문서 상태를 보고한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 상태 보고 배너 (터미널 출력) |

### `/u-skill-docs`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-docs` |
| **Description** | 모든 SSoT 문서 목록과 상태(Draft/Review/Final)를 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 문서 목록 테이블 (터미널 출력) |

### `/u-skill-validate`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-validate` |
| **Description** | SSoT 문서 무결성을 검증한다 (헤더, 추적성, 구조) |
| **Calling Agents** | `u-RA` + `scripts/validate-ssot.py` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 검증 결과 보고서 (Pass/Fail 항목별) |

### `/u-skill-backlog`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-backlog` |
| **Description** | 현재 백로그 항목을 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `5_IterationLog_RA.md` 존재 |
| **Output** | 백로그 테이블 (터미널 출력) |

### `/u-skill-backlog-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-backlog-add [description]` |
| **Description** | 새로운 백로그 항목을 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`5_IterationLog_RA.md` 없으면 자동 생성) |
| **Output** | `5_IterationLog_RA.md` 업데이트 (Table row + Detail block + Summary 갱신) |

**Input Fields**: Type (Bug/Enhancement/Task), Priority (Critical/Major/Minor/Trivial), Origin (PLAN/DESIGN/DEV/CHECK), Assignee, Related FT, Acceptance Criteria

### `/u-skill-us-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-us-add [description]` |
| **Description** | 새로운 유저 스토리를 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_Roadmap_PM.md` 없으면 자동 생성) |
| **Output** | `1_Roadmap_PM.md` 업데이트 (Table row + Change Log 갱신) |

**Input Fields**: As a (역할), I want to (필요/의도), So that (효과), Priority (Must/Should/Could/Won't), FR Mapping, FT Mapping(선택)

### `/u-skill-fr-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-fr-add [app] [description]` |
| **Description** | 새로운 기능 요구사항(FR)을 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_SRS_RA.md` 없으면 자동 생성) |
| **Output** | `1_SRS_RA.md` 업데이트 (Table row + FR Detail block + Change Log 갱신) |

**Input Fields**: Requirement (요구사항명), Description (설명), Priority (Must/Should/Could/Won't), US Mapping, Input/Output/Business Rule/Exception (선택)

### `/u-skill-glossary`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-glossary [app]` |
| **Description** | 용어 정의(Glossary) 문서를 생성/수정한다. 도메인 용어, 약어, 기술 용어를 정의하고 통일한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `{app}/01-plan/1_Glossary_RA.md` |

### `/u-skill-workflow`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-workflow [app]` |
| **Description** | 주요 워크플로우 정의 문서를 생성/수정한다. 비즈니스 프로세스, 사용자 흐름, 시스템 연동 플로우를 정의한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `1_SRS_RA.md` 존재 (FR/US/FT 참조) |
| **Output** | `{app}/01-plan/1_Workflow_RA.md` |

### `/u-skill-refine`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-refine <FR-NNNN\|US-NNNN\|FT-NNNN> [app]` |
| **Description** | FR, US, FT 항목을 세분화한다. 하나의 큰 항목을 분석하여 하위 항목으로 분해하고 SRS를 갱신한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_SRS_RA.md` 존재) |
| **Output** | `1_SRS_RA.md` 업데이트 (원본 항목 "(세분화됨)" 표시 + 하위 항목 테이블/Detail 추가 + Change Log 갱신) |

**Decomposition Types**: FR → 하위 FR (중간 번호 FR-0011~), US → 하위 US (중간 번호 US-0011~), FT → 하위 FT (중간 번호 FT-0011~)

### `/u-skill-index`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-index` |
| **Description** | 문서 인덱스(`1_Index_PM.md`)를 갱신한다 |
| **Calling Agents** | `u-PM` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `1_Index_PM.md` 업데이트 |

---

## 5. Individual Task Commands

특정 문서/산출물을 개별적으로 생성/수정하는 커맨드.

### `/u-skill-srs`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-srs [app]` |
| **Description** | SRS(Software Requirements Specification)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `1_Roadmap_PM.md` 존재 (optional; SRS 내부 체인은 항상 FR+NFR→US→FT) |
| **Output** | `{app}/01-plan/1_SRS_RA.md` |

### `/u-skill-erd`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-erd` |
| **Description** | ERD(Entity Relationship Diagram)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `1_SRS_RA.md` = Final |
| **Output** | `common/02-design/2_ERD_SA.md` |

### `/u-skill-api`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-api [app]` |
| **Description** | API Contract(OpenAPI 3.0)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `2_ERD_SA.md` 존재 |
| **Output** | `{app}/02-design/2_API_SA.md` |

### `/u-skill-screen`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-screen [app]` |
| **Description** | Screen Design(화면 상세 설계)을 생성/수정한다 |
| **Calling Agents** | `u-UX` |
| **Prerequisites** | `1_IA_RA.md` = Final |
| **Output** | `{app}/02-design/2_Screen_UX.md` |

### `/u-skill-wireframe`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-wireframe [app]` |
| **Description** | 화면 와이어프레임을 HTML로 생성/수정한다 |
| **Calling Agents** | `u-UX` |
| **Prerequisites** | `2_Screen_UX.md` 존재 |
| **Output** | `{app}/02-design/2_Screen_Wireframes/*.html` |

### `/u-skill-ux-figma`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-ux-figma [app]` |
| **Description** | pencil.dev MCP를 사용하여 화면을 시각적으로 디자인한다 |
| **Calling Agents** | `u-UX-DS` |
| **Prerequisites** | `2_Screen_UX.md` 존재, 와이어프레임 완료 |
| **Output** | `.pen` 파일 |

### `/u-skill-ux-designsystem`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-ux-designsystem [app]` |
| **Description** | pencil.dev를 사용해 디자인 시스템, 컴포넌트를 시각적으로 구성한다 |
| **Calling Agents** | `u-UX-DS` |
| **Prerequisites** | `2_UXGuide_UX.md` 존재 |
| **Output** | `.pen` 파일 |

### `/u-skill-testcase`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-testcase [app]` |
| **Description** | SRS FT 기반으로 Unit+E2E 테스트 케이스를 상세 설계한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | `1_SRS_RA.md` = Final |
| **Output** | `{app}/04-check/4_Case_QA.md` |

### `/u-skill-tc-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-tc-add [app] [FT-NNNN] [description]` |
| **Description** | 새로운 테스트 케이스(TC)를 개별 추가한다. `app=all`이면 모든 앱에 추가. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | `1_SRS_RA.md` 존재 (FT 유효성 검증 필요) |
| **Output** | `{app}/04-check/4_Case_QA.md` 업데이트 (TC row + Detail block + coverageMatrix + Change Log 갱신), `_links.json` qa 필드 갱신 |

**Input Fields**: FT Mapping (필수), Title, Level (Unit/E2E), Type (Positive/Negative/Boundary), Priority (Critical/Major/Minor/Trivial), Actor, Precondition, AutomationTarget, Steps (6W: step/screen/element/action/input/expected)

### `/u-skill-tc-refine`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-tc-refine <TC-NNNN> [app]` |
| **Description** | 테스트 케이스를 세분화한다. 하나의 큰 TC를 분석하여 하위 TC로 분해하고 4_Case_QA.md를 갱신한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | `4_Case_QA.md` 존재, 대상 TC-NNNN 존재 |
| **Output** | `{app}/04-check/4_Case_QA.md` 업데이트 (원본 TC "*(세분화됨)*" 표시 + 하위 TC 테이블/Detail 추가 + coverageMatrix + Change Log 갱신), `_links.json` qa 필드 갱신 |

**Decomposition Criteria**: 시나리오 독립성, Type 분리(Positive/Negative/Boundary), Level 분리(Unit/E2E), 스텝 복잡도, 입력 데이터 분기

### `/u-skill-qa`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-qa [app]` |
| **Description** | 테스트를 실행한다. Unit Test(Vitest) + E2E Test(Playwright) 실행 및 결과 리포트 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | `4_Case_QA.md` 존재, `bun run build` 성공 |
| **Output** | `{app}/04-check/4_Report_QA.md` |

### `/u-skill-fix`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-fix [app] [FT-NNNN\|description]` |
| **Description** | 버그/기능을 수정한다. 코드를 fix한 후, 백그라운드에서 QA 에이전트가 해당 수정에 대한 TC가 없으면 자동 추가한다 |
| **Calling Agents** | `u-DV-FE` / `u-DV-BE` (foreground) + `u-QA` (background) |
| **Prerequisites** | 프로젝트 코드 존재, `1_SRS_RA.md` 존재 (FT 유효성 검증) |
| **Output** | 수정된 코드 파일 + `{app}/04-check/4_Case_QA.md` 갱신 (background) |

**Workflow**:
- Foreground: 관련 코드 분석 → FE/BE 에이전트를 통한 코드 수정 → 빌드 검증
- Background: QA 에이전트가 4_Case_QA.md에서 해당 FT의 TC 존재 여부 확인 → 없으면 Positive/Negative TC 자동 추가

### `/u-skill-report`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-report [app]` |
| **Description** | 프로젝트 종합 보고서를 생성한다. SSoT 문서와 git 이력 기반으로 FR/US/FT/NFR 구현 현황, QA 결과, 결함 목록, 기술 부채, Iteration 이력을 포함한다 |
| **Calling Agents** | `u-PM` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `common/05-act/5_Report_PM_yyyymmddhhmm.md` + `.html` |

---

## 6. Quality Assurance Commands

CHECK Phase에서 설계-구현 일치도를 분석하는 커맨드.

### `/u-skill-gap-detector`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-gap-detector` |
| **Description** | SSoT 설계 문서(SRS, ERD, API, Screen)와 실제 구현 코드를 비교하여 Gap을 분석한다 |
| **Calling Agents** | `u-RA` (문서 수집) → `u-QA` (항목별 매칭 검사) |
| **Prerequisites** | DO Phase 완료 (코드 구현 존재), 설계 문서(SRS, ERD, API) Final 상태 |
| **Output** | Gap Analysis Report (`4_Report_QA.md`에 추가), Match Rate 산출 |

**Analysis Targets**:
- **SRS FT 검사**: `1_SRS_RA.md`의 모든 FT 항목이 코드에 구현되었는지 확인
- **API Endpoint 검사**: `2_API_SA.md`의 모든 Endpoint가 API Route에 존재하는지 확인
- **ERD Entity 검사**: `2_ERD_SA.md`의 모든 Entity가 DB Schema/ORM에 정의되었는지 확인
- **Screen 검사**: `2_Screen_UX.md`의 모든 화면이 페이지/컴포넌트로 구현되었는지 확인

**Match Rate 기준**:
- >= 90%: PASS → CHECK 통과 가능
- < 90%: FAIL → ACT Phase에서 Gap 항목을 백로그로 전환

---

## 7. Utility Commands

프로젝트 유틸리티 커맨드.

### `/u-skill-help`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-help` |
| **Description** | 사용 가능한 모든 커맨드 목록과 도움말을 표시한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | None |
| **Output** | 커맨드 도움말 (터미널 출력) |

### `/u-skill-history`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-history` |
| **Description** | Iteration 이력을 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `5_IterationLog_RA.md` 존재 |
| **Output** | Iteration 이력 테이블 (터미널 출력) |

### `/u-skill-archive`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-archive` |
| **Description** | 현재 Iteration 문서를 아카이브한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | ACT Phase 진행 중 |
| **Output** | `.u-maker/docs/iterations/iter-N/` 디렉토리에 문서 복사 |

### `/u-skill-storybook`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-storybook` |
| **Description** | Storybook 스토리를 생성/업데이트한다 |
| **Calling Agents** | `u-DV-FE` |
| **Prerequisites** | UI 컴포넌트 코드 존재 |
| **Output** | `*.stories.tsx` 파일 |

### `/u-skill-build`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-build` |
| **Description** | 프로젝트 빌드를 실행한다 (`bun run build`) |
| **Calling Agents** | Orchestrator (Bash) |
| **Prerequisites** | 프로젝트 코드 존재 |
| **Output** | 빌드 결과 (성공/실패 + 로그) |

### `/u-skill-summary`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-summary` |
| **Description** | 프로젝트 개요와 개발 상태를 콘솔에 요약 출력한다 (파일 생성 없음) |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 프로젝트 요약 (터미널 출력) |

### `/u-skill-git-pr`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-git-pr [feat/<feature-name>]` |
| **Description** | 변경된 파일을 feature 단위로 그룹핑하여 git commit 후 GitHub PR을 생성한다 |
| **Calling Agents** | Orchestrator (Bash + gh CLI) |
| **Prerequisites** | git 저장소 초기화 완료, 변경된 파일 존재 |
| **Output** | feature 브랜치 생성, commit, push, PR URL 출력 |

### `/u-skill-html-doc`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-html-doc [doc-type] [app]` |
| **Description** | SSoT 문서(.md + .json)를 인터랙티브 HTML 뷰어/보고서로 변환한다. Plan~Act 전 Phase 문서를 지원한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | 변환 대상 SSoT 문서 존재 |
| **Output** | 원본 .md와 동일 경로에 `.html` 파일 생성 |

**doc-type (Plan)**: `srs`, `ia`, `common`, `roadmap`
**doc-type (Design)**: `erd`, `api`, `screen`, `screenflow`, `uxguide`, `rtm`
**doc-type (Dev)**: `code`, `uicomponents`, `designtoken`
**doc-type (Check)**: `testcase`, `qareport`
**doc-type (Act)**: `iteration`, `report`
**doc-type (All)**: `all` — 전체 문서 변환 (파일 없으면 Skip)

**Feature Grouping**: 변경 파일을 디렉토리/문서 기준으로 feature 단위로 자동 분류하거나, 사용자가 feature 이름을 직접 지정할 수 있다.

**Rules**:
- main 브랜치에 직접 commit하지 않음 (항상 feature 브랜치)
- PR 생성 전 `git diff`로 변경 내용 사용자 확인
- force push 금지, 민감 파일 commit 차단
- 하나의 PR에는 하나의 feature만 포함

---

### `/u-skill-import`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-skill-import [source-type] [path-or-url]` |
| **Description** | 외부 소스(문서, Figma, pencil, Stitch, URL, 이미지)를 SSoT 문서로 변환한다 |
| **Calling Agents** | u-RA, u-SA, u-UX (소스 유형에 따라) |
| **Prerequisites** | 소스 파일/URL 또는 `.u-maker/refs/_sources.json` |
| **Output** | SSoT 문서 생성/갱신 (Draft 상태) |

**source-type**: `figma`, `pencil`, `stitch`, `url`, `doc`, `image`
**서브커맨드**: `init` (refs/ 구조 초기화), `sources` (현황 조회)
**일괄 모드**: 인자 없이 실행 시 `_sources.json`의 `pending` 소스 일괄 처리

---

## 8. Command Summary Table

| Category | Command | Phase | Agents |
|----------|---------|-------|--------|
| Lifecycle | `/u-skill-create-project` | - | Orch → u-RA |
| Lifecycle | `/u-skill-init` | - | Orch → u-RA → u-SA → u-UX → u-PM |
| Lifecycle | `/u-skill-plan [app]` | PLAN | Orch → (u-PM ↔ u-SA) → u-UX → u-PM |
| Lifecycle | `/u-skill-design [app]` | DESIGN | Orch → u-UX → u-SA → u-RA |
| Lifecycle | `/u-skill-dev [app]` | DO | Orch → u-UX + u-DV-FE + u-DV-BE |
| Lifecycle | `/u-skill-check [app]` | CHECK | Orch → u-QA |
| Lifecycle | `/u-skill-act` | ACT | Orch → u-RA + u-PM |
| Auto-Loop | `/u-skill-loop` | ALL | Orch → All |
| Auto-Loop | `/u-skill-loop-from` | Varies | Orch → Varies |
| Auto-Loop | `/u-skill-stop` | - | Orch |
| Auto-Loop | `/u-skill-resume` | - | Orch |
| Agent Direct | `/u-agent-pm` | - | u-PM |
| Agent Direct | `/u-agent-ra` | - | u-RA |
| Agent Direct | `/u-agent-sa` | - | u-SA |
| Agent Direct | `/u-agent-ux` | - | u-UX |
| Agent Direct | `/u-agent-qa` | - | u-QA |
| Doc Mgmt | `/u-skill-status` | - | u-RA |
| Doc Mgmt | `/u-skill-docs` | - | u-RA |
| Doc Mgmt | `/u-skill-validate` | - | u-RA + script |
| Doc Mgmt | `/u-skill-backlog` | - | u-RA |
| Doc Mgmt | `/u-skill-backlog-add` | - | u-RA |
| Doc Mgmt | `/u-skill-us-add` | PLAN | u-RA |
| Doc Mgmt | `/u-skill-fr-add` | PLAN | u-SA |
| Doc Mgmt | `/u-skill-glossary [app]` | PLAN | u-RA |
| Doc Mgmt | `/u-skill-workflow [app]` | PLAN | u-RA |
| Doc Mgmt | `/u-skill-refine` | PLAN | u-SA |
| Doc Mgmt | `/u-skill-index` | - | u-PM |
| Task | `/u-skill-srs [app]` | PLAN | u-SA |
| Task | `/u-skill-erd` | DESIGN | u-SA |
| Task | `/u-skill-api [app]` | DESIGN | u-SA |
| Task | `/u-skill-screen [app]` | DESIGN | u-UX |
| Task | `/u-skill-wireframe [app]` | DESIGN | u-UX |
| Task | `/u-skill-ux-figma [app]` | DESIGN | u-UX-DS |
| Task | `/u-skill-ux-designsystem [app]` | DESIGN | u-UX-DS |
| Task | `/u-skill-testcase [app]` | CHECK | u-QA |
| Task | `/u-skill-tc-add [app] [FT] [desc]` | CHECK | u-QA |
| Task | `/u-skill-tc-refine <TC> [app]` | CHECK | u-QA |
| Task | `/u-skill-qa [app]` | CHECK | u-QA |
| Task | `/u-skill-fix [app] [FT\|desc]` | DO | u-DV-FE / u-DV-BE + u-QA (bg) |
| Task | `/u-skill-report [app]` | ACT | u-PM |
| QA | `/u-skill-gap-detector` | CHECK | u-RA → u-QA |
| Utility | `/u-skill-help` | - | Orch |
| Utility | `/u-skill-history` | - | u-RA |
| Utility | `/u-skill-archive` | ACT | u-RA |
| Utility | `/u-skill-storybook` | DO | u-DV-FE |
| Utility | `/u-skill-build` | DO | Orch (Bash) |
| Utility | `/u-skill-summary` | - | u-RA |
| Utility | `/u-skill-git-pr` | - | Orch (Bash + gh) |
| Utility | `/u-skill-html-doc [doc-type] [app]` | - | Orch |
| Utility | `/u-skill-import [source-type] [path-or-url]` | - | u-RA, u-SA, u-UX |
