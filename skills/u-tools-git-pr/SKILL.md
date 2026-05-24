---
name: u-tools-git-pr
description: "This skill should be used when the user asks to '/u-tools-git-pr', 'create PR', 'pull request', 'git PR', 'u-maker PR 생성', 'u-maker 풀 리퀘스트', 'git PR 분리', or '변경사항 PR로'. Auto-generates a Git pull request with structured description. Supports intelligent grouping to split changes into multiple PRs by domain/phase."
version: 5.0.0
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
