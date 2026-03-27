---
name: u-ship
description: "ACT Phase. 최종 검증 + iteration log + retrospective. Exit criteria 평가 후 PASS면 아카이브, FAIL이면 미완료 항목을 다음 iteration으로 이월한다."
triggers:
  - "/u-ship"
  - "ship"
  - "배포"
  - "출시"
  - "act phase"
---

# u-ship -- Act Phase: Final Verification + Delivery

`/u-ship [scope] [-i] [--step]` 명령으로 iteration의 최종 검증, 회고, 아카이브를 수행한다. PDCA 사이클의 마지막 단계.

**Primary Agent:** u-agent-guardian (최종 검증) + u-agent-orchestrator (iteration 관리)

---

## Flags

| Flag | Description |
|------|-------------|
| `-i` | 분기점에서 사용자 확인 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |

---

## Execution Flow

### Step 1: Run Final Validation

u-agent-guardian에게 최종 검증 요청:

1. **Exit criteria 재평가:**

   | # | Criterion | Threshold |
   |---|-----------|-----------|
   | E-01 | Critical defects = 0 | Open/In Progress Critical = 0 |
   | E-02 | Major defects = 0 | Open/In Progress Major = 0 |
   | E-03 | All FR implemented | RTM 100% |
   | E-04 | Build success | `bun run build` pass |
   | E-05 | Test pass rate >= 95% | 최신 test-report 기준 |

2. **Cross-document consistency 최종 검사:**
   - 13개 consistency rule 전체 실행 (engine-validator)
   - C-01 ~ C-13 결과 리포트

3. **RTM coverage 최종 확인:**
   - Requirement coverage: FR 추적 체인 완성도
   - Test coverage: FT → TC 매핑 완성도
   - Implementation coverage: FT code-complete 비율

### Step 2: Evaluate PASS or FAIL

**PASS 조건:** Exit criteria E-01 ~ E-05 전부 충족

**FAIL 조건:** 하나라도 미충족

---

## PASS Path -- Successful Iteration

### Step 3-P: Generate Iteration Log

`docs/common/project/iteration-log.md` 갱신 + `iteration-log.json`:

```markdown
## Iteration {n}

**Started:** {date}
**Ended:** {date}
**Duration:** {days}

### Phase Timeline
| Phase | Started | Ended | Duration | Status |
|-------|---------|-------|----------|--------|
| Plan | {date} | {date} | {n}d | Complete |
| Design | {date} | {date} | {n}d | Complete |
| Do | {date} | {date} | {n}d | Complete |
| Check | {date} | {date} | {n}d | Complete |
| Act | {date} | {date} | {n}d | Complete |

### Deliverables
| Document | Version | Status |
|----------|---------|--------|
| SRS | 1.0.0 | Final |
| ERD | 1.0.0 | Final |
| API | 1.0.0 | Final |

### Metrics
- FR delivered: {n}/{total} ({pct}%)
- Defects found: {n} ({critical} Critical, {major} Major, {minor} Minor, {trivial} Trivial)
- Defects resolved: {n}/{total} ({pct}%)
- Test pass rate: {pct}%
- Velocity: {points} story points
```

### Step 4-P: Run Retrospective Session

회고 세션 실행:

1. Iteration 데이터 수집:
   - Phase별 소요 시간
   - 결함 패턴 분석
   - 공수 예측 vs 실제 비교
   - 가정(assumptions) 정확도

2. Keep / Problem / Try 프레임워크:

```markdown
## Retrospective - Iteration {n}

### Keep (잘한 점)
- {데이터 기반 인사이트}

### Problem (문제점)
- {결함 패턴에서 발견}
- {Phase 기간 분석에서 발견}

### Try (다음 iteration 개선)
- {구체적 액션 아이템}

### Action Items
| # | Action | Owner | Priority | Due |
|---|--------|-------|----------|-----|
| 1 | {action} | {agent} | High | Iteration {n+1} |
```

3. `/u-discuss retro` 세션 결과가 있으면 통합

**산출물:** `retrospective.md` + `retrospective.json`

### Step 5-P: Archive Current Iteration

