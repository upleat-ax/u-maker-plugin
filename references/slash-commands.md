# Slash Commands Reference

> u-ssot 플러그인의 모든 슬래시 커맨드(`/u-*`) 정의 및 동작 명세.

---

## 1. Lifecycle Commands

프로젝트 라이프사이클을 관리하는 핵심 커맨드.

### `/u-create-project`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-create-project <project-name>` |
| **Description** | 새 프로젝트를 생성하고 u-docs/ 구조를 초기화한다 |
| **Calling Agents** | Orchestrator → `u-RA` |
| **Prerequisites** | None |
| **Output** | `u-docs/` 디렉토리 구조 생성, `1_Index_RA.md` 초기화, `u-ssot.config.json` 초기화 |

### `/u-init`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-init [project-path]` |
| **Description** | 기존 프로젝트의 리소스(package.json, 소스코드, DB 스키마, README 등)를 분석하여 SSoT 문서를 역공학으로 자동 생성한다 |
| **Calling Agents** | Orchestrator → `u-RA` → `u-SA` → `u-UX` → `u-RA` |
| **Prerequisites** | 프로젝트 파일 존재 (package.json 등) |
| **Output** | `u-docs/` 구조 생성, 분석 기반 SSoT 문서 자동 생성 (Draft), `u-ssot.config.json` 업데이트 |

**Scan Targets**: package.json, README.md, 페이지/라우트 구조, API 라우트, Prisma/Drizzle 스키마, 컴포넌트 파일

**Difference from `/u-create-project`**: 새 프로젝트를 스캐폴딩하는 것이 아니라, 기존 코드에서 정보를 추출하여 문서를 사전 작성한다. 모든 문서는 Draft 상태로 생성되어 사용자 검토가 필요하다.

### `/u-plan`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-plan` |
| **Description** | PLAN Phase를 실행한다. Roadmap, SRS, IA, Index를 순서대로 생성한다 |
| **Calling Agents** | Orchestrator → (`u-RA` ↔ `u-SA`) → `u-UX` → `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`u-docs/` 존재) |
| **Output** | `1_Roadmap_RA.md`, `1_SRS_SA.md`, `1_IA_UX.md`, `1_Index_RA.md` |

### `/u-design`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-design` |
| **Description** | DESIGN Phase를 실행한다. DesignSystem, Screen, ERD, API Contract를 생성한다 |
| **Calling Agents** | Orchestrator → `u-UX` → `u-SA` → `u-RA` |
| **Prerequisites** | PLAN Gate 통과 (`1_Roadmap_RA`, `1_SRS_SA`, `1_IA_UX` 모두 Final) |
| **Output** | `2_DesignSystem_UX.md`, `2_Screen_UX.md`, `2_ERD_SA.md`, `2_API_SA.md` |

### `/u-dev`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-dev` |
| **Description** | DO Phase를 실행한다. UX/Frontend/Backend 병렬 개발 |
| **Calling Agents** | Orchestrator → `u-UX` + `u-DV-FE` + `u-DV-BE` |
| **Prerequisites** | DESIGN Gate 통과 (`2_ERD_SA`, `2_API_SA`, `2_Screen_UX`, `2_DesignSystem_UX` 모두 Final + u-RA 검수) |
| **Output** | 코드 파일 + `3_Screen_UX.md`, `3_UIComponents_UX.md`, `3_DesignToken_UX.md`, `3_Code_DV.md` |

### `/u-check`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-check` |
| **Description** | CHECK Phase를 실행한다. 테스트 케이스 설계, 실행, 결함 분석 |
| **Calling Agents** | Orchestrator → `u-QA` |
| **Prerequisites** | DO Gate 통과 (코드 구현 완료 + `bun run build` 성공) |
| **Output** | `4_Case_QA.md`, `4_Report_QA.md` |

### `/u-act`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-act` |
| **Description** | ACT Phase를 실행한다. 백로그 정리, 아카이브, 회고 |
| **Calling Agents** | Orchestrator → `u-RA` |
| **Prerequisites** | CHECK Phase 완료 (종료 조건 미충족) |
| **Output** | `5_Backlog_RA.md`, `5_IterationLog_RA.md`, `5_Retrospective_RA.md` |

