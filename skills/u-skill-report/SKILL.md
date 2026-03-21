---
name: u-skill-report
description: |
  프로젝트 종합 보고서를 생성한다.
  SSoT 문서와 git 이력을 바탕으로 FR/US/FT/NFR 구현 현황, QA 결과, 결함 목록, 부채(기획/디자인/기술), 기여자별 작업 내역, Iteration 이력을 포함한다.
  .md + .html 2종 파일을 동시에 생성한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-report, 보고서, 리포트, report, 종합 보고서, 루프 리포트, 데일리 리포트, 결함 리포트, project report, 프로젝트 보고서, generate report, 보고서 생성, status report, 상태 보고서
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
  - ${PLUGIN_ROOT}/_refer/html-report-standard.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  - u-maker:u-agent-pm
---

# u-skill-report

`u-agent-pm` 에이전트를 호출하여 프로젝트 종합 보고서를 생성한다.

## Output Path

- `.u-maker/docs/common/05-act/5_Report_PM_yyyymmddhhmm.md`
- `.u-maker/docs/common/05-act/5_Report_PM_yyyymmddhhmm.html`

## App Context

| Condition | Behavior |
|-----------|----------|
| Single app in config | Auto-select, no argument needed |
| Multiple apps + argument given | Use specified app |
| Multiple apps + no argument | Prompt user via AskUserQuestion |

## Data Collection

에이전트는 아래 SSoT 문서와 git 이력을 순서대로 읽어 데이터를 수집한다:

| # | Source | 수집 데이터 |
|---|--------|------------|
| 1 | `.u-maker/u-maker.config.json` | 프로젝트명, iteration, phase, documentLanguage |
| 2 | `{app}/01-plan/1_SRS_RA.md` | USR, FR, US, FT 목록 + NFR |
| 3 | `{app}/02-design/2_RTM_RA.md` | 추적 매트릭스 |
| 4 | `{app}/02-design/2_ERD_SA.md` | Entity 목록 |
| 5 | `{app}/02-design/2_API_SA.md` | Endpoint 목록 |
| 6 | `{app}/03-dev/3_Code_DV.md` | 구현 현황 + Gap 이력 |
| 7 | `{app}/04-check/4_Case_QA.md` | 테스트 케이스 |
| 8 | `{app}/04-check/4_Report_QA.md` | 테스트 결과, 결함 |
| 9 | `common/05-act/5_IterationLog_RA.md` | 백로그, 기획/디자인/기술 부채 |
| 10 | `git log --stat` (최근 Iteration) | 코드 변경 통계 |
| 11 | `bun run build` 결과 (가능한 경우) | 빌드 상태, route 수 |
| 12 | `common/05-act/5_Report_PM_*.md` (이전 보고서) | 이전 카운트 비교용 |
| 13 | `git log --oneline --no-merges` (최근 50건) | 주요 커밋 내용 분석 |
| 14 | `git shortlog -sn --no-merges` | 기여자별 커밋 수 |
| 15 | `git diff --stat HEAD~30` (또는 Iter 시작 태그) | 변경 파일/라인 통계 |
| 16 | `git log --author="<name>" --no-merges --shortstat` | 기여자별 추가/삭제 라인 |
| 17 | `git log --author="<name>" --no-merges --name-only` | 기여자별 주요 작업 영역 |
| 18 | `{app}/01-plan/1_SRS_RA.md` (TBD/미정 스캔) | 기획 부채 |
| 19 | `{app}/01-plan/1_IA_RA.md` (누락 화면 스캔) | 기획 부채 |
| 20 | `{app}/02-design/2_Screen_UX.md` (미작성 와이어프레임) | 디자인 부채 |
| 21 | `{app}/02-design/2_ERD_SA.md` ↔ `2_API_SA.md` 교차 검증 | 디자인 부채 |

### 이전 보고서 비교

- `common/05-act/` 디렉토리에서 `5_Report_PM_*.md` 파일을 Glob으로 검색
- 타임스탬프 기준 가장 최근 보고서 1건을 읽어 이전 카운트를 추출
- 비교 항목: FR, NFR, US, FT, TC 총 갯수 + 구현/달성 갯수 + 결함 수
- 이전 보고서가 없으면 "첫 번째 보고서"로 표시 (비교 섹션은 "이전 데이터 없음")

### Git 내용 분석

- `git log --oneline --no-merges` 최근 50건에서 커밋 메시지를 분류:
  - `feat` → 신규 기능, `fix` → 버그 수정, `refactor` → 리팩토링, `docs` → 문서, `test` → 테스트, `chore` → 기타
- `git shortlog -sn` 으로 기여자별 커밋 수 집계
- `git diff --stat` 으로 변경된 파일 수, 추가/삭제 라인 수 집계
- 주요 변경사항 Top 5를 요약 (가장 많은 변경이 있는 파일/기능 기준)

## 약어 표기 규칙

