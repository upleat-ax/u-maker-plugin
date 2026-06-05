# router Reference

> **Source of truth:** the command routing tables below mirror `agents/u-agent-pm.md` §2 (Command Routing Table) and §7 (Global aliases & forwarding). If they ever diverge, treat `u-agent-pm.md` as authoritative and update this file. The parsing, dispatch, and error-handling algorithms in this file are implementation patterns and remain stable across command-inventory changes.

The router is the entry point for all u-maker interactions. It parses `/u-*` commands and natural language input, classifies intent, dispatches to the appropriate agent, and handles option parsing and error cases.

## 1. /u-* Command Parsing

All u-maker commands follow a consistent syntax:

```
/u-{command} [options] [arguments]
```

### Command Syntax

```
/u-{command} [--auto] [--loop] [--app {name}] [additional args...]
```

### Parsing Algorithm

```
function parseCommand(input):
    // Step 1: Trim and normalize
    input = input.trim()

    // Step 2: Check if it starts with /u-
    if not input.startsWith("/u-"):
        return classifyNaturalLanguage(input)

    // Step 3: Tokenize
    tokens = tokenize(input)
    command = tokens[0].replace("/u-", "")

    // Step 3.5: Resolve aliases (PBGD v4.0)
    ALIASES = {
        "init": { canonical: "prepare" },
        "check": { canonical: "gatekeeping" },
        "qa": { canonical: "gatekeeping", inject: { only: "qa" } },
    }
    aliasInject = {}
    if command in ALIASES:
        aliasInject = ALIASES[command].inject or {}
        command = ALIASES[command].canonical

    // Step 4: Parse options
    options = {
        auto: true,       // Default ON
        loop: false,      // Default OFF
        app: null,         // No default
        ...aliasInject,   // e.g., `/u-qa` injects { only: "qa" }
    }
    args = []

    i = 1
    while i < tokens.length:
        token = tokens[i]
        if token == "--auto":
            options.auto = true
        else if token == "--no-auto":
            options.auto = false
        else if token == "--loop":
            options.loop = true
            // Check if next token is a number (criteria count)
            if tokens[i+1] and isNumeric(tokens[i+1]):
                i++
                options.loopCriteria = parseInt(tokens[i])  // 1-11, default 5
            else:
                options.loopCriteria = 5  // default
        else if token == "--app":
            i++
            options.app = tokens[i]
        else if token.startsWith("--"):
            // Command-specific option
            options[token.replace("--", "")] = tokens[i+1] or true
            if not tokens[i+1]?.startsWith("--"):
                i++
        else:
            args.push(token)
        i++

    // Step 5: Validate command
    if command not in KNOWN_COMMANDS:
        return { error: "unknown-command", command, suggestions: findSimilar(command) }

    return {
        command: command,
        options: options,
        args: args
    }
```

### Known Commands (PBGD v4.0)

| Command | Full Form | PBGD Phase | Category |
|---------|-----------|-----------|----------|
| `prepare` | `/u-prepare` | Plan.Prepare (umbrella) | Phase |
| `init` | `/u-init` → `/u-prepare` | Plan.Prepare | Alias |
| `prepare-foldertree` | `/u-prepare-foldertree` | Plan.Prepare (granular) | Phase |
| `analyze` | `/u-analyze` | Plan.Prepare (analysis) | Phase |
| `reverse` | `/u-reverse` | Plan.Prepare (reverse) | Phase |
| `tools-figma` | `/u-tools-figma` | Plan.Prepare (figma) | Tool |
| `plan` | `/u-plan` | Plan.Plan | Phase |
| `wireframe` | `/u-wireframe` | Build.UIDesign (companion) | Phase |
| `build` | `/u-build` | Build (umbrella) | Phase |
| `design` | `/u-design` | Build.UIDesign | Phase |
| `dev` | `/u-dev` | Build.Development | Phase |
| `gatekeeping` | `/u-gatekeeping` | Gatekeeping (umbrella) | Phase |
| `check` | `/u-check` → `/u-gatekeeping` | Gatekeeping | Alias |
| `qa` | `/u-qa` → `/u-gatekeeping --only qa` | Gatekeeping.RuntimeQA | Alias |
| `deploy` | `/u-deploy` | Deploy | Phase |
| `loop` | `/u-loop` | Cross-phase | Automation |
| `discuss` | `/u-discuss` | Any | Collaboration |
| `tools-git-pr` | `/u-tools-git-pr` | Any | Tool |
| `output` | `/u-output` | Cross-cutting | Rendering |
| `report` | `/u-report --daily` / `--weekly` | Any | Reporting |
| `reports-roadmap` | `/u-reports-roadmap` | Any | Reporting |
| `createproject` | `/u-createproject` | Any | Scaffolding |
| `engine` | `/u-engine` | Any | Internal |

