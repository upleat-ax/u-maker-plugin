# Session Types — Facilitation Guide

This reference provides detailed facilitation guides for each of the five discussion session types supported by u-discuss. Each guide covers phase structure, facilitation techniques, output format, and action item tracking.

## 1. Brainstorm Session

### 1.1 Purpose

Divergent ideation to generate as many ideas as possible around a topic. Brainstorm sessions prioritize quantity over quality, defer judgment, and encourage wild ideas.

### 1.2 Phase Structure

**Phase 1: Frame (2 min)**
- State the topic as a "How Might We" (HMW) question
- Example: "How might we reduce onboarding friction for new users?"
- Set ground rules: no criticism, build on others' ideas, quantity over quality
- Clarify scope boundaries (what is in/out of scope)

**Phase 2: Diverge (10-15 min)**
- Generate ideas freely — each idea gets a unique ID (IDEA-001, IDEA-002...)
- Use prompting techniques when flow slows:
  - "What if we had unlimited budget?"
  - "What would the opposite approach look like?"
  - "How would [industry X] solve this?"
  - "What if we removed [constraint]?"
- Record every idea without filtering

**Phase 3: Cluster (5 min)**
- Group related ideas into themes
- Name each cluster with a descriptive label
- Identify cross-cutting ideas that span multiple themes
- Typical cluster count: 3-7 themes

**Phase 4: Prioritize (5 min)**
- Score each cluster on two axes:
  - **Impact** (High/Medium/Low): How much does this move the needle?
  - **Effort** (High/Medium/Low): How hard is this to implement?
- Rank clusters by Impact/Effort ratio
- Select top 2-3 clusters for further exploration

**Phase 5: Capture (2 min)**
- Record final output (see format below)
- Assign action items for top-priority clusters
- Schedule follow-up if needed

### 1.3 Output Format

```markdown
# Brainstorm Summary

**Topic:** How might we reduce onboarding friction?
**Date:** 2026-04-03
**Participants:** [list]

## Ideas (27 total)

### Theme 1: Simplified Registration (8 ideas)
- IDEA-001: Social login (Google, GitHub) — Impact: H, Effort: L
- IDEA-002: Progressive profiling — Impact: H, Effort: M
- ...

### Theme 2: Interactive Tutorials (6 ideas)
- IDEA-009: Step-by-step wizard — Impact: M, Effort: M
- ...

## Priority Matrix

| Theme | Impact | Effort | Priority |
|-------|--------|--------|----------|
| Simplified Registration | High | Low | 1 |
| Interactive Tutorials | Medium | Medium | 2 |
| ...

## Action Items
- [ ] @pm: Draft US for social login — due 2026-04-05
- [ ] @design: Prototype wizard flow — due 2026-04-07
```

## 2. Review Session

### 2.1 Purpose

Structured review of a document, design artifact, or code. The goal is to identify issues, provide constructive feedback, and agree on improvements.

### 2.2 Phase Structure

**Phase 1: Context (3 min)**
- Present the artifact being reviewed
- State the review criteria (completeness, correctness, consistency, clarity)
- Define review scope (which sections/files to focus on)
- State what kind of feedback is most useful

**Phase 2: Walkthrough (10-15 min)**
- Walk through the artifact section by section
- For each section:
  - Presenter explains intent and key decisions
  - Reviewers ask clarifying questions
  - Reviewers note feedback items (tagged by severity)

**Phase 3: Feedback Collection (5-10 min)**
- Collect all feedback items
- Categorize each item:
  - **Must Fix**: Blocking issues that must be resolved before approval
  - **Should Fix**: Important improvements, non-blocking
  - **Consider**: Suggestions for future improvement
  - **Praise**: What works well (positive reinforcement)

**Phase 4: Resolution (5 min)**
- For each "Must Fix" item, agree on resolution approach
- For "Should Fix" items, decide: fix now vs. create backlog item
- For "Consider" items, note and archive
- Determine if re-review is needed after fixes

