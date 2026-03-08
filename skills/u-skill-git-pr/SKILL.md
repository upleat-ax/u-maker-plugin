---
name: u-skill-git-pr
description: |
  feature별로 git commit하고 PR을 생성한다. 변경된 파일을 feature 단위로 그룹핑하여 커밋 후 GitHub PR을 남긴다.
  Args: `[feat/<feature-name>]` — feature 브랜치 이름 (생략 시 자동 분류)
  Triggers: /u-skill-git-pr, git pr, 커밋, commit and pr, pull request
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

# Feature Git Commit & PR

> feature별로 변경사항을 git commit하고 GitHub PR을 생성한다.

## Flow

1. git status로 변경 파일 수집
2. 변경 파일을 feature 단위로 그룹핑
3. feature별 브랜치 생성 (feat/<feature-name>)
4. feature별 stage + commit
5. push
6. gh pr create

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

## Rules

- main 브랜치에 직접 commit 금지
- PR 생성 전 git diff로 변경 확인 후 사용자에게 보여줌
- force push 금지
- 민감 파일 (.env, credentials) commit 차단
- 하나의 PR에 하나의 feature만 포함
- Post-Execution Summary Box 출력 필수
