# Slash Commands Reference

> u-maker 플러그인의 모든 슬래시 커맨드(`/u-*`) 정의 및 동작 명세.

---

## 1. Lifecycle Commands

프로젝트 라이프사이클을 관리하는 핵심 커맨드.

### `/uc-create-project`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-create-project <project-name>` |
| **Description** | 새 프로젝트를 생성하고 u-docs/ 구조를 초기화한다 |
| **Calling Agents** | Orchestrator → `u-RA` |
| **Prerequisites** | None |
| **Output** | `u-docs/` 디렉토리 구조 생성, `1_Index_PM.md` 초기화, `u-maker.config.json` 초기화 |

### `/uc-init`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-init [project-path]` |
| **Description** | 기존 프로젝트의 리소스(package.json, 소스코드, DB 스키마, README 등)를 분석하여 SSoT 문서를 역공학으로 자동 생성한다 |
| **Calling Agents** | Orchestrator → `u-RA` → `u-SA` → `u-UX` → `u-RA` |
| **Prerequisites** | 프로젝트 파일 존재 (package.json 등) |
| **Output** | `u-docs/` 구조 생성, 분석 기반 SSoT 문서 자동 생성 (Draft), `u-maker.config.json` 업데이트 |

**Scan Targets**: package.json, README.md, 페이지/라우트 구조, API 라우트, Prisma/Drizzle 스키마, 컴포넌트 파일

**Difference from `/uc-create-project`**: 새 프로젝트를 스캐폴딩하는 것이 아니라, 기존 코드에서 정보를 추출하여 문서를 사전 작성한다. 모든 문서는 Draft 상태로 생성되어 사용자 검토가 필요하다.

### `/uc-plan`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-plan [app]` |
| **Description** | PLAN Phase를 실행한다. Roadmap, SRS, IA, Index를 순서대로 생성한다 |
| **Calling Agents** | Orchestrator → (`u-RA` ↔ `u-SA`) → `u-UX` → `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`u-docs/` 존재) |
| **Output** | `1_Roadmap_PM.md`, `1_SRS_RA.md`, `1_IA_RA.md`, `1_Index_PM.md` |

### `/uc-design`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-design [app]` |
| **Description** | DESIGN Phase를 실행한다. DesignSystem, Screen, ERD, API Contract를 생성한다 |
| **Calling Agents** | Orchestrator → `u-UX` → `u-SA` → `u-RA` |
| **Prerequisites** | PLAN Gate 통과 (`1_Roadmap_PM`, `1_SRS_RA`, `1_IA_RA` 모두 Final) |
| **Output** | `2_UXGuide_UX.md`, `2_Screen_UX.md`, `2_ERD_SA.md`, `2_API_SA.md` |

### `/uc-dev`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-dev [app]` |
| **Description** | DO Phase를 실행한다. UX/Frontend/Backend 병렬 개발 |
| **Calling Agents** | Orchestrator → `u-UX` + `u-DV-FE` + `u-DV-BE` |
| **Prerequisites** | DESIGN Gate 통과 (`2_ERD_SA`, `2_API_SA`, `2_Screen_UX`, `2_UXGuide_UX` 모두 Final + u-RA 검수) |
| **Output** | 코드 파일 + `3_Screen_UX.md`, `3_UIComponents_UX.md`, `3_DesignToken_UX.md`, `3_Code_DV.md` |

### `/uc-check`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-check [app]` |
| **Description** | CHECK Phase를 실행한다. Unit+E2E 테스트 케이스 설계(상세 스텝), 실행, 결함 분석 |
| **Calling Agents** | Orchestrator → `u-QA` |
| **Prerequisites** | DO Gate 통과 (코드 구현 완료 + `bun run build` 성공) |
| **Output** | `4_Case_QA.md`, `4_Report_QA.md` |

### `/uc-act`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-act` |
| **Description** | ACT Phase를 실행한다. 백로그 정리, 아카이브, 회고 |
| **Calling Agents** | Orchestrator → `u-RA` |
| **Prerequisites** | CHECK Phase 완료 (종료 조건 미충족) |
| **Output** | `5_IterationLog_RA.md`, `5_Retrospective_PM.md` |

---

## 2. Auto-Loop Commands