**Phase 5: Verdict (2 min)**
- Approve / Approve with conditions / Request changes / Reject
- Record verdict and conditions

### 2.3 Output Format

```markdown
# Review Summary

**Artifact:** SRS v2.1
**Date:** 2026-04-03
**Reviewer(s):** [list]
**Verdict:** Approve with conditions

## Feedback Items (12 total)

### Must Fix (3)
- [REV-001] FR-030 missing acceptance criteria — Section 3.3
- [REV-002] US-015 duplicates US-012 — Section 2.5
- [REV-003] ERD missing index on email column — Section 5.1

### Should Fix (4)
- [REV-004] Inconsistent naming: "user" vs "account" — Throughout
- ...

### Consider (3)
- [REV-007] Add rate limiting to all public endpoints
- ...

### Praise (2)
- [REV-010] Excellent traceability matrix coverage
- ...

## Conditions for Approval
1. Resolve all 3 "Must Fix" items
2. Re-review Section 3.3 after changes

## Action Items
- [ ] @author: Fix REV-001 through REV-003 — due 2026-04-04
- [ ] @reviewer: Re-review Section 3.3 — due 2026-04-05
```

## 3. Decision Session

### 3.1 Purpose

Structured decision-making when the team faces a choice between multiple options. Uses explicit criteria and scoring to reach a transparent, defensible decision.

### 3.2 Phase Structure

**Phase 1: Frame the Decision (3 min)**
- State the decision question clearly
- Example: "Which state management library should we adopt for the dashboard?"
- Identify who is the decision maker (RACI: who has the D)
- Set decision method: consensus, majority, or decision-maker final call

**Phase 2: Define Criteria (5 min)**
- List evaluation criteria (typically 4-7)
- Assign weights to each criterion (total = 100%)
- Example criteria: learning curve (20%), performance (25%), ecosystem (15%), bundle size (15%), TypeScript support (15%), community activity (10%)

**Phase 3: List Options (3 min)**
- Enumerate all viable options
- Briefly describe each option (1-2 sentences)
- Include "status quo" as an option if applicable

**Phase 4: Score Options (10 min)**
- For each option, score against each criterion (1-5 scale)
- Provide brief justification for each score
- Calculate weighted total
- Identify top 2-3 options

**Phase 5: Deliberate (5-10 min)**
- Discuss pros/cons of top options
- Surface risks, concerns, and unknowns
- Check for strong objections (any "over my dead body" reactions?)
- If new information surfaces, adjust scores

**Phase 6: Decide (2 min)**
- Announce the decision
- Record the rationale
- Document dissenting opinions (for future reference)
- Define next steps

### 3.3 Output Format

```markdown
# Decision Record

**Decision:** Which state management library for the dashboard?
**Date:** 2026-04-03
**Decision Maker:** @tech-lead
**Method:** Weighted scoring + decision-maker final call

## Criteria & Weights

| # | Criterion | Weight |
|---|----------|--------|
| 1 | Learning curve | 20% |
| 2 | Performance | 25% |
| 3 | Ecosystem | 15% |
| 4 | Bundle size | 15% |
| 5 | TypeScript support | 15% |
| 6 | Community activity | 10% |

## Options Evaluated

### Option A: Zustand
Lightweight, hook-based state management with minimal boilerplate.

### Option B: Jotai
Atomic state management with fine-grained reactivity.

### Option C: Redux Toolkit
Mature, feature-rich with strong ecosystem and devtools.

## Scoring Matrix

| Criterion (weight) | Zustand | Jotai | Redux Toolkit |
|-------------------|---------|-------|---------------|
| Learning curve (20%) | 5 | 4 | 2 |
| Performance (25%) | 4 | 5 | 3 |
| Ecosystem (15%) | 3 | 3 | 5 |
| Bundle size (15%) | 5 | 5 | 2 |
| TS support (15%) | 5 | 5 | 4 |
| Community (10%) | 4 | 3 | 5 |
| **Weighted Total** | **4.35** | **4.25** | **3.15** |

## Decision: Zustand

**Rationale:** Highest weighted score. Best learning curve and bundle size. Strong TypeScript support. Performance is excellent for our use case.

**Dissenting View:** @dev-2 preferred Jotai for finer-grained reactivity in complex dashboard widgets. Acknowledged but overridden by simplicity advantage.

## Action Items
- [ ] @tech-lead: Add Zustand to project dependencies — due 2026-04-04
- [ ] @tech-lead: Write state management guidelines — due 2026-04-05
- [ ] @team: Migrate existing useState patterns to Zustand — Sprint 3
```

