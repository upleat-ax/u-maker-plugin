---
skill_id: 'skill-builder'
name: 'skill-builder'
description: 'Create well-structured Codex Skills following official best practices. Use when user wants to create new skills or improve existing ones.'
category: team/doc
last_updated: '2026-03-11'
---

# Skill Builder - Codex Skill 생성 도구

Codex Skill을 공식 모범 사례에 따라 정확하게 생성하는 스킬입니다.

## 핵심 원칙

1. **간결함 우선**: SKILL.md는 500줄 이하 유지
2. **실행 가능한 코드**: 추측 금지, 실제 작동하는 코드만
3. **정확성 검증**: 백엔드/라이브러리 실제 코드 확인 필수
4. **점진적 공개**: 메인 가이드 + 참조 파일 분리
5. **3가지 모델 테스트**: Haiku, Sonnet, Opus 모두 고려

### 정확성 검증 필수 프로세스

**스킬 작성 시 반드시 실제 코드 확인**:

1. **API 정의 작성 시**:

   - ❌ API 파라미터나 응답 형식 추측
   - ✅ 기존 API 정의 파일 패턴 분석 (packages/api/src/)
   - ✅ 실제 타입 정의 확인 (packages/types/src/)
   - ✅ 유사한 도메인의 완전한 예시 확인 (CRUD 패턴)

   **참고**: Safe-U는 프론트엔드 프로젝트입니다. m6.api 백엔드와 통신하지만,
   개발 시에는 safe-u 프로젝트만 사용합니다. API 정의 작성 시 기존 패턴을 따르고
   타입 정의를 참고하세요.

2. **라이브러리 사용법 문서화 시**:

   - ❌ 비슷해 보이는 다른 라이브러리 패턴 유추
   - ✅ 해당 라이브러리 공식 문서 확인
   - ✅ 프로젝트 내 실제 사용 예시 수집

3. **예시 코드 작성 시**:
   - ❌ "이렇게 하면 될 것 같습니다" 코드
   - ✅ 실제 프로젝트에서 작동하는 코드만
   - ✅ 파일 경로와 줄 번호 명시

## TypeScript Import 패턴 (코드 예시 작성 시)

스킬 문서에 TypeScript 코드 예시를 포함할 때 올바른 import 패턴을 사용하세요.

**필수 규칙**:

```typescript
// ✅ 올바른 패턴
import { externalLib } from '@external/package';

import { InternalType } from '@safe-u/types';

import { localFunction } from './local-file';

export const example = () => {
  // ...
};
```

**규칙**:

1. Import 그룹 사이 빈 줄 **정확히 1개**
2. Import와 export/코드 사이 빈 줄 **정확히 1개**
3. 괄호 공백: `import { name } from` (앞뒤 각 1칸)
4. Import 순서:
   - 외부 라이브러리 (`@tanstack`, `@lukemorales` 등)
   - 빈 줄
   - 내부 패키지 (`@safe-u/types`, `@safe-u/api` 등)
   - 빈 줄
   - 상대 경로 (`./`, `../`)
5. Type import는 `import type { ... }` 사용

**자동 수정**:

- API 코드: `pnpm --filter @safe-u/api lint --fix`
- Query 코드: `pnpm --filter @safe-u/query lint --fix`

**검증 체크리스트**:

- [ ] 백엔드/라이브러리 실제 코드 확인함
- [ ] 모든 파라미터가 실제로 처리되는지 검증함
- [ ] 예시 코드가 실제 프로젝트에 존재함
- [ ] 추측한 부분이 하나도 없음

## Codex Skill 구조

### 필수 구조

```
skill-name/
└── SKILL.md          # 필수 (YAML frontmatter + 본문)
```

### 권장 구조

```
skill-name/
├── SKILL.md          # 메인 가이드 (500줄 이하)
├── templates/        # 선택: 코드 템플릿
│   └── example.ts
└── scripts/          # 선택: 실행 스크립트
    └── helper.py
```

### 복잡한 Skill 구조