> CRITICAL: 보고서 내 약어를 풀어쓸 때 아래를 반드시 준수한다:
> - FT = Feature (구현 단위). ~~Functional Test~~ 절대 아님.
> - FR = Functional Requirement, US = User Story, TC = Test Case, NFR = Non-Functional Requirement

## Report Sections (HTML)

보고서는 13개 섹션으로 구성한다: Header, Gate Banner, KPI Cards(7개), 1.이전보고서비교, 2.Iteration구현요약, 3.FR구현현황, 4.NFR달성현황, 5.US달성현황, 6.FT구현현황, 7.QA결과요약, 8.결함목록, 9.부채현황, 10.Git활동요약, 11.기여자별작업내역, 12.Iteration이력, 13.다음Iteration계획.

각 섹션의 상세 HTML 구조, 테이블 컬럼, 카드 템플릿, 부채 수집 기준은 `references/report-sections.md` 참조.

### 기여자별 작업 내역 (Section 11)

git 이력 분석으로 기여자별 커밋 수, 변경 라인, 주요 작업 영역을 `.ft-card` 스타일로 표시한다. Data Collection 명령어 및 HTML 템플릿은 `references/contributors-detail.md` 참조.

## Report Sections (Markdown)

`.md` 파일은 HTML과 동일한 데이터를 마크다운 테이블로 표현한다. 섹션 구조 및 차트 표현 방식(유니코드 블록 바 차트, 트렌드 화살표)은 `references/markdown-format.md` 참조.

## HTML Generation Rules

`.html` 파일은 `html-report-standard.md`의 dark-first purple-accent CSS 스타일을 따르며:

- **Theme**: Dark-first (`:root` = 다크 기본, `[data-theme="light"]` = 라이트), 원형 토글 버튼
- **Language**: `<html lang="{{LANG}}">` — `documentLanguage` config 값, 모든 텍스트도 해당 언어로 작성
- **Header**: purple accent-glow 그래디언트 배경 + 프로젝트명 + KPI 한 줄 요약
- **Gate Banner**: 성공(green) / 실패(red) 배너
- **KPI Cards**: `.kpi-grid` + `.kpi-card` (success/primary/info/accent/warning 컬러) + hover translateY 효과
- **Section Title**: 숫자 뱃지(`.num`) + 하단 파란 보더
- **FT Cards**: `.ft-grid` + `.ft-card` 그리드 레이아웃
- **Tables**: `.table-wrap` + 표준 테이블, `.total-row`, `.new-row`, `.fixed-row` 하이라이트
- **Badges**: `.badge-success`, `.badge-primary`, `.badge-warning`, `.badge-danger`, `.badge-info`, `.badge-accent`, `.badge-gray`
- **Charts**: SVG 도넛 + CSS 바 차트 (UML Sequence/Class만 Mermaid CDN 허용, 그 외 외부 JS 금지)
- **Timeline**: `.timeline` + `.tl-item` 컴포넌트
- **Summary Box**: `.summary-box` (dark background) + `.summary-grid`
- **Footer**: 가운데 정렬 + 프로젝트명 + 날짜

## Gate 판정 기준

| 조건 | COMPLETE 기준 |
|------|--------------|
| Critical/Major 결함 | 0건 |
| FR 구현률 | 100% (전체 FR 구현) |
| 빌드 | 성공 |
| 테스트 통과율 | 100% (Unit + E2E) |

4개 조건 모두 충족 시 `COMPLETE`, 하나라도 미충족 시 `IN PROGRESS`.

## Rules

- 타임스탬프는 반드시 `yyyymmddhhmm` 형식(12자리 숫자)
- 인자가 없으면 현재 시각으로 생성
- 2종 파일 동시 생성: `.md` + `.html`
- `.md`와 `.html`은 동일한 데이터, 동일한 버전
- HTML은 단일 파일로 완결 (Pretendard CDN + UML Sequence/Class용 Mermaid CDN만 허용, 그 외 외부 JS 금지)
- HTML `<html lang>` 속성은 `.u-maker/u-maker.config.json`의 `documentLanguage` 값을 사용 (예: `ko`, `en`, `ja`, `zh`)
- 보고서 내 모든 레이블, 섹션 제목, 설명 텍스트는 `documentLanguage` 설정 언어로 작성
- HTML 스타일은 Dark-first (`:root` = 다크, `[data-theme="light"]` = 라이트), README.html과 동일한 purple-accent 디자인
- Post-Execution Summary Box 출력 필수
- 데이터가 없는 섹션은 "해당 없음" 또는 "데이터 없음"으로 표시 (섹션 자체는 유지)

## References

| 파일 | 내용 |
|------|------|
| `references/report-sections.md` | 13개 섹션 상세 (HTML 구조, 테이블 컬럼, 카드 템플릿, 부채 수집 기준) |
| `references/markdown-format.md` | Markdown 섹션 구조, 차트 표현 방식 (유니코드 바 차트, 트렌드) |
| `references/contributors-detail.md` | Section 11 기여자별 작업 내역 — Data Collection 명령어, HTML 템플릿 |
