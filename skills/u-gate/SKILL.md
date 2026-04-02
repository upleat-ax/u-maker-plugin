---
name: u-gate
description: "Phase Gate 충족 여부 검사 + 다음 Phase 전환. 현재 Phase의 exit criteria를 평가하고, PASS 시 다음 Phase로 전환한다."
triggers:
  - "/u-gate"
  - "gate check"
  - "phase gate"
  - "페이즈 전환"
---

# u-gate -- Phase Gate Check + Transition

`/u-gate [scope] [--to phase]` 명령으로 현재 Phase의 gate 조건을 평가하고, 조건 충족 시 다음 Phase로 전환한다.

**Primary Agent:** u-agent-gatekeeper (engine-validator, engine-phase-detector 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |

## Flags

| Flag | Description |
|------|-------------|
| `--to phase` | 명시적 전환 대상 Phase 지정 (plan, do, check, act) |
| `--dry-run` | 실제 전환 없이 gate 조건 평가만 수행 |
| `--verbose` | 각 조건별 상세 결과 출력 |

---

## Execution Flow

### Step 1: Detect Current Phase

1. `app.config.json` → `phase` 필드 읽기
2. engine-phase-detector로 실제 문서 상태 기반 Phase 감지:
   - `_index.json` 문서 상태 집계
   - 완료도 규칙에 따라 현재 Phase 판별
3. 설정값 vs 감지값 불일치 시 경고 + 감지값 우선

### Step 2: Determine Gate Conditions

현재 Phase → 다음 Phase 전환별 gate 조건:

#### plan -> do

| # | Condition | Check Method | Severity |
|---|-----------|-------------|----------|
| G-01 | SRS = Final | `_index.json` status 확인 | Critical |
| G-02 | IA = Final | `_index.json` status 확인 | Critical |
| G-03 | Roadmap approved | `_index.json` status = Final 또는 Review | Critical |
| G-04 | 모든 FR에 US 매핑 | C-01 규칙 실행 | Critical |
| G-05 | 모든 US에 FT 매핑 | C-02 규칙 실행 | Critical |
| G-06 | USR 정의 완료 | SRS User Types 섹션 비어있지 않음 | Warning |
| G-07 | Backlog 초기화 | `data/backlog/_index.json` 항목 존재 | Warning |

#### do -> check

| # | Condition | Check Method | Severity |
|---|-----------|-------------|----------|
| G-10 | ERD = Final | `_index.json` status 확인 | Critical |
| G-11 | API Contract = Final | `_index.json` status 확인 | Critical |
| G-12 | Screens = Final | `_index.json` status 확인 | Critical |
| G-13 | RTM = Final | `_index.json` status 확인 | Critical |
| G-14 | 모든 FT code-complete | `code.json` 확인 | Critical |
| G-15 | Build success | `bun run build` exit code 0 | Critical |
| G-16 | Cross-doc consistency | C-03 ~ C-05 규칙 실행 | Critical |
| G-17 | Spec-sync pass | spec-sync-report 확인 | Warning |

#### check -> complete (iteration 완료)

| # | Condition | Check Method | Severity |
|---|-----------|-------------|----------|
| G-20 | Critical defects = 0 | `defects/` 스캔 | Critical |
| G-21 | Major defects = 0 | `defects/` 스캔 | Critical |
| G-22 | All FR implemented | RTM 100% coverage | Critical |
| G-23 | Build success | `bun run build` exit code 0 | Critical |
| G-24 | Test pass rate >= 95% | test-report.json 기준 | Critical |

#### check -> act (check 실패 시)

| # | Condition | Check Method | Severity |
|---|-----------|-------------|----------|
| G-30 | Check phase 실행 완료 | test-report 존재 | Critical |
| G-31 | Exit criteria 미충족 | G-20 ~ G-24 중 하나 이상 FAIL | Trigger |

- check->act는 check->complete가 FAIL할 때 자동 전환 경로

#### act -> plan (다음 iteration)

| # | Condition | Check Method | Severity |
|---|-----------|-------------|----------|
| G-40 | Retrospective 작성 완료 | retrospective.md 존재 + 현 iteration 데이터 포함 | Critical |
| G-41 | Archive 완료 | `docs/iterations/{n}/` 존재 | Critical |
| G-42 | Iteration log 갱신 | iteration-log.md에 현 iteration 기록 | Warning |
| G-43 | Carried-over items 등록 | `data/backlog/` carry-over 플래그 확인 | Warning |

### Step 3: Evaluate Each Condition

각 조건을 순차 실행:

1. Check method 실행
2. 결과: PASS / FAIL / SKIP (해당 문서 없음)
3. SKIP은 해당 Phase에 진입하지 않은 경우 (예: design 문서가 없는데 do->check gate)

### Step 4: Calculate Gate Result

```
Critical 조건 중 FAIL이 1개라도 있으면 → GATE FAIL
모든 Critical PASS → GATE PASS (Warning은 비차단)
```

### Step 5: Display Gate Report

```markdown
## Phase Gate Report

**App:** {app}
**Current Phase:** {phase}
**Target Phase:** {next-phase}
**Result:** {PASS ✅ | FAIL ❌}

### Conditions

| # | Condition | Result | Detail |
|---|-----------|--------|--------|
| G-01 | SRS = Final | ✅ PASS | v1.2.0, Final |
| G-02 | IA = Final | ✅ PASS | v1.1.0, Final |
| G-04 | FR→US mapping | ❌ FAIL | FR-0042 has no US |
| G-05 | US→FT mapping | ✅ PASS | 100% mapped |
| G-06 | USR defined | ⚠ WARN | 2 USR types (recommend ≥3) |

### Summary
- Critical PASS: {n}/{total}
- Critical FAIL: {n}
- Warnings: {n}
```

### Step 6: Execute Transition (PASS Only)

Gate PASS 시:

1. `app.config.json` 갱신:
   ```json
   {
     "phase": "{next-phase}"
   }
   ```

2. `u-maker.config.json` 갱신 (해당 시):
   ```json
   {
     "iteration": {
       "current": {n},
       "phase": "{next-phase}"
     }
   }
   ```

3. Phase 전환 로그 기록:
   - `iteration-log.md`에 Phase 전환 시각 기록
   - `_index.json`에 phase 갱신

4. 다음 Phase 안내:
   ```
   ## Phase Transition Complete

   {phase} → {next-phase}

   ### Next Steps
   - plan→do: Run /u-design or /u-dev
   - do→check: Run /u-qa
   - check→act: Run /u-ship
   - act→plan: Run /u-plan (new iteration)
   ```

### Step 7: Handle FAIL

Gate FAIL 시:

1. **항상 일시 중지** (mode와 무관하게 Always-Pause):
   ```
   ## Gate FAIL - Cannot Proceed

   {count} critical condition(s) not met.

   ### Blocking Issues
   1. {G-XX}: {description} → {fix suggestion}
   2. {G-XX}: {description} → {fix suggestion}

   ### Estimated Fix Effort
   - {issue}: ~{estimate}
   - Total: ~{total-estimate}

   ### Suggested Actions
   - /u-add {scope} us --parent FR-0042  (for G-04)
   - /u-sync {scope} --fix              (for consistency)
   - /u-dev {scope}                    (for code-complete)
   ```

2. Phase 전환 실행하지 않음
3. 사용자가 문제 해결 후 `/u-gate` 재실행 필요

---

## --to Flag

명시적 전환 대상 지정:

```
/u-gate myapp --to do      # plan→do gate 검사
/u-gate myapp --to check   # do→check gate 검사
```

- 현재 Phase에서 지정 Phase로의 전환이 유효하지 않으면 에러
- 유효 전환: plan→do, do→check, check→complete, check→act, act→plan

---

## --dry-run Flag

실제 전환 없이 gate 조건만 평가:

```
/u-gate myapp --dry-run
```

- 모든 조건 평가 + 리포트 생성
- `app.config.json` 수정하지 않음
- PASS/FAIL 결과만 표시

---

## Safety Rules

1. Gate FAIL 시 절대 자동 전환하지 않음 (Always-Pause, mode 무관)
2. Phase 전환은 순방향만 허용 (역방향 전환 금지, act→plan만 예외)
3. `--to` 플래그로 Phase 건너뛰기 불가 (plan→check 등)
4. 설정 vs 감지 Phase 불일치 시 사용자에게 알림 + 확인
5. Gate 조건 평가 중 에러 시 해당 조건 = FAIL 처리 (SKIP 아님)
6. `app.config.json`, `u-maker.config.json` 갱신 필수 (전환 시)
7. Phase 전환 로그 기록 필수
8. check→complete vs check→act 분기는 exit criteria 결과에 의해 자동 결정