PDCA 사이클 자동 반복을 제어하는 커맨드.

### `/uc-loop`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-loop` |
| **Description** | PDCA 사이클을 종료 조건 충족까지 자동 반복한다 |
| **Calling Agents** | Orchestrator (전체 에이전트 순차 호출) |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 전체 SSoT 문서 + 코드 + 테스트 결과 |

### `/uc-loop-from`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-loop-from <phase>` (plan / design / dev / check / act) |
| **Description** | 지정된 Phase부터 루프를 시작한다 |
| **Calling Agents** | Orchestrator (지정 Phase부터 에이전트 순차 호출) |
| **Prerequisites** | 선행 Phase 문서가 Final 상태 |
| **Output** | 지정 Phase부터의 SSoT 문서 |

### `/uc-stop`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-stop` |
| **Description** | 실행 중인 루프를 즉시 중단한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | 루프 실행 중 (`loopStatus = RUNNING`) |
| **Output** | 현재 상태 저장, 루프 상태 `PAUSED`로 변경 |

### `/uc-resume`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-resume` |
| **Description** | 중단된 루프를 재개한다 |
| **Calling Agents** | Orchestrator (중단 지점부터 에이전트 호출) |
| **Prerequisites** | 루프 중단 상태 (`loopStatus = PAUSED`) |
| **Output** | 루프 재개, 루프 상태 `RUNNING`으로 변경 |

---

## 3. Document Management Commands

SSoT 문서 상태를 관리하고 검증하는 커맨드.

### `/uc-status`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-status` |
| **Description** | 현재 Iteration, Phase, 완료율, 문서 상태를 보고한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 상태 보고 배너 (터미널 출력) |

### `/uc-docs`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-docs` |
| **Description** | 모든 SSoT 문서 목록과 상태(Draft/Review/Final)를 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 문서 목록 테이블 (터미널 출력) |

### `/uc-validate`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-validate` |
| **Description** | SSoT 문서 무결성을 검증한다 (헤더, 추적성, 구조) |
| **Calling Agents** | `u-RA` + `scripts/validate-ssot.py` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 검증 결과 보고서 (Pass/Fail 항목별) |

### `/uc-backlog`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-backlog` |
| **Description** | 현재 백로그 항목을 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `5_IterationLog_RA.md` 존재 |
| **Output** | 백로그 테이블 (터미널 출력) |

### `/uc-backlog-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-backlog-add [description]` |
| **Description** | 새로운 백로그 항목을 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`5_IterationLog_RA.md` 없으면 자동 생성) |
| **Output** | `5_IterationLog_RA.md` 업데이트 (Table row + Detail block + Summary 갱신) |

**Input Fields**: Type (Bug/Enhancement/Task), Priority (Critical/Major/Minor/Trivial), Origin (PLAN/DESIGN/DEV/CHECK), Assignee, Related FR, Acceptance Criteria

### `/uc-us-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-us-add [description]` |
| **Description** | 새로운 유저 스토리를 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_Roadmap_PM.md` 없으면 자동 생성) |
| **Output** | `1_Roadmap_PM.md` 업데이트 (Table row + Change Log 갱신) |

**Input Fields**: As a (역할), I want to (기능), So that (효과), Priority (Must/Should/Could/Won't), FR Mapping

### `/uc-fr-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-fr-add [app] [description]` |
| **Description** | 새로운 기능 요구사항(FR)을 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_SRS_RA.md` 없으면 자동 생성) |
| **Output** | `1_SRS_RA.md` 업데이트 (Table row + FR Detail block + Change Log 갱신) |