## 2. Intent Classification

When the input is not a `/u-*` command, the router classifies intent from natural language.

### Classification Patterns

| Pattern | Detected Intent | Dispatches To |
|---------|----------------|---------------|
| "prepare", "start project", "initialize", "new project", "setup u-maker" | `prepare` | u-agent-plan |
| "foldertree", "scaffold .u-maker", "only folders" | `prepare-foldertree` | u-agent-plan |
| "analyze dropzone", "process files", "rescan data", "generate digest" | `analyze` | u-agent-plan |
| "reverse engineer", "code to docs", "extract docs from code", "analyze existing code" | `reverse` | u-agent-plan |
| "figma", "analyze figma", "figma.com" | `tools-figma` | u-agent-figma |
| "plan phase", "write SRS", "generate IA", "requirements" | `plan` | u-agent-plan |
| "wireframe", "mockup", "screen preview" | `wireframe` | u-agent-plan |
| "build phase", "design + dev", "run build", "ping-pong design dev" | `build` | u-agent-build |
| "design the system", "create ERD", "API contract", "screen spec", "design system" | `design` | u-agent-design |
| "generate code", "implement", "build frontend/backend", "code gen" | `dev` | u-agent-dev |
| "gatekeep", "quality gate", "score documents", "run tests", "test cases", "QA" | `gatekeeping` | u-agent-gatekeeper + u-agent-qa |
| "deploy", "release", "ship", "CI/CD", "generate pipeline" | `deploy` | u-agent-deploy |
| "auto loop", "run loop", "unattended", "run all phases" | `loop` | u-agent-pm |
| "let's discuss", "brainstorm", "review session", "decision session" | `discuss` | u-agent-pm |
| "create PR", "pull request", "open PR" | `tools-git-pr` | u-agent-pm |
| "generate HTML", "render output", "rebuild HTML" | `output` | u-agent-pm |
| "daily report", "weekly report", "generate report" | `report` | u-agent-report |
| "roadmap", "gantt roadmap", "estimate timeline", "로드맵", "일정 산정" | `reports-roadmap` | u-agent-report |
| "create project", "new monorepo", "scaffold project" | `createproject` | u-agent-pm |

### Classification Algorithm

```
function classifyNaturalLanguage(input):
    lowered = input.toLowerCase()

    // Priority-ordered pattern matching (PBGD v4.0)
    patterns = [
        { keywords: ["prepare", "initialize", "init", "start project", "new project", "setup u-maker"],
          intent: "prepare" },
        { keywords: ["foldertree", "scaffold .u-maker", "only folders"],
          intent: "prepare-foldertree" },
        { keywords: ["analyze", "process files", "scan dropzone", "rescan data", "generate digest"],
          intent: "analyze" },
        { keywords: ["reverse", "reverse-engineer", "reverse engineer", "code to docs",
                     "extract from code", "analyze existing code", "code analysis"],
          intent: "reverse" },
        { keywords: ["figma", "figma.com", "analyze figma", "extract figma"],
          intent: "tools-figma" },
        { keywords: ["plan", "requirements", "srs", "information architecture", "ia"],
          intent: "plan" },
        { keywords: ["wireframe", "mockup", "screen preview", "ui preview"],
          intent: "wireframe" },
        { keywords: ["build phase", "ping-pong", "design dev", "run build"],
          intent: "build" },
        { keywords: ["design", "erd", "api contract", "screen spec", "design system"],
          intent: "design" },
        { keywords: ["dev", "implement", "generate code", "code gen", "frontend", "backend"],
          intent: "dev" },
        { keywords: ["gatekeep", "gatekeeping", "quality gate", "score documents",
                     "test", "check", "qa", "test case", "testcases"],
          intent: "gatekeeping" },
        { keywords: ["deploy", "release", "ship", "ci/cd", "generate pipeline"],
          intent: "deploy" },
        { keywords: ["loop", "auto loop", "unattended", "run all phases"],
          intent: "loop" },
        { keywords: ["discuss", "brainstorm", "review session", "workshop", "retro", "decision session"],
          intent: "discuss" },
        { keywords: ["pull request", "create pr", "open pr", "merge request"],
          intent: "tools-git-pr" },
        { keywords: ["generate html", "render output", "rebuild html", "regenerate output"],
          intent: "output" },
        { keywords: ["daily report", "weekly report", "generate report"],
          intent: "report" },
        { keywords: ["roadmap", "gantt roadmap", "estimate timeline", "로드맵", "일정 산정"],
          intent: "reports-roadmap" },
        { keywords: ["create project", "new monorepo", "scaffold project"],
          intent: "createproject" },
    ]

    for each pattern in patterns:
        for each keyword in pattern.keywords:
            if lowered.contains(keyword):
                return { command: pattern.intent, confidence: "high", source: "natural-language" }

    // No match — ask user for clarification
    return { error: "unclassified", input, suggestion: "Try /u-prepare or /u-plan" }
```

