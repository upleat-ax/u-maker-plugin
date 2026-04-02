---
version: "1.0"
techStack: []
include:
  - "src/**/*.{ts,tsx}"
  - "app/**/*.{ts,tsx}"
exclude:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/*.stories.tsx"
  - "**/*.d.ts"
  - "**/generated/**"
  - "**/node_modules/**"
---

# Code Review Rules

프로젝트 코딩 컨벤션 및 리뷰 룰 정의. `/u-codereview`가 이 파일의 룰을 기준으로 코드를 검사한다.

> 룰 추가: `/u-codereview add-rule` 또는 직접 편집
> 룰 조회: `/u-codereview rules`
> 상세 포맷: `references/rules-format.md` 참조

---

## naming

### CR-naming-001: 컴포넌트 PascalCase

- **Severity:** Major
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** React 컴포넌트 파일명과 export명은 PascalCase를 따른다.

**Bad:**
```typescript
// src/components/user-card.tsx
export function user_card() { ... }
```

**Good:**
```typescript
// src/components/UserCard.tsx
export function UserCard() { ... }
```

### CR-naming-002: 훅 함수 use- prefix

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 커스텀 훅 함수명은 반드시 `use`로 시작한다.

**Bad:**
```typescript
export function fetchUserData() {
  const [data, setData] = useState(null);
}
```

**Good:**
```typescript
export function useUserData() {
  const [data, setData] = useState(null);
}
```

### CR-naming-003: 의미 있는 변수명

- **Severity:** Minor
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 단일 문자 변수명은 루프 인덱스(`i`, `j`, `k`)를 제외하고 금지. 의미 있는 이름 사용.

**Bad:**
```typescript
const d = new Date();
const u = await getUser();
```

**Good:**
```typescript
const currentDate = new Date();
const user = await getUser();
```

---

## structure

### CR-structure-001: 배럴 export

- **Severity:** Minor
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** 컴포넌트 디렉토리에 `index.ts` 배럴 파일 존재 필수.

**Bad:**
```
components/UserCard/
  UserCard.tsx
  // index.ts 누락
```

**Good:**
```
components/UserCard/
  UserCard.tsx
  index.ts
```

### CR-structure-002: 깊은 상대 경로 import 금지

- **Severity:** Major
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** `../../../` 이상의 상대 경로 import 금지. path alias(`@/`) 사용.

**Bad:**
```typescript
import { Button } from '../../../components/ui/Button';
```

**Good:**
```typescript
import { Button } from '@/components/ui/Button';
```

---

## type-safety

### CR-type-001: any 타입 사용 금지

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** `any` 타입 사용 금지. `unknown`으로 대체하고 타입 가드 사용.

**Bad:**
```typescript
function parse(data: any) {
  return data.name;
}
```

**Good:**
```typescript
function parse(data: unknown) {
  if (isUser(data)) return data.name;
  throw new Error('Invalid data');
}
```

### CR-type-002: @ts-ignore 금지

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** `@ts-ignore` 사용 금지. `@ts-expect-error`로 대체하고 사유 주석 필수.

**Bad:**
```typescript
// @ts-ignore
const value = obj.unknownProp;
```

**Good:**
```typescript
// @ts-expect-error: legacy API 호환, v2 마이그레이션 시 제거 예정
const value = obj.unknownProp;
```

---

## error-handling

### CR-error-001: 빈 catch 블록 금지

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** catch 블록에서 에러를 무시하지 않는다. 최소 로깅 또는 재throw 필수.

**Bad:**
```typescript
try {
  await fetchData();
} catch (e) {}
```

**Good:**
```typescript
try {
  await fetchData();
} catch (error) {
  console.error('Failed to fetch data:', error);
  throw error;
}
```

---

## security

### CR-security-001: 하드코딩 시크릿 금지

- **Severity:** Critical
- **AutoFixable:** No
- **Enabled:** true
- **Description:** API 키, 비밀번호, 토큰 등을 코드에 직접 작성 금지. 환경 변수 사용.

**Bad:**
```typescript
const API_KEY = 'sk-abc123def456';
```

**Good:**
```typescript
const API_KEY = process.env.API_KEY;
```

### CR-security-002: 사용자 입력 검증 필수

- **Severity:** Critical
- **AutoFixable:** No
- **Enabled:** true
- **Description:** API route handler에서 사용자 입력은 Zod 등으로 검증 후 사용.

**Bad:**
```typescript
export async function POST(req: Request) {
  const { email } = await req.json();
  await db.user.create({ data: { email } });
}
```

**Good:**
```typescript
const Schema = z.object({ email: z.string().email() });

export async function POST(req: Request) {
  const body = Schema.parse(await req.json());
  await db.user.create({ data: { email: body.email } });
}
```

---

## performance

### CR-perf-001: 인라인 객체 props 지양

- **Severity:** Minor
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 렌더링마다 새 참조를 생성하는 인라인 객체/배열을 props로 전달하지 않는다.

**Bad:**
```tsx
<Chart options={{ responsive: true }} />
```

**Good:**
```tsx
const options = useMemo(() => ({ responsive: true }), []);
<Chart options={options} />
```

---

## style

### CR-style-001: 인라인 style 금지

- **Severity:** Minor
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** Tailwind CSS 프로젝트에서 인라인 `style` 속성 사용 금지. Tailwind 유틸리티 클래스 사용.

**Bad:**
```tsx
<div style={{ color: 'red', marginTop: '16px' }}>Hello</div>
```

**Good:**
```tsx
<div className="text-red-500 mt-4">Hello</div>
```

---

## testing

### CR-test-001: 테스트 describe 블록 필수

- **Severity:** Minor
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 테스트 파일에 최소 하나의 `describe` 블록으로 그룹핑 필수.

**Bad:**
```typescript
test('adds numbers', () => { ... });
test('subtracts numbers', () => { ... });
```

**Good:**
```typescript
describe('Calculator', () => {
  test('adds numbers', () => { ... });
  test('subtracts numbers', () => { ... });
});
```

---

## custom

<!-- 프로젝트 고유 룰을 여기에 추가 -->
<!-- 예시:
### CR-custom-001: {룰 제목}

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** {설명}

**Bad:**
```typescript
// 위반 예시
```

**Good:**
```typescript
// 준수 예시
```
-->
