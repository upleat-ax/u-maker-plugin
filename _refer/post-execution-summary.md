# Post-Execution Summary Box

**u-maker 에코시스템의 모든 skill, command, agent 실행 완료 후 반드시 아래 형식의 Summary Box를 출력한다.**

이 규칙은 다음 모든 경우에 적용된다:
- **Slash Commands**: `/u-skill-plan`, `/u-skill-design`, `/u-skill-dev`, `/u-skill-check`, `/u-skill-act`, `/u-skill-srs`, `/u-skill-erd`, `/u-skill-api`, `/u-skill-screen`, `/u-agent-dv-fe`, `/u-agent-dv-be`, `/u-skill-test`, `/u-skill-report`, `/u-agent-status`, `/u-agent-docs`, `/u-agent-validate`, `/u-agent-backlog`, `/u-agent-backlog-add`, `/u-skill-u-skill-add`, `/u-skill-fr-add`, `/u-skill-init`, `/u-skill-create-project`, `/u-skill-loop`, `/u-skill-loop-from`, `/u-skill-stop`, `/u-skill-resume`, `/u-skill-index`, `/u-skill-history`, `/u-skill-archive`, `/u-skill-storybook`, `/u-skill-build`, `/u-skill-summary`, `/u-skill-gap-detector`, `/u-skill-git-pr`, `/u-skill-help`, `/u-skill-fix`, `/u-skill-glossary`, `/u-skill-workflow`, `/u-skill-html-doc`
- **Agent 실행**: `u-agent-pm`, `u-agent-ra`, `u-agent-sa`, `u-agent-ux`, `u-agent-dv-fe`, `u-agent-dv-be`, `u-agent-qa` 에이전트가 작업을 완료했을 때
- **Skill 호출**: u-maker 관련 skill이 호출되어 실행 완료되었을 때
- **자연어 트리거**: 사용자의 자연어 요청이 u-maker 에코시스템으로 라우팅되어 처리되었을 때

## Output Format

**세로선 없는 ASCII 스타일**로 터미널에서 깔끔하게 표시한다. Markdown 테이블(`| ... |`)과 세로 박스 문자(`║ │`)는 사용하지 않는다. 수평선(`═ ─`)과 들여쓰기만으로 구조를 표현한다.

### 문자 세트

```
상단/하단:  ═
섹션 구분:  ─
들여쓰기:   2칸 스페이스
```

### Header + Context Bar

```
══════════════════════════════════════════════════
  ⚡ U-MAKER SUMMARY
══════════════════════════════════════════════════
  Skill     /u-skill-{command}
  Phase     {PHASE}
  Iter      {N} / {max}
  Result    ✅ Success
──────────────────────────────────────────────────
```

### Work Done

작업 내용이 **2개 이하**일 때는 bullet, **3개 이상**일 때는 넘버링.

#### 2개 이하 — Bullet

```
  📋 Work Done
  • Added Tabler-based repo status badges
  • Reused repo polling via shared workspace hook
──────────────────────────────────────────────────
```

#### 3개 이상 — Numbered

```
  📋 Work Done
   #  Action       Target
   1  Created      1_SRS_RA.md — 14 FRs, 8 USs
   2  Created      1_SRS_RA.json
   3  Updated      1_Index_PM.md — added SRS entry
──────────────────────────────────────────────────
```

### Resources Used

```
  🔧 Resources
  Skills    u-skill-srs
  Agents    u-agent-sa
  Docs      web/01-plan/1_SRS_RA.md .json
──────────────────────────────────────────────────
```

Agent가 호출되지 않은 단순 조회 명령은 Agents 칸을 `—`로 표시한다.

### Verification (선택적 — 검증 실행 시에만 표시)

빌드, 타입체크, 테스트 등 검증 작업이 포함된 경우에만 표시한다.

```
  🔍 Verification
  Type Check   bun run tsc      ⚠️ TS6133 Sidebar:52
  Build        bun run build    ✅ Pass
──────────────────────────────────────────────────
```

### Next Steps

```
  👉 Next
   1  /u-skill-design web    DESIGN Phase 실행
   2  /u-skill-validate      문서 무결성 검증
══════════════════════════════════════════════════
```

---

## Complete Example — Agent Direct 실행 후

