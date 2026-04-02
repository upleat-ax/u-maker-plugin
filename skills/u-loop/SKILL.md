---
name: u-loop
description: "무인 자동 실행 루프. PDCA 파이프라인을 중단 없이 연속 실행한다. 밤새 돌려놓으면 아침에 결과물을 확인할 수 있다. 체크포인트 기반 재개, 에러 자동 복구, 진행 로그를 지원한다."
triggers:
  - "/u-loop"
  - "/u-pleat"
  - "loop"
  - "pleat"
  - "자동 실행"
  - "밤새 돌려"
  - "무인 실행"
  - "전체 자동"
  - "run all"
---

# u-loop -- Unattended Continuous Execution

`/u-loop [scope] [--from X] [--to Y] [--max-errors N] [--resume]` 명령으로 PDCA 파이프라인을 중단 없이 연속 실행한다.

**Primary Agent:** u-agent-orchestrator | **용도:** 밤새 무인 자동화. auto 모드 강제, 에러 시 자동 복구/스킵, 모든 판단을 Assumptions Log에 기록.

---

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--from X` | `ingest` | 시작 단계 (ingest/plan/design/dev/qa) |
| `--to Y` | `qa` | 종료 단계 (ship은 루프 제외) |
| `--max-errors N` | `10` | 누적 에러 초과 시 중단 |
| `--max-assumptions N` | `50` | 가정 초과 시 중단 (무한 추정 방지) |
| `--resume` | - | 이전 중단 지점에서 재개 |
| `--dry-run` | - | 실행 계획만 표시 |
| `--notify` | - | 완료/중단 시 알림 |
| `--iterations N` | `1` | PDCA 반복 횟수 |

---

## Execution Flow

### Step 0: Pre-flight Check

1. `.u-maker/` 존재 확인 → config 읽기 → scope 해석
2. `--resume`: `.state/loop-state.json` 로드 → 마지막 체크포인트에서 재개 / 없으면 새 루프
3. 실행 계획 생성 표시 (scope, mode, pipeline 범위, limits)
4. `--dry-run`이면 여기서 종료

### Step 1: Execute Pipeline

모든 단계 auto 모드 강제 (사용자 입력 대기 없음).

**Pipeline:** `[ingest] → [plan] → [gate] → [design] → [gate] → [dev] → [gate] → [qa]`

> `/u-ship`은 의도적 제외. 배포는 사람이 결과 확인 후 직접 실행.

| Step | 커맨드 | 성공 조건 | 실패 시 |
|------|--------|----------|---------|
| ingest | `/u-ingest {scope}` | classified 1개+ | 스킵 (raw data 없으면) |
| plan | `/u-plan {scope}` | SRS+IA+Roadmap 생성 | 에러 로그 + 중단 |
| gate-1 | `/u-gate {scope}` | Plan→Design PASS | 자동 재시도 1회 |
| design | `/u-design {scope}` | ERD+API+Screen+RTM 생성 | 에러 로그 + 중단 |
| gate-2 | `/u-gate {scope}` | Design→Do PASS | 자동 재시도 1회 |
| dev | `/u-dev {scope}` | Code 생성 + build success | build 실패 시 자동 수정 3회 |
| gate-3 | `/u-gate {scope}` | Do→Check PASS | 자동 재시도 1회 |
| qa | `/u-qa {scope}` | TC+Report 생성 | 실패는 결과 기록 (중단 안함) |

### Step 1.1: Auto Review Report (per step)

각 단계 완료 후 `/u-report {scope} --only {phase}` 자동 호출 → `.u-maker/out/reports/loop-{loopId}/`에 저장. 루프 종료 시 `--only dashboard` 추가 생성. 브라우저에서 `index.html` 열어 전체 결과 확인.

### Step 2: Checkpoint Management

매 단계 완료 시 `.u-maker/.state/loop-state.json`에 체크포인트 저장:

```json
{
  "loopId": "LOOP-{timestamp}",
  "scope": "retail",
  "currentStep": "design",
  "completedSteps": ["ingest", "plan", "gate-1"],
  "iteration": 1,
  "status": "running",
  "config": { "from": "ingest", "to": "qa", "maxErrors": 10, "maxAssumptions": 50 },
  "errors": [{ "step": "plan", "error": "...", "action": "assumed Medium", "assumptionId": "A-015" }],
  "metrics": { "totalErrors": 2, "totalAssumptions": 15, "documentsCreated": 8, "elapsedMs": 1234567 }
}
```

### Step 3: Error Handling

| 에러 유형 | 자동 대응 | 최대 재시도 |
|----------|----------|------------|
| Gate 실패 | 누락 문서 자동 생성 시도 | 1회 |
| Build 실패 | missing imports, type 에러 자동 수정 | 3회 |
| Test 실패 | 정상 결과로 기록 (중단 안함) | - |
| 문서 생성 실패 | 재시도 → 실패 시 스킵 + 로그 | 2회 |
| 데이터 부족 | assumption 생성 후 계속 | - |
| Unknown | 에러 로그 + 다음 단계 시도 | 1회 |

**Hard Stop 조건:** max-errors 초과 / max-assumptions 초과 / `.u-maker/` 구조 손상 / 동일 에러 3회 연속 / 디스크 부족

### Step 4: Progress Logging

`.u-maker/.state/loop-log.md`에 실시간 기록 (append only): 각 단계 Status, Duration, 생성 항목 수, Assumptions 수. 완료 시 Summary 테이블 포함.

### Step 5: Multi-Iteration

`--iterations N` (N>=2): 각 iteration에서 이전 QA 결과 + backlog 미완료 수집 → 다음 Plan 반영 → `iteration.current` 자동 증가

### Step 6: Completion Report

Pipeline Result 테이블, Metrics, Next Steps (사람이 직접: assumptions 리뷰, 실패 테스트 확인, 백로그 정리, `/u-ship`), 리포트 파일 경로 표시.

---

## --from / --to 범위

| 값 | 순서 |
|----|------|
| `ingest` | 1 |
| `plan` | 2 |
| `design` | 3 |
| `dev` | 4 |
| `qa` | 5 |

> `ship`은 루프 제외. 배포/회고는 `/u-ship`으로 직접 실행.

---

## Resume

`/u-loop retail --resume` → `.state/loop-state.json` 로드 → `completedSteps` 이후 재개 → 에러/가정 카운트 유지 → 로그에 "RESUMED" 마커. 파일 없으면 에러.

## Multi-App

`/u-loop all` 또는 `retail,admin` → common 정책 먼저 → 앱별 순차 실행 (의존성 가능하므로 병렬 안함) → 앱별 state/log 개별 생성

---

## Safety Rules

1. auto 모드 강제: 모든 판단은 assumption으로 기록
2. 소스/`data/input/` 무수정, `.u-maker/` 대상 디렉토리만 쓰기
3. 체크포인트 필수, 무한 루프 방지 (동일 에러 3회 시 hard stop)
4. max-errors/max-assumptions 가드, 기존 Final 문서 보존
5. 로그 보존 (append only), 중단 시 상태 저장 후 종료
