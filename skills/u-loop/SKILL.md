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

**Primary Agent:** u-agent-orchestrator (모든 phase를 순차 조율)

> **용도:** 밤새 돌려놓고 아침에 결과물을 확인하는 무인 자동화.
> 사람이 개입하지 않아도 되도록 auto 모드를 강제하고, 에러 시 자동 복구/스킵하며, 모든 판단을 Assumptions Log에 기록한다.

---

## Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--from X` | `ingest` | 시작 단계 (ingest, plan, design, dev, qa) |
| `--to Y` | `qa` | 종료 단계 (ship은 루프에서 제외) |
| `--max-errors N` | `10` | 누적 에러 N개 초과 시 루프 중단 |
| `--max-assumptions N` | `50` | 가정 N개 초과 시 루프 중단 (무한 추정 방지) |
| `--resume` | - | 이전 중단 지점에서 재개 |
| `--dry-run` | - | 실행 계획만 표시, 실제 실행하지 않음 |
| `--notify` | - | 완료/중단 시 알림 (터미널 벨 + 로그 파일) |
| `--iterations N` | `1` | PDCA 반복 횟수 (2 이상이면 Act 후 다시 Plan부터) |

---

## Execution Flow

### Step 0: Pre-flight Check

루프 시작 전 환경을 검증한다.

1. `.u-maker/` 존재 확인 → 없으면 중단 + "/u-init을 먼저 실행하세요"
2. `u-maker.config.json` 읽기 → scope 해석
3. `--resume` 플래그 확인:
   - 있으면: `_loop-state.json` 로드 → 마지막 체크포인트에서 재개
   - 없으면: 새 루프 시작
4. 실행 계획 생성 + 표시:

```
## u-loop Execution Plan

Scope: retail
Mode: auto (unattended)
Pipeline: ingest → plan → design → dev → qa
Max errors: 10
Max assumptions: 50
Iterations: 1

Estimated steps:
  1. /u-ingest retail
  2. /u-plan retail
  3. /u-gate retail (Plan → Design)
  4. /u-design retail
  5. /u-gate retail (Design → Do)
  6. /u-dev retail
  7. /u-gate retail (Do → Check)
  8. /u-qa retail

※ /u-ship은 루프에서 제외됩니다. 배포/회고는 직접 실행하세요.

Starting in 3 seconds... (Ctrl+C to cancel)
```

5. `--dry-run`이면 여기서 종료

### Step 1: Execute Pipeline

각 단계를 순차 실행한다. 모든 단계는 **auto 모드 강제** (사용자 입력 대기 없음).

#### Pipeline Sequence

```
[ingest] → [plan] → [gate] → [design] → [gate] → [dev] → [gate] → [qa]
```

> `/u-ship`(배포/회고)은 루프에서 **의도적으로 제외**한다. 무인 실행으로 배포가 자동 트리거되면 안 되므로, 배포는 사람이 결과를 확인한 후 직접 실행해야 한다.

각 단계별 실행 내용:

| Step | 실행 커맨드 | 성공 조건 | 실패 시 |
|------|-----------|----------|---------|
| **ingest** | `/u-ingest {scope}` | _classified/ 항목 1개 이상 | 스킵 (raw data 없으면 건너뜀) |
| **plan** | `/u-plan {scope}` | SRS + IA + Roadmap 생성 | 에러 로그 + 중단 |
| **gate-1** | `/u-gate {scope}` | Plan → Design PASS | 자동 재시도 1회 (누락 문서 생성 시도) |
| **design** | `/u-design {scope}` | ERD + API + Screen + RTM 생성 | 에러 로그 + 중단 |
| **gate-2** | `/u-gate {scope}` | Design → Do PASS | 자동 재시도 1회 |
| **dev** | `/u-dev {scope}` | Code 생성 + build success | build 실패 시 자동 수정 3회 시도 |
| **gate-3** | `/u-gate {scope}` | Do → Check PASS | 자동 재시도 1회 |
| **qa** | `/u-qa {scope}` | TC + Test Report 생성 | 테스트 실패는 에러 아님 (결과 기록) |

### Step 1.1: Auto Review Report (per step)

각 단계 완료 후 `/u-report`를 자동 호출하여 중간 리뷰 리포트 HTML을 생성한다.

```
[ingest 완료] → /u-report {scope} --only ingest
[plan 완료]   → /u-report {scope} --only plan
[design 완료] → /u-report {scope} --only design
[dev 완료]    → /u-report {scope} --only dev
[qa 완료]     → /u-report {scope} --only qa
[루프 종료]   → /u-report {scope} --only dashboard
```

