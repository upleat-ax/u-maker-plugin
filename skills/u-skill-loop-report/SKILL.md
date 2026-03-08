---
name: u-skill-loop-report
description: |
  PDCA Loop 완료 후 종합 보고서를 생성한다.
  전체 요구사항, 유저스토리, 피쳐, 구현내용, 테스트케이스, 테스트결과, 기술부채를 포함한다.
  .md + .json + .html 3종 파일을 동시에 생성한다.
  Optional [app] argument for multi-app projects (e.g., `/u-skill-loop-report web`).
  Triggers: /u-skill-loop-report, 루프 리포트, loop report, 종합 보고서, 전체 보고서
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
  - ${PLUGIN_ROOT}/_refer/html-report-standard.md
  - ${PLUGIN_ROOT}/templates/05-act/5_LoopReport_PM.template.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-pm
---

# u-skill-loop-report

`u-agent-pm` 에이전트를 호출하여 PDCA Loop 종합 보고서를 생성한다.

## Output Path

- `.u-maker/docs/common/05-act/5_LoopReport_PM_yyyymmddhhmm.md`
- `.u-maker/docs/common/05-act/5_LoopReport_PM_yyyymmddhhmm.json`
- `.u-maker/docs/common/05-act/5_LoopReport_PM_yyyymmddhhmm.html`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Data Collection

에이전트는 아래 SSoT 문서를 순서대로 읽어 데이터를 수집한다:

| # | Source Document | 수집 데이터 |
|---|----------------|------------|
| 1 | `.u-maker/u-maker.config.json` | 프로젝트명, iteration, phase |
| 2 | `{app}/01-plan/1_SRS_RA.md` | USR, US, FT, FR 목록 |
| 3 | `{app}/02-design/2_RTM_RA.md` | 추적 매트릭스 |
| 4 | `{app}/02-design/2_ERD_SA.md` | Entity 목록 |
| 5 | `{app}/02-design/2_API_SA.md` | Endpoint 목록 |
| 6 | `{app}/03-dev/3_Code_DV.md` | 구현 현황 + **Gap 이력** |
| 7 | `{app}/04-check/4_Case_QA.md` | 테스트 케이스 |
| 8 | `{app}/04-check/4_Report_QA.md` | 테스트 결과, 결함 |
| 9 | `common/05-act/5_IterationLog_RA.md` | 백로그, 기술부채 |
| 10 | git log (최근 Iteration) | 코드 변경 통계 |

## Report Sections

보고서는 아래 11개 섹션으로 구성한다:

1. **KPI Dashboard** — 핵심 지표 요약 (US, FT, FR, TC, Pass Rate, Defects, Build, Debt, **최종 Match Rate**)
2. **Requirements Summary** — USR, US, FT, FR 전체 목록 + 상태
3. **Implementation Summary** — 코드 통계, FT별 구현 상태, 기술 스택
4. **Gap Analysis History** — Iteration별 Match Rate 추이, Gap FT 목록, 해소 이력 (**NEW**)
5. **Test Summary** — TC 실행 결과, FT별 결과, 실패 케이스 상세
6. **Defect Summary** — Severity별 통계, 결함 상세
7. **Technical Debt** — 부채 항목, 카테고리별 통계
8. **Traceability Matrix** — US→FT→FR→Screen→API→DB→TC 추적
9. **Exit Criteria** — 종료 조건 판정
10. **Iteration History** — 전체 Iteration 이력 (Gap Attempt 포함)

## HTML Generation Rules

`.html` 파일은 `html-report-standard.md`의 템플릿 구조를 따르며:

- KPI Dashboard → `.kpi-grid` + `.kpi-card` 컴포넌트로 렌더링
- 테이블 데이터 → `<table>` HTML 테이블로 렌더링
- 상태값 → `.badge-*` 클래스로 시각화
- FT 구현율 → `.progress-bar` 컴포넌트로 렌더링
- 결함 분포 → HTML/CSS 기반 가로 막대 차트로 시각화 (외부 JS 금지)

## Rules

- 타임스탬프는 반드시 `yyyymmddhhmm` 형식(12자리 숫자)
- 인자가 없으면 현재 시각으로 생성
- 3종 파일 동시 생성: `.md` + `.json` + `.html`
- `.md`와 `.html`은 동일한 데이터, 동일한 버전
- HTML은 단일 파일로 완결 (외부 CSS/JS 금지, Pretendard CDN만 허용)
- Post-Execution Summary Box 출력 필수
