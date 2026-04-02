# Code Review Rules File Format

룰 파일(`code-review-rules.md`)의 상세 작성 가이드.

---

## 파일 구조

```markdown
---
version: "1.0"
techStack: ["Next.js", "TypeScript", "Tailwind CSS"]
include:
  - "src/**/*.{ts,tsx}"
  - "app/**/*.{ts,tsx}"
exclude:
  - "**/*.test.ts"
  - "**/*.stories.tsx"
  - "**/*.d.ts"
  - "**/generated/**"
---

# Code Review Rules

## {Category Name}

### CR-{category}-{NNN}: {Rule Title}

- **Severity:** Critical | Major | Minor
- **AutoFixable:** Yes | No
- **Enabled:** true | false
- **Description:** 룰에 대한 상세 설명

**Bad:**
\`\`\`typescript
// 위반 예시 코드
\`\`\`

**Good:**
\`\`\`typescript
// 준수 예시 코드
\`\`\`
```

---

## Frontmatter 필드

| Field | Required | Description |
|-------|----------|-------------|
| `version` | Yes | 룰 파일 버전 (`"1.0"`) |
| `techStack` | No | 프로젝트 기술 스택 (init 시 자동 설정) |
| `include` | No | 검사 대상 파일 glob 패턴 (미지정 시 `src/**` 기본) |
| `exclude` | No | 검사 제외 파일 glob 패턴 |

---

## 룰 ID 규칙

**형식:** `CR-{category}-{NNN}`

| Category Prefix | Category |
|----------------|----------|
| `naming` | 네이밍 규칙 |
| `structure` | 파일/폴더 구조 |
| `type` | TypeScript 타입 안전성 |
| `error` | 에러 처리 |
| `security` | 보안 |
| `perf` | 성능 |
| `style` | 코드 스타일 |
| `test` | 테스트 |
| `custom` | 프로젝트 고유 |

번호는 카테고리 내에서 001부터 순차 부여한다. 삭제된 번호는 재사용하지 않는다.

---

## Severity 기준

| Level | 기준 | 예시 |
|-------|------|------|
| **Critical** | 보안 취약점, 데이터 손실 위험, 런타임 크래시 유발 | SQL injection, XSS, 미처리 null reference |
| **Major** | 유지보수 저하, 버그 발생 가능성, 컨벤션 심각 위반 | `any` 타입 사용, 빈 catch 블록, 하드코딩 시크릿 |
| **Minor** | 코드 품질 개선, 가독성 향상, 선호 패턴 | 변수명 개선, 불필요 주석, import 정렬 |

---

## 카테고리별 룰 예시

### naming (네이밍)

```markdown
### CR-naming-001: 컴포넌트 PascalCase

- **Severity:** Major
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** React 컴포넌트 파일명과 export명은 PascalCase를 따른다.

**Bad:**
\`\`\`typescript
// src/components/user-card.tsx
export function user_card() { ... }
\`\`\`

**Good:**
\`\`\`typescript
// src/components/UserCard.tsx
export function UserCard() { ... }
\`\`\`
```

```markdown
### CR-naming-002: 훅 함수 use- prefix

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 커스텀 훅 함수명은 반드시 `use`로 시작한다.

**Bad:**
\`\`\`typescript
export function fetchUserData() {
  const [data, setData] = useState(null);
  ...
}
\`\`\`

**Good:**
\`\`\`typescript
export function useUserData() {
  const [data, setData] = useState(null);
  ...
}
\`\`\`
```

```markdown
### CR-naming-003: 변수명 최소 2자 이상 의미 있는 이름

- **Severity:** Minor
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 단일 문자 변수명(`x`, `i`, `j` 등)은 루프 인덱스를 제외하고 금지. 의미 있는 이름 사용 필수.

**Bad:**
\`\`\`typescript
const d = new Date();
const u = await getUser();
\`\`\`

**Good:**
\`\`\`typescript
const currentDate = new Date();
const user = await getUser();
\`\`\`
```