## 4. Workshop Session

### 4.1 Purpose

Collaborative design and creation sessions where participants work together to produce a concrete artifact. Workshops are longer, more interactive, and produce tangible outputs.

### 4.2 Phase Structure

**Phase 1: Set the Stage (3 min)**
- State the workshop objective and expected deliverable
- Example: "Design the information architecture for the admin panel"
- Introduce any constraints or pre-existing decisions
- Distribute reference materials (user research, competitive analysis)

**Phase 2: Explore (10-15 min)**
- Examine the problem space together
- Review relevant data: user research findings, analytics, pain points
- Build shared understanding of the current state
- Map the landscape: stakeholders, touchpoints, data flows

**Phase 3: Create (15-20 min)**
- Collaborative artifact creation
- Work in iterations:
  - Rough draft (structure and skeleton)
  - First pass (fill in details)
  - Refinement (polish and consistency check)
- Types of artifacts produced:
  - Information Architecture (site map, navigation tree)
  - User flows (step-by-step journey)
  - Wireframes (layout and component placement)
  - Data models (entity relationships)
  - API contracts (endpoint definitions)

**Phase 4: Critique (5 min)**
- Review the created artifact against requirements
- Check for completeness: are all use cases covered?
- Check for consistency: do naming and patterns align?
- Identify gaps and open questions

**Phase 5: Refine & Close (5 min)**
- Address critical gaps from critique
- Mark open questions for follow-up
- Document the artifact in its final workshop-quality state
- Note: workshop output is a draft — it will be refined in the formal design phase

### 4.3 Output Format

```markdown
# Workshop Summary

**Objective:** Design information architecture for admin panel
**Date:** 2026-04-03
**Participants:** [list]
**Deliverable:** IA draft (site map + navigation structure)

## Artifact

[The actual artifact produced — e.g., IA tree, wireframe description, data model]

### Admin Panel IA

```
Admin Panel
├── Dashboard (overview metrics)
├── Users
│   ├── User List (search, filter, paginate)
│   ├── User Detail (profile, activity, permissions)
│   └── Invite User (form)
├── Content
│   ├── Posts (CRUD)
│   └── Categories (CRUD)
├── Settings
│   ├── General
│   ├── Billing
│   └── Integrations
└── Analytics
    ├── Usage
    └── Reports
```

## Open Questions
1. Should "Billing" be a top-level section or under Settings?
2. Do we need a separate "Audit Log" section?

## Action Items
- [ ] @designer: Create wireframes for Dashboard and User List — due 2026-04-07
- [ ] @pm: Resolve open questions with stakeholders — due 2026-04-05
- [ ] @analyst: Validate IA against user research findings — due 2026-04-06
```

## 5. Retro (Retrospective) Session

### 5.1 Purpose

Reflect on a completed sprint, phase, or milestone. Identify what went well, what needs improvement, and commit to specific actions for the next iteration. The retro uses a Keep/Problem/Try framework.

### 5.2 Phase Structure

**Phase 1: Set the Tone (2 min)**
- Remind participants of the Prime Directive: "Regardless of what we discover, we understand and truly believe that everyone did the best job they could, given what they knew at the time."
- State the retrospective scope (Sprint N, Phase X, Milestone Y)
- Review key metrics: velocity, pass rate, defect count, cycle time

