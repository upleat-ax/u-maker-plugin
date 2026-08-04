---
name: u-tools-git-pr
description: "This skill should be used when the user asks to '/u-tools-git-pr', 'create PR', 'pull request', 'git PR', 'u-maker PR 생성', 'u-maker 풀 리퀘스트', 'git PR 분리', or '변경사항 PR로'. Auto-generates a Git pull request with structured description. Supports intelligent grouping to split changes into multiple PRs by domain/phase."
version: 5.1.0
---

# u-tools-git-pr — Git Pull Request Generator

`/u-tools-git-pr [--base {branch}] [--strategy {single|group|auto}] [--dry-run]`

Analyze uncommitted/committed changes, intelligently decide grouping strategy, create branches per group, commit, push, and open PRs.

## Completeness Policy (v5.1)

**스킬 종료 시 `git status --porcelain` 결과는 반드시 비어 있어야 한다.** 즉, `.gitignore`에 의해 무시되지 않는 모든 변경 파일은 commit + push까지 완료되어야 한다.

- `.gitignore`에 등록된 파일은 자동으로 제외된다 (`git status --porcelain` 기본 동작 — `--ignored` 플래그 절대 사용 금지).
- `git add -A` / `git add .` 절대 사용 금지 — 분류된 그룹별 명시적 파일 목록으로만 stage.
- Step 5.5 verification이 working tree가 비어있을 때까지 책임진다 (Step 5의 그룹 루프가 아닌 별도 안전망).

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--base {branch}` | `main` | Base branch for PRs |
| `--strategy {mode}` | `auto` | Grouping strategy: `single` (1 PR), `group` (domain/phase split), `auto` (decide based on analysis) |
| `--dry-run` | OFF | Show planned groups and PR titles without executing |

## Execution Flow

### Step 1: Analyze Changes

1. Detect repository root and current branch
2. If on `main`/`master` — work from **uncommitted changes** (will create feature branches)
3. If on feature branch — work from **commits since divergence** from base **+ any uncommitted local changes** (Step 5.5 sweeps uncommitted on feature branches too)
4. Collect all changed files:
   ```bash
   # Uncommitted (staged + unstaged + untracked) — .gitignore'd 파일은 자동 제외됨
   git status --porcelain

   # Committed on feature branch
   git diff --name-status {base}..HEAD
   ```
   - **금지:** `git status --porcelain --ignored` (gitignore 파일까지 끌고 옴), `git add -A`, `git add .`
   - **원칙:** 분류기가 인식한 파일 + 분류되지 않은 파일 모두 misc 폴백으로 흡수되어 결국 commit + push 됨. working tree에 남는 파일은 0개.

### Step 2: Classify Files into Groups

Classify each changed file into a **group** using 5 ordered rules (first match wins):
1. **u-maker output structure** (`output/{app}/{phase}/{doc}/`) — 10 patterns covering plan/design/gatekeeping splits + navigation
2. **u-maker docs structure** (`docs/{app}/{phase}/`) — 4 patterns
3. **Source code by directory** (`src/app`, `components`, `lib`, `prisma`, `api`)
4. **Config and CI** (config files, `.github/`, `.gitlab-ci*`)
5. **Fallback** → `misc`

Full pattern → group-key tables → **see `references/classification-rules.md`**.

### Step 3: Decide Strategy

#### `--strategy auto` (default)

Apply these heuristics to decide `single` vs `group`:

```
IF total changed files <= 5
  → single (too few files to split)

IF all files belong to 1 group
  → single (naturally cohesive)

IF groups.count >= 2 AND largest_group.files >= 3
  → group (meaningful split)

IF groups.count >= 2 AND all groups have <= 2 files
  → single (splitting would be noise)
```

**Navigation files** (`{app}-nav`, `root-nav`) are always **merged into the largest co-located group** instead of becoming a standalone PR.

#### `--strategy single`

Force all changes into 1 PR.

#### `--strategy group`

Force grouping even for small changesets.

### Step 4: Present Plan (MANDATORY Confirmation)

**절대 사용자 확인 없이 실행하지 않는다.** 4.1 Plan 요약(그룹/파일/PR 제목) → 4.2 표준 multiline box (5개 번호 선택지: `[1] Single` `[2] Group/Stacked` `[3] 부분 선택` `[4] Dry-run` `[5] Abort` + `[edit]`) → 4.3 응답 grammar 매칭. 한 줄 압축 형식 `[Y/n]` 금지.

전체 박스 양식 + 응답 표 + `--dry-run` 플래그 동작 → **see `references/confirmation-ux.md`**.

### Step 5: Execute Per Group

For each group, execute sequentially:

```
for group in groups:
    1. Create branch:  git checkout -b {branch-name} {base}
    2. Stage files:    git add {group.files}
    3. Commit:         git commit -m "{commit-message}"
    4. Push:           git push -u origin {branch-name}
    5. Create PR:      gh pr create --base {base} --title "{title}" --body "{body}"
    6. Return to base: git checkout {base}
    7. Print PR URL
