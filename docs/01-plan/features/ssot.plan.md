---
document: "ssot.plan"
title: "Rename u-agent-ssot to ssot"
owner: "u-PM"
status: "Draft"
version: "v0.1.0"
last_updated: "2026-03-01"
feature: "ssot"
phase: "plan"
related_docs:
  - "README.md"
  - "u-agent-ssot.config.json"
  - ".claude-plugin/plugin.json"
---

# Rename u-agent-ssot to ssot

## 1. Background

### 1.1 Project Overview

u-Agent SSoT는 PDCA 사이클 기반의 SSoT(Single Source of Truth) 소프트웨어 개발 협업 자동화 Claude Code Plugin이다. 현재 프로젝트명이 `u-agent-ssot`로 사용되고 있으나, 더 간결하고 명확한 이름인 `ssot`로 변경한다.

### 1.2 Problem Statement

- `u-agent-ssot` 이름이 길어 명령어, 파일 경로, 참조 시 불편
- Plugin 외부에서 참조할 때 이름이 직관적이지 않음
- 브랜딩 관점에서 `ssot`가 더 기억하기 쉽고 핵심 가치(Single Source of Truth)를 직접 전달

### 1.3 Goals

| # | Goal | Success Metric |
|---|------|---------------|
| G-001 | 모든 파일/폴더에서 `u-agent-ssot` 참조를 `ssot`로 변경 | grep 결과 0건 |
| G-002 | Plugin 기능 정상 동작 유지 | 전체 slash command 동작 확인 |
| G-003 | 문서/README 일관성 유지 | 모든 문서에서 새 이름 반영 |

---

## 2. Scope

### 2.1 In-Scope

- 설정 파일명 변경: `u-agent-ssot.config.json` → `ssot.config.json`
- `plugin.json` 내 name/description 업데이트
- `README.md` 내 프로젝트명, 설치 경로, 참조 업데이트
- `skills/` 디렉토리 내 skill 파일 참조 변경
- `hooks/` 내 참조 변경
- Agent 파일 내 프로젝트명 참조 변경
- `commands/` 내 참조 변경
- `lib/` 내 참조 변경
- `scripts/` 내 참조 변경
- `references/` 내 참조 변경
- `.bkit-memory.json` 업데이트

### 2.2 Out-of-Scope

- Agent 이름 변경 (u-pm, u-a, u-cx 등은 유지)
- Slash command 이름 변경 (/u-plan, /u-design 등은 유지)
- u-docs/ 폴더 구조 변경 (기존 SSoT 문서 체계 유지)
- 기술 스택 규칙 변경

---

## 3. Impact Analysis

### 3.1 Files to Rename

| Current Name | New Name |
|-------------|----------|
| `u-agent-ssot.config.json` | `ssot.config.json` |

### 3.2 Files to Modify (Content)

| File/Directory | Change Description |
|---------------|-------------------|
| `.claude-plugin/plugin.json` | name, description 필드 업데이트 |
| `README.md` | 프로젝트명, 설치 경로, 구조 설명 변경 |
| `skills/u-agent-ssot/` | 디렉토리명 및 내부 참조 변경 |
| `agents/*.md` | 프로젝트명 참조 변경 (있을 경우) |
| `commands/*.md` | 프로젝트명 참조 변경 (있을 경우) |
| `hooks/hooks.json` | config 경로 참조 변경 (있을 경우) |
| `scripts/*.sh` | 경로 참조 변경 (있을 경우) |
| `references/*.md` | 프로젝트명 참조 변경 (있을 경우) |
| `lib/**` | 참조 변경 (있을 경우) |
| `evals/` | 참조 변경 (있을 경우) |

### 3.3 Impact on External References

- Plugin 설치 경로: `~/.claude/plugins/u-agent-ssot/` → `~/.claude/plugins/ssot/`
- 프로젝트 로컬 경로: `.claude/plugins/u-agent-ssot/` → `.claude/plugins/ssot/`

---

## 4. Implementation Strategy

### 4.1 Approach

전체 리네이밍을 단계적으로 수행한다:

1. **Phase 1**: 파일명 변경 (config 파일, skill 디렉토리)
2. **Phase 2**: 설정 파일 내용 변경 (plugin.json, config)
3. **Phase 3**: 문서 내용 변경 (README, references)
4. **Phase 4**: 코드/스크립트 내용 변경 (scripts, lib, hooks)
5. **Phase 5**: 검증 (grep으로 잔여 참조 확인)

### 4.2 Risk

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|------------|
| Plugin 로딩 실패 | High | Medium | plugin.json 경로 정확히 변경, 테스트 |
| 잔여 참조 누락 | Medium | Medium | grep 전수조사로 검증 |
| Hook 동작 실패 | High | Low | Hook config 경로 확인 |

---

## 5. Acceptance Criteria

| # | Criteria | Verification |
|---|---------|-------------|
| AC-001 | `grep -r "u-agent-ssot"` 결과 0건 (docs/01-plan 제외) | grep 실행 |
| AC-002 | 모든 slash command 정상 동작 | 수동 테스트 |
| AC-003 | Plugin 정상 로딩 | Claude Code 재시작 후 확인 |
| AC-004 | README.md에 새 이름 반영 | 문서 리뷰 |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | 2026-03-01 | u-PM | Initial plan draft |
