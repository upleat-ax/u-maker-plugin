# Post-Execution Summary Box

**u-ssot 에코시스템의 모든 skill, command, agent 실행 완료 후 반드시 아래 형식의 Summary Box를 출력한다.**

이 규칙은 다음 모든 경우에 적용된다:
- **Slash Commands**: `/u-plan`, `/u-design`, `/u-dev`, `/u-check`, `/u-act`, `/u-srs`, `/u-erd`, `/u-api`, `/u-screen`, `/u-fe`, `/u-be`, `/u-test`, `/u-bug-report`, `/u-status`, `/u-docs`, `/u-validate`, `/u-backlog`, `/u-backlog-add`, `/u-us-add`, `/u-fr-add`, `/u-init`, `/u-create-project`, `/u-loop`, `/u-loop-from`, `/u-stop`, `/u-resume`, `/u-index`, `/u-history`, `/u-archive`, `/u-storybook`, `/u-build`, `/u-summary`, `/u-gap-detector`, `/u-git-pr`, `/u-help`
- **Agent 실행**: `u-ra`, `u-sa`, `u-ux`, `u-dv-fe`, `u-dv-be`, `u-qa` 에이전트가 작업을 완료했을 때
- **Skill 호출**: u-ssot 관련 skill이 호출되어 실행 완료되었을 때
- **자연어 트리거**: 사용자의 자연어 요청이 u-ssot 에코시스템으로 라우팅되어 처리되었을 때

## Output Format

```
┌─────────────────────────────────────────────┐
│  u-ssot Summary                             │
├─────────────────────────────────────────────┤
│                                             │
│  Command : /u-{command} 또는 {trigger}      │
│  Phase   : {currentPhase}                   │
│  Iter    : {currentIteration}               │
│                                             │
│  ── Work Done ──────────────────────────    │
│  • {작업 내용 1}                             │
│  • {작업 내용 2}                             │
│  • ...                                      │
│                                             │
│  ── Used ────────────────────────────────   │
│  Skills : {사용된 skill 목록}                │
│  Agents : {사용된 agent 목록}                │
│  Docs   : {생성/수정된 문서 목록}             │
│                                             │
│  ── Next Steps ─────────────────────────    │
│  → {추천 명령어 1} : {설명}                   │
│  → {추천 명령어 2} : {설명}                   │
│                                             │
└─────────────────────────────────────────────┘
```

## Field Descriptions

| Field | Description | Example |
|-------|-------------|---------|
| **Command** | 실행된 command 또는 트리거 | `/u-plan`, `/u-srs web`, `자연어: ERD 작성 요청` |
| **Phase** | 현재 PDCA Phase | `PLAN`, `DESIGN`, `DO`, `CHECK`, `ACT` |
| **Iter** | 현재 Iteration 번호 | `1 / 10` |
| **Work Done** | 실행된 작업 내용 요약 (bullet list) | `1_SRS_RA.md 생성 (14 FRs)` |
| **Skills** | 호출된 skill 이름 목록 | `u-ssot`, `u-plan` |
| **Agents** | 호출된 agent 이름 목록 | `u-ra`, `u-sa`, `u-ux` |
| **Docs** | 생성 또는 수정된 SSoT 문서 경로 | `web/01-plan/1_SRS_RA.md` |
| **Next Steps** | 추천되는 다음 명령어와 설명 (1~3개) | `/u-design : DESIGN Phase 실행` |

## Next Steps Recommendation Rules

현재 상태에 따라 가장 적합한 다음 명령어를 1~3개 추천한다:

| 현재 상태 | 추천 Next Steps |
|-----------|----------------|
| PLAN 문서 작성 중 | → 미완성 문서 작성 명령어, → `/u-validate`, → `/u-design` (Gate 충족 시) |
| PLAN 완료 | → `/u-design` |
| DESIGN 문서 작성 중 | → 미완성 문서 작성 명령어, → `/u-validate`, → `/u-dev` (Gate 충족 시) |
| DESIGN 완료 | → `/u-dev` |
| DO Phase 중 | → `/u-fe`, `/u-be`, → `/u-build`, → `/u-check` (구현 완료 시) |
| DO 완료 | → `/u-check` |
| CHECK 완료 (Pass) | → `/u-act` (결함 있을 시), → Complete (결함 없을 시) |
| CHECK 완료 (Fail) | → `/u-act` |
| ACT 완료 | → `/u-plan` (다음 Iteration) |
| 문서 개별 작성 후 | → 다음 문서 작성, → `/u-status`, → Phase 실행 명령어 |
| 백로그/US/FR 추가 후 | → `/u-status`, → 해당 Phase 실행 명령어 |
| `/u-status` 후 | → 현재 Phase 실행 명령어, → `/u-validate` |
| `/u-validate` 후 | → 발견된 문제 수정 명령어, → Phase 실행 명령어 |
| `/u-loop` 시작 | → `/u-stop` (중단 필요 시) |
| `/u-stop` 후 | → `/u-resume` |

## Rules

- **필수 출력**: u-ssot 에코시스템의 skill, command, agent 실행 후 반드시 Summary Box를 출력해야 한다
- **마지막에 출력**: Summary Box는 실행의 가장 마지막 출력이어야 한다
- **정확한 정보**: 실제 실행된 내용만 기록한다 (추측이나 계획 X)
- **문서 경로**: 실제 생성/수정된 문서의 상대 경로를 `u-docs/` 기준으로 표시
- **Agent 미사용 시**: Agent가 호출되지 않은 단순 조회 명령은 Agents 항목을 `-`로 표시
- **Loop 실행 중**: `/u-loop` 실행 중에는 각 Phase 완료 시마다 Summary Box를 출력하고, 루프 종료 시 최종 Summary Box를 출력
- **Agent 단독 실행 시**: 에이전트가 orchestrator 없이 직접 호출된 경우에도 작업 완료 후 Summary Box를 출력한다
- **자연어 트리거 시**: Command 필드에 트리거된 자연어 요약을 표시 (예: `자연어: ERD 작성 요청`)