**Input Fields**: Feature (기능명), Description (설명), Priority (Must/Should/Could/Won't), US Mapping, Input/Output/Business Rule/Exception (선택)

### `/uc-index`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-index` |
| **Description** | 문서 인덱스(`1_Index_PM.md`)를 갱신한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `1_Index_PM.md` 업데이트 |

---

## 4. Individual Agent Commands

특정 에이전트를 직접 호출하여 개별 문서를 생성/수정하는 커맨드.

### `/uc-srs`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-srs [app]` |
| **Description** | SRS(Software Requirements Specification)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `1_Roadmap_PM.md` 존재 (optional; FR-First 시 없이도 실행 가능) |
| **Output** | `{app}/01-plan/1_SRS_RA.md` |

### `/uc-erd`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-erd` |
| **Description** | ERD(Entity Relationship Diagram)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `1_SRS_RA.md` = Final |
| **Output** | `shared/02-design/2_ERD_SA.md` |

### `/uc-api`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-api [app]` |
| **Description** | API Contract(OpenAPI 3.0)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `2_ERD_SA.md` 존재 |
| **Output** | `{app}/02-design/2_API_SA.md` |

### `/uc-screen`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-screen [app]` |
| **Description** | Screen Design(화면 상세 설계)을 생성/수정한다 |
| **Calling Agents** | `u-UX` |
| **Prerequisites** | `1_IA_RA.md` = Final |
| **Output** | `{app}/02-design/2_Screen_UX.md` |

### `/uc-fe`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-fe [app]` |
| **Description** | Frontend 코드를 생성한다 |
| **Calling Agents** | `u-DV-FE` |
| **Prerequisites** | `2_Screen_UX.md` = Final, `2_API_SA.md` = Final |
| **Output** | Frontend code files + `3_Code_DV.md` 업데이트 |

### `/uc-be`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-be [app]` |
| **Description** | Backend 코드를 생성한다 |
| **Calling Agents** | `u-DV-BE` |
| **Prerequisites** | `2_ERD_SA.md` = Final, `2_API_SA.md` = Final |
| **Output** | Backend code files + `3_Code_DV.md` 업데이트 |

### `/uc-test`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-test [app]` |
| **Description** | Unit+E2E 테스트 케이스를 상세 설계하고 실행한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | DO Phase 완료 |
| **Output** | `4_Case_QA.md`, `4_Report_QA.md` |

### `/uc-bug-report`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-bug-report [app]` |
| **Description** | 결함 분석 리포트를 생성한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | `4_Report_QA.md` 존재 |
| **Output** | 결함 분석 결과, `5_IterationLog_RA.md` 업데이트 |

---

## 5. Quality Assurance Commands

CHECK Phase에서 설계-구현 일치도를 분석하는 커맨드.

### `/uc-gap-detector`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-gap-detector` |
| **Description** | SSoT 설계 문서(SRS, ERD, API, Screen)와 실제 구현 코드를 비교하여 Gap을 분석한다 |
| **Calling Agents** | `u-RA` (문서 수집) → `u-QA` (항목별 매칭 검사) |
| **Prerequisites** | DO Phase 완료 (코드 구현 존재), 설계 문서(SRS, ERD, API) Final 상태 |
| **Output** | Gap Analysis Report (`4_Report_QA.md`에 추가), Match Rate 산출 |

**Analysis Targets**:
- **SRS FR 검사**: `1_SRS_RA.md`의 모든 FR 항목이 코드에 구현되었는지 확인
- **API Endpoint 검사**: `2_API_SA.md`의 모든 Endpoint가 API Route에 존재하는지 확인
- **ERD Entity 검사**: `2_ERD_SA.md`의 모든 Entity가 DB Schema/ORM에 정의되었는지 확인
- **Screen 검사**: `2_Screen_UX.md`의 모든 화면이 페이지/컴포넌트로 구현되었는지 확인

**Match Rate 기준**:
- >= 90%: PASS → CHECK 통과 가능
- < 90%: FAIL → ACT Phase에서 Gap 항목을 백로그로 전환

---

## 6. Utility Commands

프로젝트 유틸리티 커맨드.

### `/uc-help`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-help` |
| **Description** | 사용 가능한 모든 커맨드 목록과 도움말을 표시한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | None |
| **Output** | 커맨드 도움말 (터미널 출력) |

### `/uc-history`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-history` |
| **Description** | Iteration 이력을 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `5_IterationLog_RA.md` 존재 |
| **Output** | Iteration 이력 테이블 (터미널 출력) |

### `/uc-archive`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-archive` |
| **Description** | 현재 Iteration 문서를 아카이브한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | ACT Phase 진행 중 |
| **Output** | `u-docs/iterations/iter-N/` 디렉토리에 문서 복사 |

### `/uc-storybook`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-storybook` |
| **Description** | Storybook 스토리를 생성/업데이트한다 |
| **Calling Agents** | `u-DV-FE` |
| **Prerequisites** | UI 컴포넌트 코드 존재 |
| **Output** | `*.stories.tsx` 파일 |

### `/uc-build`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-build` |
| **Description** | 프로젝트 빌드를 실행한다 (`bun run build`) |
| **Calling Agents** | Orchestrator (Bash) |
| **Prerequisites** | 프로젝트 코드 존재 |
| **Output** | 빌드 결과 (성공/실패 + 로그) |

### `/uc-git-pr`

| Field | Value |
|-------|-------|
| **Syntax** | `/uc-git-pr [feat/<feature-name>]` |
| **Description** | 변경된 파일을 feature 단위로 그룹핑하여 git commit 후 GitHub PR을 생성한다 |
| **Calling Agents** | Orchestrator (Bash + gh CLI) |
| **Prerequisites** | git 저장소 초기화 완료, 변경된 파일 존재 |
| **Output** | feature 브랜치 생성, commit, push, PR URL 출력 |

**Feature Grouping**: 변경 파일을 디렉토리/문서 기준으로 feature 단위로 자동 분류하거나, 사용자가 feature 이름을 직접 지정할 수 있다.

**Rules**:
- main 브랜치에 직접 commit하지 않음 (항상 feature 브랜치)
- PR 생성 전 `git diff`로 변경 내용 사용자 확인
- force push 금지, 민감 파일 commit 차단
- 하나의 PR에는 하나의 feature만 포함

---

## 7. Command Summary Table

| Category | Command | Phase | Agents |
|----------|---------|-------|--------|
| Lifecycle | `/uc-create-project` | - | Orch → u-RA |
| Lifecycle | `/uc-init` | - | Orch → u-RA → u-SA → u-UX → u-RA |
| Lifecycle | `/uc-plan [app]` | PLAN | Orch → (u-RA ↔ u-SA) → u-UX → u-RA |
| Lifecycle | `/uc-design [app]` | DESIGN | Orch → u-UX → u-SA → u-RA |
| Lifecycle | `/uc-dev [app]` | DO | Orch → u-UX + u-DV-FE + u-DV-BE |
| Lifecycle | `/uc-check [app]` | CHECK | Orch → u-QA |
| Lifecycle | `/uc-act` | ACT | Orch → u-RA |
| Auto-Loop | `/uc-loop` | ALL | Orch → All |
| Auto-Loop | `/uc-loop-from` | Varies | Orch → Varies |
| Auto-Loop | `/uc-stop` | - | Orch |
| Auto-Loop | `/uc-resume` | - | Orch |
| Doc Mgmt | `/uc-status` | - | u-RA |
| Doc Mgmt | `/uc-docs` | - | u-RA |
| Doc Mgmt | `/uc-validate` | - | u-RA + script |
| Doc Mgmt | `/uc-backlog` | - | u-RA |
| Doc Mgmt | `/uc-backlog-add` | - | u-RA |
| Doc Mgmt | `/uc-us-add` | PLAN | u-RA |
| Doc Mgmt | `/uc-fr-add` | PLAN | u-SA |
| Doc Mgmt | `/uc-index` | - | u-RA |
| Agent | `/uc-srs [app]` | PLAN | u-SA |
| Agent | `/uc-erd` | DESIGN | u-SA |
| Agent | `/uc-api [app]` | DESIGN | u-SA |
| Agent | `/uc-screen [app]` | DESIGN | u-UX |
| Agent | `/uc-fe [app]` | DO | u-DV-FE |
| Agent | `/uc-be [app]` | DO | u-DV-BE |
| Agent | `/uc-test [app]` | CHECK | u-QA |
| Agent | `/uc-bug-report [app]` | CHECK | u-QA |
| QA | `/uc-gap-detector` | CHECK | u-RA → u-QA |
| Utility | `/uc-help` | - | Orch |
| Utility | `/uc-history` | - | u-RA |
| Utility | `/uc-archive` | ACT | u-RA |
| Utility | `/uc-storybook` | DO | u-DV-FE |
| Utility | `/uc-build` | DO | Orch (Bash) |
| Utility | `/uc-git-pr` | - | Orch (Bash + gh) |