### structure (구조)

```markdown
### CR-structure-001: 배럴 export 필수

- **Severity:** Minor
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** 컴포넌트 디렉토리에 `index.ts` 배럴 파일이 존재해야 한다.

**Bad:**
\`\`\`
components/UserCard/
  UserCard.tsx
  UserCard.stories.tsx
  // index.ts 누락
\`\`\`

**Good:**
\`\`\`
components/UserCard/
  UserCard.tsx
  UserCard.stories.tsx
  index.ts          // export { UserCard } from './UserCard'
\`\`\`
```

```markdown
### CR-structure-002: 상대 경로 import 금지 (3단계 이상)

- **Severity:** Major
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** `../../../` 이상의 상대 경로 import 금지. path alias(`@/`) 사용 필수.

**Bad:**
\`\`\`typescript
import { Button } from '../../../components/ui/Button';
\`\`\`

**Good:**
\`\`\`typescript
import { Button } from '@/components/ui/Button';
\`\`\`
```

### type-safety (타입 안전성)

```markdown
### CR-type-001: any 타입 사용 금지

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** `any` 타입 사용 금지. `unknown`으로 대체하고 타입 가드를 사용한다.

**Bad:**
\`\`\`typescript
function parse(data: any) {
  return data.name;
}
\`\`\`

**Good:**
\`\`\`typescript
function parse(data: unknown) {
  if (isUser(data)) {
    return data.name;
  }
  throw new Error('Invalid data');
}
\`\`\`
```

```markdown
### CR-type-002: as 타입 캐스팅 최소화

- **Severity:** Minor
- **AutoFixable:** No
- **Enabled:** true
- **Description:** `as` 타입 캐스팅 사용 최소화. 타입 가드, 제네릭, 오버로드로 대체한다.

**Bad:**
\`\`\`typescript
const user = response.data as User;
\`\`\`

**Good:**
\`\`\`typescript
function isUser(data: unknown): data is User {
  return typeof data === 'object' && data !== null && 'name' in data;
}
const data = response.data;
if (isUser(data)) { /* type-safe */ }
\`\`\`
```

### security (보안)

```markdown
### CR-security-001: 하드코딩 시크릿 금지

- **Severity:** Critical
- **AutoFixable:** No
- **Enabled:** true
- **Description:** API 키, 비밀번호, 토큰 등을 코드에 직접 작성 금지. 환경 변수 사용 필수.

**Bad:**
\`\`\`typescript
const API_KEY = 'sk-abc123def456';
fetch(url, { headers: { Authorization: `Bearer ${API_KEY}` } });
\`\`\`

**Good:**
\`\`\`typescript
const API_KEY = process.env.API_KEY;
if (!API_KEY) throw new Error('API_KEY not configured');
fetch(url, { headers: { Authorization: `Bearer ${API_KEY}` } });
\`\`\`
```

```markdown
### CR-security-002: 사용자 입력 검증 필수

- **Severity:** Critical
- **AutoFixable:** No
- **Enabled:** true
- **Description:** API route handler에서 사용자 입력(body, query, params)은 Zod 등으로 검증 후 사용한다.

**Bad:**
\`\`\`typescript
export async function POST(req: Request) {
  const { email } = await req.json();
  await db.user.create({ data: { email } });
}
\`\`\`

**Good:**
\`\`\`typescript
const CreateUserSchema = z.object({ email: z.string().email() });

export async function POST(req: Request) {
  const body = CreateUserSchema.parse(await req.json());
  await db.user.create({ data: { email: body.email } });
}
\`\`\`
```

### error-handling (에러 처리)

