# Slash Commands Reference

> u-agent-ssot 플러그인의 모든 슬래시 커맨드(`/u-*`) 정의 및 동작 명세.

---

## 1. Lifecycle Commands

프로젝트 라이프사이클을 관리하는 핵심 커맨드.

### `/u-create-project`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-create-project <project-name>` |
| **Description** | 새 프로젝트를 생성하고 u-docs/ 구조를 초기화한다 |
| **Calling Agents** | Orchestrator → `u-PM` → `u-M` |
| **Prerequisites** | None |
| **Output** | `u-docs/` 디렉토리 구조 생성, `1M_Index.md` 초기화, `u-agent-ssot.config.json` 초기화 |

### `/u-plan`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-plan` |
| **Description** | PLAN Phase를 실행한다. Roadmap, SRS, IA, Index를 순서대로 생성한다 |
| **Calling Agents** | Orchestrator → `u-PM` → `u-A` → `u-CX` → `u-M` |
| **Prerequisites** | 프로젝트 생성 완료 (`u-docs/` 존재) |
| **Output** | `1PM_Roadmap.md`, `1A_SRS.md`, `1CX_IA.md`, `1M_Index.md` |

### `/u-design`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-design` |
| **Description** | DESIGN Phase를 실행한다. Screen, ERD, API Contract를 생성한다 |
| **Calling Agents** | Orchestrator → `u-CX` → `u-A` → `u-M` |
| **Prerequisites** | PLAN Gate 통과 (`1PM_Roadmap`, `1A_SRS`, `1CX_IA` 모두 Final) |
| **Output** | `2CX_Screen.md`, `2A_ERD.md`, `2A_API.md` |

### `/u-dev`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-dev` |
| **Description** | DO Phase를 실행한다. Frontend/Backend 병렬 개발 |
| **Calling Agents** | Orchestrator → `u-DV-FE` + `u-DV-BE` |
| **Prerequisites** | DESIGN Gate 통과 (`2A_ERD`, `2A_API`, `2CX_Screen` 모두 Final + u-M 검수) |
| **Output** | 코드 파일 + `3DV_Code.md` |

### `/u-check`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-check` |
| **Description** | CHECK Phase를 실행한다. 테스트 케이스 설계, 실행, 결함 분석 |
| **Calling Agents** | Orchestrator → `u-QA-A` → `u-QA-T` → `u-QA-N` |
| **Prerequisites** | DO Gate 통과 (코드 구현 완료 + `bun run build` 성공) |
| **Output** | `4QA_Case.md`, `4QA_Report.md` |

### `/u-act`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-act` |
| **Description** | ACT Phase를 실행한다. 백로그 정리, 아카이브, 회고 |
| **Calling Agents** | Orchestrator → `u-M` → `u-PM` |
| **Prerequisites** | CHECK Phase 완료 (종료 조건 미충족) |
| **Output** | `5ACT_Backlog.md`, `5ACT_Iteration_Log.md`, `5ACT_Retrospective.md` |

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
| **Calling Agents** | `u-M` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 상태 보고 배너 (터미널 출력) |

### `/u-docs`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-docs` |
| **Description** | 모든 SSoT 문서 목록과 상태(Draft/Review/Final)를 표시한다 |
| **Calling Agents** | `u-M` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 문서 목록 테이블 (터미널 출력) |

### `/u-validate`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-validate` |
| **Description** | SSoT 문서 무결성을 검증한다 (헤더, 추적성, 구조) |
| **Calling Agents** | `u-M` + `scripts/validate-ssot.py` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | 검증 결과 보고서 (Pass/Fail 항목별) |

### `/u-backlog`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-backlog` |
| **Description** | 현재 백로그 항목을 표시한다 |
| **Calling Agents** | `u-M` |
| **Prerequisites** | `5ACT_Backlog.md` 존재 |
| **Output** | 백로그 테이블 (터미널 출력) |

### `/u-index`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-index` |
| **Description** | 문서 인덱스(`1M_Index.md`)를 갱신한다 |
| **Calling Agents** | `u-M` |
| **Prerequisites** | 프로젝트 생성 완료 |
| **Output** | `1M_Index.md` 업데이트 |

---

## 4. Individual Agent Commands

특정 에이전트를 직접 호출하여 개별 문서를 생성/수정하는 커맨드.

### `/u-srs`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-srs` |
| **Description** | SRS(Software Requirements Specification)를 생성/수정한다 |
| **Calling Agents** | `u-A` |
| **Prerequisites** | `1PM_Roadmap.md` 존재 |
| **Output** | `1A_SRS.md` |

### `/u-erd`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-erd` |
| **Description** | ERD(Entity Relationship Diagram)를 생성/수정한다 |
| **Calling Agents** | `u-A` |
| **Prerequisites** | `1A_SRS.md` = Final |
| **Output** | `2A_ERD.md` |

### `/u-api`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-api` |
| **Description** | API Contract(OpenAPI 3.0)를 생성/수정한다 |
| **Calling Agents** | `u-A` |
| **Prerequisites** | `2A_ERD.md` 존재 |
| **Output** | `2A_API.md` |

