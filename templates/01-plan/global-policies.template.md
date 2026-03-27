---
document: "1_GlobalPolicies_PM"
title: "{{PROJECT_NAME}} Global Policies"
owner: "u-agent-orchestrator"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - ".u-maker/docs/common/01-plan/1_Roadmap_PM.md"
  - ".u-maker/docs/common/01-plan/1_Common_RA.md"
external_links: []
---

# {{PROJECT_NAME}} Global Policies

## 1. Service Policies

### 1.1 Service Level Agreement (SLA)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Uptime | {{e.g., 99.9%}} | {{모니터링 도구}} |
| Response Time (P95) | {{e.g., < 500ms}} | {{측정 기준}} |
| Incident Response | {{e.g., P1: 15min, P2: 1h}} | {{에스컬레이션 절차}} |
| Data Recovery (RPO) | {{e.g., < 1h}} | {{백업 주기}} |
| Service Restoration (RTO) | {{e.g., < 4h}} | {{복구 절차}} |

### 1.2 Support Policy

| Item | Policy |
|------|--------|
| Support Hours | {{e.g., 24/7, 평일 09-18}} |
| Support Channels | {{e.g., 이메일, 채팅, 전화}} |
| Response SLA | {{우선순위별 응답 시간}} |
| Escalation Path | {{1차 → 2차 → 3차}} |

### 1.3 Data Policy

| Item | Policy |
|------|--------|
| Data Retention | {{e.g., 활성 데이터 1년, 아카이브 5년}} |
| Data Classification | {{e.g., Public, Internal, Confidential, Restricted}} |
| Backup Strategy | {{e.g., Daily incremental, Weekly full}} |
| Data Sovereignty | {{e.g., 국내 데이터센터 필수}} |

### 1.4 Compliance

| Standard | Status | Notes |
|----------|--------|-------|
| {{e.g., GDPR}} | {{Compliant / In Progress / N/A}} | {{비고}} |
| {{e.g., PIPA (개인정보보호법)}} | {{Compliant / In Progress / N/A}} | {{비고}} |

---

## 2. Development Policies

### 2.1 Coding Standards

| Area | Standard |
|------|----------|
| Language | {{e.g., TypeScript strict mode}} |
| Linter | {{e.g., ESLint + Prettier}} |
| Naming Convention | {{e.g., camelCase for vars, PascalCase for components}} |
| File Structure | {{e.g., feature-based, colocation}} |
| Max File Length | {{e.g., 300 lines recommended}} |

### 2.2 Code Review Policy

| Item | Policy |
|------|--------|
| Required Approvals | {{e.g., 최소 1명}} |
| Review SLA | {{e.g., PR 생성 후 24h 이내}} |
| Auto-merge Conditions | {{e.g., CI 통과 + 1 approve}} |
| Review Checklist | {{주요 체크 항목}} |

### 2.3 Branching Strategy

| Item | Policy |
|------|--------|
| Strategy | {{e.g., GitHub Flow, Git Flow}} |
| Branch Naming | {{e.g., feature/FT-XXXX-description}} |
| Protected Branches | {{e.g., main, develop}} |
| Merge Method | {{e.g., Squash and merge}} |

### 2.4 CI/CD Policy

| Stage | Tool | Policy |
|-------|------|--------|
| Build | {{e.g., Turbopack}} | {{빌드 실패 시 머지 차단}} |
| Test | {{e.g., Vitest + Playwright}} | {{커버리지 80% 이상}} |
| Deploy | {{e.g., Vercel}} | {{Preview → Staging → Production}} |
| Rollback | {{e.g., Vercel Rollback}} | {{자동 롤백 조건}} |

### 2.5 Dependency Management

| Item | Policy |
|------|--------|
| Package Manager | {{e.g., bun, pnpm}} |
| Update Frequency | {{e.g., 월 1회 minor, 분기 1회 major}} |
| Security Audit | {{e.g., npm audit, Snyk}} |
| License Policy | {{e.g., MIT, Apache 2.0 허용, GPL 금지}} |

---

## 3. Design Policies

### 3.1 Design Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | {{e.g., 일관성 (Consistency)}} | {{설명}} |
| 2 | {{e.g., 접근성 (Accessibility)}} | {{설명}} |
| 3 | {{e.g., 반응형 우선 (Mobile First)}} | {{설명}} |

### 3.2 Accessibility Standards

| Item | Standard |
|------|----------|
| WCAG Level | {{e.g., AA}} |
| Color Contrast | {{e.g., 4.5:1 minimum}} |
| Keyboard Navigation | {{e.g., 모든 인터랙션 키보드 접근 가능}} |
| Screen Reader | {{e.g., ARIA label 필수}} |
| Language | {{e.g., lang 속성 필수}} |

### 3.3 Branding Guidelines

| Item | Value |
|------|-------|
| Primary Color | {{e.g., #3B82F6}} |
| Typography | {{e.g., Pretendard (본문), Geist Mono (코드)}} |
| Logo Usage | {{로고 사용 규칙}} |
| Tone of Voice | {{e.g., 친근하고 전문적인}} |
| Iconography | {{e.g., Lucide Icons}} |

### 3.4 Responsive Design Policy

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | {{e.g., < 768px}} | {{single column}} |
| Tablet | {{e.g., 768px - 1023px}} | {{2 column}} |
| Desktop | {{e.g., >= 1024px}} | {{full layout}} |

### 3.5 Design Review Process

| Stage | Reviewer | Criteria |
|-------|----------|----------|
| Wireframe | {{e.g., PM + UX}} | {{IA 일치, 흐름 적절성}} |
| Visual Design | {{e.g., Design Lead}} | {{브랜드 가이드 준수, 접근성}} |
| Implementation | {{e.g., FE Lead}} | {{디자인 시스템 컴포넌트 활용}} |

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v0.1.0 | {{DATE}} | u-PM | Initial creation |
