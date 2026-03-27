---
name: engine-estimator
description: |
  SRS 항목(FR, US, FT) 수량과 복잡도를 분석하여
  공수 추정, 일정 계획, Gantt 차트 데이터를 생성하는 추정 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports: []
---

# Engine: Estimator

> SRS 항목을 분석하여 공수를 추정하고 로드맵/일정 계획 데이터를 생성한다.

## 역할

- SRS 항목(FR, US, FT) 수량 및 복잡도 분석
- 항목별 공수 추정 (T-shirt sizing + 시간 환산)
- 팀 규모 및 이터레이션 용량 반영
- Gantt 차트 데이터 생성
- 리스크 기반 버퍼 계산

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | SRS 문서 (FR/US/FT 목록), config (팀 규모, 이터레이션 주기) |
| **Output** | `{ estimation, schedule, ganttData, riskBuffer }` |

## 복잡도 기준

### T-shirt Sizing

| 사이즈 | 포인트 | 시간(h) | 기준 |
|--------|--------|---------|------|
| **XS** | 1 | 2 | 단순 UI 변경, 텍스트 수정 |
| **S** | 2 | 4 | 단일 CRUD, 간단한 검증 로직 |
| **M** | 3 | 8 | 복합 비즈니스 로직, 외부 연동 1개 |
| **L** | 5 | 16 | 다중 연동, 복잡한 상태 관리 |
| **XL** | 8 | 32 | 아키텍처 변경, 대규모 리팩토링 |

### 자동 복잡도 판별 요소

- API 연동 수: 0=XS~S, 1=M, 2+=L~XL
- 비즈니스 규칙 수: 0~1=S, 2~3=M, 4+=L
- 데이터 모델 관계: 단일=S, 1:N=M, M:N=L
- UI 구성요소 수: 1~3=S, 4~7=M, 8+=L

## 실행 절차

### Step 1. SRS 항목 수집

1. SRS 문서에서 FR, US, FT 목록 추출
2. 각 항목의 속성 파싱: 도메인, 설명, 매핑 관계
3. 항목 수 집계: `{ frCount, usCount, ftCount }`

### Step 2. 복잡도 분석

각 FT에 대해:
1. 설명 내용에서 복잡도 판별 요소 추출
2. T-shirt 사이즈 자동 배정
3. 시간 환산
4. 총 공수 합산

### Step 3. 일정 계획

1. config에서 팀 정보 로드:
   - `teamSize`: 개발자 수
   - `iterationWeeks`: 이터레이션 주기 (기본 2주)
   - `dailyHours`: 일일 가용 시간 (기본 6h)
2. 이터레이션 용량 계산: `teamSize x iterationWeeks x 5 x dailyHours`
3. FT를 우선순위/의존성 순으로 이터레이션에 배치
4. 전체 필요 이터레이션 수 산출

### Step 4. Gantt 차트 데이터 생성

```json
{
  "iterations": [
    {
      "id": "iter-1",
      "startDate": "2026-04-01",
      "endDate": "2026-04-14",
      "features": ["FT-0010", "FT-0020", "FT-0030"],
      "totalPoints": 12,
      "capacity": 15
    }
  ],
  "milestones": [
    { "name": "MVP", "date": "2026-05-01", "features": ["FT-0010~FT-0050"] }
  ]
}
```

### Step 5. 리스크 버퍼 계산

| 리스크 요소 | 버퍼 비율 |
|------------|----------|
| 기술 불확실성 (신기술 도입) | +20% |
| 요구사항 불안정성 (빈번한 변경) | +15% |
| 외부 연동 의존성 | +10% |
| 팀 경험 부족 | +10% |

최종 일정 = 기본 추정 x (1 + 리스크 버퍼 합계)

## 오류 처리

| 상황 | 처리 |
|------|------|
| SRS 미존재 | Plan Phase 선행 필요 안내 |
| FT 0건 | US 기반 추정으로 전환 (정확도 감소 경고) |
| config 팀 정보 미설정 | 기본값 적용 (teamSize=2, iterationWeeks=2) |
| 추정 결과 비합리적 (100+ 이터레이션) | 스코프 축소 제안 |

## 연동

- **호출원**: `u-skill-plan` (로드맵 생성), `u-agent-pm` (일정 관리)
- **호출 대상**: 없음 (계산 전용)
- **참조 엔진**: engine-doc (SRS 문서 읽기)