---

## 2. Auto-Loop Commands

PDCA 사이클 자동 반복을 제어하는 커맨드.

### `/u-loop`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-loop` |
| **Description** | PDCA 사이클을 종료 조건 충족까지 자동 반복한다 |
| **Calling Agents** | Orchestrator (전체 에이전트 순차 호출) |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 전체 SSoT 문서 + 코드 + 테스트 결과 |

### `/u-loop-from`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-loop-from <phase>` (plan / design / dev / check / act) |
| **Description** | 지정된 Phase부터 루프를 시작한다 |
| **Calling Agents** | Orchestrator (지정 Phase부터 에이전트 순차 호출) |
| **Prerequisites** | 선행 Phase 문서가 Final 상태 |
| **Output** | 지정 Phase부터의 SSoT 문서 |

### `/u-stop`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-stop` |
| **Description** | 실행 중인 루프를 즉시 중단한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | 루프 실행 중 (`loopStatus = RUNNING`) |
| **Output** | 현재 상태 저장, 루프 상태 `PAUSED`로 변경 |

### `/u-resume`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-resume` |
| **Description** | 중단된 루프를 재개한다 |
| **Calling Agents** | Orchestrator (중단 지점부터 에이전트 호출) |
| **Prerequisites** | 루프 중단 상태 (`loopStatus = PAUSED`) |
| **Output** | 루프 재개, 루프 상태 `RUNNING`으로 변경 |

---

## 3. Document Management Commands

SSoT 문서 상태를 관리하고 검증하는 커맨드.

### `/u-status`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-status` |
| **Description** | 현재 Iteration, Phase, 완료율, 문서 상태를 보고한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 상태 보고 배너 (터미널 출력) |

### `/u-docs`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-docs` |
| **Description** | 모든 SSoT 문서 목록과 상태(Draft/Review/Final)를 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 문서 목록 테이블 (터미널 출력) |

### `/u-validate`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-validate` |
| **Description** | SSoT 문서 무결성을 검증한다 (헤더, 추적성, 구조) |
| **Calling Agents** | `u-RA` + `scripts/validate-ssot.py` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 검증 결과 보고서 (Pass/Fail 항목별) |

### `/u-backlog`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-backlog` |
| **Description** | 현재 백로그 항목을 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `5_Backlog_RA.md` 존재 |
| **Output** | 백로그 테이블 (터미널 출력) |

### `/u-backlog-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-backlog-add [description]` |
| **Description** | 새로운 백로그 항목을 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`5_Backlog_RA.md` 없으면 자동 생성) |
| **Output** | `5_Backlog_RA.md` 업데이트 (Table row + Detail block + Summary 갱신) |

**Input Fields**: Type (Bug/Enhancement/Task), Priority (Critical/Major/Minor/Trivial), Origin (PLAN/DESIGN/DEV/CHECK), Assignee, Related FR, Acceptance Criteria

### `/u-us-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-us-add [description]` |
| **Description** | 새로운 유저 스토리를 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_Roadmap_RA.md` 없으면 자동 생성) |
| **Output** | `1_Roadmap_RA.md` 업데이트 (Table row + Change Log 갱신) |

**Input Fields**: As a (역할), I want to (기능), So that (효과), Priority (Must/Should/Could/Won't), FR Mapping

### `/u-fr-add`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-fr-add [description]` |
| **Description** | 새로운 기능 요구사항(FR)을 추가한다. 인자 없이 실행하면 대화형으로 입력받는다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | 프로젝트 생성 완료 (`1_SRS_SA.md` 없으면 자동 생성) |
| **Output** | `1_SRS_SA.md` 업데이트 (Table row + FR Detail block + Change Log 갱신) |

