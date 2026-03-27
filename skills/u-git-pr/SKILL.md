---
name: u-git-pr
description: "Git PR/MR 생성. 현재 브랜치의 변경사항을 분석하여 구조화된 PR(GitHub) 또는 MR(GitLab)을 자동 생성한다. 커밋 그루핑 분석, 분할/통합 PR 선택, 리뷰 가이드, 체크리스트를 포함한 팀 친화적 PR/MR을 만든다."
triggers:
  - "/u-git-pr"
  - "PR 생성"
  - "PR 만들어"
  - "MR 생성"
  - "MR 만들어"
  - "풀리퀘스트"
  - "머지리퀘스트"
  - "pull request"
  - "merge request"
  - "create pr"
  - "create mr"
---

# u-git-pr -- Create Pull Request / Merge Request

`/u-git-pr [base] [flags]` 명령으로 현재 브랜치의 변경사항을 분석하고, 구조화된 PR(GitHub) 또는 MR(GitLab)을 생성한다.

> **용어:** Git 호스팅 플랫폼에 따라 PR(Pull Request) 또는 MR(Merge Request)로 자동 전환된다. 이 문서에서는 편의상 "PR/MR"로 표기한다.

---

## Platform Detection

리모트 URL을 기반으로 플랫폼을 자동 감지한다:

```bash
git remote get-url origin
```

| Remote URL pattern | Platform | 용어 | CLI |
|--------------------|----------|------|-----|
| `github.com` | GitHub | Pull Request (PR) | `gh` |
| `gitlab.com` 또는 self-hosted GitLab | GitLab | Merge Request (MR) | `glab` |

- **GitHub:** `gh pr create` 사용
- **GitLab:** `glab mr create` 사용
- 감지 실패 시 사용자에게 플랫폼을 질문한다

---

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `base` | Optional | PR/MR의 base(target) branch. 생략 시 `main` 또는 repo 기본 브랜치 사용 |

## Flags

| Flag | Description |
|------|-------------|
| `--draft` | Draft PR/MR로 생성 |
| `--jira <URL>` | Jira 티켓 URL 첨부 |
| `--reviewer <user>` | 리뷰어 지정 (복수: 쉼표 구분) |
| `--label <name>` | 라벨 지정 (복수: 쉼표 구분) |
| `--no-push` | PR/MR 생성만 하고 push는 하지 않음 (이미 push된 상태일 때) |
| `--split` | 커밋 그루핑 분석 후 분할 PR/MR 생성 모드 강제 진입 |
| `-i` | 각 섹션 작성 시 사용자 확인 |

---

## Execution Flow

### Step 1: Detect Platform & Gather Branch Context

1. **Platform 감지:**
   ```bash
   git remote get-url origin              # GitHub vs GitLab 판별
   ```

2. **Branch info:**
   ```bash
   git branch --show-current              # 현재 브랜치명
   git rev-parse --abbrev-ref HEAD        # HEAD 확인
   ```

3. **Base branch 대비 변경사항:**
   ```bash
   git log {base}..HEAD --oneline         # 커밋 목록
   git log {base}..HEAD --format="%H %s"  # 전체 해시 + 메시지
   git diff {base}...HEAD --stat          # 변경 파일 통계
   git diff {base}...HEAD                 # 전체 diff
   ```

4. **Working tree 상태:**
   ```bash
   git status                             # uncommitted changes 확인
   git stash list                         # stash 확인
   ```

5. **Remote 동기화 확인:**
   - 현재 브랜치가 remote를 추적하는지 확인
   - push가 필요한지 판단

> **주의:** uncommitted changes가 있으면 사용자에게 경고하고, 커밋 또는 stash를 권유한다.

### Step 2: Commit Grouping Analysis

커밋이 2개 이상일 때 그루핑 분석을 수행하고, 사용자에게 분할/통합 선택지를 제공한다.

#### 2-1. 커밋 분류

각 커밋을 conventional commit prefix 기반으로 분류한다:

| Prefix | 분류 |
|--------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `refactor` | 리팩토링 |
| `docs` | 문서 |
| `test` | 테스트 |
| `chore` | 기타 유지보수 |
| `style` | 스타일/포맷 |
| `perf` | 성능 개선 |
| `ci` | CI/CD |

prefix가 없으면 diff 내용 기반으로 변경 성격을 추론한다.

#### 2-2. 그룹 도출

아래 기준으로 커밋을 논리적 그룹으로 묶는다:

1. **같은 prefix** (feat끼리, fix끼리)
2. **같은 변경 영역** (같은 디렉토리/모듈을 수정한 커밋)
3. **같은 기능/이슈** (커밋 메시지에서 공통 키워드나 이슈 번호)

#### 2-3. 그루핑 결과 표시

분석 결과를 사용자에게 보여준다:

```
## Commit Grouping Analysis

총 {n}개 커밋 → {m}개 그룹으로 분류

### Group 1: {그룹 제목} ({type})
| # | Commit | Message | Files |
|---|--------|---------|-------|
| 1 | `abc1234` | feat: add user profile page | 4 files |
| 2 | `def5678` | feat: add profile avatar upload | 2 files |

### Group 2: {그룹 제목} ({type})
| # | Commit | Message | Files |
|---|--------|---------|-------|
| 3 | `ghi9012` | fix: resolve login session timeout | 1 file |

### Group 3: {그룹 제목} ({type})
| # | Commit | Message | Files |
|---|--------|---------|-------|
| 4 | `jkl3456` | chore: update dependencies | 3 files |
| 5 | `mno7890` | chore: fix lint warnings | 2 files |

---

어떻게 PR/MR을 생성할까요?

1. **통합** — 전체를 하나의 PR/MR로 생성
2. **분할** — 그룹별로 {m}개의 PR/MR을 각각 생성
3. **커스텀** — 그룹을 직접 조합 (예: "1+2 / 3")
```

#### 2-4. 사용자 선택 처리

| 선택 | 동작 |
|------|------|
| **통합** | 모든 커밋을 하나의 PR/MR로 생성. Step 3으로 진행 |
| **분할** | 그룹별 브랜치 분리 후 각각 PR/MR 생성. Step 3을 그룹 수만큼 반복 |
| **커스텀** | 사용자가 지정한 조합대로 그룹을 재배치 후 PR/MR 생성 |

> **단일 커밋 또는 단일 그룹:** 그루핑 분석을 건너뛰고 바로 Step 3으로 진행한다.

#### 분할 PR/MR 브랜치 전략

분할 시 cherry-pick 기반으로 그룹별 브랜치를 생성한다:

```bash
# 그룹별 브랜치 생성
git checkout -b {original-branch}/group-{n} {base}
git cherry-pick {commit-hash-1} {commit-hash-2} ...
git push -u origin {original-branch}/group-{n}
```

브랜치 명명: `{원본-브랜치}/group-{n}-{short-description}`

### Step 3: Compose PR/MR Body

아래 템플릿에 분석 결과를 채워 PR/MR body를 생성한다:

```markdown
## {작업 주제}

{브랜치명과 커밋 내용을 기반으로 작업의 핵심 목적을 1-2문장으로 요약}

## 작업 내용

{커밋 단위로 어떤 작업을 수행했는지 설명. 리뷰어가 "왜 이 작업이 필요했는지"를 이해할 수 있도록 작성}

| Commit | Description |
|--------|-------------|
| `{hash}` | {commit message} |
| `{hash}` | {commit message} |

### 주요 변경 파일

{변경 규모가 큰 파일 위주로 나열하고, 각 파일에서 무엇이 바뀌었는지 한 줄 설명}

- `path/to/file.ts` — {변경 요약}
- `path/to/file.ts` — {변경 요약}

## Jira

{--jira 플래그가 있으면 링크 표시, 없으면 섹션 생략}

- [{TICKET-ID}]({URL})

## 스크린샷

{UI 변경이 감지되면 섹션 포함, 아니면 생략}

> UI 변경이 포함된 PR/MR입니다. 스크린샷을 첨부해주세요.

## 관련 문서

{변경과 관련된 문서가 있으면 링크, 없으면 섹션 생략}

- [문서명](URL) — 참고 사유

## 추가 코멘트

{특별히 전달할 내용이 있으면 기재, 없으면 섹션 생략}

---

## 체크리스트

- [ ] base(`{base}`) ← compare(`{current}`) 브랜치가 올바른가요?
- [ ] 로컬에서 빌드/테스트를 통과했나요?
- [ ] 불필요한 console.log / debugger가 제거되었나요?
- [ ] 새로운 환경변수가 필요한 경우 .env.example에 반영했나요?

## 리뷰 가이드

| Priority | 의미 | Action |
|----------|------|--------|
| **P1** | 꼭 반영해주세요 | Request Changes |
| **P2** | 웬만하면 반영해주세요 | Comment |
| **P3** | 참고만 해주세요 | Approve |
```

### Step 4: Create PR/MR

1. **Push (필요한 경우):**
   ```bash
   git push -u origin {branch}
   ```

2. **PR/MR 생성 (플랫폼별):**

   **GitHub:**
   ```bash
   gh pr create --title "{title}" --base {base} --body "{body}" [--draft] [--reviewer {users}] [--label {labels}]
   ```

   **GitLab:**
   ```bash
   glab mr create --title "{title}" --target-branch {base} --description "{body}" [--draft] [--reviewer {users}] [--label {labels}]
   ```

3. **결과 보고:**
   - PR/MR URL 표시
   - 변경 통계 요약 (파일 수, 추가/삭제 라인)
   - 분할 생성 시: 각 PR/MR의 URL 목록과 그룹 요약

---

## Template Rules

### 섹션 표시 규칙

| Section | 조건 |
|---------|------|
| 작업 주제 | 항상 표시 |
| 작업 내용 | 항상 표시 (커밋 기반 자동 생성) |
| Jira | `--jira` 플래그가 있을 때만 표시 |
| 스크린샷 | UI 관련 파일 변경 감지 시 표시 (.tsx, .css, .scss, .vue, .svelte 등) |
| 관련 문서 | `.u-maker/docs/` 변경이 포함되거나 사용자가 명시한 경우 |
| 추가 코멘트 | `-i` 모드에서 사용자가 입력한 경우 |
| 체크리스트 | 항상 표시 |
| 리뷰 가이드 | 항상 표시 |

### UI 변경 감지 패턴

아래 확장자/경로의 변경이 있으면 스크린샷 섹션을 포함한다:

```
**/*.tsx, **/*.jsx, **/*.vue, **/*.svelte
**/*.css, **/*.scss, **/*.less
**/components/**, **/pages/**, **/views/**, **/screens/**
**/public/images/**, **/assets/**
```

---

## Safety Rules

1. **uncommitted changes 경고:** PR/MR 생성 전 uncommitted changes가 있으면 반드시 경고
2. **base branch 확인:** base가 main/master가 아닌 경우 사용자에게 확인
3. **force push 금지:** PR/MR 생성 과정에서 force push 절대 사용하지 않음
4. **빈 PR/MR 방지:** base 대비 변경사항이 없으면 PR/MR 생성하지 않음
5. **민감 파일 경고:** `.env`, `credentials`, `secret` 등이 diff에 포함되면 경고
6. **body HEREDOC:** body는 반드시 HEREDOC으로 전달하여 포맷 보존
7. **push 전 확인:** remote push는 사용자 확인 후 수행 (이미 push된 경우 제외)
8. **분할 시 원본 브랜치 보존:** cherry-pick 기반 분할은 원본 브랜치를 변경하지 않음
9. **CLI 존재 확인:** `gh`(GitHub) 또는 `glab`(GitLab) CLI가 설치되어 있는지 확인. 미설치 시 안내