```
skill-name/
├── SKILL.md          # 개요 (500줄 이하)
├── REFERENCE.md      # 상세 참조
├── ADVANCED.md       # 고급 기능
├── EXAMPLES.md       # 사용 예시
├── templates/
│   └── *.template
└── scripts/
    └── *.py
```

## SKILL.md 작성 규칙

### YAML Frontmatter (필수)

```yaml
---
skill_id: 'skill-name' # 소문자, 하이픈만 (= 폴더명과 동일)
name: 'skill-name' # 🚨 skill_id와 반드시 동일해야 함 (CI 검증)
description: 'What it does and when to use. Max 1024 chars.'
category: 'team/doc' # 필수! 아래 카테고리 목록 참조
last_updated: '2026-03-12' # YYYY-MM-DD 날짜만
---
```

**skill_id / name 규칙:**
- `skill_id`와 `name`은 **반드시 동일한 값**이어야 합니다 (CI에서 검증)
- 값은 **폴더명과 동일**하게 설정합니다
- 예: 폴더 `team-daily/` → `skill_id: 'team-daily'`, `name: 'team-daily'`

**유효한 category 값:**

| category | 설명 |
|----------|------|
| `team/doc` | 팀 문서/리포트 (team-daily, team-weekly, gate-document 등) |
| `team/analysis` | 팀 분석/동기화 (team-figma-*, cs 등) |
| `planner` | 기획자 워크플로우 (planner-*, spec-feature 등) |
| `designer` | 디자이너 워크플로우 (designer-*, design-* 등) |
| `developer/db` | DB 관련 (db-read, db-write 등) |
| `developer/convention` | 개발 컨벤션/도구 (api-generator, query-generator, gate-code 등) |
| `developer/domain` | 도메인 특화 개발 (admin-*, print-utils 등) |

**Description 작성법**:

- ✅ "무엇을 하는지" + "언제 사용하는지" 모두 포함
- ✅ 3인칭으로 작성
- ✅ 구체적인 키워드 포함
- ❌ "도와줍니다", "지원합니다" 같은 모호한 표현 금지

**좋은 예시**:

```yaml
description: 'Generate type-safe API definitions for MongoDB backend. Use when creating REST APIs, CRUD operations, or database schemas.'
```

**나쁜 예시**:

```yaml
description: 'API 작업을 도와줍니다' # 너무 모호함
```

### 본문 구조

```markdown
# Skill Name

간단한 설명 (1-2문장)

## 핵심 원칙

1. 원칙 1
2. 원칙 2
3. 원칙 3

## 사용 방법

### 1단계: ...

실제 코드 예시

### 2단계: ...

실제 코드 예시

## 실제 예시

\`\`\`
완전한 작동 코드
\`\`\`

## 자주 하는 실수

### ❌ 1. 잘못된 방법

\`\`\`
나쁜 예시 코드
\`\`\`

### ✅ 올바른 방법

\`\`\`
좋은 예시 코드
\`\`\`

## 체크리스트

- [ ] 항목 1
- [ ] 항목 2

## 참조 자료

- 공식 문서: https://...
```

## 명명 규칙

### 🚨 관심사 기반 Prefix 규칙 (필수)

**원칙: 하나의 prefix = 하나의 관심사 경계.**
**prefix를 보면 이 스킬이 어디 소속인지 즉시 파악 가능해야 한다.**

```
{관심사}-{행위}
예: team-daily, team-publish, gate-code, designer-mockup
```

**현재 등록된 관심사 Prefix:**

| Prefix | 관심사 경계 | 포함 범위 | 예시 |
|--------|-----------|----------|------|
| `team-` | 팀 운영 자동화 | 일일/주간 리포트, 스프린트 세러모니, Jira 동기화, Confluence 발행 | team-daily, team-weekly, team-jira-sync, team-publish |
| `spec-` | 기획/설계 문서 | 기능 기획서, API 설계서, 디자인 스펙 | spec-feature |
| `gate-` | 품질 검증 | 문서/코드 품질 채점, 자동 검증 | gate-document, gate-code |
| `designer-` | 디자인 워크플로우 | 목업, 리뷰, PR, 캡처 | designer-mockup, designer-review |
| `db-` | 데이터베이스 작업 | 조회, 쓰기, 마이그레이션 | db-read, db-write |
| `assist-` | AI 보조 도구 | 인터뷰, 피드백 루프, 문서 품질 게이트 | assist-interview, assist-loop-feedback, assist-gate-document |

