---
name: u-codereview
description: "코드 리뷰. 프로젝트 코딩 컨벤션/룰 파일을 정의하고, 해당 룰 기반으로 현재 코드의 위반 사항을 탐지·분류·리포트·자동 수정한다. /u-codereview init으로 룰 파일 초기화, /u-codereview [scope]로 리뷰 실행."
triggers:
  - "/u-codereview"
  - "code review"
  - "코드 리뷰"
  - "코드 리뷰 해줘"
  - "코딩 컨벤션 검사"
  - "컨벤션 위반 검사"
  - "코드 품질 검사"
  - "리뷰 룰 설정"
  - "convention check"
  - "룰 기반 리뷰"
---

# u-codereview -- Convention-Based Code Review

`/u-codereview [sub-command] [scope] [flags]` 명령으로 프로젝트 코딩 룰을 정의하고, 해당 룰 기반으로 코드를 리뷰한다.

**Primary Agent:** u-agent-gatekeeper (engine-validator 사용)

---

## Sub-Commands

| Sub-Command | Description |
|-------------|-------------|
| `init` | 룰 파일 초기화 (템플릿 기반 `code-review-rules.md` 생성) |
| `rules` | 현재 룰 파일 조회 및 요약 |
| `add-rule` | 룰 파일에 새 룰 추가 (인터랙티브) |
| *(default)* | 룰 기반 코드 리뷰 실행 |

## Flags

| Flag | Description |
|------|-------------|
| `--scope <path>` | 리뷰 대상 경로 지정 (파일, 디렉토리, glob 패턴) |
| `--app <name>` | 특정 앱 스코프 지정 (모노레포) |
| `--category <cat>` | 특정 룰 카테고리만 검사 (naming, structure, security 등) |
| `--severity <level>` | 최소 심각도 필터 (critical, major, minor) |
| `--fix` | 자동 수정 가능한 위반 사항 즉시 수정 |
| `--diff-only` | git diff 기준 변경된 파일만 리뷰 |
| `-i` | 분기점에서 사용자 확인 |
| `--step` | 매 단계 결과 표시 후 승인 대기 |

---

## Rules File

### 위치

```
.u-maker/docs/common/dev/code-review-rules.md    (공통 룰)
.u-maker/docs/{app}/code-review-rules.md          (앱별 오버라이드)
```

공통 룰이 기본 적용되고, 앱별 오버라이드가 존재하면 병합한다. 앱별 파일에서 `override: true`로 표기된 룰은 공통 룰을 덮어쓴다.

### 룰 파일 구조

룰 파일은 카테고리별 섹션으로 구성되며, 각 룰은 고유 ID, 심각도, 설명, 위반/준수 예시를 포함한다. 상세 포맷은 **`references/rules-format.md`** 참조.

### 기본 카테고리

| Category | Description |
|----------|-------------|
| `naming` | 변수, 함수, 파일, 컴포넌트 네이밍 규칙 |
| `structure` | 파일/폴더 구조, import/export 패턴 |
| `type-safety` | TypeScript 타입 안전성 규칙 |
| `error-handling` | 에러 처리 패턴 |
| `security` | 보안 관련 규칙 (XSS, injection 등) |
| `performance` | 성능 관련 패턴 |
| `style` | 코드 스타일 (포매팅 외 논리적 스타일) |
| `testing` | 테스트 코드 작성 규칙 |
| `custom` | 프로젝트 고유 규칙 |

---

## Execution Flow

### Sub-Command: `init`

1. `.u-maker/docs/common/dev/code-review-rules.md` 존재 여부 확인
2. 이미 존재하면: 덮어쓰기 여부 사용자 확인 (기본 = No)
3. `_meta/templates/code-review-rules.template.md` 기반 초기 룰 파일 생성
4. 프로젝트 techStack 분석 (`app.config.json`) → 스택에 맞는 룰 자동 활성화:
   - Next.js → `use client`/`use server` 분리 룰 활성화
   - TypeScript → `any` 금지, strict 타입 룰 활성화
   - Tailwind → 인라인 style 금지 룰 활성화
   - React → hooks 규칙, key prop 룰 활성화
5. 기존 `coding-convention.md` 존재 시 → 내용 파싱하여 룰로 자동 변환
6. 사용자에게 룰 파일 위치 + 커스터마이징 안내 출력

### Sub-Command: `rules`

1. 현재 활성 룰 파일 로드 (공통 + 앱별)
2. 카테고리별 룰 수 요약 테이블 출력
3. 비활성(disabled) 룰 별도 표시

### Sub-Command: `add-rule`

1. 사용자에게 카테고리, 룰 ID, 심각도, 설명, 예시 질문
2. 룰 파일에 해당 카테고리 섹션에 삽입
3. 중복 ID 검사 → 충돌 시 사용자에게 확인

### Default: 코드 리뷰 실행

#### Step 0: Load Rules

1. 룰 파일 로드: `common/dev/code-review-rules.md` (필수)
2. 앱별 오버라이드 로드: `docs/{app}/code-review-rules.md` (있으면)
3. 병합: 공통 룰 + 앱별 오버라이드 (override 표기 룰은 덮어쓰기)
4. `--category` 지정 시 해당 카테고리만 필터
5. `--severity` 지정 시 해당 심각도 이상만 필터
6. disabled 룰 제외
7. **룰 파일 없으면:** "룰 파일이 없습니다. `/u-codereview init`을 먼저 실행하세요." 안내 후 중단

#### Step 1: Resolve Target Files

