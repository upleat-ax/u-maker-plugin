---
name: u-skill-report
description: |
  프로젝트 종합 보고서를 생성한다.
  SSoT 문서와 git 이력을 바탕으로 FR/US/FT/NFR 구현 현황, QA 결과, 결함 목록, 부채(기획/디자인/기술), 기여자별 작업 내역, Iteration 이력을 포함한다.
  .md + .html 2종 파일을 동시에 생성한다.
  Args: `[app]` — 멀티앱 프로젝트 시 앱 이름 (e.g., `web`)
  Triggers: /u-skill-report, 보고서, 리포트, report, 종합 보고서, 루프 리포트, 데일리 리포트, 결함 리포트
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

보고서는 아래 13개 섹션으로 구성한다. HTML에서 각 섹션은 숫자 뱃지와 하단 구분선이 있는 `section-title`을 사용한다.

### Header

- 프로젝트명, Iteration 번호, 상태(COMPLETE / IN PROGRESS)를 배지로 표시
- 주요 KPI 한 줄 요약 (FR, 빌드, Unit, E2E, 결함, FT 등)

### Gate Banner

- Gate 판정 결과 (COMPLETE / FAIL) + 판정 근거 요약
- 조건: Critical/Major 결함 0건 + FR 전체 구현 + 빌드 성공 + 테스트 통과

### KPI Cards — 전체 카운트 대시보드

- `.kpi-grid`에 아래 **7개 KPI 카드**를 반드시 표시:

| KPI Card | 값 | 서브텍스트 | 색상 |
|----------|-----|-----------|------|
| FR 총 갯수 | `{구현}/{전체}` | `구현률 N%` | primary |
| NFR 총 갯수 | `{달성}/{전체}` | `달성률 N%` | info |
| US 총 갯수 | `{완료}/{전체}` | `달성률 N%` | accent |
| FT 총 갯수 | `{구현}/{전체}` | `구현률 N%` | success |
| TC 총 갯수 | `{Pass}/{전체}` | `통과율 N%` | primary |
| 결함 | `{Open}건` | `전체 N건 / 해결 N건` | danger or success |
| 빌드 | `성공` or `실패` | `N routes` | success or danger |

### 1. 이전 보고서 비교 (Trend)

- 이전 보고서(`5_Report_PM_*.md` 가장 최근 1건)와 현재 데이터를 비교
- **비교 테이블** (`.table-wrap` + `.compare-highlight`):

| 항목 | 이전 | 현재 | 변화 |
|------|------|------|------|
| FR (구현/전체) | N/N | N/N | +N (+N%) |
| NFR (달성/전체) | N/N | N/N | +N |
| US (완료/전체) | N/N | N/N | +N |
| FT (구현/전체) | N/N | N/N | +N |
| TC (Pass/전체) | N/N | N/N | +N |
| 결함 Open | N | N | -N |

- **트렌드 차트** (`.chart-row`): 바 차트로 이전 vs 현재 비교 시각화
  - X축: FR, NFR, US, FT, TC  /  Y축: 갯수
  - 이전(회색 바) vs 현재(컬러 바) 나란히 표시
- 이전 보고서가 없으면: "첫 번째 보고서 — 비교 데이터 없음" 메시지 표시

### 2. Iteration 구현 요약

- 현재 Iteration에서 신규 구현 / 해결된 항목을 FT 카드(`.ft-grid` + `.ft-card`)로 표시
- 각 카드에 FT/FR/DEF ID, 주요 내용, 뱃지

### 3. FR 구현 현황

- 전체 FR 목록 테이블: FR-ID, Feature, Priority, 화면 수, 구현 수, 구현률, Iteration, 상태
- 합계 행 포함
- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 구현 완료 N건 | 미구현 N건`

### 4. NFR 달성 현황

- 전체 NFR 테이블: NFR-ID, 범주, 요구사항, 지표/판정 기준, 달성 여부
- 달성/부분 달성/미달성 뱃지
- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 달성 N건 | 부분달성 N건 | 미달성 N건`

### 5. US 달성 현황

- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 완료 N건 | 진행중 N건 | 미착수 N건`

#### US 목록 테이블

| US-ID | USR | 사용자 역할 | As a… | I want to… | So that… | Priority | 연결 FT | 수락 기준 요약 | 상태 |
|-------|-----|------------|-------|-----------|---------|----------|---------|--------------|------|

- SRS의 User Stories 섹션에서 전체 US를 추출
- **As a / I want to / So that** 3요소를 모두 표시하여 유저 스토리 맥락을 완전히 전달
- **수락 기준 요약**: 각 US의 Acceptance Criteria를 1~2줄로 요약 (예: "이메일+비밀번호 입력 후 JWT 발급, 실패 시 에러 메시지 표시")
- 연결 FT 칼럼에 해당 US를 구현하는 FT-ID 목록 표시 (쉼표 구분)
- 합계 행 포함

#### US 상세 카드 (HTML)

각 US를 `.ft-card` 스타일로 상세 표시:

```html
<div class="ft-grid">
  <div class="ft-card">
    <div class="ft-card-header">
      <h5>US-0001 — 회원가입</h5>
      <span class="badge badge-success">Complete</span>
    </div>
    <div style="font-size:13px;color:var(--text2);margin-bottom:8px;">
      <strong>As a</strong> 신규 사용자, <strong>I want to</strong> 이메일로 회원가입,
      <strong>So that</strong> 서비스를 이용할 수 있다.
    </div>
    <div style="font-size:12px;margin-bottom:8px;">
      <strong>수락 기준:</strong>
      <ul style="margin:4px 0 0 18px;">
        <li>이메일 형식 유효성 검증</li>
        <li>비밀번호 8자 이상, 특수문자 포함</li>
        <li>중복 이메일 가입 차단</li>
        <li>가입 완료 시 인증 메일 발송</li>
      </ul>
    </div>
    <ul>
      <li><strong>USR</strong>: USR-0001 (일반사용자)</li>
      <li><strong>Priority</strong>: Must</li>
      <li><strong>연결 FT</strong>: FT-0001, FT-0002</li>
    </ul>
  </div>
</div>
```

- 모든 US에 대해 카드를 생성 (테이블과 카드 모두 표시)
- 수락 기준은 SRS에서 가져온 원문 리스트를 그대로 표시

### 6. FT 구현 현황

- 전체 FT 테이블: FT-ID, FR-ID, 기능, Priority, 상태, 비고
- 신규 FT는 `.new-row` 클래스로 하이라이트
- 합계 행 포함
- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 구현 완료 N건 | 진행중 N건 | 미착수 N건`

### 7. QA 결과 요약

- **TC 전체 카운트**: 테이블 상단에 `전체 TC N건 | Pass N건 | Fail N건 | Skip N건`
- 차트 영역: 자동화 테스트 비율(도넛 SVG), TC 분류별 현황(바 차트)
- 요약 테이블: Unit/E2E/정적분석 Pass/Fail 수 + 합계

#### TC 상세 목록 테이블

| TC-ID | FT-ID | 테스트 유형 | 테스트명 | 시나리오 | 기대 결과 | 실제 결과 | 상태 |
|-------|-------|-----------|---------|---------|----------|----------|------|

- 4_Case_QA.md에서 전체 TC를 추출
- **테스트 유형**: Unit / E2E 구분
- **시나리오**: 테스트 스텝을 1~2줄로 요약 (예: "로그인 폼에 올바른 이메일/PW 입력 → 로그인 버튼 클릭")
- **기대 결과**: 예상 동작 (예: "대시보드 페이지로 리다이렉트, JWT 토큰 저장")
- **실제 결과**: 4_Report_QA.md 기반 실제 결과 (Pass면 "기대와 일치", Fail이면 실패 원인 간략 기술)
- **상태**: Pass(`badge-success`), Fail(`badge-danger`), Skip(`badge-gray`)

#### TC FT별 그룹 뷰 (HTML)

FT 단위로 그룹핑하여 `.ft-card` 스타일로 상세 표시:

```html
<div class="ft-grid">
  <div class="ft-card">
    <div class="ft-card-header">
      <h5>FT-0001 — 이메일 로그인</h5>
      <span class="badge badge-success">5/5 Pass</span>
    </div>
    <div class="table-wrap" style="margin-top:8px;">
      <table>
        <thead><tr><th>TC-ID</th><th>유형</th><th>시나리오</th><th>기대 결과</th><th>상태</th></tr></thead>
        <tbody>
          <tr>
            <td>TC-0001</td>
            <td><span class="badge badge-info">Unit</span></td>
            <td>유효한 이메일+PW로 로그인 API 호출</td>
            <td>200 OK, JWT 토큰 반환</td>
            <td><span class="badge badge-success">Pass</span></td>
          </tr>
          <tr>
            <td>TC-0002</td>
            <td><span class="badge badge-accent">E2E</span></td>
            <td>로그인 폼 입력 → 버튼 클릭 → 대시보드 이동 확인</td>
            <td>URL이 /dashboard로 변경, 사용자 이름 표시</td>
            <td><span class="badge badge-success">Pass</span></td>
          </tr>
          <tr>
            <td>TC-0003</td>
            <td><span class="badge badge-info">Unit</span></td>
            <td>잘못된 비밀번호로 로그인 시도</td>
            <td>401 Unauthorized, 에러 메시지 반환</td>
            <td><span class="badge badge-success">Pass</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

- 모든 FT에 대해 해당 TC를 그룹핑하여 카드 생성
- 카드 헤더에 FT명과 Pass/Fail 집계 뱃지 표시
- Fail이 있는 카드는 `border-color: var(--danger)` 적용
- FT에 연결된 TC가 없으면 "테스트 케이스 미설계" 경고 뱃지

### 8. 결함 목록

- 전체 DEF 테이블: DEF-ID, 제목, 등급, 발견 Iter, 해결 Iter, 상태
- 해결된 결함은 `.fixed-row` 클래스

### 9. 부채 현황 (Planning / Design / Tech Debt)

3가지 부채를 탭 또는 서브섹션으로 구분하여 표시한다.

#### 9-1. 기획 부채 (Planning Debt)

SRS/IA/Roadmap 등 기획 문서에서 발견된 미비사항, 모호한 요구사항, 누락된 유저 스토리 등.

- 기획 부채 테이블:

| # | 이슈 | 관련 문서 | 심각도 | 상태 |
|---|------|----------|--------|------|
| 1 | US-0003 수락 기준 미정의 | 1_SRS_RA.md | Major | Open |

- **수집 기준**: SRS에서 `TBD`/`미정`/수락기준 빈 항목, IA에서 누락 화면, Roadmap에서 마일스톤 미설정 US
- 해소된 항목은 취소선 + `.fixed-row`

#### 9-2. 디자인 부채 (Design Debt)

화면 설계, ERD, API Contract 등 설계 문서에서 발견된 불일치, 미구현 화면, 스키마 불일치 등.

- 디자인 부채 테이블:

| # | 이슈 | 관련 문서 | 심각도 | 상태 |
|---|------|----------|--------|------|
| 1 | S-0005 화면 와이어프레임 미작성 | 2_Screen_UX.md | Minor | Open |

- **수집 기준**: Screen 문서에서 와이어프레임 없는 화면, ERD에서 API와 불일치하는 Entity, API에서 미구현 Endpoint, UXGuide에서 미적용 디자인 토큰
- 해소된 항목은 취소선 + `.fixed-row`

#### 9-3. 기술 부채 (Tech Debt)

코드 품질, 아키텍처, 테스트 커버리지 등 구현 레벨의 부채.

- 기술 부채 테이블:

| # | 이슈 | 위치 | 심각도 | 상태 |
|---|------|------|--------|------|
| 1 | 하드코딩 API URL | src/api/client.ts | Minor | Open |

- **수집 기준**: 3_Code_DV.md의 기술부채 섹션, 4_Report_QA.md의 코드 품질 이슈, 5_IterationLog_RA.md의 기술부채 백로그
- 해소된 항목은 취소선 + `.fixed-row`

#### 부채 요약 KPI

섹션 상단에 3가지 부채의 카운트를 `.section-count`로 표시:

```html
<div class="section-count">
  <span class="count-item">기획 부채 <strong>N</strong>건</span>
  <span class="count-item">디자인 부채 <strong>N</strong>건</span>
  <span class="count-item">기술 부채 <strong>N</strong>건</span>
  <span class="count-item">해소 <strong>N</strong>건</span>
</div>
```

### 10. Git 활동 요약

- **커밋 분류 차트** (도넛 SVG): feat/fix/refactor/docs/test/chore 비율
- **커밋 분류 테이블**:

| 유형 | 갯수 | 비율 | 주요 내용 |
|------|------|------|----------|
| feat | N | N% | 주요 feat 커밋 메시지 요약 (최대 3건) |
| fix | N | N% | 주요 fix 커밋 메시지 요약 (최대 3건) |
| ... | | | |

- **변경 통계**: 변경 파일 수, 추가 라인, 삭제 라인
- **주요 변경사항 Top 5**: 변경 라인이 가장 많은 파일/기능 기준 요약

### 11. 기여자별 작업 내역 (Contributors)

git 이력을 분석하여 누가 어떤 작업을 했는지 상세하게 표시한다.

#### Data Collection

```bash
# 기여자별 커밋 수
git shortlog -sn --no-merges

