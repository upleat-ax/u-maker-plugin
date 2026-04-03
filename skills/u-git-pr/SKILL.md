---
name: u-git-pr
description: "This skill should be used when the user asks to 'create PR', 'make pull request', 'git PR', '/u-git-pr', or wants to auto-generate a Git pull request with structured description."
version: 4.0.0
triggers:
  - "/u-git-pr"
  - "create PR"
  - "pull request"
  - "git PR"
---

# u-git-pr — Git Pull Request Generator

`/u-git-pr [--base {branch}]`

Auto-generate a Git PR/MR with structured description using `_meta/templates/pr.template.md`.

## Flow

1. Detect current branch, base branch (default: main)
2. Collect commits since divergence (`git log base..HEAD`)
3. Analyze changed files (`git diff --stat base..HEAD`)
4. Generate PR title (< 70 chars)
5. Fill `pr.template.md`:
   - Work summary with commit table
   - Changed files with descriptions
   - Implementation details from commit messages
   - Checklist (build, type check, console.log, .env.example)
   - Review guide (P1/P2/P3)
6. Create PR via `gh pr create`

## PR Template

Located at `_meta/templates/pr.template.md`. Includes:
- Commit table with hash and description
- Changed files list
- Auto-generated checklist
- Review priority guide (P1=Request Changes, P2=Comment, P3=Approve)