| 조건 | 대상 |
|------|------|
| `--scope <path>` | 지정 경로 (glob 지원) |
| `--app <name>` | `{app-root}/src/**` |
| `--diff-only` | `git diff --name-only HEAD` 결과 |
| *(none)* | 프로젝트 전체 소스 (`src/` 기준) |

대상 파일 필터링:
- `node_modules/`, `.next/`, `dist/`, `build/` 제외
- `.gitignore` 패턴 존중
- 바이너리 파일 제외
- 룰 파일의 `include`/`exclude` glob 패턴 적용

#### Step 2: Analyze Code Against Rules

각 룰에 대해 대상 파일을 검사:

1. **Pattern-based rules:** 정규식/glob 매칭 (예: `any` 타입 사용, 하드코딩 색상값)
2. **Structural rules:** AST-level 분석이 필요한 규칙 (예: 미사용 import, 중첩 깊이)
3. **Convention rules:** 네이밍 패턴 검증 (예: 컴포넌트 PascalCase, 훅 use- prefix)
4. **Cross-file rules:** 파일 간 일관성 검사 (예: 배럴 export 누락, 타입 재정의)

검사 시 Grep, Glob, Read 도구를 활용하여 코드를 스캔한다.

#### Step 3: Classify Violations

각 위반 사항을 분류:

```
{
  "id": "V-{NNNN}",
  "ruleId": "CR-{category}-{NNN}",
  "severity": "Critical | Major | Minor",
  "file": "src/components/Button.tsx",
  "line": 42,
  "column": 8,
  "message": "변수명 'x'는 naming 룰 CR-naming-001 위반 (2자 이상 의미있는 이름 필수)",
  "suggestion": "'x' → 'buttonWidth' 등 의미 있는 이름으로 변경",
  "autoFixable": true
}
```

#### Step 4: Generate Review Report

**산출물:** `code-review-report.md` + `code-review-report.json` + `code-review-report.html`

**출력 경로:**
- 앱 스코프: `docs/{app}/03-dev/code-review-report.{ext}`
- 공통 스코프: `docs/common/dev/code-review-report.{ext}`

**리포트 구조:**

```markdown
# Code Review Report

**Date:** {ISO 8601}
**Scope:** {대상 경로 또는 앱}
**Rules Applied:** {적용된 룰 수}
**Files Scanned:** {스캔 파일 수}

## Summary

| Severity | Count | Auto-Fixable |
|----------|-------|-------------|
| Critical | 3 | 1 |
| Major | 12 | 8 |
| Minor | 25 | 20 |
| **Total** | **40** | **29** |

## Violations by Category

### naming (8 violations)

| # | File | Line | Rule | Message | Fix |
|---|------|------|------|---------|-----|
| V-0001 | src/utils/calc.ts | 12 | CR-naming-001 | 변수명 'x' 의미 불명 | 자동 수정 불가 |

### security (3 violations)

| # | File | Line | Rule | Message | Fix |
|---|------|------|------|---------|-----|
| V-0009 | src/api/user.ts | 45 | CR-security-002 | 미검증 사용자 입력 | autoFixable |

## Auto-Fix Summary (--fix 사용 시)

| # | File | Before | After | Rule |
|---|------|--------|-------|------|
| V-0002 | src/App.tsx:8 | `color: '#ff0000'` | `className="text-red-500"` | CR-style-003 |
```

#### Step 5: Apply Auto-Fix (`--fix` 지정 시)

1. `autoFixable: true`인 위반 사항만 대상
2. 파일별로 그룹핑 → Edit 도구로 수정 적용
3. 수정 전/후 diff 기록
4. `--step` 모드: 각 수정 전 사용자 확인
5. 수정 완료 후 재검증 (수정이 새 위반을 만들지 않는지)

#### Step 6: Summary Output

1. 총 위반 수 + 카테고리별 분포 표시
2. Critical 위반 있으면 강조 경고
3. `--fix` 사용 시 수정된/남은 위반 수 표시
4. "수정이 필요한 항목은 코드를 직접 수정 후 `/u-codereview`를 다시 실행하세요." 안내

---

## coding-convention.md 연동

기존 `common/dev/coding-convention.md`와의 관계:

| 파일 | 역할 |
|------|------|
| `coding-convention.md` | 개발자 가독용 코딩 컨벤션 문서 (서술형) |
| `code-review-rules.md` | 기계 검증용 룰 정의 (구조화, ID 부여, 예시 포함) |

`/u-codereview init` 실행 시 `coding-convention.md`가 존재하면 내용을 파싱하여 `code-review-rules.md`의 초기 룰로 자동 변환한다. 이후 두 파일은 독립적으로 관리된다.

---

## Additional Resources

### Reference Files

- **`references/rules-format.md`** — 룰 파일 작성 상세 포맷, 카테고리별 룰 예시, include/exclude 설정, 앱별 오버라이드 방법

---

## Safety Rules

1. 룰 파일 없이 리뷰 실행 금지 (`/u-codereview init` 선행 필수)
2. `--fix` 적용 시 autoFixable 항목만 수정 (비자동 항목 수정 금지)
3. `--fix` 적용 전 원본 상태 보존 (`git diff`로 롤백 가능 확인)
4. Critical 위반은 `--fix`로 자동 수정하지 않음 (사용자 확인 필수)
5. 리뷰 리포트는 `.md` + `.json` + `.html` 3종 동시 생성
6. 바이너리 파일, `node_modules/`, 빌드 산출물 스캔 금지
7. 룰 ID 중복 금지 (init/add-rule 시 검증)
8. 앱별 오버라이드에서 공통 Critical 룰을 disabled 처리하는 것 금지