1. 현재 iteration 문서를 아카이브:
   ```
   .u-maker/docs/iterations/{n}/
     ├── {app}/
     │   ├── 01-plan/    (복사)
     │   ├── 02-design/  (복사)
     │   ├── 03-dev/     (복사)
     │   └── 04-check/   (복사)
     ├── retrospective.md
     └── iteration-summary.json
   ```
2. 현재 `docs/{app}/` 문서 status 유지 (다음 iteration 기반)
3. `_classified/` 항목 중 `adopted` → 보존, 나머지 → 정리 대상 표시

### Step 6-P: Mark Iteration Complete

1. `u-maker.config.json` 갱신:
   ```json
   {
     "iteration": {
       "current": {n+1},
       "phase": "plan"
     }
   }
   ```
2. `app.config.json` → `phase: "plan"` (다음 iteration 시작)
3. 완료 메시지 표시:

```
## Iteration {n} Complete

**Status:** PASS
**Duration:** {days} days
**FR delivered:** {n}/{total}
**Test pass rate:** {pct}%

### Next Steps
- New iteration {n+1} initialized
- Backlog items carried over: {count}
- Run /u-plan to start next iteration
```

---

## FAIL Path -- Incomplete Iteration

### Step 3-F: Report Gaps

실패 원인 상세 보고:

```markdown
## Ship Evaluation: FAIL

### Failed Criteria
| # | Criterion | Required | Actual | Gap |
|---|-----------|----------|--------|-----|
| E-02 | Major defects = 0 | 0 | 2 | DEF-0023, DEF-0045 |
| E-03 | All FR implemented | 100% | 94% | FR-0012 incomplete |

### Blocking Issues
1. DEF-0023: Payment flow NaN error (Major)
2. DEF-0045: Session timeout (Major)
3. FR-0012: FT-0045 not code-complete

### Estimated Fix Effort
- DEF-0023: ~0.5 day
- DEF-0045: ~0.5 day
- FT-0045: ~1 day
- Total: ~2 days
```

### Step 4-F: Carry Over to Next Iteration

미완료 항목을 다음 iteration 백로그로 이월:

1. Open/In Progress 결함 → 다음 iteration backlog에 `carried-over` 플래그
2. 미완성 FT → 다음 iteration backlog에 이월
3. `_backlog/_index.json` 갱신
4. 이월 사유 기록

### Step 5-F: Transition to Act -> Plan

1. Iteration log에 FAIL 기록
2. 회고 세션 실행 (Step 4-P와 동일)
3. 아카이브 (Step 5-P와 동일, 단 status = "Incomplete")
4. 다음 iteration으로 전환:
   ```json
   {
     "iteration": {
       "current": {n+1},
       "phase": "plan"
     }
   }
   ```
5. 실패 메시지 표시:

```
## Iteration {n} Incomplete

**Status:** FAIL (2 criteria not met)
**Carried Over:** {count} items

### Carried Items
- DEF-0023: Payment flow NaN error (Major)
- DEF-0045: Session timeout (Major)
- FT-0045: Password reset feature

### Next Steps
- Iteration {n+1} initialized with carried-over items
- Run /u-plan to incorporate fixes into next plan
- Or run /u-dev to fix specific items directly
```

---

## Backlog Management at Ship

| Source | Action |
|--------|--------|
| Completed items (todo/in-progress → done) | status = "done", closedIn = iteration-{n} |
| Open defects (Critical/Major) | Carry over to iteration-{n+1}, flag = "carried-over" |
| Open defects (Minor/Trivial) | Remain in backlog, priority unchanged |
| Incomplete FT | Carry over to iteration-{n+1} |
| New action items (from retro) | Add to iteration-{n+1} backlog |

---

## Safety Rules

1. Exit criteria 최종 평가는 항상 수행 (건너뛰기 불가)
2. PASS/FAIL 판정은 자동이지만, 결과는 항상 사용자에게 보고 (Always-Pause on FAIL)
3. 아카이브 전 사용자 확인 필수 (interactive/step mode)
4. Retrospective는 실제 iteration 데이터 없이 생성 금지
5. 이월 항목에 반드시 `carried-over` 플래그 + 원 iteration 참조
6. iteration 번호 rollback 금지 (항상 증가)
7. `.json` 동반 파일 생성 필수
8. `_index.json`, `_links.json`, `u-maker.config.json` 갱신 필수
