---
document: "1_SRS_SA"
title: "{{PROJECT_NAME}} Software Requirements Specification"
owner: "u-SA"
status: "Draft"
version: "v0.1.0"
last_updated: "{{DATE}}"
related_docs:
  - "u-docs/01-plan/1_Roadmap_RA.md"
  - "u-docs/02-design/2_ERD_SA.md"
  - "u-docs/02-design/2_API_SA.md"
  - "u-docs/01-plan/1_Index_RA.md"
external_links: []
---

# {{PROJECT_NAME}} SRS

## 1. Background

### 1.1 Purpose

{{이 SRS 문서의 목적을 서술한다.}}

### 1.2 Scope

{{시스템 범위를 정의한다.}}

### 1.3 Definitions & Acronyms

| Term | Definition |
|------|-----------|
| {{용어}} | {{정의}} |

### 1.4 References

- `1_Roadmap_RA.md` — 프로젝트 로드맵 및 유저 스토리

---

## 2. Functional Requirements (FR)

> US Mapping은 Roadmap 작성 후 갱신 가능. Technical FR은 `-`로 표시.

| FR-ID | Feature | Description | Priority | US Mapping | Implemented |
|-------|---------|-------------|----------|------------|-------------|
| FR-001 | {{기능명}} | {{상세 설명}} | Must | US-001 | No |
| FR-002 | {{기능명}} | {{상세 설명}} | Must | US-002 | No |
| FR-003 | {{기능명}} | {{상세 설명}} | Should | TBD | No |
| FR-004 | {{기능명 (Technical)}} | {{상세 설명}} | Could | - | No |

### FR Details

#### FR-001: {{기능명}}

- **Description**: {{상세 설명}}
- **Input**: {{입력 데이터/조건}}
- **Output**: {{출력 결과}}
- **Business Rule**: {{비즈니스 규칙}}
- **Exception**: {{예외 케이스}}

#### FR-002: {{기능명}}

- **Description**: {{상세 설명}}
- **Input**: {{입력 데이터/조건}}
- **Output**: {{출력 결과}}
- **Business Rule**: {{비즈니스 규칙}}
- **Exception**: {{예외 케이스}}

---

## 3. Non-Functional Requirements (NFR)

| NFR-ID | Category | Requirement | Target | Priority |
|--------|----------|-------------|--------|----------|
| NFR-001 | Performance | {{요구사항}} | {{목표치}} | Must |
| NFR-002 | Security | {{요구사항}} | {{목표치}} | Must |
| NFR-003 | Usability | {{요구사항}} | {{목표치}} | Should |
| NFR-004 | Reliability | {{요구사항}} | {{목표치}} | Should |
| NFR-005 | Scalability | {{요구사항}} | {{목표치}} | Could |

---

## 4. Feature Dependency

```mermaid
flowchart TD
    FR001[FR-001: {{기능}}] --> FR002[FR-002: {{기능}}]
    FR001 --> FR003[FR-003: {{기능}}]
    FR002 --> FR004[FR-004: {{기능}}]
```

---

## 5. Gantt (Feature Timeline)

```mermaid
gantt
    title Feature Implementation Timeline
    dateFormat YYYY-MM-DD

    section Core
        FR-001 {{기능명}}  :f1, {{START_DATE}}, 5d
        FR-002 {{기능명}}  :f2, after f1, 5d

    section Extended
        FR-003 {{기능명}}  :f3, after f2, 3d
        FR-004 {{기능명}}  :f4, after f2, 3d
```

---

## 6. Acceptance Criteria Summary

| FR-ID | Acceptance Criteria |
|-------|-------------------|
| FR-001 | {{인수 조건 1}}, {{인수 조건 2}} |
| FR-002 | {{인수 조건 1}}, {{인수 조건 2}} |

---

## Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| v0.1.0 | {{DATE}} | u-SA | Initial draft |