```markdown
### CR-error-001: 빈 catch 블록 금지

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** catch 블록에서 에러를 무시하지 않는다. 최소한 로깅 또는 재throw 필수.

**Bad:**
\`\`\`typescript
try {
  await fetchData();
} catch (e) {
  // 무시
}
\`\`\`

**Good:**
\`\`\`typescript
try {
  await fetchData();
} catch (error) {
  console.error('Failed to fetch data:', error);
  throw error;
}
\`\`\`
```

### performance (성능)

```markdown
### CR-perf-001: 컴포넌트 내 인라인 객체/배열 리터럴 지양

- **Severity:** Minor
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 렌더링마다 새 참조를 생성하는 인라인 객체/배열을 props로 전달하지 않는다.

**Bad:**
\`\`\`tsx
<Chart options={{ responsive: true, plugins: { legend: true } }} />
\`\`\`

**Good:**
\`\`\`tsx
const chartOptions = useMemo(() => ({
  responsive: true,
  plugins: { legend: true }
}), []);
<Chart options={chartOptions} />
\`\`\`
```

### style (코드 스타일)

```markdown
### CR-style-001: 인라인 style 금지 (Tailwind 프로젝트)

- **Severity:** Minor
- **AutoFixable:** Yes
- **Enabled:** true
- **Description:** Tailwind CSS 프로젝트에서 인라인 `style` 속성 사용 금지. Tailwind 유틸리티 클래스 사용.

**Bad:**
\`\`\`tsx
<div style={{ color: 'red', marginTop: '16px' }}>Hello</div>
\`\`\`

**Good:**
\`\`\`tsx
<div className="text-red-500 mt-4">Hello</div>
\`\`\`
```

### custom (프로젝트 고유)

```markdown
### CR-custom-001: {프로젝트 고유 룰 제목}

- **Severity:** {Critical | Major | Minor}
- **AutoFixable:** {Yes | No}
- **Enabled:** true
- **Description:** {프로젝트에 특화된 룰 설명}

**Bad:**
\`\`\`typescript
// 위반 예시
\`\`\`

**Good:**
\`\`\`typescript
// 준수 예시
\`\`\`
```

---

## 앱별 오버라이드

앱별 룰 파일(`docs/{app}/code-review-rules.md`)에서 공통 룰을 오버라이드할 수 있다.

### 오버라이드 방법

```markdown
---
version: "1.0"
extends: "common"
---

### CR-naming-003: 변수명 최소 2자 이상 의미 있는 이름

- **Override:** true
- **Enabled:** false
- **Reason:** 이 앱은 수학 연산 중심이라 단일 문자 변수 허용

### CR-custom-app-001: API 응답 캐싱 필수

- **Severity:** Major
- **AutoFixable:** No
- **Enabled:** true
- **Description:** 모든 GET API 호출에 react-query 캐싱 적용 필수.

**Bad:**
\`\`\`typescript
const data = await fetch('/api/users').then(r => r.json());
\`\`\`

**Good:**
\`\`\`typescript
const { data } = useQuery({ queryKey: ['users'], queryFn: fetchUsers });
\`\`\`
```

### 오버라이드 규칙

| Action | 방법 |
|--------|------|
| 룰 비활성화 | `Override: true` + `Enabled: false` + `Reason` 필수 |
| 심각도 변경 | `Override: true` + 새 `Severity` 지정 |
| 앱 전용 룰 추가 | 새 ID 부여 (`CR-custom-app-{NNN}`) |
| 공통 Critical 룰 비활성화 | **금지** (Safety Rule) |

---

## 룰 파일 검증

`/u-codereview rules` 실행 시 자동 검증 항목:

| Check | Description |
|-------|-------------|
| ID 유일성 | 모든 룰 ID가 파일 내 유일한지 |
| 필수 필드 | Severity, Enabled, Description 존재 여부 |
| 예시 존재 | Bad/Good 예시 최소 하나 존재 여부 |
| 카테고리 유효성 | ID prefix가 유효 카테고리인지 |
| 오버라이드 충돌 | 공통 Critical 룰 비활성화 시도 탐지 |
