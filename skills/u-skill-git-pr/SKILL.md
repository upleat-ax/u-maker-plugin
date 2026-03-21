---
name: u-skill-git-pr
description: |
  feature별로 git commit하고 PR(GitHub) 또는 MR(GitLab)을 생성한다. 변경된 파일을 feature 단위로 그룹핑하여 커밋 후 PR/MR을 남긴다.
  Git provider는 u-maker.config.json의 git.provider 설정 또는 remote URL에서 자동 감지한다.
  Args: `[feat/<feature-name>]` — feature 브랜치 이름 (생략 시 자동 분류)
  Triggers: /u-skill-git-pr, git pr, git mr, 커밋, commit and pr, pull request, merge request, PR 생성, MR 생성, create pr, create mr, 브랜치 커밋, branch commit, 깃 커밋, git commit
user-invocable: true
argument-hint: "[feat/<feature-name>]"
model: sonnet
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
  - ${PLUGIN_ROOT}/_refer/post-execution-summary.md
  - ${PLUGIN_ROOT}/_refer/json-export.md
  - ${PLUGIN_ROOT}/.u-maker/u-maker.config.json
---

# Feature Git Commit & PR/MR

> feature별로 변경사항을 git commit하고 GitHub PR 또는 GitLab MR을 생성한다.

## Step 0: Git Provider 감지

1. `u-maker.config.json`의 `git.provider` 값을 확인한다.
2. `"auto"` 또는 미설정이면 `git remote get-url origin`으로 자동 감지한다:
   - URL에 `github.com` 포함 → **github**
   - URL에 `gitlab` 포함 → **gitlab**
   - 판별 불가 시 → 사용자에게 질문
3. 감지된 provider의 CLI 존재 여부를 확인한다:
   - **github** → `which gh` 실행
   - **gitlab** → `which glab` 실행
4. CLI가 없으면 **git-only fallback 모드**로 전환한다 (Step 0-F 참조).

### Provider별 CLI 및 용어 매핑

| 항목 | GitHub | GitLab | Fallback (CLI 미설치) |
|------|--------|--------|----------------------|
| CLI | `gh` | `glab` | 순수 `git` only |
| 생성 명령 | `gh pr create` | `glab mr create` | 수동 생성 안내 |
| 용어 | Pull Request (PR) | Merge Request (MR) | PR/MR (provider에 따름) |
| 기본 브랜치 확인 | `gh repo view --json defaultBranchRef` | `glab repo view` | `git remote show origin \| grep HEAD` |

### Step 0-F: CLI 미설치 Fallback

CLI(`gh` 또는 `glab`)가 설치되어 있지 않은 경우:

1. commit + push까지는 정상 수행한다 (순수 `git` 명령만 사용).
2. PR/MR 자동 생성은 건너뛴다.
3. 사용자에게 다음을 안내한다:
   - push된 브랜치명과 remote URL
   - 웹 브라우저에서 PR/MR을 생성할 수 있는 직접 URL 구성:
     - **GitHub**: `https://github.com/<owner>/<repo>/compare/<base>...<branch>?expand=1`
     - **GitLab**: `https://<gitlab-host>/<owner>/<repo>/-/merge_requests/new?merge_request[source_branch]=<branch>`
   - CLI 설치 방법 안내:
     - **gh**: `brew install gh` 또는 https://cli.github.com
     - **glab**: `brew install glab` 또는 https://gitlab.com/gitlab-org/cli

## Flow

1. **Provider 감지** (Step 0)
2. **u-maker.config.json 보호**: `.u-maker/u-maker.config.json`이 변경 목록에 있으면 `git checkout -- .u-maker/u-maker.config.json`으로 원래 상태로 복원한다 (런타임 상태 변경은 커밋하지 않음)
3. `git status`로 변경 파일 수집
4. 변경 파일을 feature 단위로 그룹핑
5. feature별 브랜치 생성 (`feat/<feature-name>`)
6. feature별 stage + commit
7. push
7. Provider에 따라 PR 또는 MR 생성:
   - **GitHub**: `gh pr create --title "<title>" --body "<body>"`
   - **GitLab**: `glab mr create --title "<title>" --description "<body>" --source-branch "<branch>"`
   - **Fallback** (CLI 미설치): push까지만 수행, 웹 URL 안내 (Step 0-F)

## Feature Grouping Rules

| 변경 대상 | Feature Name | 기준 |
|-----------|-------------|------|
| .u-maker/docs/**/01-plan/* | docs-plan | PLAN Phase 문서 |
| .u-maker/docs/**/02-design/* | docs-design | DESIGN Phase 문서 |
| .u-maker/docs/**/03-dev/* | docs-dev | DO Phase 문서 |
| .u-maker/docs/**/04-check/* | docs-check | CHECK Phase 문서 |
| .u-maker/docs/**/05-act/* | docs-act | ACT Phase 문서 |
| apps/web/** | fe-<name> | Frontend 코드 |
| packages/** | pkg-<name> | 공유 패키지 |
| commands/*, agents/*, skills/* | plugin-<desc> | 플러그인 구성 |
| 기타 | misc-<desc> | 분류 불가 |

## Commit Convention

<type>(<scope>): <subject>
Co-Authored-By: Claude <noreply@anthropic.com>

Types: feat, fix, docs, refactor, test, chore

## PR/MR Body Format

```markdown
## Summary
- <1-3 bullet points>

## Changed Files
- <file list>

## Related Documents
- <SSoT doc references if applicable>
```

## Rules

- `.u-maker/u-maker.config.json`은 절대 커밋하지 않는다 (런타임 상태 파일)
- main 브랜치에 직접 commit 금지
- PR/MR 생성 전 git diff로 변경 확인 후 사용자에게 보여줌
- force push 금지
- 민감 파일 (.env, credentials) commit 차단
- 하나의 PR/MR에 하나의 feature만 포함
- GitLab MR 생성 시 `--remove-source-branch` 옵션 사용 권장
- Post-Execution Summary Box 출력 필수
- Summary Box에서 PR/MR URL과 provider 종류를 명시
