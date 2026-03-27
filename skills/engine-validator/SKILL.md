---
name: engine-validator
description: |
  Phase Gate 검증, 문서 간 교차 정합성 검사(13개 규칙),
  Exit Criteria 판정, RTM 일관성 검증을 수행하는 검증 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports:
  - ${PLUGIN_ROOT}/_refer/traceability-matrix.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
---

# Engine: Validator

> Phase Gate 조건 검증, 문서 교차 정합성 검사, Exit Criteria 판정을 수행한다.

## 역할

- Phase Gate 검증 (각 Phase 종료 조건 확인)
- 13개 교차 문서 정합성 규칙 검사
- Exit Criteria 판정 (Phase 전환 가/불가)
- 문서 완성도 검사 (`{{TODO}}` 잔존 확인)
- RTM(Requirements Traceability Matrix) 일관성 검증

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | 검증 대상 (Phase 또는 특정 문서), 앱 스코프 |
| **Output** | `{ pass, violations[], warnings[], exitCriteria }` |

## 13개 정합성 규칙

| # | 규칙 | 검사 내용 |
|---|------|----------|
| 1 | FR→US 매핑 | 모든 FR이 최소 1개 US에 매핑 |
| 2 | US→FT 매핑 | 모든 US가 최소 1개 FT에 매핑 |
| 3 | FT→Screen 매핑 | UI 관련 FT가 Screen에 매핑 |
| 4 | FT→API 매핑 | 서버 관련 FT가 API에 매핑 |
| 5 | Screen→IA 일치 | Screen의 모든 화면이 IA에 존재 |
| 6 | API→ERD 정합 | API 스키마가 ERD 엔티티와 일치 |
| 7 | FT→TC 매핑 | 모든 FT에 최소 1개 TC 존재 |
| 8 | ID 유일성 | FR/US/FT/TC ID 전체 중복 없음 |
| 9 | 상태 일관성 | Final 문서 내 Draft 참조 없음 |
| 10 | 버전 정합 | _index.json 버전과 문서 헤더 버전 일치 |
| 11 | JSON 동기화 | 모든 .md에 대응하는 .json 존재 |
| 12 | 링크 정합 | _links.json의 모든 참조가 유효 |
| 13 | NFR 최소 수량 | NFR 최소 10개 정의 |

## Phase Gate 조건

### Plan Gate
- Roadmap: Final
- Common_RA: Final
- SRS: Final (모든 앱)
- IA: Final (모든 앱)
- FR→US→FT 매핑 완료, TBD 0건
- NFR >= 10개
- JSON Export 완료

### Design Gate
- ERD: Final
- API: Final
- Screen: Final
- ScreenFlow: Final
- 교차 참조 규칙 #3~#6 통과

### Do Gate
- 코드 빌드 성공
- FT 구현율 100%
- Storybook 빌드 성공 (FE)

### Check Gate
- 모든 TC 실행 완료
- Critical/Major 결함 0건
- 커버리지 기준 충족

## 실행 절차

### Step 1. 검증 범위 결정

1. 대상 Phase 또는 특정 문서 식별
2. 해당하는 정합성 규칙 세트 선택
3. 관련 문서 로드

### Step 2. 규칙별 검사 실행

각 규칙에 대해:
1. 검사 대상 데이터 수집 (문서 파싱, _links.json 참조)
2. 조건 평가
3. 위반 시 violation 기록: `{ rule, severity, message, location }`

### Step 3. 완성도 검사

Final 상태 문서에 대해:
1. `{{TODO}}` 패턴 검색 → 잔존 시 violation
2. `TBD` 패턴 검색 → 잔존 시 violation
3. 필수 섹션 존재 여부 확인

### Step 4. Exit Criteria 판정

```
violations 중 Critical 0건 AND Major 0건
  → exitCriteria = PASS
violations 중 Critical > 0 OR Major > 0
  → exitCriteria = BLOCKED + 차단 사유 목록
```

### Step 5. 검증 리포트 생성

```json
{
  "phase": "Plan",
  "pass": false,
  "exitCriteria": "BLOCKED",
  "violations": [
    { "rule": 1, "severity": "Major", "message": "FR-0030 미매핑 US 없음" }
  ],
  "warnings": [
    { "rule": 11, "severity": "Minor", "message": "1_IA_RA.json 미존재" }
  ],
  "summary": { "critical": 0, "major": 1, "minor": 1, "info": 0 }
}
```

## 오류 처리

| 상황 | 처리 |
|------|------|
| 문서 로드 실패 | 해당 규칙 skip + 경고 (문서 미존재) |
| _links.json 미존재 | 링크 관련 규칙 skip + 경고 |
| 대규모 위반 (50+) | 상위 10건만 출력 + "외 N건" 요약 |
| Phase 미식별 | 전체 규칙 적용 |

## 연동

- **호출원**: `u-skill-validate`, `u-skill-check`, engine-workflow-runner (Gate 검사)
- **호출 대상**: 없음 (읽기 전용 검증)
- **참조 엔진**: engine-dep (_links.json 참조), engine-phase-detector (Phase 상태)
