# confirmation-ux — Plan Display + Strategy Selection (Step 4)

`/u-tools-git-pr` **Step 4 (Present Plan — MANDATORY Confirmation)**의 표준 프롬프트 양식과 응답 grammar를 정의한다.

**핵심 원칙**
- 절대 사용자 확인 없이 Step 5 / 5.5로 진행하지 않는다.
- 반드시 아래 multiline 표 + 옵션 리스트 양식으로 표시 — `[Y/n/edit]` 한 줄 압축 표기 금지.
- 묵시적 진행(빈 응답 → 자동 1번) 절대 금지.

---

## 4.1 Plan 요약 (table)

자동 분류 결과를 한 화면에 보여준다. 그룹은 **알파벳 라벨(A, B, C…)** 로 식별하고, 분류 키는 `Group` 컬럼에 표기한다.

```
u-tools-git-pr  /  Step 4

  Groups detected: 2     Files: 13 (12M / 1A / 0D)
  Strategy hint:   single  (recommended)

  | Label | Group              | Files | Type | Branch                    |
  |-------|--------------------|-------|------|---------------------------|
  | A     | myapp-design-erd   |   12  | feat | feat/myapp-design-erd     |
  | B     | myapp-nav          |    1  |  →   | folded into A             |

  PR titles:
    A  feat(myapp): regenerate ERD HTML with Ctr domain (52 tables)

  >
```

| 컬럼 | 의미 |
|------|------|
| **Label** | 사용자 응답용 식별자 (`A`, `B`, `C` …). 그룹이 1개뿐이면 라벨 컬럼 생략. |
| **Group** | `classification-rules.md`의 group key. |
| **Files** | 그룹에 속한 파일 수. |
| **Type** | 자동 감지 commit type (`feat` / `fix` / `docs` / `chore` / `refactor`). Navigation 등으로 다른 그룹에 합쳐진 경우 `→`. |
| **Branch** | 생성 예정 브랜치 이름. 머지된 그룹은 `folded into {label}`. |

**Stats line 약어**: `M` = modified, `A` = added, `D` = deleted.

---

## 4.2 전략 선택 프롬프트

```
  Options:
  1) Single PR        All files → 1 PR              (recommended)
  2) Stacked PRs      A → B → … (rebase per merge)
  3) Pick groups      e.g.  3 A     or    3 A,B
  4) Dry-run          Show plan only, no commits
  5) Abort            Cancel everything
  e) Edit             Rename / regroup / retitle

  >
```

- `(recommended)` 표시는 Step 3 heuristic 결과를 기준으로 `1)` 또는 `2)` 중 한 곳에만 동적으로 부착.
- 그룹이 1개뿐이면 `2)` 와 `3)` 은 **숨기고** `1 / 4 / 5 / e` 만 노출.
- 각 옵션은 한 줄(`라벨) 제목 + 우측 설명`) — 여러 줄 설명이 필요하면 4.1 PR titles 블록처럼 별도 섹션으로 분리.

---

## 4.3 수용 가능한 응답

| 응답 | 해석 |
|------|------|
| `1` | Single PR 실행 |
| `2` | 전체 그룹 stacked PR 실행 |
| `3 A,C` / `3 A C` / `3: A,C` | 지정 그룹만 실행 (라벨 대·소문자 무시). 선택되지 않은 그룹은 **Step 5.5에서 misc 처리** (v5.1 Completeness Policy) |
| `4` | Dry-run 결과 출력 후 종료 |
| `5` 또는 `n` | 중단 |
| `e` 또는 `edit` | 파일 재배치 / 브랜치명·PR 제목 인라인 수정 세션으로 진입 |
| (공백 / Enter 단독) | **재질문**. 묵시적 진행 절대 금지 |

**Edge cases**

- `Y` / `y` 단독 응답: v5.1부터 지원 중단. → "`1` (Single PR)로 해석할까요?" 재확인 후 진행.
- 정의되지 않은 라벨 (`3 X`): 사용 가능한 라벨 목록을 보여주고 재질문.
- 라벨 컬럼이 생략된 단일 그룹 상태에서 `3 ...` 입력: "그룹이 1개뿐이라 부분 선택을 사용할 수 없습니다 — `1`로 진행할까요?" 재확인.

---

## 4.4 `--dry-run` 플래그

플래그가 켜진 경우 4.1 요약 + 4.2 옵션 + **Step 5.5 leftover 예측** 을 표시하고 사용자 응답을 **기다리지 않고 즉시 종료** 한다. Step 5 / 5.5 의 실제 commit / push 는 **일절 수행되지 않는다**.

예시 dry-run 마지막 블록:

```
  Dry-run summary:
    Step 4 plan      shown above
    Step 5 actions   would create 1 PR (Single strategy)
    Step 5.5 sweep   would leave 0 files in working tree  ✓
```

leftover가 예상되는 경우:

```
    Step 5.5 sweep   would leave 2 files → chore/misc-leftover-{ts}
```

> Step 5.5의 인터랙티브 박스도 본 문서의 4.1/4.2 표 양식을 그대로 따른다 (`SKILL.md` Step 5.5 참고).