### `/u-screen`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-screen` |
| **Description** | Screen Design(화면 상세 설계)을 생성/수정한다 |
| **Calling Agents** | `u-CX` |
| **Prerequisites** | `1CX_IA.md` = Final |
| **Output** | `2CX_Screen.md` |

### `/u-fe`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-fe` |
| **Description** | Frontend 코드를 생성한다 |
| **Calling Agents** | `u-DV-FE` |
| **Prerequisites** | `2CX_Screen.md` = Final, `2A_API.md` = Final |
| **Output** | Frontend code files + `3DV_Code.md` 업데이트 |

### `/u-be`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-be` |
| **Description** | Backend 코드를 생성한다 |
| **Calling Agents** | `u-DV-BE` |
| **Prerequisites** | `2A_ERD.md` = Final, `2A_API.md` = Final |
| **Output** | Backend code files + `3DV_Code.md` 업데이트 |

### `/u-test`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-test` |
| **Description** | 테스트 케이스를 설계하고 실행한다 |
| **Calling Agents** | `u-QA-A` → `u-QA-T` |
| **Prerequisites** | DO Phase 완료 |
| **Output** | `4QA_Case.md`, `4QA_Report.md` |

### `/u-bug-report`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-bug-report` |
| **Description** | 결함 분석 리포트를 생성한다 |
| **Calling Agents** | `u-QA-N` |
| **Prerequisites** | `4QA_Report.md` 존재 |
| **Output** | 결함 분석 결과, `5ACT_Backlog.md` 업데이트 |

---

## 5. Quality Assurance Commands

CHECK Phase에서 설계-구현 일치도를 분석하는 커맨드.

### `/u-gap-detector`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-gap-detector` |
| **Description** | SSoT 설계 문서(SRS, ERD, API, Screen)와 실제 구현 코드를 비교하여 Gap을 분석한다 |
| **Calling Agents** | `u-M` (문서 수집) → `u-QA-A` (항목별 매칭 검사) |
| **Prerequisites** | DO Phase 완료 (코드 구현 존재), 설계 문서(SRS, ERD, API) Final 상태 |
| **Output** | Gap Analysis Report (`4QA_Report.md`에 추가), Match Rate 산출 |

**Analysis Targets**:
- **SRS FR 검사**: `1A_SRS.md`의 모든 FR 항목이 코드에 구현되었는지 확인
- **API Endpoint 검사**: `2A_API.md`의 모든 Endpoint가 API Route에 존재하는지 확인
- **ERD Entity 검사**: `2A_ERD.md`의 모든 Entity가 DB Schema/ORM에 정의되었는지 확인
- **Screen 검사**: `2CX_Screen.md`의 모든 화면이 페이지/컴포넌트로 구현되었는지 확인

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
| **Calling Agents** | `u-M` |
| **Prerequisites** | `5ACT_Iteration_Log.md` 존재 |
| **Output** | Iteration 이력 테이블 (터미널 출력) |

### `/u-archive`

| Field | Value |
|-------|-------|
| **Syntax** | `/u-archive` |
| **Description** | 현재 Iteration 문서를 아카이브한다 |
| **Calling Agents** | `u-M` |
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

---

## 6. Command Summary Table

| Category | Command | Phase | Agents |
|----------|---------|-------|--------|
| Lifecycle | `/u-create-project` | - | Orch → u-PM → u-M |
| Lifecycle | `/u-plan` | PLAN | Orch → u-PM → u-A → u-CX → u-M |
| Lifecycle | `/u-design` | DESIGN | Orch → u-CX → u-A → u-M |
| Lifecycle | `/u-dev` | DO | Orch → u-DV-FE + u-DV-BE |
| Lifecycle | `/u-check` | CHECK | Orch → u-QA-A → u-QA-T → u-QA-N |
| Lifecycle | `/u-act` | ACT | Orch → u-M → u-PM |
| Auto-Loop | `/u-loop` | ALL | Orch → All |
| Auto-Loop | `/u-loop-from` | Varies | Orch → Varies |
| Auto-Loop | `/u-stop` | - | Orch |
| Auto-Loop | `/u-resume` | - | Orch |
| Doc Mgmt | `/u-status` | - | u-M |
| Doc Mgmt | `/u-docs` | - | u-M |
| Doc Mgmt | `/u-validate` | - | u-M + script |
| Doc Mgmt | `/u-backlog` | - | u-M |
| Doc Mgmt | `/u-index` | - | u-M |
| Agent | `/u-srs` | PLAN | u-A |
| Agent | `/u-erd` | DESIGN | u-A |
| Agent | `/u-api` | DESIGN | u-A |
| Agent | `/u-screen` | DESIGN | u-CX |
| Agent | `/u-fe` | DO | u-DV-FE |
| Agent | `/u-be` | DO | u-DV-BE |
| Agent | `/u-test` | CHECK | u-QA-A → u-QA-T |
| Agent | `/u-bug-report` | CHECK | u-QA-N |
| QA | `/u-gap-detector` | CHECK | u-M → u-QA-A |
| Utility | `/u-help` | - | Orch |
| Utility | `/u-history` | - | u-M |
| Utility | `/u-archive` | ACT | u-M |
| Utility | `/u-storybook` | DO | u-DV-FE |
| Utility | `/u-build` | DO | Orch (Bash) |