**새 스킬 추가 시 판단 기준:**

1. 기존 prefix에 해당하는 관심사인가? → 해당 prefix 사용
2. 새로운 관심사인가? → 새 prefix 등록 (이 테이블에 추가)
3. 어디에도 안 맞으면 → 무리하게 끼우지 말고 새 prefix 생성

**❌ 잘못된 예시:**
```
sync-confluence  → ❌ 행위(sync)가 prefix
report-daily     → ❌ 행위(report)가 prefix. team 관심사에서 분리됨
sprint-retro     → ❌ 같은 팀 운영인데 sprint-로 또 분리
jira-sync        → ❌ 같은 팀 운영인데 jira-로 또 분리
pm-spec          → ❌ 역할(pm)이 prefix
```

**✅ 올바른 예시:**
```
team-daily       → ✅ 팀 운영(team) 안에서 일일 리포트
team-publish     → ✅ 팀 운영(team) 안에서 Confluence 발행
team-jira-sync   → ✅ 팀 운영(team) 안에서 Jira 동기화
team-sprint-plan → ✅ 팀 운영(team) 안에서 스프린트 플래닝
gate-code        → ✅ 품질 검증(gate) 안에서 코드 채점
spec-feature     → ✅ 기획문서(spec) 안에서 기능 기획서
```

### skill_id / name

- ✅ **관심사-행위 형태**: `team-daily`, `gate-code`, `designer-mockup`
- ✅ **소문자, 숫자, 하이픈만**: `my-skill-123`
- ❌ **피할 것**: `helper`, `utils`, `tools`, `assistant`
- ❌ **피할 것**: 행위를 prefix로 (`sync-*`, `create-*`, `manage-*`, `report-*`)
- ❌ **피할 것**: 역할을 prefix로 (`pm-*`, `dev-*`, `admin-*`)

### 폴더/파일명

- ✅ `kebab-case`: `skill-builder/`, `api-generator/`
- ✅ 의미있는 이름: `createUserApiDef.ts`
- ❌ 단일 문자: `a.ts`, `util.ts`

## 콘텐츠 작성 가이드

### 1. 간결함 유지

**원칙**: Codex는 이미 똑똑함. 필수 정보만 제공.

```markdown
❌ 나쁜 예시:
이 섹션에서는 API를 생성하는 방법에 대해 자세히 설명합니다.
먼저 타입을 확인해야 하는데, 타입은 TypeScript에서 매우 중요한
개념으로서 코드의 안전성을 보장해줍니다...

✅ 좋은 예시:

## API 생성

1. 타입 확인: `grep -r "YourType" src/`
2. 파일 생성: `touch createApiDef.ts`
3. 코드 작성: 아래 템플릿 참조
```

### 2. 점진적 공개

**SKILL.md**: 개요와 핵심 패턴만
**참조 파일**: 상세 설명

```markdown
// SKILL.md

## API 패턴

기본 구조:
\`\`\`typescript
export const apiDef: ApiDefinition = { /_ ... _/ };
\`\`\`

상세한 예시는 `@templates/api.template.ts` 참조
```

### 3. 워크플로우 제공

**체크리스트 형식으로 단계 명확화**:

```markdown
## 생성 워크플로우

### 1단계: 요구사항 확인

- [ ] 어떤 기능이 필요한가?
- [ ] 기존 패턴이 있는가?

### 2단계: 타입 확인

\`\`\`bash
grep -r "TypeName" src/
\`\`\`

### 3단계: 코드 생성

템플릿 복사 후 수정
```

### 4. 실제 코드 예시

**추측 금지. 실제 작동하는 코드만**:

```markdown
❌ 나쁜 예시:
\`\`\`typescript
// 이런 식으로 작성하세요
const api = createApi({ /_ config _/ });
\`\`\`

✅ 좋은 예시:
\`\`\`typescript
// packages/api/src/user/createUserApiDef.ts
import { UserData, SVCUser, ResponseDocs } from '@safe-u/types';
import type { ApiDefinition } from '../api.type';

type CreateUserParams = UserData & { siteId: string };
type CreateUserResponse = ResponseDocs<SVCUser>;

export const createUserApiDef: ApiDefinition<
CreateUserParams,
CreateUserResponse

> = {
> method: 'post',
> url: '/users',
> config: ({ siteId, ...userData }) => ({

    params: { bucketId: siteId },
    data: { userData },

}),
};
\`\`\`
```

### 5. 비교 예시

**잘못된 것 vs 올바른 것**:

```markdown
## 자주 하는 실수

### ❌ 1. 타입 추측

\`\`\`typescript
import { User } from '@types'; // 존재하는지 미확인
\`\`\`

### ✅ 올바른 방법

\`\`\`bash

# 먼저 확인

grep -r "User" packages/types/src/

# 실제 타입 import

import { SVCUser } from '@safe-u/types';
\`\`\`
```

## 템플릿 파일 작성

### TypeScript 템플릿

```typescript
// templates/example.template.ts

// @ts-nocheck - 템플릿 파일이므로 타입 체크 비활성화
import type { YourType } from '../types';

/**
 * 템플릿 설명
 *
 * 사용법:
 * 1. 이 파일을 프로젝트로 복사
 * 2. @ts-nocheck 주석 제거
 * 3. TODO 부분 수정
 */

type YourParams = {
  // TODO: 파라미터 정의
};

type YourResponse = {
  // TODO: 응답 정의
};

export const yourFunction = (params: YourParams): YourResponse => {
  // TODO: 구현
  return {} as YourResponse;
};
```

### Python 스크립트

```python
# scripts/helper.py

"""
스크립트 설명

요구사항:
    pip install requests pandas

사용법:
    python scripts/helper.py input.csv output.csv
"""

import sys
import requests
import pandas as pd

# 상수 (주석으로 이유 설명)
REQUEST_TIMEOUT = 30  # HTTP 요청은 보통 30초 이내 완료
MAX_RETRIES = 3       # 3번 재시도로 안정성과 속도 균형

def process_data(input_file: str, output_file: str) -> None:
    """데이터 처리 및 저장"""
    try:
        df = pd.read_csv(input_file)
        # 처리 로직...
        df.to_csv(output_file, index=False)
        print(f"✅ 완료: {output_file}")
    except FileNotFoundError:
        print(f"❌ 에러: {input_file} 파일을 찾을 수 없음")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 에러: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("사용법: python helper.py input.csv output.csv")
        sys.exit(1)

    process_data(sys.argv[1], sys.argv[2])
```

## 스킬 생성 워크플로우

### 1단계: 요구사항 정의

```markdown
**질문할 것**:

- 스킬이 해결할 문제는?
- 사용자가 언제 이 스킬을 사용하나?
- 필요한 입력/출력은?
- 유사한 기존 스킬이 있나?
```

### 2단계: 구조 결정

```markdown
**선택 기준**:

- 간단한 작업 (500줄 이하) → SKILL.md만
- 중간 복잡도 → SKILL.md + templates/
- 복잡한 작업 → SKILL.md + 여러 참조 파일
```

### 3단계: SKILL.md 작성

```markdown
**순서**:

1. YAML frontmatter 작성
   - skill_id: 동명사 형태
   - description: 무엇 + 언제
2. 핵심 원칙 (3-5개)
3. 실제 코드 예시 (2-3개)
4. 워크플로우 (체크리스트)
5. 자주 하는 실수 (비교 예시)
6. 체크리스트
7. 참조 링크
```

### 4단계: 템플릿/스크립트 작성

