# Iteration Rules

> u-ssot의 Iteration 반복 시스템과 `/u-loop` 관련 규칙을 정의한다.

---

## 1. `/u-loop` Behavior

`/u-loop` 커맨드는 PDCA 사이클을 종료 조건 충족까지 자동 반복한다.

### 6-Step Loop Process

```mermaid
flowchart TD
    START([/u-loop]) --> STEP1[Step 1: Init Check]
    STEP1 --> STEP2[Step 2: Progress Report]
    STEP2 --> STEP3[Step 3: Phase Traverse]
    STEP3 --> STEP4[Step 4: Exit Check]
    STEP4 -->|Pass| STEP6[Step 6: Complete]
    STEP4 -->|Fail| STEP5[Step 5: ACT on Fail]
    STEP5 --> STEP2
    STEP6 --> DONE([Loop Done])
```

| Step | Name | Description |
|------|------|-------------|
| 1 | **Init Check** | 현재 프로젝트 상태 확인. `u-docs/` 구조 검증, `1M_Index.md` 로드, 현재 Phase/Iteration 파악 |
| 2 | **Progress Report** | 현재 Iteration 진행률 배너 출력 (Phase, 완료율, 백로그 수, 결함 수) |
| 3 | **Phase Traverse** | 현재 Phase부터 순서대로 실행: PLAN → DESIGN → DO → CHECK. 각 Phase 완료 시 Gate 검증 |
| 4 | **Exit Check** | 4가지 종료 조건 판정. 모두 충족 시 Step 6, 미충족 시 Step 5 |
| 5 | **ACT on Fail** | ACT Phase 실행 (백로그 정리, 아카이브, 회고). 다음 Iteration 번호 증가 후 Step 2로 복귀 |
| 6 | **Complete** | 최종 완료. 완료 배너 출력, 전체 Iteration 요약 |

---

## 2. `/u-loop-from [phase]` Behavior

특정 Phase부터 루프를 시작한다.

```
/u-loop-from design   # DESIGN Phase부터 시작
/u-loop-from check    # CHECK Phase부터 시작
```

| Phase Argument | Starting Point | Skipped Phases |
|---------------|----------------|----------------|
| `plan` | PLAN Phase | None (전체 실행) |
| `design` | DESIGN Phase | PLAN |
| `dev` / `do` | DO Phase | PLAN, DESIGN |
| `check` | CHECK Phase | PLAN, DESIGN, DO |
| `act` | ACT Phase | PLAN, DESIGN, DO, CHECK |

**주의사항:**
- 시작 Phase의 선행 문서가 Final 상태인지 자동 검증
- 선행 문서가 Final이 아닌 경우 경고 출력 후 사용자 확인 요청
- Iteration 2+ 에서만 유효 (Iteration 1은 반드시 PLAN부터)

---

## 3. `/u-stop` Behavior

실행 중인 루프를 즉시 중단한다.

```
/u-stop
```

동작:
1. 현재 Phase 작업을 안전하게 중단 (진행 중인 문서는 Draft 상태로 저장)
2. 루프 상태를 `PAUSED`로 변경
3. 현재 상태 저장: Phase, Iteration, 진행률
4. 중단 배너 출력

```
+--------------------------------------------------+
| LOOP PAUSED                                       |
| Iteration: 2 | Phase: DO | Progress: 45%         |
| Resume: /u-resume | Status: /u-status             |
+--------------------------------------------------+
```

---

## 4. `/u-resume` Behavior

중단된 루프를 재개한다.

```
/u-resume
```

동작:
1. 저장된 상태 로드 (Phase, Iteration, 진행률)
2. 루프 상태를 `RUNNING`으로 변경
3. 중단된 Phase부터 루프 재개
4. 재개 배너 출력

```
+--------------------------------------------------+
| LOOP RESUMED                                      |
| Iteration: 2 | Phase: DO | Progress: 45%         |
| Continuing from where you left off...             |
+--------------------------------------------------+
```

---

## 5. Exit Criteria

### Pseudocode