루프용 리포트는 `.u-maker/_reports/loop-{loopId}/`에 저장되며, 루프 메타데이터(소요 시간, 에러, 가정)가 대시보드에 추가 포함된다.

아침에 `index.html`을 브라우저에서 열면 전체 결과를 한눈에 확인할 수 있다. `/u-report` 스킬의 상세 사양을 참조.

### Step 2: Checkpoint Management

매 단계 완료 시 체크포인트를 저장한다.

**체크포인트 파일:** `.u-maker/_loop-state.json`

```json
{
  "loopId": "LOOP-{timestamp}",
  "scope": "retail",
  "startedAt": "{ISO 8601}",
  "lastCheckpoint": "{ISO 8601}",
  "currentStep": "design",
  "completedSteps": ["ingest", "plan", "gate-1"],
  "iteration": 1,
  "totalIterations": 1,
  "status": "running",
  "config": {
    "from": "ingest",
    "to": "ship",
    "maxErrors": 10,
    "maxAssumptions": 50
  },
  "errors": [
    {
      "step": "plan",
      "error": "FR-023 priority 미확정",
      "action": "assumed Medium",
      "assumptionId": "A-015",
      "timestamp": "{ISO 8601}"
    }
  ],
  "metrics": {
    "totalErrors": 2,
    "totalAssumptions": 15,
    "totalSkipped": 1,
    "documentsCreated": 8,
    "codeFilesGenerated": 24,
    "testCasesCreated": 12,
    "elapsedMs": 1234567
  }
}
```

### Step 3: Error Handling Strategy

에러 유형별 자동 대응:

| 에러 유형 | 자동 대응 | 최대 재시도 |
|----------|----------|------------|
| **Gate 실패** | 누락 문서 자동 생성 시도 | 1회 |
| **Build 실패** | missing imports, type 에러 자동 수정 | 3회 |
| **Test 실패** | 실패는 정상 결과로 기록 (중단하지 않음) | - |
| **문서 생성 실패** | 재시도 → 실패 시 스킵 + 에러 로그 | 2회 |
| **데이터 부족** | assumption 생성 후 계속 | - |
| **Unknown 에러** | 에러 로그 + 다음 단계 시도 | 1회 |

#### 중단 조건 (Hard Stop)

아래 조건 중 하나라도 충족되면 루프를 즉시 중단한다:

1. `--max-errors` 초과
2. `--max-assumptions` 초과
3. `.u-maker/` 구조 손상 감지
4. 동일 에러 3회 연속 반복 (무한 루프 방지)
5. 디스크 공간 부족

### Step 4: Progress Logging

실행 중 진행 상황을 실시간으로 기록한다.

**로그 파일:** `.u-maker/_loop-log.md`

```markdown
# u-loop Execution Log

**Loop ID:** LOOP-20260328-013000
**Scope:** retail
**Started:** 2026-03-28 01:30:00
**Mode:** auto (unattended)

---

## [01:30:05] Step 1/8: /u-ingest retail
- Status: COMPLETED
- Duration: 45s
- Items classified: 42
- Assumptions: 3

## [01:30:50] Step 2/8: /u-plan retail
- Status: COMPLETED
- Duration: 120s
- Documents: srs.md, ia.md, roadmap.md
- Assumptions: 8

## [01:32:50] Step 3/8: /u-gate retail (Plan → Design)
- Status: PASS
- Duration: 5s

## [01:32:55] Step 4/8: /u-design retail
- Status: COMPLETED
- Duration: 180s
- Documents: erd.md, api.md, screens.md, screen-flow.md, rtm.md
- Wireframe viewer: wireframes/index.html
- Assumptions: 5

...

## [03:15:00] Step 8/8: /u-qa retail
- Status: COMPLETED
- Duration: 600s
- Test cases: 24
- Tests passed: 20/24

---

## Summary

| Metric | Value |
|--------|-------|
| Total duration | 1h 45m |
| Steps completed | 8/8 |
| Documents created | 12 |
| Code files generated | 48 |
| Test cases | 24 |
| Tests passed | 20/24 |
| Errors encountered | 2 |
| Errors auto-resolved | 2 |
| Assumptions made | 16 |
| Final status | **COMPLETED** |
```

### Step 5: Multi-Iteration Loop

`--iterations N` (N >= 2) 사용 시:

```
Iteration 1: ingest → plan → design → dev → qa
                                                 ↓
Iteration 2: plan (backlog 기반) → design → dev → qa
                                                   ↓
Iteration 3: ...
```

