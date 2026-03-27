---
name: engine-phase-detector
description: |
  _index.json 파일을 읽어 문서 상태를 집계하고,
  완료도 규칙에 따라 현재 PDCA Phase를 자동 판별하는 엔진.
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
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
---

# Engine: Phase Detector

> 프로젝트 문서 상태를 집계하여 현재 PDCA Phase를 자동 판별한다.

## 역할

- 각 Phase별 _index.json 파일에서 문서 상태(Draft/Review/Final) 집계
- 완료도 규칙에 따른 현재 Phase 자동 판별
- 5-Phase / 4-Phase 모드 지원
- Phase 전환 가능 여부(Gate) 판정

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | `.u-maker/docs/` 하위 _index.json 파일들 |
| **Output** | `{ currentPhase, phaseStatuses[], gateStatus, completeness% }` |

## 실행 절차

### Step 1. 문서 상태 수집

1. `.u-maker/docs/{app}/` 및 `common/` 하위의 모든 `_index.json` 읽기
2. 각 문서 항목에서 `status` 필드 추출
3. Phase별 그룹핑: `01-plan`, `02-design`, `03-do`, `04-check`, `05-act`

### Step 2. Phase별 완료도 계산

각 Phase의 완료도를 다음 기준으로 산출:

| Phase | 핵심 문서 | Final 조건 |
|-------|----------|-----------|
| **Plan** | Roadmap, Common_RA, SRS, IA | 모든 핵심 문서 Final |
| **Design** | ERD, API, Screen, ScreenFlow | 모든 핵심 문서 Final |
| **Do** | 코드 완성 + 빌드 성공 | build status = pass |
| **Check** | TestCase, TestReport | 전체 TC 실행 완료 |
| **Act** | IterationLog, Retrospective | 판정 완료 |

완료도 = (Final 문서 수 / 전체 필수 문서 수) x 100

### Step 3. 모드별 Phase 판별

**config 확인**: `.u-maker/u-maker.config.json`의 `designPhase` 값 읽기

| 모드 | designPhase 값 | Phase 구성 |
|------|----------------|-----------|
| 5-Phase | `standalone` | Plan → Design → Do → Check → Act |
| 4-Phase | `merged` | Plan → Do(Design 포함) → Check → Act |

### Step 4. 현재 Phase 결정

```
if Plan 미완료 → currentPhase = "Plan"
else if Design 미완료 (5-Phase) → currentPhase = "Design"
else if Do 미완료 → currentPhase = "Do"
else if Check 미완료 → currentPhase = "Check"
else → currentPhase = "Act"
```

### Step 5. Gate 상태 판정

현재 Phase의 모든 Gate 조건을 검사하여 다음 Phase 진입 가능 여부 반환:
- `PASS`: 모든 Gate 조건 충족 → 다음 Phase 진입 가능
- `BLOCKED`: 미충족 조건 목록과 함께 반환

## 오류 처리

| 상황 | 처리 |
|------|------|
| _index.json 미존재 | 해당 Phase = 0% 완료로 간주 |
| status 필드 누락 | `Draft`로 기본 처리 |
| config 미존재 | 4-Phase(merged) 모드를 기본값으로 사용 |
| 앱 디렉토리 미존재 | 해당 앱 skip + 경고 로그 |

## 연동

- **호출원**: engine-router (Phase 컨텍스트), engine-workflow-runner (Phase 전환 판단)
- **호출 대상**: 없음 (읽기 전용 엔진)
- **참조 엔진**: engine-validator (Gate 조건 상세 검증 위임 가능)