### Confidence Levels

| Level | Meaning | Action |
|-------|---------|--------|
| `high` | Clear keyword match | Proceed with dispatch |
| `medium` | Partial match or ambiguous | Confirm with user before dispatch (unless `--auto`) |
| `low` | Weak signal | Ask user to clarify or use explicit `/u-*` command |

## 3. Agent Dispatch Mapping

Once intent is classified, the router dispatches to the appropriate agent.

### Dispatch Table (PBGD v4.0)

| Command | Primary Agent | Fallback |
|---------|--------------|----------|
| `prepare` | u-agent-plan | u-agent-pm |
| `prepare-foldertree` | u-agent-plan | u-agent-pm |
| `analyze` | u-agent-plan | u-agent-pm |
| `reverse` | u-agent-plan | u-agent-pm |
| `tools-figma` | u-agent-figma | u-agent-plan |
| `plan` | u-agent-plan | u-agent-pm |
| `wireframe` | u-agent-plan | u-agent-pm |
| `build` | u-agent-build | u-agent-pm |
| `design` | u-agent-design | u-agent-build |
| `dev` | u-agent-dev | u-agent-build |
| `gatekeeping` | u-agent-gatekeeper + u-agent-qa | u-agent-pm |
| `deploy` | u-agent-deploy | u-agent-pm |
| `loop` | u-agent-pm (orchestrates all) | (none) |
| `discuss` | u-agent-pm (inline) | (none) |
| `tools-git-pr` | u-agent-pm (inline) | (none) |
| `output` | u-agent-pm (inline via doc-engine) | (none) |
| `report` | u-agent-report | u-agent-pm |
| `reports-roadmap` | u-agent-report | u-agent-pm |
| `createproject` | u-agent-pm (inline) | (none) |
| `engine` | u-agent-pm (inline) | (none) |

### Dispatch Algorithm

```
function dispatch(parsed):
    if parsed.error:
        return handleError(parsed)

    agent = DISPATCH_TABLE[parsed.command].primaryAgent
    skill = SKILL_MAP[parsed.command]

    // Check prerequisites
    prereq = checkPrerequisites(parsed.command)
    if prereq.failed:
        return {
            error: "prerequisite-failed",
            message: prereq.message,
            suggestion: prereq.suggestion
        }

    // Build dispatch payload
    payload = {
        command: parsed.command,
        options: parsed.options,
        args: parsed.args,
        skill: skill,
        agent: agent
    }

    return payload
```

### Skill Mapping (PBGD v4.0)

| Command | Skill |
|---------|-------|
| `prepare` | u-prepare |
| `prepare-foldertree` | u-prepare-foldertree |
| `analyze` | u-analyze |
| `reverse` | u-reverse |
| `tools-figma` | u-tools-figma |
| `plan` | u-plan |
| `wireframe` | u-wireframe |
| `build` | u-build |
| `design` | u-design |
| `dev` | u-dev |
| `gatekeeping` | u-gatekeeping |
| `deploy` | u-deploy |
| `loop` | u-loop |
| `discuss` | u-discuss |
| `tools-git-pr` | u-tools-git-pr |
| `output` | u-output |
| `report` | u-engine (html-engine) via u-agent-report |
| `reports-roadmap` | u-reports-roadmap |
| `createproject` | u-createproject |
| `engine` | u-engine |

