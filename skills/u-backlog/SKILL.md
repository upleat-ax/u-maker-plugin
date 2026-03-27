---
name: u-backlog
description: "백로그 관리. 항목 조회, 추가, 스프린트 할당, 우선순위 정렬, 그루밍, 상태 변경, 번다운 차트를 지원한다."
triggers:
  - "/u-backlog"
  - "backlog"
  - "백로그"
  - "스프린트"
---

# u-backlog -- Backlog Management

`/u-backlog [scope] [action] [args]` 명령으로 백로그 항목을 관리한다. 조회, 추가, 스프린트 할당, 우선순위 정렬, 그루밍, 상태 변경, 번다운 차트를 지원한다.

**Primary Agent:** u-agent-orchestrator (engine-estimator 사용)

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `scope` | Optional | 대상 앱 이름. 생략 시 자동 선택 |
| `action` | Optional | 서브 액션 (아래 참조). 생략 시 목록 표시 |
| `args` | Varies | 액션별 추가 인자 |

## Flags (전역)

| Flag | Description |
|------|-------------|
| `--type X` | 유형 필터 (feature, bug, improvement, tech-debt) |
| `--status X` | 상태 필터 (backlog, todo, in-progress, review, done, blocked) |
| `--iteration N` | 특정 iteration 필터 |
| `--assignee X` | 담당자 필터 |
| `--label X` | 라벨 필터 |
| `--sort X` | 정렬 기준 (priority, created, updated, points). 기본: priority |

---

## Backlog Item Structure

```json
{
  "id": "BL-001",
  "type": "feature|bug|improvement|tech-debt",
  "title": "",
  "description": "",
  "priority": "must|should|could|wont",
  "storyPoints": null,
  "iteration": null,
  "status": "backlog",
  "assignee": null,
  "source": {
    "type": "fr|us|ft|defect|manual|discuss|retro",
    "ref": "FR-0001"
  },
  "labels": [],
  "dependencies": [],
  "created": "",
  "updated": ""
}
```

---

## Sub-Actions

### (none) -- List Backlog

`/u-backlog [scope] [flags]`

전체 백로그 항목을 우선순위순으로 표시:

```markdown
## Backlog - {app}

**Total:** {n} items | **Open:** {n} | **Done:** {n} | **Blocked:** {n}

### Must ({count})
| ID | Type | Title | Status | Points | Iteration | Assignee |
|----|------|-------|--------|--------|-----------|----------|
| BL-001 | feature | 사용자 인증 | todo | 5 | 1 | builder |
| BL-003 | bug | 로그인 오류 | in-progress | 2 | 1 | builder |

### Should ({count})
| ID | Type | Title | Status | Points | Iteration | Assignee |
|----|------|-------|--------|--------|-----------|----------|
| BL-005 | improvement | 대시보드 성능 | backlog | -- | -- | -- |

### Could ({count})
...

### Won't ({count})
...
```

필터 적용 예:
```
/u-backlog myapp --type bug --status in-progress
/u-backlog myapp --iteration 2 --sort points
```

### add -- Add Item

`/u-backlog [scope] add [type] "title"`

수동으로 백로그 항목 추가:

1. 새 BL-ID 생성 (기존 최대 + 1)
2. 항목 생성 (source.type = "manual")
3. `_backlog/_index.json` 갱신
4. 확인 메시지 표시

추가 플래그:
| Flag | Description |
|------|-------------|
| `--priority X` | 우선순위 (must/should/could/wont). 기본: should |
| `--description "text"` | 상세 설명 |
| `--labels "a,b"` | 라벨 |
| `--dependency BL-XXX` | 의존 항목 |

### sprint -- Sprint Planning

`/u-backlog [scope] sprint N`

Iteration N에 항목 할당:

1. **자동 추천 모드** (인자 없이):
   - engine-estimator로 velocity 계산 (이전 iteration 기반)
   - priority 순으로 항목 정렬
   - dependencies 확인 (의존 항목이 먼저 할당되어야 함)
   - velocity 한도까지 자동 추천
   ```markdown
   ## Sprint {N} Planning Recommendation

   **Velocity (prev):** {points} SP
   **Capacity:** {points} SP

   ### Recommended Items
   | ID | Title | Points | Priority | Dependencies |
   |----|-------|--------|----------|-------------|
   | BL-001 | 사용자 인증 | 5 | Must | -- |
   | BL-003 | 로그인 오류 | 2 | Must | BL-001 |
   | BL-007 | 프로필 설정 | 3 | Should | -- |
   | **Total** | | **10** | | |

   ### Not Included (overflow)
   | ID | Title | Points | Reason |
   |----|-------|--------|--------|
   | BL-012 | 리포트 기능 | 8 | Exceeds capacity |
   ```