```python
def check_exit_criteria():
    # Condition 1: All backlog items Done
    backlog = parse_backlog("u-docs/05-act/5ACT_Backlog.md")
    open_items = [item for item in backlog if item.status != "Done"]
    cond_1 = len(open_items) == 0

    # Condition 2: No Critical/Major defects
    report = parse_report("u-docs/04-check/4QA_Report.md")
    critical_major = [d for d in report.defects
                      if d.severity in ("Critical", "Major")]
    cond_2 = len(critical_major) == 0

    # Condition 3: All FR implemented
    srs = parse_srs("u-docs/01-plan/1A_SRS.md")
    unimplemented = [fr for fr in srs.features
                     if not fr.implemented]
    cond_3 = len(unimplemented) == 0

    # Condition 4: Build success
    cond_4 = run_command("bun run build").returncode == 0

    return ExitResult(
        passed=all([cond_1, cond_2, cond_3, cond_4]),
        details={
            "backlog_open": len(open_items),
            "critical_major_defects": len(critical_major),
            "unimplemented_fr": len(unimplemented),
            "build_success": cond_4,
        }
    )
```

### Exit Report Format

```
+--------------------------------------------------+
| EXIT CRITERIA CHECK                               |
|--------------------------------------------------|
| [PASS] Backlog items: 0 open                     |
| [PASS] Critical/Major defects: 0                 |
| [FAIL] FR implementation: 2 remaining            |
| [PASS] Build: SUCCESS                            |
|--------------------------------------------------|
| Result: FAIL - Continuing to ACT Phase           |
+--------------------------------------------------+
```

---

## 6. Backlog Item Structure

`5ACT_Backlog.md` 내 백로그 항목의 표준 구조:

| Field | Description | Example |
|-------|-------------|---------|
| `BL-ID` | 백로그 고유 ID | BL-001, BL-002 |
| `Type` | 항목 유형 | Bug, Enhancement, Task |
| `Origin` | 발생 출처 | CHECK (QA 발견), DESIGN (설계 누락), DEV (구현 이슈) |
| `Description` | 항목 설명 | "로그인 API 에러 핸들링 누락" |
| `Priority` | 우선순위 | Critical, Major, Minor, Trivial |
| `Status` | 처리 상태 | Open, In Progress, Done |
| `Iteration` | 등록된 Iteration | Iter 1, Iter 2 |

### Backlog Table Format

```markdown
| BL-ID | Type | Origin | Description | Priority | Status | Iteration |
|-------|------|--------|-------------|----------|--------|-----------|
| BL-001 | Bug | CHECK | 로그인 API 500 에러 | Critical | Open | Iter 1 |
| BL-002 | Enhancement | DESIGN | 비밀번호 규칙 강화 | Minor | Open | Iter 1 |
| BL-003 | Task | DEV | 에러 바운더리 추가 | Major | Open | Iter 1 |
```

---

## 7. Progress Banner Formats

### Iteration Start Banner

```
+==================================================+
| ITERATION 2 STARTED                               |
|--------------------------------------------------|
| Previous: Iter 1 (FAIL - 3 open backlog items)   |
| Focus: BL-001 (Critical), BL-003 (Major)         |
| Target Phase: PLAN → CHECK                        |
+==================================================+
```

### Phase Progress Banner

```
+--------------------------------------------------+
| PHASE: DESIGN | Iteration: 2                      |
|--------------------------------------------------|
| [DONE] u-CX: Screen Design (2CX_Screen.md)       |
| [WORK] u-A: ERD (2A_ERD.md)                      |
| [WAIT] u-A: API Contract (2A_API.md)             |
| [WAIT] u-M: Validation                           |
|--------------------------------------------------|
| Progress: 25% | Backlog: 3 open                  |
+--------------------------------------------------+
```

### Loop Complete Banner

```
+==================================================+
| LOOP COMPLETE                                     |
|--------------------------------------------------|
| Total Iterations: 3                               |
| Final Status: ALL PASS                            |
| Documents: 13 Final                               |
| Build: SUCCESS                                    |
| Defects Resolved: 5/5                             |
+==================================================+
```

---

## 8. Iteration Rules Summary

| # | Rule | Description |
|---|------|-------------|
| 1 | 자동 반복 | CHECK Gate 실패 시 자동으로 ACT → 다음 PLAN 전환 |
| 2 | 증분 작업 | Iteration 2+ 에서는 Backlog Open 항목만 대상으로 변경분만 갱신 |
| 3 | 최대 반복 | 기본 10회 제한 (`maxIterations` 설정으로 변경 가능) |
| 4 | 중단/재개 | `/u-stop`으로 루프 중단, `/u-resume`으로 재개 |
| 5 | Final 유지 | 기존 Final 문서는 유지, 해당 항목만 PATCH 업데이트 |
| 6 | 아카이브 | 매 Iteration 완료 시 `u-docs/iterations/iter-N/`에 스냅샷 보관 |
