---
document: "3_DesignToken_UX"
title: "{{PROJECT_NAME}} Design Tokens"
owner: "u-UX"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/02-design/2_DesignSystem_UX.md"
  - "u-docs/03-dev/3_UIComponents_UX.md"
  - "u-docs/03-dev/3_Code_DV.md"
  - "u-docs/01-plan/1_Index_RA.md"
external_links: []
---

# {{PROJECT_NAME}} Design Tokens

## 1. Overview

### 1.1 Purpose

{{디자인 토큰 문서의 목적. packages/tokens에 정의할 CSS Custom Properties를 명세한다.}}

### 1.2 Token Path

```
packages/tokens/src/
├── colors.css          # 색상 토큰
├── typography.css      # 타이포그래피 토큰
├── spacing.css         # 간격 토큰
├── borders.css         # 테두리 토큰
├── shadows.css         # 그림자 토큰
├── motion.css          # 애니메이션 토큰
└── index.css           # 전체 import
```

---

## 2. Color Tokens

### 2.1 colors.css

```css
:root {
  /* Brand */
  --color-primary: {{VALUE}};
  --color-primary-hover: {{VALUE}};
  --color-primary-active: {{VALUE}};
  --color-secondary: {{VALUE}};
  --color-accent: {{VALUE}};

  /* Semantic */
  --color-success: {{VALUE}};
  --color-warning: {{VALUE}};
  --color-error: {{VALUE}};
  --color-info: {{VALUE}};

  /* Neutral */
  --color-bg-primary: {{VALUE}};
  --color-bg-secondary: {{VALUE}};
  --color-bg-tertiary: {{VALUE}};
  --color-text-primary: {{VALUE}};
  --color-text-secondary: {{VALUE}};
  --color-text-disabled: {{VALUE}};
  --color-border: {{VALUE}};
  --color-border-focus: {{VALUE}};
}
```

---

## 3. Typography Tokens

### 3.1 typography.css

```css
:root {
  /* Font Family */
  --font-sans: {{VALUE}};
  --font-mono: {{VALUE}};

  /* Font Size */
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-xl: 1.25rem;
  --text-2xl: 1.5rem;
  --text-3xl: 1.875rem;
  --text-4xl: 2.25rem;

  /* Font Weight */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;

  /* Line Height */
  --leading-tight: 1.2;
  --leading-normal: 1.5;
  --leading-relaxed: 1.75;
}
```

---

## 4. Spacing Tokens

### 4.1 spacing.css

```css
:root {
  --space-px: 1px;
  --space-0: 0;
  --space-1: 0.25rem;   /* 4px */
  --space-2: 0.5rem;    /* 8px */
  --space-3: 0.75rem;   /* 12px */
  --space-4: 1rem;      /* 16px */
  --space-5: 1.25rem;   /* 20px */
  --space-6: 1.5rem;    /* 24px */
  --space-8: 2rem;      /* 32px */
  --space-10: 2.5rem;   /* 40px */
  --space-12: 3rem;     /* 48px */
  --space-16: 4rem;     /* 64px */
}
```

---

## 5. Border Tokens

### 5.1 borders.css

```css
:root {
  /* Border Radius */
  --radius-none: 0;
  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
  --radius-full: 9999px;

  /* Border Width */
  --border-0: 0;
  --border-1: 1px;
  --border-2: 2px;
}
```

---

## 6. Shadow Tokens

### 6.1 shadows.css

```css
:root {
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.15);
}
```

---

## 7. Motion Tokens

### 7.1 motion.css

```css
:root {
  --duration-fast: 150ms;
  --duration-normal: 250ms;
  --duration-slow: 400ms;
  --easing-default: ease-in-out;
  --easing-in: ease-in;
  --easing-out: ease-out;
}
```

---

## 8. Theme Support

### 8.1 Dark Theme (Optional)

```css
[data-theme="dark"] {
  --color-bg-primary: {{VALUE}};
  --color-bg-secondary: {{VALUE}};
  --color-text-primary: {{VALUE}};
  --color-text-secondary: {{VALUE}};
  --color-border: {{VALUE}};
}
```

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-UX | Initial draft |