```markdown
**원칙**:

- 실제 작동하는 코드만
- 오류 처리 명시적으로
- 의존성 명확히
- 주석으로 설명
```

### 5단계: 검증

```markdown
**체크리스트**:

- [ ] SKILL.md 500줄 이하
- [ ] description 구체적 (무엇 + 언제)
- [ ] 실제 코드 예시 포함
- [ ] 추측 코드 없음
- [ ] 체크리스트 제공
- [ ] 일관된 용어 사용
- [ ] 경로는 슬래시(/) 사용
- [ ] Haiku에서 테스트
```

## 자주 하는 실수

### ❌ 1. 모호한 description

```yaml
❌ description: '파일 작업을 도와줍니다'

✅ description: 'CSV, JSON, XML 파일 파싱 및 변환. 데이터 파일 처리, 형식 변환, 배치 작업 시 사용.'
```

### ❌ 2. 너무 긴 SKILL.md

```markdown
❌ SKILL.md: 2000줄

- 모든 예시를 한 파일에

✅ SKILL.md: 400줄 (개요)

- EXAMPLES.md: 상세 예시
- templates/: 코드 템플릿
```

### ❌ 3. 추측 코드

```typescript
❌ // 이런 식으로 하면 될 것 같습니다
const result = magicFunction(data);

✅ // packages/lib/src/processor.ts (실제 확인한 코드)
import { processData } from '@lib/processor';

const result = processData({
  input: data,
  options: { validate: true },
});
```

### ❌ 4. 깊은 참조 구조

```markdown
❌ SKILL.md → REF1.md → REF2.md → REF3.md

✅ SKILL.md → REF1.md
→ REF2.md
→ REF3.md
```

### ❌ 5. Windows 경로

```markdown
❌ scripts\helper.py
❌ templates\example.ts

✅ scripts/helper.py
✅ templates/example.ts
```

## 체크리스트

### 생성 전

- [ ] 스킬의 목적 명확히 정의
- [ ] 유사한 기존 스킬 검색
- [ ] 필요한 구조 결정 (파일 개수)
- [ ] skill_id 명명 (동명사 형태)

### 작성 중

- [ ] YAML frontmatter 정확히 작성
- [ ] category: 유효한 카테고리 값 지정 (CI 검증 대상)
- [ ] description: 무엇 + 언제
- [ ] 실제 작동하는 코드만
- [ ] 체크리스트 워크플로우 제공
- [ ] 비교 예시 (❌ vs ✅)
- [ ] 일관된 용어 사용

### 완료 후

- [ ] SKILL.md 500줄 이하
- [ ] 추측 코드 0개
- [ ] 경로에 슬래시(/) 사용
- [ ] 템플릿에 @ts-nocheck
- [ ] 스크립트에 오류 처리
- [ ] Haiku에서 테스트

## 참조 자료

### 공식 문서

- **Best Practices**: https://anthropic.mintlify.app/ko/docs/agents-and-tools/agent-skills/best-practices
- **Skills Guide**: https://anthropic.mintlify.app/ko/docs/build-with-Codex/skills-guide
- **Quickstart**: https://anthropic.mintlify.app/ko/docs/agents-and-tools/agent-skills/quickstart
- **Overview**: https://anthropic.mintlify.app/ko/docs/agents-and-tools/agent-skills/overview
- **Cookbook**: https://github.com/anthropics/Codex-cookbooks/tree/main/skills

### 핵심 요약

**필수 파일**: `SKILL.md` (YAML frontmatter + 본문)

**권장 구조**:

- 간단: SKILL.md만
- 중간: + templates/
- 복잡: + 여러 참조 파일

**작성 원칙**:

1. 간결함 (500줄 이하)
2. 실제 코드만
3. 점진적 공개
4. 체크리스트 제공

**명명 규칙**:

- skill_id: `동명사-형태` (소문자, 하이픈)
- description: 무엇을 하는지 + 언제 사용하는지

**피할 것**:

- 추측 코드
- 모호한 설명
- Windows 경로
- 깊은 참조 구조
- 500줄 초과