각 iteration에서:
1. 이전 iteration의 QA 결과 + backlog에서 미완료 항목 수집
2. 미완료 항목을 다음 iteration의 Plan에 반영
3. 새 iteration 번호로 문서 생성
4. `u-maker.config.json`의 `iteration.current` 자동 증가

### Step 6: Completion Report

루프 완료 시 최종 리포트를 표시한다.

```
## u-loop Complete

**Loop ID:** LOOP-20260328-013000
**Duration:** 1h 45m (01:30 → 03:15)
**Iterations:** 1/1

### Pipeline Result
| Step | Status | Duration | Notes |
|------|--------|----------|-------|
| ingest | DONE | 45s | 42 items classified |
| plan | DONE | 2m | SRS + IA + Roadmap |
| gate (Plan→Design) | PASS | 5s | |
| design | DONE | 3m | ERD + API + Screen + RTM |
| gate (Design→Do) | PASS | 5s | |
| dev | DONE | 15m | 48 files generated |
| gate (Do→Check) | PASS | 5s | |
| qa | DONE | 10m | 20/24 tests passed |

### Metrics
- Documents: 12 created, 0 failed
- Code files: 48 generated, build success
- Tests: 24 cases, 20 passed, 4 failed
- Errors: 2 encountered, 2 auto-resolved
- Assumptions: 16 made (review with /u-assume)

### Next Steps (사람이 직접 수행)
1. Review 16 assumptions: `/u-assume retail`
2. Review 4 failed tests: `/u-doc retail test-report`
3. Review backlog items: `/u-backlog retail`
4. 결과 확인 후 배포 + 회고: `/u-ship retail`

### Files
- **Review dashboard: `.u-maker/_reports/loop-{loopId}/index.html`** ← 브라우저에서 열기
- Step reports: `.u-maker/_reports/loop-{loopId}/01-ingest-report.html` ~ `05-qa-report.html`
- Execution log: `.u-maker/_loop-log.md`
- State file: `.u-maker/_loop-state.json`
```

---

## --from / --to 범위 지정

| 값 | Pipeline 위치 |
|----|--------------|
| `ingest` | 1번째 (데이터 분석) |
| `plan` | 2번째 (기획) |
| `design` | 3번째 (설계) |
| `dev` | 4번째 (구현) |
| `qa` | 5번째 (검증) |

> `ship`은 루프에서 제외. 배포/회고는 사람이 결과를 확인한 후 `/u-ship`으로 직접 실행한다.

예시:
```bash
/u-loop retail                           # ingest → qa (전체)
/u-loop retail --from plan --to design   # plan → design만
/u-loop retail --from dev                # dev → qa
/u-loop retail --to plan                 # ingest → plan만
```

---

## Resume (재개)

중단된 루프를 이어서 실행:

```bash
/u-loop retail --resume
```

1. `_loop-state.json` 로드
2. `completedSteps` 이후 단계부터 재개
3. 이전 에러/가정 카운트 유지
4. 로그에 "RESUMED" 마커 추가

`_loop-state.json`이 없으면 에러: "재개할 루프가 없습니다. --resume 없이 실행하세요."

---

## Parallel Multi-App

멀티 앱 프로젝트에서 앱별 병렬 실행:

```bash
/u-loop all                              # 모든 앱 순차 실행
/u-loop retail,admin                     # 2개 앱 순차 실행
```

실행 순서:
1. `common` 정책 먼저 생성 (있으면 스킵)
2. 앱별 순차 실행 (앱 간 의존성이 있을 수 있으므로 병렬 아님)
3. 앱별 `_loop-state.json` + `_loop-log.md` 개별 생성

---

## Safety Rules

1. **auto 모드 강제**: 루프 중 사용자 입력 대기 없음. 모든 판단은 assumption으로 기록
2. **`_input/` READ-ONLY**: raw data 수정 금지
3. **체크포인트 필수**: 매 단계 완료 시 `_loop-state.json` 갱신
4. **무한 루프 방지**: 동일 에러 3회 연속 시 hard stop
5. **max-errors / max-assumptions 가드**: 초과 시 즉시 중단
6. **기존 Final 문서 보존**: 이미 Final인 문서는 덮어쓰지 않음 (스킵)
7. **디스크 공간 확인**: 각 단계 시작 전 최소 100MB 여유 확인
8. **로그 보존**: `_loop-log.md`는 절대 삭제하지 않음 (append only)
9. **중단 시 정리**: Ctrl+C 또는 에러 중단 시 현재 단계까지의 상태 저장 후 종료
10. **알림**: `--notify` 시 완료/중단 시점에 터미널 벨 + 로그 파일에 명시
