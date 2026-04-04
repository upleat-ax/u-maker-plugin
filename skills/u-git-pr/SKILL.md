---
name: u-git-pr
description: "This skill should be used when the user asks to 'create PR', 'make pull request', 'git PR', '/u-git-pr', or wants to auto-generate a Git pull request with structured description. Supports intelligent grouping to split changes into multiple PRs by domain/phase."
version: 5.0.0
triggers:
  - "/u-git-pr"
  - "create PR"
  - "pull request"
  - "git PR"
---

# u-git-pr — Git Pull Request Generator

`/u-git-pr [--base {branch}] [--strategy {single|group|auto}] [--dry-run]`

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
| `output/{app}/check/testcases/` | `{app}-check-tc` | {app} Check TestCases |
| `output/{app}/check/test-results.*` | `{app}-check-tr` | {app} Check TestResults |
| `output/{app}/index.html` | `{app}-nav` | {app} Navigation |
| `output/index.html` | `root-nav` | Root Navigation |

#### Rule 2: u-maker docs directory structure

For files under `.u-maker/docs/{app}/{phase}/`:

| Path Pattern | Group Key | Group Name |
|-------------|-----------|------------|
| `docs/{app}/plan/*` | `{app}-docs-plan` | {app} Plan Docs |
| `docs/{app}/design/*` | `{app}-docs-design` | {app} Design Docs |
| `docs/{app}/check/*` | `{app}-docs-check` | {app} Check Docs |
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

Display the grouping plan and ask for user confirmation:

```
u-git-pr: {N} groups detected (strategy: {auto|single|group})

  Group 1: hjw-design-erd (feat/hjw-design-erd)
    12 files — ERD index + 9 domain pages + ctr-group (new)
    PR: "feat(hjw): regenerate ERD HTML with Ctr domain (52 tables)"

  Group 2: hjw-nav (merged → Group 1)
    1 file — hjw/index.html count update

Proceed? [Y/n/edit]
```

**사용자에게 반드시 확인받을 항목:**

1. **그룹 분류가 맞는지** — "이렇게 그룹을 나눠도 괜찮을까요?"
2. **브랜치명** — 각 그룹의 `feat/hjw-design-erd` 등 브랜치명 확인
3. **PR 제목** — 각 그룹의 PR 타이틀 문구 확인
4. **base 브랜치** — PR 대상 브랜치 (기본 main) 확인
5. **실행 범위** — 전체 그룹 실행 또는 특정 그룹만 선택 가능

**응답 옵션:**

- `Y` or Enter — 전체 실행
- `n` — 중단
- `edit` — 파일을 다른 그룹으로 재배치
- `1,3` — 특정 그룹 번호만 선택 실행 (예: 1번과 3번만)
- 사용자가 브랜치명/PR 제목을 직접 수정해서 응답 가능

If `--dry-run`, display plan and stop (실행 없이 계획만 표시).

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
  feat/hjw-design-erd
  fix/hjw-nav-update
  docs/hjw-docs-plan
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
  feat(hjw/erd): add 계약(Ctr) domain ERD page with 24 tables
  fix(hjw/erd): update sidebar navigation for 9 domains
  docs(hjw): regenerate ERD HTML output
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
u-git-pr complete.
  Strategy:  group (auto-detected)
  Groups:    2
  PRs:       2

  #1 feat/hjw-design-erd → PR #42
     12 files, 1 commit
     https://github.com/org/repo/pull/42

  #2 docs/hjw-docs-design → PR #43
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
/u-git-pr

# Force single PR
/u-git-pr --strategy single

# Force grouped PRs
/u-git-pr --strategy group

# Preview without executing
/u-git-pr --dry-run

# Custom base branch
/u-git-pr --base develop
```