2. **사용자 확인 후:**
   - 승인: 추천 항목의 `iteration` = N, `status` → "todo"
   - 수정: 항목 추가/제거 후 재계산
   - 거부: 변경 없음

3. `_backlog/_index.json` 갱신

### prioritize -- Priority Sorting

`/u-backlog [scope] prioritize`

대화형 우선순위 정렬 세션:

1. 현재 backlog/todo 상태 항목 표시
2. 에이전트가 MoSCoW 기반 우선순위 제안:
   - **Must:** 비즈니스 필수, 법규 요건, 핵심 UX
   - **Should:** 중요하지만 대체 가능
   - **Could:** 있으면 좋은 기능
   - **Won't:** 현 iteration에서 제외
3. 사용자가 항목별로 확인/변경
4. 최종 확정 후 `_backlog/_index.json` 갱신

### groom -- Grooming Workshop

`/u-backlog [scope] groom`

스토리 포인트 추정 워크숍:

1. `/u-discuss workshop "Backlog Grooming"` 세션 위임
2. unestimated 항목 (storyPoints = null) 목록 표시
3. 항목별 추정:
   - 에이전트가 복잡도 분석 + 유사 항목 비교
   - 피보나치 스케일 제안: 1, 2, 3, 5, 8, 13, 21
   - 사용자 확인/수정
4. 추정 완료 후 `_backlog/_index.json` 갱신

### move -- Status Change

`/u-backlog [scope] move [id] [status]`

항목 상태 변경:

```
유효 전환:
backlog → todo
todo → in-progress
in-progress → review
review → done
(any) → blocked
blocked → (previous status)
```

1. 전환 유효성 검증
2. 상태 변경 + `updated` 갱신
3. `done` 전환 시:
   - `closedIn` = 현재 iteration
   - source.ref의 원본 항목도 상태 갱신 (FT → "complete" 등)
4. `blocked` 전환 시:
   - 차단 사유 입력 필수 (`--reason "사유"`)
   - 의존 항목에 영향 경고

### burn -- Burndown Chart

`/u-backlog [scope] burn`

현재 iteration의 번다운 차트:

1. 현재 iteration에 할당된 항목 집계
2. 일별 완료/잔여 스토리 포인트 계산
3. Mermaid 차트 생성:

```markdown
## Burndown Chart - Iteration {N}

**Total SP:** {total} | **Completed:** {done} | **Remaining:** {remaining}
**Ideal Burn Rate:** {rate} SP/day

### Progress
| Day | Date | Ideal Remaining | Actual Remaining | Done Today |
|-----|------|----------------|-----------------|------------|
| 1 | 2026-03-20 | 28 | 30 | 0 |
| 2 | 2026-03-21 | 26 | 27 | 3 |
| 3 | 2026-03-22 | 24 | 22 | 5 |

### Status Breakdown
| Status | Count | SP |
|--------|-------|----|
| Done | {n} | {sp} |
| In Progress | {n} | {sp} |
| Todo | {n} | {sp} |
| Blocked | {n} | {sp} |
```

---

## Auto-Import Rules

외부 이벤트로 자동 생성되는 백로그 항목:

| Source Event | Type | Source.type | Trigger |
|-------------|------|------------|---------|
| classified requirements validated | feature | fr/us | `/u-ingest --review` 또는 `/u-assume approve` |
| Test failure → defect | bug | defect | `/u-check` Step 4 |
| `/u-discuss` /action 태그 | improvement | discuss | `/u-discuss --wrap` |
| Retrospective "Try" 항목 | improvement | retro | `/u-ship` Step 4-P |
| Guardian tech-debt detection | tech-debt | guardian | `/u-dev` Step 9 |
| Gap detector findings | improvement | gap-detector | `/u-skill-gap-detector` |

각 자동 생성 항목에는 `source.ref`로 원본 추적 가능.

---

## Backlog → Iteration Log 연동

iteration 완료 시 (`/u-ship`):
- `done` 항목 → iteration-log에 delivered 기록
- `blocked`/`in-progress` 항목 → carry-over 플래그 + 다음 iteration 이월
- velocity = 해당 iteration에서 완료된 SP 합계

---

## Safety Rules

1. BL-ID 중복 및 재사용 금지
2. 유효하지 않은 상태 전환 거부 (예: backlog → done 직행 불가)
3. `blocked` 전환 시 사유 필수
4. sprint 할당 시 의존성 순환 참조 검증
5. done 항목은 이전 상태로 되돌리기 불가 (reopen 시 새 항목 생성)
6. `_backlog/_index.json` 갱신 필수
7. storyPoints는 양의 정수만 허용 (0 불가)
8. auto-import 항목의 source 추적 필수