**Input Fields**: Feature (기능명), Description (설명), Priority (Must/Should/Could/Won't), US Mapping, Input/Output/Business Rule/Exception (선택)

### `/u-index`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-index` |
| **Description** | 문서 인덱스(`1_Index_RA.md`)를 갱신한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `1_Index_RA.md` 업데이트 |

---

## 4. Individual Agent Commands

특정 에이전트를 직접 호출하여 개별 문서를 생성/수정하는 커맨드.

### `/u-srs`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-srs` |
| **Description** | SRS(Software Requirements Specification)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `1_Roadmap_RA.md` 존재 (optional; FR-First 시 없이도 실행 가능) |
| **Output** | `1_SRS_SA.md` |

### `/u-erd`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-erd` |
| **Description** | ERD(Entity Relationship Diagram)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `1_SRS_SA.md` = Final |
| **Output** | `2_ERD_SA.md` |

### `/u-api`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-api` |
| **Description** | API Contract(OpenAPI 3.0)를 생성/수정한다 |
| **Calling Agents** | `u-SA` |
| **Prerequisites** | `2_ERD_SA.md` 존재 |
| **Output** | `2_API_SA.md` |

### `/u-screen`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-screen` |
| **Description** | Screen Design(화면 상세 설계)을 생성/수정한다 |
| **Calling Agents** | `u-UX` |
| **Prerequisites** | `1_IA_UX.md` = Final |
| **Output** | `2_Screen_UX.md` |

### `/u-fe`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-fe` |
| **Description** | Frontend 코드를 생성한다 |
| **Calling Agents** | `u-DV-FE` |
| **Prerequisites** | `2_Screen_UX.md` = Final, `2_API_SA.md` = Final |
| **Output** | Frontend code files + `3_Code_DV.md` 업데이트 |

### `/u-be`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-be` |
| **Description** | Backend 코드를 생성한다 |
| **Calling Agents** | `u-DV-BE` |
| **Prerequisites** | `2_ERD_SA.md` = Final, `2_API_SA.md` = Final |
| **Output** | Backend code files + `3_Code_DV.md` 업데이트 |

### `/u-test`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-test` |
| **Description** | 테스트 케이스를 설계하고 실행한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | DO Phase 완료 |
| **Output** | `4_Case_QA.md`, `4_Report_QA.md` |

### `/u-bug-report`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-bug-report` |
| **Description** | 결함 분석 리포트를 생성한다 |
| **Calling Agents** | `u-QA` |
| **Prerequisites** | `4_Report_QA.md` 존재 |
| **Output** | 결함 분석 결과, `5_Backlog_RA.md` 업데이트 |

---

## 5. Quality Assurance Commands

CHECK Phase에서 설계-구현 일치도를 분석하는 커맨드.

### `/u-gap-detector`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-gap-detector` |
| **Description** | SSoT 설계 문서(SRS, ERD, API, Screen)와 실제 구현 코드를 비교하여 Gap을 분석한다 |
| **Calling Agents** | `u-RA` (문서 수집) → `u-QA` (항목별 매칭 검사) |
| **Prerequisites** | DO Phase 완료 (코드 구현 존재), 설계 문서(SRS, ERD, API) Final 상태 |
| **Output** | Gap Analysis Report (`4_Report_QA.md`에 추가), Match Rate 산출 |

**Analysis Targets**:
- **SRS FR 검사**: `1_SRS_SA.md`의 모든 FR 항목이 코드에 구현되었는지 확인
- **API Endpoint 검사**: `2_API_SA.md`의 모든 Endpoint가 API Route에 존재하는지 확인
- **ERD Entity 검사**: `2_ERD_SA.md`의 모든 Entity가 DB Schema/ORM에 정의되었는지 확인
- **Screen 검사**: `2_Screen_UX.md`의 모든 화면이 페이지/컴포넌트로 구현되었는지 확인

**Match Rate 기준**:
- >= 90%: PASS → CHECK 통과 가능
- < 90%: FAIL → ACT Phase에서 Gap 항목을 백로그로 전환

---

## 6. Utility Commands

프로젝트 유틸리티 커맨드.

### `/u-help`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-help` |
| **Description** | 사용 가능한 모든 커맨드 목록과 도움말을 표시한다 |
| **Calling Agents** | Orchestrator |
| **Prerequisites** | None |
| **Output** | 커맨드 도움말 (터미널 출력) |

### `/u-history`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-history` |
| **Description** | Iteration 이력을 표시한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | `5_IterationLog_RA.md` 존재 |
| **Output** | Iteration 이력 테이블 (터미널 출력) |

### `/u-archive`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-archive` |
| **Description** | 현재 Iteration 문서를 아카이브한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | ACT Phase 진행 중 |
| **Output** | `u-docs/iterations/iter-N/` 디렉토리에 문서 복사 |

### `/u-storybook`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-storybook` |
| **Description** | Storybook 스토리를 생성/업데이트한다 |
| **Calling Agents** | `u-DV-FE` |
| **Prerequisites** | UI 컴포넌트 코드 존재 |
| **Output** | `*.stories.tsx` 파일 |

### `/u-build`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-build` |
| **Description** | 프로젝트 빌드를 실행한다 (`bun run build`) |
| **Calling Agents** | Orchestrator (Bash) |
| **Prerequisites** | 프로젝트 코드 존재 |
| **Output** | 빌드 결과 (성공/실패 + 로그) |

### `/u-summary`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-summary` |
| **Description** | 프로젝트 개요와 개발 상태를 요약하여 `u-docs/summary.md`에 생성한다 |
| **Calling Agents** | `u-RA` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `u-docs/summary.md` (프로젝트명, 목표, 기능 목록, Iteration/Phase 상태, 문서 현황, 마일스톤) |

### `/u-git-pr`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-git-pr [feat/<feature-name>]` |
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
| Lifecycle | `/u-create-project` | - | Orch → u-RA |
| Lifecycle | `/u-init` | - | Orch → u-RA → u-SA → u-UX → u-RA |
| Lifecycle | `/u-plan` | PLAN | Orch → (u-RA ↔ u-SA) → u-UX → u-RA |
| Lifecycle | `/u-design` | DESIGN | Orch → u-UX → u-SA → u-RA |
| Lifecycle | `/u-dev` | DO | Orch → u-UX + u-DV-FE + u-DV-BE |
| Lifecycle | `/u-check` | CHECK | Orch → u-QA |
| Lifecycle | `/u-act` | ACT | Orch → u-RA |
| Auto-Loop | `/u-loop` | ALL | Orch → All |
| Auto-Loop | `/u-loop-from` | Varies | Orch → Varies |
| Auto-Loop | `/u-stop` | - | Orch |
| Auto-Loop | `/u-resume` | - | Orch |
| Doc Mgmt | `/u-status` | - | u-RA |
| Doc Mgmt | `/u-docs` | - | u-RA |
| Doc Mgmt | `/u-validate` | - | u-RA + script |
| Doc Mgmt | `/u-backlog` | - | u-RA |
| Doc Mgmt | `/u-backlog-add` | - | u-RA |
| Doc Mgmt | `/u-us-add` | PLAN | u-RA |
| Doc Mgmt | `/u-fr-add` | PLAN | u-SA |
| Doc Mgmt | `/u-index` | - | u-RA |
| Agent | `/u-srs` | PLAN | u-SA |
| Agent | `/u-erd` | DESIGN | u-SA |
| Agent | `/u-api` | DESIGN | u-SA |
| Agent | `/u-screen` | DESIGN | u-UX |
| Agent | `/u-fe` | DO | u-DV-FE |
| Agent | `/u-be` | DO | u-DV-BE |
| Agent | `/u-test` | CHECK | u-QA |
| Agent | `/u-bug-report` | CHECK | u-QA |
| QA | `/u-gap-detector` | CHECK | u-RA → u-QA |
| Utility | `/u-help` | - | Orch |
| Utility | `/u-history` | - | u-RA |
| Utility | `/u-archive` | ACT | u-RA |
| Utility | `/u-storybook` | DO | u-DV-FE |
| Utility | `/u-build` | DO | Orch (Bash) |
| Utility | `/u-summary` | - | u-RA |
| Utility | `/u-git-pr` | - | Orch (Bash + gh) |