```
══════════════════════════════════════════════════
  ⚡ U-MAKER SUMMARY
══════════════════════════════════════════════════
  Skill     /u-agent-dv-fe
  Phase     DO
  Iter      1 / 10
  Result    ⚠️ Partial
──────────────────────────────────────────────────
  📋 Work Done
   #  Action     Target
   1  Added      Tabler-based repo status badges
   2  Reused     Repo polling via shared hook
   3  Updated    StatusBar to use same hook
──────────────────────────────────────────────────
  🔧 Resources
  Skills    u-agent-dv-fe
  Agents    u-agent-dv-fe
  Docs      web/03-dev/3_Code_DV.md
──────────────────────────────────────────────────
  🔍 Verification
  Type Check   bun run tsc      ⚠️ TS6133 Sidebar:52
──────────────────────────────────────────────────
  👉 Next
   1  /u-skill-fix web       Sidebar.tsx TS6133 수정
   2  /u-skill-build         빌드 재실행
══════════════════════════════════════════════════
```

---

## Complete Example — Phase 실행 후

```
══════════════════════════════════════════════════
  ⚡ U-MAKER SUMMARY
══════════════════════════════════════════════════
  Skill     /u-skill-plan web
  Phase     PLAN
  Iter      1 / 10
  Result    ✅ Success
──────────────────────────────────────────────────
  📋 Work Done
   #  Action     Target
   1  Created    1_Roadmap_PM.md — 5 milestones
   2  Created    1_SRS_RA.md — 8 FRs, 5 USs, 8 FTs
   3  Created    1_IA_RA.md — 7 domains, 8 menus
   4  Updated    1_Index_PM.md — 3 new entries
   5  Created    .json files for all above
──────────────────────────────────────────────────
  🔧 Resources
  Skills    u-skill-plan, u-skill-srs, u-skill-index
  Agents    u-agent-pm, u-agent-sa, u-agent-ux
  Docs      1_Roadmap_PM.md, 1_SRS_RA.md,
            1_IA_RA.md, 1_Index_PM.md
──────────────────────────────────────────────────
  👉 Next
   1  /u-skill-design web    DESIGN Phase 실행
   2  /u-skill-validate      문서 무결성 검증
══════════════════════════════════════════════════
```

---

## Complete Example — 단순 조회 명령

```
══════════════════════════════════════════════════
  ⚡ U-MAKER SUMMARY
══════════════════════════════════════════════════
  Skill     /u-skill-status
  Phase     DO
  Iter      2 / 10
  Result    ✅ Success
──────────────────────────────────────────────────
  📋 Work Done
  • Displayed project status (Phase: DO, 12/18 FTs)
──────────────────────────────────────────────────
  🔧 Resources
  Skills    u-skill-status
  Agents    —
  Docs      —
──────────────────────────────────────────────────
  👉 Next
   1  /u-skill-dev web       미구현 FT 개발 계속
   2  /u-skill-gap-detector  설계-구현 Gap 분석
══════════════════════════════════════════════════
```

---

## Complete Example — git-pr 실행 후

```
══════════════════════════════════════════════════
  ⚡ U-MAKER SUMMARY
══════════════════════════════════════════════════
  Skill     /u-skill-git-pr
  Phase     DO
  Iter      1 / 10
  Result    ✅ Success
──────────────────────────────────────────────────
  📋 Work Done
   #  Action                Target
   1  branch, commit, push  feat/docs-plan → PR #16
   2  branch, commit, push  feat/docs-design → PR #17
   3  branch, commit, push  feat/misc-bootstrap → #18
──────────────────────────────────────────────────
  🔧 Resources
  Skills    u-skill-git-pr
  Agents    —
  Docs      PLAN docs, DESIGN docs, u-maker metadata
──────────────────────────────────────────────────
  👉 Next
   1  /u-skill-validate     SSoT 문서 무결성 검증
   2  /u-skill-qa kiosk     테스트 케이스/실행 정리
══════════════════════════════════════════════════
```

---

## Result Badge Rules

실행 결과에 따라 아래 뱃지를 사용한다:

| Result | Badge | Condition |
|--------|-------|-----------|
| Success | `✅ Success` | 모든 작업 정상 완료 |
| Partial | `⚠️ Partial` | 작업은 완료했으나 검증에서 기존 이슈 발견 또는 일부 미완료 |
| Failed | `❌ Failed` | 핵심 작업 실패 (파일 미생성, 빌드 에러 등) |

## Phase Badge Format

