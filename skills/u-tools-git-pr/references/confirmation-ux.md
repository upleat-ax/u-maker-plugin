# confirmation-ux — Plan Display + Strategy Selection (Step 4)

Reference for **Step 4** (Present Plan — MANDATORY Confirmation) of `/u-tools-git-pr`. Defines the strict multiline-box prompt format and the accepted response grammar.

**핵심 원칙:** 절대 사용자 확인 없이 실행하지 않는다. 반드시 아래 계획을 보여주고 **명시적 승인**을 받은 후에만 Step 5로 진행한다. 확인 프롬프트는 **반드시 multiline box + 번호 선택지** 형식으로 표시한다. 한 줄 압축 형식(`[Y/n/edit]`)은 금지.

## 4.1 Plan 요약

먼저 감지된 그룹/변경 요약을 보여준다:

```
u-tools-git-pr: {N} groups detected (strategy: {auto|single|group})
Files: {total} ({modified} modified, {new} new, {deleted} deleted)

  Group 1: myapp-design-erd
    Branch: feat/myapp-design-erd
    12 files — ERD index + 9 domain pages + ctr-group (new)
    PR: "feat(myapp): regenerate ERD HTML with Ctr domain (52 tables)"

  Group 2: myapp-nav  (merged → Group 1)
    1 file — myapp/index.html count update
```

## 4.2 전략 선택 프롬프트 (표준 양식)

```
┌─────────────────────────────────────────────────────────────┐
│  실행 전략을 선택하세요                                     │
└─────────────────────────────────────────────────────────────┘

  [1] Single PR (권장 여부: {recommended ? "권장" : "대안"})
      - 브랜치: {single-branch-name}
      - {total}개 파일 전부 1개 PR
      - Title: {single-pr-title}

  [2] Group / {N} stacked PRs
      - {group-1-label} → {group-2-label} → ... 순서로 {N}개 PR 생성
      - 각 PR은 직전 PR merge 후에 rebase 필요
      - 브랜치 네이밍:
          A: {branch-A}
          B: {branch-B}
          ...

  [3] 부분 선택
      - 예: "3: A,C" → A와 C만 PR 생성
      - 선택되지 않은 그룹의 파일은 **Step 5.5에서 다시 확인** 후 misc 그룹으로 commit + push
        (working tree에 남기지 않는 것이 기본 정책 — v5.1 Completeness Policy)
      - 그룹 라벨 조합 자유 (A, B, C, ...)

  [4] Dry-run
      - 실제 브랜치/PR 생성 없이 계획만 확인 후 종료

  [5] Abort (아무것도 하지 않음)

  [edit] 파일을 다른 그룹으로 수동 재배치 / 브랜치명·PR 제목 수정
```

## 4.3 수용 가능한 응답

| 응답 | 해석 |
|------|------|
| `1` | Single PR 실행 |
| `2` | 전체 그룹 stacked PR 실행 |
| `3: A,C` 또는 `3 A C` | 지정 그룹만 실행 (라벨은 대·소문자 무시) |
| `4` | Dry-run 결과 출력 후 종료 |
| `5` 또는 `n` | 중단 |
| `edit` | 파일 재배치 / 브랜치명·PR 제목 인라인 수정 세션으로 진입 |
| (공백 / Enter 단독) | 재질문. 묵시적 진행 절대 금지 |

- `Y` 단독 응답은 과거 단축 표기였으나 v5.1부터 **지원 중단**. 사용자가 `Y`라고 답하면 "`1` (Single PR)로 해석할까요?" 재확인 후 진행.
- 그룹이 1개뿐이면 `[2]`와 `[3]`은 숨기고 `[1]/[4]/[5]/[edit]`만 제시.

## 4.4 `--dry-run` 플래그

플래그가 켜져 있으면 4.1 요약 + 4.2 박스 + **Step 5.5 leftover 예측**을 표시하되 사용자 응답을 기다리지 않고 즉시 종료 (Step 5 실행 금지).

예시 dry-run 출력:
```
[dry-run] 4.1 plan + 4.2 box 표시 완료
[dry-run] Step 5.5 preview:
  Working tree after planned groups: 0 files would remain  ✓
  (또는 {N} files → would route to misc group: chore/misc-leftover-{timestamp})
```

`--dry-run`은 Step 5와 Step 5.5의 실제 commit/push를 일절 수행하지 않는다.