**Phase 2: Gather Data (5-10 min)**
- Collect items in three categories:
  - **Keep**: What worked well? What should we continue doing?
  - **Problem**: What did not work? What caused friction or delays?
  - **Try**: What new approaches or experiments should we attempt?
- Each participant contributes items silently first, then shares
- Group similar items together

**Phase 3: Generate Insights (5-10 min)**
- For each Problem item, discuss root causes (use "5 Whys" technique)
- For each Keep item, identify how to reinforce and sustain it
- Prioritize: which problems have the highest impact to address?
- Connect problems to potential Try items

**Phase 4: Decide Actions (5 min)**
- Select top 2-3 action items (do not overcommit)
- Each action must be:
  - **Specific**: Clear what needs to happen
  - **Assigned**: One person accountable
  - **Time-bound**: Due date within the next sprint
  - **Measurable**: How do we know it worked?
- Record previous retro actions and their status (done, in-progress, dropped)

**Phase 5: Close (2 min)**
- Summarize decisions and actions
- Rate the retro itself (1-5): was this session useful?
- Thank participants

### 5.3 Output Format

```markdown
# Retrospective Summary

**Scope:** Sprint 4 (2026-03-18 to 2026-04-01)
**Date:** 2026-04-03
**Participants:** [list]

## Previous Action Items Status
- [x] Reduce PR review turnaround to < 24h — DONE (avg: 18h)
- [ ] Add integration tests for auth module — IN PROGRESS (60%)
- [ ] Set up monitoring dashboard — DROPPED (deprioritized)

## Keep (What worked well)
1. Daily async standups in Slack kept everyone aligned
2. Pair programming on complex features reduced bugs
3. SRS-first approach caught 5 design issues before coding
4. Deploy pipeline is fast and reliable (< 3 min)

## Problem (What needs improvement)
1. **Scope creep in Sprint 4** — 3 unplanned items added mid-sprint
   - Root cause: unclear priority framework for incoming requests
   - Impact: 2 planned items pushed to Sprint 5
2. **Flaky E2E tests** — 4 tests failed intermittently
   - Root cause: shared test database state between parallel tests
   - Impact: 2 hours debugging false failures
3. **Late design reviews** — Screen specs reviewed day before coding started
   - Root cause: design backlog not synced with sprint planning

## Try (Experiments for next sprint)
1. Implement "request triage" meeting on Monday to evaluate incoming requests
2. Isolate E2E test databases using per-test transactions
3. Design specs must be review-complete 2 days before sprint start

## Action Items
- [ ] @pm: Set up Monday triage meeting cadence — due 2026-04-07
- [ ] @dev: Implement per-test DB isolation in Playwright config — due 2026-04-10
- [ ] @design: Align design review schedule with sprint planning — due 2026-04-07

## Retro Rating: 4/5
```

## 6. Action Item Tracking

### 6.1 Action Item Structure

Every action item across all session types uses this consistent format:

```json
{
  "id": "ACT-001",
  "sessionId": "DISCUSS-2026-04-03-brainstorm",
  "sessionType": "brainstorm",
  "description": "Draft US for social login",
  "assignee": "@pm",
  "dueDate": "2026-04-05",
  "status": "open",
  "createdAt": "2026-04-03T10:00:00Z",
  "completedAt": null,
  "outcome": null
}
```

### 6.2 Status Values

| Status | Meaning |
|--------|---------|
| `open` | Assigned, not yet started |
| `in-progress` | Work has begun |
| `done` | Completed successfully |
| `dropped` | Deliberately abandoned with reason |
| `overdue` | Past due date, not completed |

### 6.3 Follow-Up Protocol

- Action items are reviewed at the start of the next session of the same type
- Overdue items require an explanation and a revised due date or explicit drop decision
- Done items are briefly celebrated (positive reinforcement)
- Dropped items are recorded with rationale to maintain institutional memory
- All action items feed into the project backlog when they represent work items