Phase 이름은 그대로 표시한다:

| Phase | Badge |
|-------|-------|
| PLAN | `PLAN` |
| DESIGN | `DESIGN` |
| DO | `DO` |
| CHECK | `CHECK` |
| ACT | `ACT` |

## Next Steps Recommendation Rules

현재 상태에 따라 가장 적합한 다음 명령어를 1~3개 추천한다:

| 현재 상태 | 추천 Next Steps |
|-----------|----------------|
| PLAN 문서 작성 중 | 미완성 문서 작성 명령어, `/u-skill-validate`, `/u-skill-design` (Gate 충족 시) |
| PLAN 완료 | `/u-skill-design` |
| DESIGN 문서 작성 중 | 미완성 문서 작성 명령어, `/u-skill-validate`, `/u-skill-dev` (Gate 충족 시) |
| DESIGN 완료 | `/u-skill-dev` |
| DO Phase 중 | `/u-agent-dv-fe`, `/u-agent-dv-be`, `/u-skill-build`, `/u-skill-check` (구현 완료 시) |
| DO 완료 | `/u-skill-check` |
| CHECK 완료 (Pass) | `/u-skill-act` (결함 있을 시), Complete (결함 없을 시) |
| CHECK 완료 (Fail) | `/u-skill-act` |
| ACT 완료 | `/u-skill-plan` (다음 Iteration) |
| 문서 개별 작성 후 | 다음 문서 작성, `/u-skill-status`, Phase 실행 명령어 |
| 백로그/US/FR 추가 후 | `/u-skill-status`, 해당 Phase 실행 명령어 |
| `/u-skill-status` 후 | 현재 Phase 실행 명령어, `/u-skill-validate` |
| `/u-skill-validate` 후 | 발견된 문제 수정 명령어, Phase 실행 명령어 |
| `/u-skill-loop` 시작 | `/u-skill-stop` (중단 필요 시) |
| `/u-skill-stop` 후 | `/u-skill-resume` |
| Verification 실패 시 | `/u-skill-fix` (에러 수정), 관련 에이전트 호출 |

## Rendering Rules

- **세로선 금지**: `║ │ ╟ ╢ ╤ ╧ ┼ ├ ┤ ┬ ┴` 등 세로 박스 문자 사용 금지. Markdown 테이블(`| ... |`)도 금지
- **수평선만 사용**: 상단/하단은 `═`, 섹션 구분은 `─`. 폭은 50자 고정
- **들여쓰기로 구조 표현**: 2칸 스페이스 들여쓰기로 라벨과 값을 정렬
- **라벨-값 간격**: 라벨은 10자 폭 고정 후 값 표시 (예: `  Skill     /u-skill-plan`)
- **넘버링**: Work Done, Next 항목은 `   #  Action  Target` 형태로 스페이스 정렬
- **Resources**: `Skills`, `Agents`, `Docs` 각각 별도 행에 라벨-값 형태로 표시
- **필수 출력**: u-maker 에코시스템의 skill, command, agent 실행 후 반드시 Summary Box를 출력해야 한다
- **마지막에 출력**: Summary Box는 실행의 가장 마지막 출력이어야 한다
- **정확한 정보**: 실제 실행된 내용만 기록한다 (추측이나 계획 X)
- **문서 경로**: 실제 생성/수정된 문서의 상대 경로를 `.u-maker/docs/` 기준으로 표시
- **Agent 미사용 시**: Agent가 호출되지 않은 단순 조회 명령은 Agents 칸을 `—`로 표시
- **Loop 실행 중**: `/u-skill-loop` 실행 중에는 각 Phase 완료 시마다 Summary Box를 출력하고, 루프 종료 시 최종 Summary Box를 출력
- **Agent 단독 실행 시**: 에이전트가 orchestrator 없이 직접 호출된 경우에도 작업 완료 후 Summary Box를 출력한다
- **자연어 트리거 시**: Skill 필드에 트리거된 자연어 요약을 표시 (예: `자연어: ERD 작성 요청`)
- **Verification 섹션**: 검증 작업(빌드, 타입체크, 테스트 등)이 포함된 경우에만 표시한다. 단순 문서 생성/조회에는 생략한다.
- **Work Done 간결성**: 동일 패턴의 작업은 그룹화한다. 예: `.md`와 `.json` 동시 생성 시 한 행에 합친다.
