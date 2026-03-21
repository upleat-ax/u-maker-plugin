---
name: u-skill-act
description: |
  ACT Phase 실행. 백로그 정리 → 회고 → 아카이브 → 다음 Iteration 전환.
  Triggers: /u-skill-act, act phase, 개선, 회고, retrospective, 백로그 정리, 아카이브, archive, iteration 전환, 다음 이터레이션, improve, reflection, backlog cleanup
model: sonnet
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - TaskCreate
  - TaskUpdate
  - TaskList
  - AskUserQuestion
imports:
  - ${PLUGIN_ROOT}/_refer/ssot-standard.md
  - ${PLUGIN_ROOT}/_refer/pdca-workflow.md
  - ${PLUGIN_ROOT}/_refer/iteration-rules.md
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
agents:
  u-agent-ra: u-maker:u-agent-ra
  u-agent-pm: u-maker:u-agent-pm
---

# ACT Phase

> 백로그 정리 → 회고 → 아카이브 → 다음 Iteration 전환.

## Execution Sequence

1. `u-agent-ra`: DEF → BL 변환 및 Iteration Log에 백로그 기록 (`common/05-act/5_IterationLog_RA.md`)
   - 모든 앱의 `4_Report_QA.md` Open DEF → BL 자동 변환 (아래 Conversion Rules 참조)
   - 기존 Open/InProgress 항목 우선순위 재평가
2. `u-agent-pm`: 회고 작성 (`common/05-act/5_Retrospective_PM.md`)
   - 잘된 점, 개선할 점, 다음 Iteration 목표
3. `u-agent-pm`: 데일리 리포트 작성 (`common/05-act/5_DailyReport_PM_yyyymmddhhmm.md`)
   - 파일명에 12자리 타임스탬프(`yyyymmddhhmm`) 포함
4. `u-agent-ra`: 아카이브 수행
   - 현재 Iteration 문서 → `.u-maker/docs/iterations/iter-N/` 복사
   - `common/05-act/5_IterationLog_RA.md` 갱신
5. 다음 Iteration 전환 (currentIteration + 1)

## Gate → PLAN (Iter N+1)

회고 + 아카이브 완료

## DEF → BL Conversion Rules

ACT Phase에서 u-agent-ra가 CHECK Phase의 결함(DEF)을 백로그 항목(BL)으로 변환할 때 적용하는 규칙.

### Conversion Mapping

| DEF Field | BL Field | Rule |
|-----------|----------|------|
| Severity | Priority | 1:1 매핑 (Critical→Critical, Major→Major, Minor→Minor, Trivial→Trivial) |
| DEF-ID | Related DEF | BL 상세에 DEF 참조 기록 |
| TC-ID → FT-ID | Related FT | 복사 |
| - | Type | 항상 `Bug` |
| - | Origin | 항상 `CHECK` |
| - | Status | 항상 `Open` |

### Conversion Flow

```
1. 수집: 4_Report_QA.md에서 Status가 Open인 DEF 목록 추출
2. 중복 제외: 기존 5_IterationLog_RA.md의 Related DEF 필드와 비교, 이미 변환된 DEF 제외
3. BL 생성: 변환 매핑 테이블에 따라 BL 항목 생성 (BL-ID 자동 채번)
4. 5_IterationLog_RA.md의 Backlog 섹션에 행 추가 + 상세 블록 추가
```

### Traceability Link (양방향)

- **BL → DEF**: BL 상세의 `Related DEF` 필드에 DEF-ID 기록
- **DEF → BL**: DEF Status를 `Transferred to BL-XXX`로 갱신 (4_Report_QA.md에서)

## Rules

- 모든 문서 생성/갱신 시 동명의 `.json` 파일을 동일 경로에 함께 생성
- Post-Execution Summary Box 출력 필수