### Prerequisites (PBGD v4.0)

| Command | Prerequisite | Error Message |
|---------|-------------|---------------|
| `prepare` | Write access to project root | "Cannot write to project root. Check permissions." |
| `prepare-foldertree` | Write access to project root | "Cannot write to project root. Check permissions." |
| `analyze` | `.u-maker/` exists + dropzone has content | "Run /u-prepare-foldertree first, then add files to data/dropzone/." |
| `reverse` | Project source code exists (at least one recognized stack indicator) | "No recognizable project stack found. Use --src, --db, --api, --pages to specify paths." |
| `tools-figma` | Figma URL or source reference provided | "No Figma source detected. Pass a figma.com URL or add it to the dropzone." |
| `plan` | `data/digest/` populated | "Run /u-prepare (or /u-analyze) first." |
| `wireframe` | Plan sub-phase complete (Screens=Final after /u-design) | "Run /u-design first. Screen spec must be Final." |
| `build` | Plan phase complete (SRS=Final, IA=Final) | "Run /u-plan first. SRS and IA must be Final." |
| `design` | Plan phase complete (SRS=Final, IA=Final) | "Run /u-plan first. SRS and IA must be Final." |
| `dev` | UIDesign sub-phase complete (ERD, API, Screens, Design System = Final) | "Run /u-design first. All design docs must be Final." |
| `gatekeeping` | Build phase complete (design docs Final + code generated) | "Run /u-build first. Design must be Final and code generated." |
| `deploy` | Gatekeeping avg ≥ 98 (deployReady: true) | "Run /u-gatekeeping --loop to reach docScore ≥ 98." |
| `report` | At least one document exists | "No documents to report on." |
| `reports-roadmap` | Project source code + git history exists | "No source/git found. /u-reports-roadmap scans code+git to scope a roadmap." |

## 4. Option Parsing

### Global Options

These options are available on ALL phase commands (prepare, plan, build, design, dev, gatekeeping, deploy).

| Option | Flag | Default | Description |
|--------|------|---------|-------------|
| Auto mode | `--auto` / `--no-auto` | ON | When ON, proceed without asking questions. When OFF, pause for user confirmation at key decision points. |
| Loop mode | `--loop [N]` | OFF (default N=5) | When ON, after phase completion, invoke u-agent-gatekeeper for scoring. N = number of criteria to validate (1-11, default 5). If avg < 95, re-invoke phase with improvement items. Max 3 iterations. |
| App target | `--app {name}` | (from config) | Target app name. If not specified, uses the default app from `u-maker.config.json`. If config has multiple apps, this is required. |

### Command-Specific Options (PBGD v4.0)

| Command | Option | Description |
|---------|--------|-------------|
| `/u-prepare` | `--scenario {new\|existing}` | Skip scenario detection and pick Prepare flow explicitly |
| `/u-analyze` | `--force` | Re-analyze all dropzone files regardless of hash |
| `/u-reverse` | `--src {path}` | Source code root directory |
| `/u-reverse` | `--db {path}` | DB schema/migration path |
| `/u-reverse` | `--api {path}` | API route/controller path |
| `/u-reverse` | `--pages {path}` | Page/screen component path |
| `/u-tools-figma` | `--url {figma-url}` | Explicit Figma file URL |
| `/u-plan` | `--wireframe` | Auto-run `/u-wireframe` after Plan completes |
| `/u-wireframe` | `--screen {screen-id}` | Restrict rendering to a single screen |
| `/u-build` | `--max-rounds {N}` | Override max ping-pong rounds between `/u-design` and `/u-dev` |
| `/u-gatekeeping` | `--only {docs\|qa}` | Run only the doc-scoring or runtime-QA sub-phase |
| `/u-gatekeeping` | `--criteria {N}` | Number of doc-scoring criteria (1–11; default 5). Equivalent to `--loop N` |
| `/u-deploy` | `--target {vercel\|docker\|github-actions\|...}` | Deployment target platform |
| `/u-deploy` | `--artifacts {ci\|config\|scripts\|runbook\|env\|release-notes\|smoke-tests}` | Artifact scope (comma-separated) |
| `/u-deploy` | `--watch` | Continuous regeneration on SSoT hash changes |
| `/u-discuss` | `--type {brainstorm\|review\|decision\|workshop\|retro}` | Discussion session type |
| `/u-report` | `--daily` / `--weekly` | Report cadence |
| `/u-tools-git-pr` | `--group {auto\|single}` | Grouping mode for multi-domain PR splitting |

