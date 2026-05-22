---
name: u-tools-git-pr
description: "This skill should be used when the user asks to 'create PR', 'make pull request', 'git PR', '/u-tools-git-pr', or wants to auto-generate a Git pull request with structured description. Supports intelligent grouping to split changes into multiple PRs by domain/phase."
version: 5.0.0
triggers:
  - "/u-tools-git-pr"
  - "create PR"
  - "pull request"
  - "git PR"
---

# u-tools-git-pr — Git Pull Request Generator

`/u-tools-git-pr [--base {branch}] [--strategy {single|group|auto}] [--dry-run]`

Analyze uncommitted/committed changes, intelligently decide grouping strategy, create branches per group, commit, push, and open PRs.

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
3. If on feature branch — work from **commits since divergence** from base
4. Collect all changed files:
   ```
   # Uncommitted (staged + unstaged + untracked)
   git status --porcelain
   
   # Committed on feature branch
   git diff --name-status {base}..HEAD
   ```

### Step 2: Classify Files into Groups

Classify each changed file into a **group** using these rules (evaluated in order):

#### Rule 1: u-maker output directory structure

For files under `.u-maker/output/{app}/{phase}/{doc}/`:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `output/{app}/plan/srs/` | `{app}-plan-srs` | {app} Plan SRS |
| `output/{app}/plan/ia.*` | `{app}-plan-ia` | {app} Plan IA |
| `output/{app}/design/erd/` | `{app}-design-erd` | {app} Design ERD |
| `output/{app}/design/api/` | `{app}-design-api` | {app} Design API |
| `output/{app}/design/screens/` | `{app}-design-screens` | {app} Design Screens |
| `output/{app}/design/design-system.*` | `{app}-design-ds` | {app} Design System |
| `output/{app}/gatekeeping/testcases/` | `{app}-gatekeeping-tc` | {app} Gatekeeping TestCases |
| `output/{app}/gatekeeping/test-results.*` | `{app}-gatekeeping-tr` | {app} Gatekeeping TestResults |
| `output/{app}/index.html` | `{app}-nav` | {app} Navigation |
| `output/index.html` | `root-nav` | Root Navigation |

#### Rule 2: u-maker docs directory structure

For files under `.u-maker/docs/{app}/{phase}/`:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `docs/{app}/plan/*` | `{app}-docs-plan` | {app} Plan Docs |
| `docs/{app}/design/*` | `{app}-docs-design` | {app} Design Docs |
| `docs/{app}/gatekeeping/*` | `{app}-docs-gatekeeping` | {app} Gatekeeping Docs |
| `docs/common/*` | `common-docs` | Common Docs |

#### Rule 3: Source code by directory

For application source code:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `src/app/**` or `app/**` | `app-{nearest-dir}` | App {NearestDir} |
| `src/components/**` | `components` | Components |
| `src/lib/**` or `lib/**` | `lib` | Library |
| `prisma/**` | `db-schema` | DB Schema |
| `src/api/**` or `api/**` | `api` | API |

#### Rule 4: Config and CI

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `*.config.*`, `.*rc`, `package.json` | `config` | Config |
| `.github/**`, `.gitlab-ci*` | `ci` | CI/CD |

#### Rule 5: Fallback

Files that don't match any pattern: group as `misc` (Miscellaneous).

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

**IMPORTANT: 절대 사용자 확인 없이 실행하지 않는다.** 반드시 아래 계획을 보여주고 명시적 승인을 받은 후에만 Step 5로 진행한다.

확인 프롬프트는 **반드시 multiline box + 번호 선택지** 형식으로 표시한다. 한 줄 압축 형식(`[Y/n/edit]`)은 금지.

#### 4.1 Plan 요약

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

#### 4.2 전략 선택 프롬프트 (표준 양식)

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
      - 예: "3: A,C" → A와 C만 PR 생성, 나머지는 working tree에 보존
      - 그룹 라벨 조합 자유 (A, B, C, ...)

  [4] Dry-run
      - 실제 브랜치/PR 생성 없이 계획만 확인 후 종료

  [5] Abort (아무것도 하지 않음)

  [edit] 파일을 다른 그룹으로 수동 재배치 / 브랜치명·PR 제목 수정
```

#### 4.3 수용 가능한 응답

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

#### 4.4 `--dry-run` 플래그

플래그가 켜져 있으면 4.1 요약 + 4.2 박스를 표시하되 사용자 응답을 기다리지 않고 즉시 종료 (Step 5 실행 금지).

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

### Step 6: Summary Report

After all groups are processed:

```
u-tools-git-pr complete.
  Strategy:  group (auto-detected)
  Groups:    2
  PRs:       2

  #1 feat/myapp-design-erd → PR #42
     12 files, 1 commit
     https://github.com/org/repo/pull/42

  #2 docs/myapp-docs-design → PR #43
     3 files, 1 commit
     https://github.com/org/repo/pull/43
```

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
