# Tech Stack Rules

> u-agent-ssot 플러그인이 강제하는 10가지 기술 스택 규칙을 정의한다.
> 모든 코드 생성 에이전트(`u-DV-FE`, `u-DV-BE`)는 이 규칙을 반드시 준수해야 한다.

---

## 1. Mandatory Rules

| # | Rule | Description | Violation Consequence |
|---|------|-------------|----------------------|
| 1 | **Clean Architecture** | `apps/`, `packages/` (ui, data, domain, infrastructure, tokens, config) 폴더 구조를 반드시 따른다 | 코드 생성 거부. 올바른 폴더 구조로 재배치 요구 |
| 2 | **react-query** | 서버 상태 관리는 `react-query`만 사용한다. `usecase` 패턴 사용 금지 | usecase import 발견 시 코드 거부. react-query hook으로 대체 요구 |
| 3 | **CSS Direct** | `.css` 파일을 직접 작성한다. CSS-in-JS(styled-components, emotion 등) 사용 금지 | CSS-in-JS import 발견 시 코드 거부. .css 파일로 전환 요구 |
| 4 | **Next.js App Router** | Next.js App Router(`app/` directory)만 사용한다. Pages Router 사용 금지 | `pages/` 디렉토리 사용 발견 시 코드 거부. App Router로 전환 요구 |
| 5 | **No eslint-plugin-header** | `eslint-plugin-header` 플러그인 사용 금지 | eslint 설정에서 해당 플러그인 발견 시 코드 거부. 제거 요구 |
| 6 | **Turborepo Monorepo** | `Turborepo` 기반 모노레포 구조를 사용한다 | 단일 패키지 구조 발견 시 코드 거부. Turborepo 구조로 전환 요구 |
| 7 | **Functional Components Only** | React 컴포넌트는 함수형 컴포넌트만 사용한다. Class 컴포넌트 금지 | Class 컴포넌트 발견 시 코드 거부. 함수형으로 전환 요구 |
| 8 | **Storybook** | UI 컴포넌트에는 Storybook 스토리를 반드시 작성한다 | 컴포넌트에 대응하는 `.stories.tsx` 파일 없이 PR 거부 |
| 9 | **Design Token** | 스타일 값은 Design Token 기반으로 관리한다. 하드코딩된 색상/크기 금지 | 매직 넘버/하드코딩 스타일 발견 시 코드 거부. Token 참조로 대체 요구 |
| 10 | **bun** | 패키지 매니저는 `bun`만 사용한다. npm/yarn/pnpm 사용 금지 | package-lock.json, yarn.lock 발견 시 코드 거부. bun.lockb로 전환 요구 |

---

## 2. Rule Details

### Rule 1: Clean Architecture

프로젝트는 다음 폴더 구조를 따른다:

```
project-root/
├── apps/
│   └── web/                    # Next.js App
│       ├── app/                # App Router
│       ├── public/
│       └── package.json
├── packages/
│   ├── ui/                     # Shared UI Components
│   ├── data/                   # Data Access Layer (react-query)
│   ├── domain/                 # Business Logic / Types
│   ├── infrastructure/         # External Service Adapters
│   ├── tokens/                 # Design Tokens
│   └── config/                 # Shared Configuration
├── turbo.json
├── package.json
└── bun.lockb
```

### Rule 2: react-query (No usecase)

```typescript
// CORRECT: react-query hook
export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(res => res.json()),
  });
}

// WRONG: usecase pattern
class GetUsersUseCase {
  execute() { /* ... */ }
}
```

### Rule 3: CSS Direct (No CSS-in-JS)

```css
/* CORRECT: component.css */
.button {
  background-color: var(--color-primary);
  padding: var(--spacing-md);
}
```

```typescript
// WRONG: CSS-in-JS
const Button = styled.button`
  background-color: blue;
`;
```

### Rule 4: Next.js App Router

```
// CORRECT: app/ directory
app/
├── layout.tsx
├── page.tsx
└── dashboard/
    └── page.tsx

// WRONG: pages/ directory
pages/
├── _app.tsx
└── index.tsx
```

### Rule 5: No eslint-plugin-header

```json
// WRONG: .eslintrc.json
{
  "plugins": ["header"],
  "rules": {
    "header/header": ["error", "block", "..."]
  }
}
```

### Rule 6: Turborepo Monorepo

`turbo.json` 설정 필수:

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": { "dependsOn": ["^build"] },
    "dev": { "persistent": true },
    "lint": {},
    "test": {}
  }
}
```

### Rule 7: Functional Components Only

```typescript
// CORRECT
export function Button({ children }: ButtonProps) {
  return <button>{children}</button>;
}

// ALSO CORRECT
export const Button = ({ children }: ButtonProps) => {
  return <button>{children}</button>;
};

// WRONG
class Button extends React.Component { }
```

### Rule 8: Storybook

모든 UI 컴포넌트에 `.stories.tsx` 파일을 작성한다:

```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
};
export default meta;

type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { variant: 'primary', children: 'Click me' },
};
```

### Rule 9: Design Token

```css
/* CORRECT: Design Token 참조 */
.card {
  color: var(--color-text-primary);
  font-size: var(--font-size-md);
  border-radius: var(--radius-lg);
}

/* WRONG: 하드코딩 */
.card {
  color: #333333;
  font-size: 16px;
  border-radius: 8px;
}
```

### Rule 10: bun

```bash
# CORRECT
bun install
bun run build
bun run dev
bun add react

# WRONG
npm install
yarn add react
pnpm install
```

---

## 3. Project Init Script Reference

`scripts/init-project.sh`가 위 규칙을 준수하는 프로젝트 구조를 자동 생성한다:

```bash
# 실행
./scripts/init-project.sh <project-name>

# 생성되는 구조
<project-name>/
├── apps/web/           # Next.js App Router
├── packages/
│   ├── ui/             # Storybook included
│   ├── data/           # react-query setup
│   ├── domain/         # Types & business logic
│   ├── infrastructure/ # External adapters
│   ├── tokens/         # Design tokens (CSS custom properties)
│   └── config/         # ESLint, TypeScript configs
├── turbo.json          # Turborepo config
├── package.json        # bun workspace
├── bun.lockb
└── u-docs/             # SSoT document structure
    ├── 01-plan/
    ├── 02-design/
    ├── 03-dev/
    ├── 04-check/
    ├── 05-act/
    ├── assets/
    └── iterations/
```

---

## 4. Enforcement Mechanism

기술 스택 규칙은 `PreToolUse(Write|Edit)` hook에서 자동으로 검증된다:

1. 파일 생성/수정 시 hook이 내용을 분석
2. 위반 패턴 탐지 시 작업을 거부하고 에러 메시지 출력
3. 에이전트는 규칙을 준수하도록 코드를 수정한 후 재시도

검증 대상 패턴:

| Rule | Detection Pattern |
|------|-------------------|
| CSS-in-JS 금지 | `styled-components`, `@emotion`, `styled(` import |
| usecase 금지 | `UseCase`, `usecase` 파일명/클래스명 |
| Class 컴포넌트 금지 | `extends React.Component`, `extends Component` |
| Pages Router 금지 | `pages/` 디렉토리 내 파일 생성 |
| eslint-plugin-header 금지 | eslint 설정 내 `header` 플러그인 |
| npm/yarn 금지 | `package-lock.json`, `yarn.lock`, `.yarnrc` 생성 |
| 하드코딩 스타일 금지 | CSS 내 hex 색상코드, px 단위 직접 사용 (token 미참조) |
