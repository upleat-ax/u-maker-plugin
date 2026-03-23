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

## Step 1: 변경 파일 수집

1. `.u-maker/u-maker.config.json`이 변경 목록에 있으면 `git checkout -- .u-maker/u-maker.config.json`으로 복원한다 (런타임 상태 파일은 커밋하지 않음).
2. `git status --porcelain`으로 변경/추가/삭제된 파일 목록을 수집한다.
3. `git diff` (staged + unstaged) 내용을 확보한다.

## Step 2: Feature 그룹핑 (핵심 로직)

변경 파일을 **논리적 feature 단위**로 묶는다. 아래 우선순위를 순서대로 적용한다.

### Priority 1: 사용자 지정 (인자 제공 시)

사용자가 `feat/<name>` 인자를 제공한 경우, **모든 변경 파일을 하나의 feature 그룹**으로 묶는다. 추가 분석 불필요.

### Priority 2: FT/FR/US ID 기반 그룹핑

인자가 없으면 변경 파일의 **diff 내용**과 **파일 내용**에서 SSoT ID를 탐색한다:

1. 각 변경 파일의 diff에서 `FT-XXXX`, `FR-XXXX`, `US-XXXX` 패턴을 추출한다.
2. 동일한 FT/FR/US ID를 참조하는 파일들을 같은 feature 그룹으로 묶는다.
3. 하나의 파일이 여러 FT를 참조하면, **가장 빈번하게 등장하는 FT**에 귀속시킨다.
4. FT ID가 발견되면 브랜치명을 `feat/ft-XXXX-<간략설명>` 형태로 생성한다.

### Priority 3: 의미적 연관 분석

FT/FR/US ID가 없는 파일들은 **의미적 연관성**으로 그룹핑한다:

1. **동일 도메인/모듈**: 같은 화면, 같은 API 엔드포인트, 같은 컴포넌트에 관련된 파일
   - 예: `apps/web/app/login/page.tsx` + `apps/web/app/login/actions.ts` + `apps/web/components/LoginForm.tsx` → 하나의 feature
2. **SSoT 문서 ↔ 구현 코드 연결**: 문서와 코드가 같은 기능을 다루면 같은 그룹
   - 예: `docs/02-design/2_Screen_UX.md` (로그인 화면 섹션 변경) + `apps/web/app/login/page.tsx` → 같은 feature
3. **설정/인프라 변경**: `package.json`, `tsconfig.json`, `.eslintrc` 등 프로젝트 설정 파일은 별도 `chore/config-update` 그룹으로 분리

### Priority 4: 경로 기반 Fallback

위 방법으로도 그룹을 결정할 수 없는 파일은 경로 패턴으로 분류한다:

| 변경 대상 패턴 | Feature Name | 기준 |
|---------------|-------------|------|
| apps/{app}/** | feat/{app}-<desc> | 앱별 코드 |
| packages/{pkg}/** | feat/pkg-{pkg} | 공유 패키지 |
| .u-maker/docs/** (단독) | docs/<phase>-<desc> | SSoT 문서만 변경된 경우 |
| commands/*, agents/*, skills/* | chore/plugin-<desc> | 플러그인 구성 |
| 기타 | chore/misc-<desc> | 분류 불가 |

### 그룹핑 원칙

- **하나의 feature = 하나의 PR/MR**: 같은 기능에 속하는 코드 + 문서 + 테스트는 반드시 하나의 PR로 묶는다.
- **문서만 따로 떼지 않는다**: SSoT 문서 변경이 구현 코드 변경과 같은 기능에 속하면 함께 커밋한다.
- **변경이 적을 때는 합친다**: 전체 변경 파일이 10개 이하이고 명확한 분리 기준이 없으면 하나의 PR로 합치는 것을 우선 제안한다.
- **`<desc>`는 영문 kebab-case**로 작성한다 (예: `login-page`, `user-auth`, `erd-update`).

## Step 3: 그룹핑 확인 (필수)

실행 전에 **반드시** 사용자에게 제안된 그룹핑을 보여주고 확인을 받는다:

```
📦 PR Grouping Plan
─────────────────────────────────
 #  Branch                     Files
 1  feat/ft-0001-login-page    apps/web/app/login/page.tsx
                               apps/web/components/LoginForm.tsx
                               .u-maker/docs/web/02-design/2_Screen_UX.md
                               .u-maker/docs/web/02-design/2_Screen_UX.json

 2  chore/config-update        package.json
                               tsconfig.json
─────────────────────────────────
계속 진행할까요? (y/수정사항 입력)
```

사용자가 수정을 요청하면 그룹핑을 조정한다:
- "1번과 2번 합쳐줘" → 하나의 feature로 병합
- "LoginForm은 별도 PR로" → 파일을 다른 그룹으로 이동
- "전부 하나로" → 모든 변경을 단일 PR로 통합

## Step 4: Feature별 실행

확인된 각 feature 그룹에 대해 순서대로 실행한다:

1. **기본 브랜치에서 새 브랜치 생성**:
   ```bash
   git checkout <base-branch>
   git checkout -b <branch-name>
   ```
2. **해당 feature의 파일만 stage**:
   ```bash
   git add <file1> <file2> ...
   ```
3. **Commit** (Commit Convention 준수):
   ```bash
   git commit -m "<type>(<scope>): <subject>" -m "Co-Authored-By: Claude <noreply@anthropic.com>"
   ```
4. **Push**:
   ```bash
   git push -u origin <branch-name>
   ```
5. **PR/MR 생성** (Provider에 따라):
   - **GitHub**: `gh pr create --title "<title>" --body "<body>" --base <base-branch>`
   - **GitLab**: `glab mr create --title "<title>" --description "<body>" --source-branch "<branch>" --remove-source-branch`
   - **Fallback**: push까지만 수행, 웹 URL 안내 (Step 0-F)

6. **다음 feature 진행 전** 기본 브랜치로 복귀:
   ```bash
   git checkout <base-branch>
   ```

### 다중 Feature 실행 시 주의사항

- 각 feature 브랜치는 **기본 브랜치(main/master)에서** 분기한다 (이전 feature 브랜치에서 분기하지 않음).
- 한 feature의 push/PR 실패 시 나머지는 계속 진행하고 실패 건을 Summary에 표시한다.
- 모든 feature 완료 후 기본 브랜치로 복귀한다.

## Commit Convention

```
<type>(<scope>): <subject>

Co-Authored-By: Claude <noreply@anthropic.com>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

- `scope`는 앱명 또는 모듈명 (예: `web`, `api`, `shared`)
- 문서 + 코드 혼합 시 코드 변경에 맞는 type 사용 (예: `feat`, `fix`)
- 문서만 변경 시 `docs` type 사용

## PR/MR Body Format

```markdown
## Summary
- <1-3 bullet points describing the feature>

## Changed Files
- <file list grouped by type: code / docs / config>

## Related
- <FT-XXXX, FR-XXXX references if applicable>
- <SSoT doc references if applicable>
```

## Rules

- `.u-maker/u-maker.config.json`은 절대 커밋하지 않는다 (런타임 상태 파일)
- main/master 브랜치에 직접 commit 금지
- **Step 3 사용자 확인 없이 commit/push 절대 금지**
- force push 금지
- 민감 파일 (.env, credentials) commit 차단
- 하나의 PR/MR에 하나의 feature만 포함 (같은 기능의 코드+문서는 하나)
- GitLab MR 생성 시 `--remove-source-branch` 옵션 사용 권장
- Post-Execution Summary Box 출력 필수
- Summary Box에서 PR/MR URL과 provider 종류를 명시
