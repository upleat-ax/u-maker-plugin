# router Reference

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

    // Step 3.5: Resolve aliases
    ALIASES = { "qa": "check" }
    if command in ALIASES:
        command = ALIASES[command]

    // Step 4: Parse options
    options = {
        auto: true,       // Default ON
        loop: false,      // Default OFF
        app: null,         // No default
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

### Known Commands

| Command | Full Form | Category |
|---------|-----------|----------|
| `init` | `/u-init` | Lifecycle |
| `ingest` | `/u-ingest` | Lifecycle |
| `plan` | `/u-plan` | Lifecycle |
| `design` | `/u-design` | Lifecycle |
| `dev` | `/u-dev` | Lifecycle |
| `check` | `/u-check` (alias: `/u-qa`) | Lifecycle |
| `ship` | `/u-ship` | Lifecycle |
| `add` | `/u-add` | Operations |
| `update` | `/u-update` | Operations |
| `doc` | `/u-doc` | Operations |
| `sync` | `/u-sync` | Operations |
| `gate` | `/u-gate` | Operations |
| `backlog` | `/u-backlog` | Backlog |
| `status` | `/u-status` | Observability |
| `coverage` | `/u-coverage` | Observability |
| `trace` | `/u-trace` | Observability |
| `discuss` | `/u-discuss` | Collaboration |
| `wireframe` | `/u-wireframe` | Design |
| `loop` | `/u-loop` | Automation |
| `report` | `/u-report` | Reporting |
| `git-pr` | `/u-git-pr` | Git |
| `reverse` | `/u-reverse` | Lifecycle |

## 2. Intent Classification

When the input is not a `/u-*` command, the router classifies intent from natural language.

### Classification Patterns

| Pattern | Detected Intent | Dispatches To |
|---------|----------------|---------------|
| "start project", "initialize", "new project" | `init` | u-agent-pm |
| "analyze input", "process files", "ingest data" | `ingest` | u-agent-plan |
| "create requirements", "write SRS", "plan phase" | `plan` | u-agent-plan |
| "design the system", "create ERD", "API design" | `design` | u-agent-design |
| "generate code", "implement", "build the app" | `dev` | u-agent-dev |
| "run tests", "test cases", "QA", "check phase" | `check` | u-agent-qa |
| "deploy", "release", "ship it" | `ship` | u-agent-pm |
| "add requirement", "add feature", "add user story" | `add` | u-agent-pm |
| "update FR-010", "modify screen", "change API" | `update` | u-agent-pm |
| "show status", "project status", "dashboard" | `status` | u-agent-pm |
| "show coverage", "trace coverage" | `coverage` | u-agent-pm |
| "trace FR-010", "where does this come from" | `trace` | u-agent-pm |
| "let's discuss", "brainstorm", "review session" | `discuss` | u-agent-pm |
| "wireframe", "mockup", "screen preview" | `wireframe` | u-agent-design |
| "auto loop", "run loop", "unattended" | `loop` | u-agent-pm |
| "generate report", "daily report" | `report` | u-agent-report |
| "create PR", "pull request" | `git-pr` | u-agent-pm |
| "reverse engineer", "analyze code", "code to docs", "extract from code" | `reverse` | u-agent-pm |

### Classification Algorithm

```
function classifyNaturalLanguage(input):
    lowered = input.toLowerCase()

    // Priority-ordered pattern matching
    patterns = [
        { keywords: ["initialize", "init", "start project", "new project", "setup"],
          intent: "init" },
        { keywords: ["ingest", "analyze input", "process files", "scan dropzone"],
          intent: "ingest" },
        { keywords: ["plan", "requirements", "srs", "information architecture"],
          intent: "plan" },
        { keywords: ["design", "erd", "api contract", "screen spec", "design system"],
          intent: "design" },
        { keywords: ["dev", "implement", "generate code", "build", "code gen"],
          intent: "dev" },
        { keywords: ["test", "check", "qa", "test case", "testcases"],
          intent: "check" },
        { keywords: ["ship", "deploy", "release"],
          intent: "ship" },
        { keywords: ["add requirement", "add feature", "add user story", "add fr", "add nfr"],
          intent: "add" },
        { keywords: ["update", "modify", "change", "edit"],
          intent: "update" },
        { keywords: ["status", "dashboard", "progress"],
          intent: "status" },
        { keywords: ["coverage"],
          intent: "coverage" },
        { keywords: ["trace", "traceability", "where does"],
          intent: "trace" },
        { keywords: ["discuss", "brainstorm", "review session", "workshop", "retro"],
          intent: "discuss" },
        { keywords: ["wireframe", "mockup", "screen preview", "ui preview"],
          intent: "wireframe" },
        { keywords: ["loop", "auto loop", "unattended", "run all phases"],
          intent: "loop" },
        { keywords: ["report", "daily report"],
          intent: "report" },
        { keywords: ["pull request", "pr", "merge request"],
          intent: "git-pr" },
        { keywords: ["reverse", "reverse-engineer", "reverse engineer", "code to docs",
                     "extract from code", "analyze existing code", "code analysis"],
          intent: "reverse" },
        { keywords: ["sync", "synchronize", "consistency"],
          intent: "sync" },
        { keywords: ["gate", "quality gate", "validate"],
          intent: "gate" },
    ]

    for each pattern in patterns:
        for each keyword in pattern.keywords:
            if lowered.contains(keyword):
                return { command: pattern.intent, confidence: "high", source: "natural-language" }

    // No match — ask user for clarification
    return { error: "unclassified", input, suggestion: "Try /u-status or /u-plan" }
```

### Confidence Levels

| Level | Meaning | Action |
|-------|---------|--------|
| `high` | Clear keyword match | Proceed with dispatch |
| `medium` | Partial match or ambiguous | Confirm with user before dispatch (unless `--auto`) |
| `low` | Weak signal | Ask user to clarify or use explicit `/u-*` command |

## 3. Agent Dispatch Mapping

Once intent is classified, the router dispatches to the appropriate agent.

### Dispatch Table

| Command | Primary Agent | Fallback |
|---------|--------------|----------|
| `init` | u-agent-pm | (none) |
| `ingest` | u-agent-plan | u-agent-pm |
| `plan` | u-agent-plan | u-agent-pm |
| `design` | u-agent-design | u-agent-pm |
| `dev` | u-agent-dev | u-agent-pm |
| `check` | u-agent-qa | u-agent-pm |
| `ship` | u-agent-pm | (none) |
| `add` | u-agent-pm | (none) |
| `update` | u-agent-pm | (none) |
| `doc` | u-agent-pm | (none) |
| `sync` | u-agent-pm | (none) |
| `gate` | u-agent-gatekeeper | u-agent-pm |
| `backlog` | u-agent-pm | (none) |
| `status` | u-agent-pm | (none) |
| `coverage` | u-agent-pm | (none) |
| `trace` | u-agent-pm | (none) |
| `discuss` | u-agent-pm (inline) | (none) |
| `wireframe` | u-agent-design | u-agent-pm |
| `loop` | u-agent-pm | (none) |
| `report` | u-agent-report | u-agent-pm |
| `git-pr` | u-agent-pm (inline) | (none) |
| `reverse` | u-agent-pm | (none) |

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

### Skill Mapping

| Command | Skill |
|---------|-------|
| `init` | u-init |
| `ingest` | u-plan (digest phase) |
| `plan` | u-plan |
| `design` | u-design |
| `dev` | u-dev |
| `check` | u-check |
| `ship` | (inline in u-agent-pm) |
| `add` | u-engine (doc-engine) |
| `update` | u-engine (doc-engine) |
| `doc` | u-engine (doc-engine) |
| `sync` | u-engine (dep-engine) |
| `gate` | u-check (validator) |
| `backlog` | u-plan (backlog) |
| `status` | (inline in u-agent-pm) |
| `coverage` | u-engine (dep-engine) |
| `trace` | u-engine (dep-engine) |
| `discuss` | u-discuss |
| `wireframe` | u-wireframe |
| `loop` | u-loop |
| `report` | u-engine (html-engine) |
| `git-pr` | u-git-pr |
| `reverse` | u-reverse |

### Prerequisites

| Command | Prerequisite | Error Message |
|---------|-------------|---------------|
| `prepare` | Write access to project root | "Cannot write to project root. Check permissions." |
| `analyze` | `.u-maker/` exists + dropzone has content | "Run /u-prepare-foldertree first, then add files to data/dropzone/." |
| `plan` | `data/digest/` populated | "Run /u-prepare (or /u-analyze) first." |
| `build` | Plan phase complete (SRS=Final, IA=Final) | "Run /u-plan first. SRS and IA must be Final." |
| `design` | Plan phase complete (SRS=Final, IA=Final) | "Run /u-plan first. SRS and IA must be Final." |
| `dev` | UIDesign sub-phase complete (ERD, API, Screens, Design System = Final) | "Run /u-design first. All design docs must be Final." |
| `gatekeeping` | Build phase complete (design docs Final + code generated) | "Run /u-build first. Design must be Final and code generated." |
| `deploy` | Gatekeeping avg ≥ 98 (deployReady: true) | "Run /u-gatekeeping --loop to reach docScore ≥ 98." |
| `wireframe` | Design sub-phase complete (Screens=Final) | "Run /u-design first. Screen spec must be Final." |
| `gate` | At least one document exists | "No documents to validate. Run a phase command first." |
| `report` | At least one document exists | "No documents to report on." |
| `reverse` | Project source code exists (at least one recognized stack indicator) | "No recognizable project stack found. Use --src, --db, --api, --pages to specify paths." |

## 4. Option Parsing

### Global Options

These options are available on ALL phase commands (prepare, plan, build, design, dev, gatekeeping, deploy).

| Option | Flag | Default | Description |
|--------|------|---------|-------------|
| Auto mode | `--auto` / `--no-auto` | ON | When ON, proceed without asking questions. When OFF, pause for user confirmation at key decision points. |
| Loop mode | `--loop [N]` | OFF (default N=5) | When ON, after phase completion, invoke u-agent-gatekeeper for scoring. N = number of criteria to validate (1-11, default 5). If avg < 95, re-invoke phase with improvement items. Max 3 iterations. |
| App target | `--app {name}` | (from config) | Target app name. If not specified, uses the default app from `u-maker.config.json`. If config has multiple apps, this is required. |

### Command-Specific Options

| Command | Option | Description |
|---------|--------|-------------|
| `/u-add` | `--type {FR\|NFR\|US\|FT\|SC\|TC\|ENT\|API}` | Item type to add |
| `/u-add` | `--to {docType}` | Target document (srs, erd, api, screens) |
| `/u-update` | `--id {ITEM-ID}` | Item ID to update (e.g., FR-010) |
| `/u-update` | `--force` | Force update even if document is Final |
| `/u-doc` | `--format {md\|json\|html}` | Output format when viewing |
| `/u-discuss` | `--type {brainstorm\|review\|decision\|workshop\|retro}` | Discussion session type |
| `/u-backlog` | `--action {add\|sprint\|prioritize\|groom\|move\|burn}` | Backlog sub-action |
| `/u-report` | `--daily` | Generate daily report |
| `/u-ingest` | `--force` | Re-analyze all files regardless of hash |
| `/u-assume` | `--action {approve\|reject\|list}` | Assumption management action |
| `/u-gate` | `--phase {plan\|design\|dev\|check}` | Specific phase to gate |
| `/u-reverse` | `--src {path}` | Source code root directory |
| `/u-reverse` | `--db {path}` | DB schema/migration path |
| `/u-reverse` | `--api {path}` | API route/controller path |
| `/u-reverse` | `--pages {path}` | Page/screen component path |
| `/u-coverage` | `--from {type}` | Source item type for coverage check |
| `/u-trace` | `--id {ITEM-ID}` | Item ID to trace |

### Option Parsing Example

```
Input:  /u-plan --app my-app --loop
Parsed: { command: "plan", options: { auto: true, loop: true, app: "my-app" }, args: [] }

Input:  /u-add --type FR --to srs "User authentication feature"
Parsed: { command: "add", options: { auto: true, loop: false, app: null, type: "FR", to: "srs" },
          args: ["User authentication feature"] }

Input:  /u-update --id FR-010 --force
Parsed: { command: "update", options: { auto: true, loop: false, app: null, id: "FR-010", force: true },
          args: [] }

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
            hint: "Run /u-status to see available commands."
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