### Option Parsing Example

```
Input:  /u-plan --app my-app --loop
Parsed: { command: "plan", options: { auto: true, loop: true, app: "my-app" }, args: [] }

Input:  /u-gatekeeping --only qa --app my-app
Parsed: { command: "gatekeeping", options: { auto: true, loop: false, app: "my-app", only: "qa" },
          args: [] }

Input:  /u-qa --app my-app
Parsed: { command: "gatekeeping", options: { auto: true, loop: false, app: "my-app", only: "qa" },
          args: [] }
// `qa` resolved via alias → `gatekeeping --only qa`

Input:  /u-deploy --target vercel --artifacts ci,config
Parsed: { command: "deploy", options: { auto: true, loop: false, app: null, target: "vercel",
          artifacts: "ci,config" }, args: [] }

Input:  /u-discuss --type brainstorm "API architecture"
Parsed: { command: "discuss", options: { auto: true, loop: false, app: null, type: "brainstorm" },
          args: ["API architecture"] }
```

## 5. Error Handling

### Unknown Command

When a command is not recognized:

```
function handleUnknownCommand(command):
    similar = findSimilarCommands(command, KNOWN_COMMANDS, threshold: 0.6)

    if similar.length > 0:
        return {
            error: "unknown-command",
            message: "Unknown command: /u-{command}",
            suggestions: similar.map(s => "/u-{s}"),
            hint: "Did you mean: {similar[0]}?"
        }
    else:
        return {
            error: "unknown-command",
            message: "Unknown command: /u-{command}",
            suggestions: [],
            hint: "Run /u-prepare to start a new project, or see agents/u-agent-pm.md §2 for the full command list."
        }
```

### Similarity Matching

Use Levenshtein distance to find similar commands:

```
function findSimilarCommands(input, knownCommands, threshold):
    results = []
    for each cmd in knownCommands:
        distance = levenshtein(input, cmd)
        similarity = 1 - (distance / max(input.length, cmd.length))
        if similarity >= threshold:
            results.push({ command: cmd, similarity })
    return results.sortBy(r => r.similarity, descending).take(3)
```

### Missing Prerequisites

When a command's prerequisites are not met:

```
function handlePrerequisiteFailed(command, prereq):
    return {
        error: "prerequisite-failed",
        command: command,
        message: prereq.message,
        requiredPhase: prereq.requiredPhase,
        currentPhase: getCurrentPhase(),
        suggestion: "Run /u-{prereq.requiredCommand} first."
    }
```

### Missing Required Options

When a required option is missing:

```
function handleMissingOption(command, option):
    return {
        error: "missing-option",
        command: command,
        option: option,
        message: "The --{option} flag is required for /u-{command}.",
        usage: getUsage(command)
    }
```

### App Ambiguity

When `--app` is not specified and the config has multiple apps:

```
function handleAppAmbiguity(apps):
    return {
        error: "app-ambiguous",
        message: "Multiple apps configured. Specify --app {name}.",
        availableApps: apps,
        usage: "/u-plan --app {apps[0]}"
    }
```

## 6. Dispatch Flow Summary

The complete routing flow from input to agent invocation:

```
User Input
    │
    ├── Starts with /u-* ?
    │   ├── Yes → parseCommand()
    │   │         ├── Known command? → checkPrerequisites() → dispatch()
    │   │         └── Unknown? → handleUnknownCommand()
    │   └── No  → classifyNaturalLanguage()
    │             ├── High confidence → dispatch()
    │             ├── Medium confidence → confirm with user (unless --auto)
    │             └── Low / unclassified → ask user to clarify
    │
    ▼
dispatch()
    │
    ├── Resolve target agent from DISPATCH_TABLE
    ├── Resolve skill from SKILL_MAP
    ├── Validate options
    ├── Check prerequisites
    │   ├── PASS → invoke agent with payload
    │   └── FAIL → return prerequisite error
    │
    ▼
Agent Execution
    │
    ├── Agent uses skill references for domain logic
    ├── Agent uses u-engine for cross-cutting concerns
    └── Results returned to u-agent-pm for state tracking
```