# 기여자별 변경 통계
git log --format='%aN' --no-merges | sort -u | while read author; do
  echo "$author"
  git log --author="$author" --no-merges --shortstat
done

# 기여자별 주요 작업 영역 (디렉토리 기준)
git log --author="<name>" --no-merges --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20
```

#### 기여자 요약 테이블

| 기여자 | 커밋 수 | 비율 | 추가 라인 | 삭제 라인 | 주요 작업 영역 |
|--------|---------|------|-----------|-----------|--------------|
| Alice | 23 | 46% | +1,245 | -312 | src/app/, src/components/ |
| Bob | 18 | 36% | +890 | -156 | src/api/, prisma/ |
| Claude | 9 | 18% | +445 | -89 | docs/, tests/ |

#### 기여자별 작업 상세

각 기여자마다 `.ft-card` 스타일의 카드로 표시:

```html
<div class="ft-grid">
  <div class="ft-card">
    <div class="ft-card-header">
      <h5>Alice</h5>
      <span class="badge badge-primary">23 commits (46%)</span>
    </div>
    <ul>
      <li><strong>feat</strong>: 회원가입 화면 구현, 대시보드 레이아웃 (12건)</li>
      <li><strong>fix</strong>: 로그인 토큰 만료 처리, 폼 유효성 검증 (6건)</li>
      <li><strong>refactor</strong>: API 클라이언트 모듈화 (3건)</li>
      <li><strong>주요 파일</strong>: src/app/auth/, src/components/dashboard/</li>
    </ul>
  </div>
</div>
```

- 커밋 메시지 prefix(feat/fix/refactor/docs/test/chore)별 갯수와 주요 내용 요약
- 주요 작업 파일/디렉토리 Top 5 표시
- `Co-Authored-By` 헤더가 있으면 공동 작업자로 함께 표시

### 12. Iteration 이력

- 타임라인(`.timeline`) 컴포넌트로 표시
- 각 Iteration: 날짜, 제목, 설명

### 13. 다음 Iteration 계획

- 우선순위별 계획 테이블: 우선순위, 항목, 대상, 유형

### Post-Execution Summary Box (HTML)

- 페이지 하단 `.summary-box` (dark background)
- 핵심 지표 그리드: Iteration, 기준일, FR/US/FT/NFR/TC 전체 카운트, 빌드, 테스트, 결함, Gate 판정 등
- 이전 대비 변화량 표시 (예: `FR 15/15 (+3)`)

## Report Sections (Markdown)

`.md` 파일은 HTML과 동일한 데이터를 마크다운 테이블로 표현한다. 구조는 아래와 같다:

```markdown
---
document: "5_Report_PM_{{TIMESTAMP}}"
title: "{{PROJECT_NAME}} 종합 보고서 ({{TIMESTAMP}})"
owner: "u-PM"
status: "Final"
version: "v1.0.0"
last_updated: "{{DATE}}"
---

# {{PROJECT_NAME}} 종합 보고서

## 1. Meta
## 2. KPI Dashboard (전체 카운트)
## 3. Gate 판정
## 4. 이전 보고서 비교 (Trend)
## 5. Iteration 구현 요약
## 6. FR 구현 현황
## 7. NFR 달성 현황
## 8. US 달성 현황
## 9. FT 구현 현황
## 10. QA 결과 요약
## 11. 결함 목록
## 12. 부채 현황 (기획/디자인/기술)
### 12-1. 기획 부채
### 12-2. 디자인 부채
### 12-3. 기술 부채
## 13. Git 활동 요약
## 14. 기여자별 작업 내역
## 15. Iteration 이력
## 16. 다음 Iteration 계획
## 17. Post-Execution Summary
## Change Log
```

### Markdown 차트 표현

`.md` 파일에서 차트는 아래 방식으로 표현한다:

- **바 차트**: 유니코드 블록 문자(`█`)로 수평 바 차트 표현
  ```
  FR  ████████████████░░░░ 80% (12/15)
  NFR ██████████░░░░░░░░░░ 50% (3/6)
  US  ████████████████████ 100% (8/8)
  FT  ██████████████░░░░░░ 70% (21/30)
  TC  ████████████████░░░░ 82% (45/55)
  ```
- **비교**: 이전→현재 화살표 표기
  ```
  FR: 9/12 → 12/15 (+3/+3) ▲
  ```
- **트렌드 표시**: `▲` 증가, `▼` 감소, `—` 변화없음

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
