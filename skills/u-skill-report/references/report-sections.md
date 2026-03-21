# Report Sections (HTML) — 상세

보고서는 아래 13개 섹션으로 구성한다. HTML에서 각 섹션은 숫자 뱃지와 하단 구분선이 있는 `section-title`을 사용한다.

## Header

- 프로젝트명, Iteration 번호, 상태(COMPLETE / IN PROGRESS)를 배지로 표시
- 주요 KPI 한 줄 요약 (FR, 빌드, Unit, E2E, 결함, FT 등)

## Gate Banner

- Gate 판정 결과 (COMPLETE / FAIL) + 판정 근거 요약
- 조건: Critical/Major 결함 0건 + FR 전체 구현 + 빌드 성공 + 테스트 통과

## KPI Cards — 전체 카운트 대시보드

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

## 1. 이전 보고서 비교 (Trend)

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

## 2. Iteration 구현 요약

- 현재 Iteration에서 신규 구현 / 해결된 항목을 FT 카드(`.ft-grid` + `.ft-card`)로 표시
- 각 카드에 FT/FR/DEF ID, 주요 내용, 뱃지

## 3. FR 구현 현황

- 전체 FR 목록 테이블: FR-ID, Feature, Priority, 화면 수, 구현 수, 구현률, Iteration, 상태
- 합계 행 포함
- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 구현 완료 N건 | 미구현 N건`

## 4. NFR 달성 현황

- 전체 NFR 테이블: NFR-ID, 범주, 요구사항, 지표/판정 기준, 달성 여부
- 달성/부분 달성/미달성 뱃지
- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 달성 N건 | 부분달성 N건 | 미달성 N건`

## 5. US 달성 현황

- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 완료 N건 | 진행중 N건 | 미착수 N건`

### US 목록 테이블

| US-ID | USR | 사용자 역할 | As a… | I want to… | So that… | Priority | 연결 FT | 수락 기준 요약 | 상태 |
|-------|-----|------------|-------|-----------|---------|----------|---------|--------------|------|

- SRS의 User Stories 섹션에서 전체 US를 추출
- **As a / I want to / So that** 3요소를 모두 표시하여 유저 스토리 맥락을 완전히 전달
- **수락 기준 요약**: 각 US의 Acceptance Criteria를 1~2줄로 요약 (예: "이메일+비밀번호 입력 후 JWT 발급, 실패 시 에러 메시지 표시")
- 연결 FT 칼럼에 해당 US를 구현하는 FT-ID 목록 표시 (쉼표 구분)
- 합계 행 포함

### US 상세 카드 (HTML)

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

## 6. FT 구현 현황

- 전체 FT 테이블: FT-ID, FR-ID, 기능, Priority, 상태, 비고
- 신규 FT는 `.new-row` 클래스로 하이라이트
- 합계 행 포함
- **전체 카운트 표시**: 테이블 상단에 `전체 N건 | 구현 완료 N건 | 진행중 N건 | 미착수 N건`

## 7. QA 결과 요약

- **TC 전체 카운트**: 테이블 상단에 `전체 TC N건 | Pass N건 | Fail N건 | Skip N건`
- 차트 영역: 자동화 테스트 비율(도넛 SVG), TC 분류별 현황(바 차트)
- 요약 테이블: Unit/E2E/정적분석 Pass/Fail 수 + 합계

### TC 상세 목록 테이블

| TC-ID | FT-ID | 테스트 유형 | 테스트명 | 시나리오 | 기대 결과 | 실제 결과 | 상태 |
|-------|-------|-----------|---------|---------|----------|----------|------|

- 4_Case_QA.md에서 전체 TC를 추출
- **테스트 유형**: Unit / E2E 구분
- **시나리오**: 테스트 스텝을 1~2줄로 요약 (예: "로그인 폼에 올바른 이메일/PW 입력 → 로그인 버튼 클릭")
- **기대 결과**: 예상 동작 (예: "대시보드 페이지로 리다이렉트, JWT 토큰 저장")
- **실제 결과**: 4_Report_QA.md 기반 실제 결과 (Pass면 "기대와 일치", Fail이면 실패 원인 간략 기술)
- **상태**: Pass(`badge-success`), Fail(`badge-danger`), Skip(`badge-gray`)

### TC FT별 그룹 뷰 (HTML)

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

## 8. 결함 목록

- 전체 DEF 테이블: DEF-ID, 제목, 등급, 발견 Iter, 해결 Iter, 상태
- 해결된 결함은 `.fixed-row` 클래스

## 9. 부채 현황 (Planning / Design / Tech Debt)

3가지 부채를 탭 또는 서브섹션으로 구분하여 표시한다.

### 9-1. 기획 부채 (Planning Debt)

SRS/IA/Roadmap 등 기획 문서에서 발견된 미비사항, 모호한 요구사항, 누락된 유저 스토리 등.

- 기획 부채 테이블:

| # | 이슈 | 관련 문서 | 심각도 | 상태 |
|---|------|----------|--------|------|
| 1 | US-0003 수락 기준 미정의 | 1_SRS_RA.md | Major | Open |

- **수집 기준**: SRS에서 `TBD`/`미정`/수락기준 빈 항목, IA에서 누락 화면, Roadmap에서 마일스톤 미설정 US
- 해소된 항목은 취소선 + `.fixed-row`

### 9-2. 디자인 부채 (Design Debt)

화면 설계, ERD, API Contract 등 설계 문서에서 발견된 불일치, 미구현 화면, 스키마 불일치 등.

- 디자인 부채 테이블:

| # | 이슈 | 관련 문서 | 심각도 | 상태 |
|---|------|----------|--------|------|
| 1 | S-0005 화면 와이어프레임 미작성 | 2_Screen_UX.md | Minor | Open |

- **수집 기준**: Screen 문서에서 와이어프레임 없는 화면, ERD에서 API와 불일치하는 Entity, API에서 미구현 Endpoint, UXGuide에서 미적용 디자인 토큰
- 해소된 항목은 취소선 + `.fixed-row`

### 9-3. 기술 부채 (Tech Debt)

코드 품질, 아키텍처, 테스트 커버리지 등 구현 레벨의 부채.

- 기술 부채 테이블:

| # | 이슈 | 위치 | 심각도 | 상태 |
|---|------|------|--------|------|
| 1 | 하드코딩 API URL | src/api/client.ts | Minor | Open |

- **수집 기준**: 3_Code_DV.md의 기술부채 섹션, 4_Report_QA.md의 코드 품질 이슈, 5_IterationLog_RA.md의 기술부채 백로그
- 해소된 항목은 취소선 + `.fixed-row`

### 부채 요약 KPI

섹션 상단에 3가지 부채의 카운트를 `.section-count`로 표시:

```html
<div class="section-count">
  <span class="count-item">기획 부채 <strong>N</strong>건</span>
  <span class="count-item">디자인 부채 <strong>N</strong>건</span>
  <span class="count-item">기술 부채 <strong>N</strong>건</span>
  <span class="count-item">해소 <strong>N</strong>건</span>
</div>
```

## 10. Git 활동 요약

- **커밋 분류 차트** (도넛 SVG): feat/fix/refactor/docs/test/chore 비율
- **커밋 분류 테이블**:

| 유형 | 갯수 | 비율 | 주요 내용 |
|------|------|------|----------|
| feat | N | N% | 주요 feat 커밋 메시지 요약 (최대 3건) |
| fix | N | N% | 주요 fix 커밋 메시지 요약 (최대 3건) |
| ... | | | |

- **변경 통계**: 변경 파일 수, 추가 라인, 삭제 라인
- **주요 변경사항 Top 5**: 변경 라인이 가장 많은 파일/기능 기준 요약

## 12. Iteration 이력

- 타임라인(`.timeline`) 컴포넌트로 표시
- 각 Iteration: 날짜, 제목, 설명

## 13. 다음 Iteration 계획

- 우선순위별 계획 테이블: 우선순위, 항목, 대상, 유형

## Post-Execution Summary Box (HTML)

- 페이지 하단 `.summary-box` (dark background)
- 핵심 지표 그리드: Iteration, 기준일, FR/US/FT/NFR/TC 전체 카운트, 빌드, 테스트, 결함, Gate 판정 등
- 이전 대비 변화량 표시 (예: `FR 15/15 (+3)`)
