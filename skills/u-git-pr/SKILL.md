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

`/u-git-pr [base] [flags]` 명령으로 현재 브랜치 변경사항을 분석하고, 구조화된 PR(GitHub) 또는 MR(GitLab) 생성.

---

## Platform Detection

`git remote get-url origin` → GitHub(`gh pr create`) / GitLab(`glab mr create`) 자동 감지. 실패 시 사용자 질문.

---

## Flags

| Flag | Description |
|------|-------------|
| `base` (arg) | target branch (생략 시 main/기본 브랜치) |
| `--draft` | Draft PR/MR |
| `--jira <URL>` | Jira 티켓 첨부 |
| `--reviewer <user>` | 리뷰어 (복수: 쉼표) |
| `--label <name>` | 라벨 (복수: 쉼표) |
| `--no-push` | push 안함 (이미 push된 상태) |
| `--split` | 분할 PR/MR 강제 |
| `-i` | 각 섹션 작성 시 사용자 확인 |

---

## Execution Flow

### Step 1: Detect Platform & Gather Context

1. Platform 감지 (GitHub/GitLab)
2. 현재 브랜치, base 대비 커밋 목록/diff/통계 수집
3. **Working tree 자동 커밋:** modified/untracked 있으면 → 변경 분석 → conventional commit 생성 → 민감 파일(`.env`, credentials) 제외+경고 → `git add` + `git commit`
4. **자동 push:** remote 미추적이면 `git push -u origin {branch}`

### Step 2: Commit Grouping Analysis

커밋 2개+ 시 그루핑 분석 수행.

**분류:** conventional commit prefix(feat/fix/refactor/docs/test/chore/style/perf/ci) 기반. prefix 없으면 diff 내용 추론.

**그룹 기준:** 같은 prefix / 같은 변경 영역(디렉토리) / 같은 기능/이슈

**사용자 선택:**
| 선택 | 동작 |
|------|------|
| 통합 | 전체 하나의 PR/MR |
| 분할 | 그룹별 cherry-pick 브랜치 → 각각 PR/MR |
| 커스텀 | 사용자 조합 (예: "1+2 / 3") |

> 단일 커밋/단일 그룹: 바로 Step 3 진행

분할 시 브랜치: `{original-branch}/group-{n}-{description}` (cherry-pick 기반, 원본 브랜치 불변)

### Step 3: Compose PR/MR Body

**템플릿 구조:**
- **작업 주제:** 핵심 목적 1-2문장
- **작업 내용:** 커밋별 설명 테이블 + 주요 변경 파일 목록
- **Jira:** `--jira` 있을 때만
- **스크린샷:** UI 파일(tsx/css/vue/svelte/components/pages) 변경 시 포함
- **관련 문서:** `.u-maker/docs/` 변경 포함 시
- **체크리스트:** base/compare 확인, 빌드/테스트, console.log 제거, .env.example 반영
- **리뷰 가이드:** P1(Request Changes) / P2(Comment) / P3(Approve)

### Step 4: Create PR/MR

Push → 플랫폼별 CLI로 PR/MR 생성 → URL + 변경 통계 보고. 분할 시 각 PR/MR URL 목록.

---

## Safety Rules

1. uncommitted changes 자동 커밋 (민감 파일 제외+경고)
2. push 필요 시 자동 push, force push 절대 금지
3. base가 main/master 아니면 사용자 확인
4. 변경사항 없으면 PR/MR 미생성
5. body는 HEREDOC으로 전달, 분할 시 원본 브랜치 보존
6. `gh`/`glab` CLI 미설치 시 안내