```

#### Branch Naming

```
{type}/{group-key}

Examples:
  feat/myapp-design-erd
  fix/myapp-nav-update
  docs/myapp-docs-plan
  chore/config-update
```

**Type detection:**
- New files dominant → `feat`
- Modified files only → `fix` or `refactor` (based on commit message keywords)
- Docs/output only → `docs`
- Config only → `chore`

#### Commit Message

```
{type}({scope}): {summary}

Examples:
  feat(myapp/erd): add 계약(Ctr) domain ERD page with 24 tables
  fix(myapp/erd): update sidebar navigation for 9 domains
  docs(myapp): regenerate ERD HTML output
```

If a group has mixed new + modified files, combine into a single descriptive commit.

#### PR Body

Fill using `_meta/templates/pr.template.md`:
- **prTitle**: `{type}({scope}): {summary}`
- **commits**: table of commits in this group
- **files**: list with descriptions
- **implementationDetails**: auto-generated from file analysis

### Step 5.5: Verify Working Tree (안전망 — 항상 실행)

Step 5 그룹 루프가 끝나면 **현재 브랜치 상태와 관계없이** working tree가 비어있는지 검증한다.

```bash
git status --porcelain
```

- **결과가 비어있음** → "Working tree clean ✓" 출력 후 Step 6으로 진행.
- **남은 파일 존재** → Step 4.2 형식과 동일한 multiline box로 사용자에게 선택지 제시:

```
┌─────────────────────────────────────────────────────────────┐
│  Step 5.5: 남은 변경 파일 {N}개 감지                        │
│  (Step 5의 그룹에 포함되지 않은 파일들)                     │
└─────────────────────────────────────────────────────────────┘

  남은 파일:
    M  path/to/file-1.ts
    A  path/to/new-file-2.md
    ...

  [1] misc 그룹으로 commit + push (권장)
      - 브랜치: chore/misc-leftover-{timestamp}
      - {N}개 파일 전부 1개 PR로 처리
      - Title: chore(misc): commit leftover files from u-tools-git-pr

  [2] 그대로 두고 종료 (working tree에 남김)
      - 정책 위반: 사용자가 명시적으로 선택한 경우에만 허용
```

**응답 grammar:**
| 응답 | 해석 |
|------|------|
| `1` (default) | misc 그룹 생성 → commit + push + PR 후 다시 5.5 재실행하여 clean 확인 |
| `2` | 종료 (Step 6 summary는 "Working tree has {N} uncommitted files (user-skipped)" 출력) |
| (공백 / Enter) | 재질문 |

#### misc 그룹 처리 규칙

- 모든 남은 파일을 **명시적 파일 목록**으로 stage (절대 `git add -A` 사용 금지)
- 분류 그룹 위반시 commit 메시지에 `chore(misc):` prefix 강제
- 5.5 미만에서 다시 검증 — 그래도 남으면 사용자에게 에러 보고 (예: 권한 거부, conflict 등)

#### `--dry-run` 모드

`--dry-run` 플래그가 켜진 경우, Step 5.5는 실제 commit 없이 다음만 출력:
```
[dry-run] Step 5.5 preview:
  Working tree after planned groups: {N} files would remain
  → would route to misc group: chore/misc-leftover-{timestamp}
```
Step 4.4의 "즉시 종료" 원칙은 유지하되, leftover 예측은 표시한다.

### Step 6: Summary Report

After all groups + Step 5.5 are processed:

```
u-tools-git-pr complete.
  Strategy:  group (auto-detected)
  Groups:    2 (+ 1 misc leftover)
  PRs:       3

  #1 feat/myapp-design-erd → PR #42
     12 files, 1 commit
     https://github.com/org/repo/pull/42

  #2 docs/myapp-docs-design → PR #43
     3 files, 1 commit
     https://github.com/org/repo/pull/43

  #3 chore/misc-leftover-20260524 → PR #44 (Step 5.5)
     2 files, 1 commit
     https://github.com/org/repo/pull/44

  Working tree clean ✓
```

- Step 5.5가 misc PR을 만들었으면 `(+ 1 misc leftover)` 표시 + 별도 PR 항목 추가.
- `git status --porcelain`이 비어있으면 마지막 줄에 `Working tree clean ✓`.
- 사용자가 [2] 종료를 선택한 경우 `Working tree has {N} uncommitted files (user-skipped)` 출력.

## Error Handling

| Error | Action |
|-------|--------|
| Dirty working tree with conflicts | Abort with message |
| `gh` CLI not authenticated | Prompt `gh auth login` |
| Branch already exists | Append `-v2`, `-v3` suffix |
| Push rejected | Show error, skip group, continue others |
| PR creation fails | Show error, keep branch for manual retry |

## Examples

```bash
# Auto-detect grouping strategy
/u-tools-git-pr

# Force single PR
/u-tools-git-pr --strategy single

# Force grouped PRs
/u-tools-git-pr --strategy group

# Preview without executing
/u-tools-git-pr --dry-run

# Custom base branch
/u-tools-git-pr --base develop
```
