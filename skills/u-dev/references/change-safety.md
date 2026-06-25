# Change-Safety / Side-Effect Gatekeeping (ADVERSARIAL · 사용자 승인 필수)

**Purpose:** stop the dev pipeline from introducing **side-effects** (regressions, breakage of
dependent code, scope creep) when it **fixes a bug or changes an already-implemented feature / UI-UX**
— i.e. when it modifies code that is **already built and committed**. Forward construction (building
something new, or iterating on a file that is still in progress) is **not** gated.
Minimum bar for a fix = **explicit user approval per already-implemented file change**
("최소 사용자에게 승인 / 물어보고 확인").

This protocol is the agent-side counterpart of the PreToolUse guard `hooks/on-edit-guard.js`.
The guard makes it **non-bypassable for fixes**: any Edit/Write/MultiEdit/Bash that mutates an
**already-implemented**, un-approved file in a u-maker project is forced to a native user-approval
prompt (`permissionDecision: "ask"`). The Bash coverage is broad — `sed -i` / `perl -i`, output
redirects (incl. `1>` / `>|`), `rm` / `mv` / `cp`-or-`tee`-or-`dd` **destinations**,
`git rm` / `git checkout --` / `git restore` / `git apply` / `patch`, and **interpreter inline
writes** (`python -c open(…, "w")`, `node -e fs.writeFileSync(…)`, etc.) — so you cannot route a fix
around the gate through the shell. Follow this protocol so approval is **informed**, not a bare prompt.

### Gate mode — `U_MAKER_EDIT_GATE` (default `auto`)

| Mode | What gets gated |
| --- | --- |
| `auto` *(default)* | **Only already-implemented files** — git-**tracked AND clean vs HEAD**. New (untracked) and in-progress (dirty/uncommitted) files pass freely. This is the "fix-only" policy. |
| `strict` | **Every existing file** (the pre-`4.0.0-alpha.24` always-on behavior). Use for git-less projects or maximum caution. |
| `off` | Nothing — the side-effect gate is disabled. |

> **Boundary:** `auto` protects already-**committed** code from regressions. It does **not** guard
> uncommitted in-progress work (e.g. `git restore` on a dirty file) — commit to make work "implemented",
> or set `U_MAKER_EDIT_GATE=strict`.

---

## 1. Classify every target path: NEW · IN-PROGRESS · IMPLEMENTED

- **NEW** — path does not exist on disk → create freely, **no gate**.
- **IN-PROGRESS** — exists but is **untracked** (never committed) or **dirty** (has uncommitted
  changes) → you are still building it → **no gate** in `auto`.
- **IMPLEMENTED** — exists, git-**tracked AND clean vs HEAD** (committed/shipped) → a change here is a
  **fix to already-built code** → **gated** (edits, refactors, renames, deletions all gated).
- **Ambiguous** (symlink, generated-but-hand-edited) → treat as **IMPLEMENTED** (default-deny posture).

`.u-maker/**` (SSoT docs / state) is out of scope here — it is managed by the doc/sync flows.

## 2. Impact / Blast-Radius Analysis — required per IMPLEMENTED target

Produce this BEFORE proposing the edit:

1. **Reverse dependencies** — `grep -rn` / import graph for who imports or calls the symbols you will change.
2. **Public-surface delta** — are you changing an **exported signature, component prop, API route, DB column/schema, or env contract**? (these are the highest-risk, blast-radius-wide changes)
3. **Behavior delta** — what runtime behavior changes for existing callers? Any change in defaults, ordering, side-effects, error paths?
4. **Test/spec coverage** — which TC / tests / specs exercise this file? Are they still valid after the change?
5. **Necessity** — is this edit **strictly required** by the current spec delta or bug, or is it opportunistic (**scope creep**)?

> **Verdict defaults to UNSAFE** if any of the above is unknown or unverifiable.

## 3. Adversarial self-review

Argue **against** your own change: write the single worst plausible regression it could cause.
If you cannot rule it out with evidence (deps + tests), the verdict stays **UNSAFE** and the change
must be the **smallest reversible step** that fixes the issue — no drive-by refactors.

## 4. Approval gate — mandatory `AskUserQuestion` (default-deny)

For each IMPLEMENTED file (or, under `--auto`, one consolidated batch), present:

- file path · **NEW/IN-PROGRESS/IMPLEMENTED** · the exact intent + diff · blast-radius summary · top regression risk · verdict

Options: **Approve** · **Approve all in batch** · **Skip this file** · **Abort run**.

- **No edit to already-implemented code is applied without an explicit Approve.**
- `--auto` / `--loop` may **batch** the questions but **never auto-approve** deletions, renames, or
  signature / schema / route changes. Bug-fix edits to implemented code **always** require an Approve.

## 5. Approval marker contract (consumed by `hooks/on-edit-guard.js`)

On **Approve**, before issuing the Edit/Write, record a marker so the guard authorizes the edit
(and subsequent same-session edits to that file) instead of re-prompting:

```
path:  .u-maker/.state/edit-approvals/<sha1(absolute_target_path)>.json
body:  { "path": "<abspath>", "approvedAt": "<iso8601>", "scope": "edit" | "delete", "reason": "<why>" }
```

- The filename hash is `sha1` of the **absolute** target path (hex).
- The guard accepts a marker whose **file mtime** is within the TTL
  (`U_MAKER_EDIT_APPROVAL_TTL_MIN`, default **480 min**). Re-`Write` the marker to refresh approval.
- Stale markers (older than TTL) are ignored → the gate asks again. Approval does **not** leak
  indefinitely or across long-idle sessions.

Create the marker with the `Write` tool or `mkdir -p .u-maker/.state/edit-approvals && cat > …`
(writes under `.u-maker/` are not gated). Compute the hash, e.g.:
`node -e 'console.log(require("crypto").createHash("sha1").update(process.argv[1]).digest("hex"))' "<abspath>"`.

## 6. Scope lock

Only **approved** paths may be touched. Touching an unapproved implemented file to "finish" a task is
**scope creep = hard FAIL** — raise a fresh approval for that file instead. Never widen a bug fix into
an unrequested refactor.

## 7. Relationship to `code-gen-rules.md` §7

This protocol **supersedes** the advisory §7.1 (`--force`) and §7.3 (three-options) guidance for
**already-implemented-code edits**: approval is **mandatory and default-deny** (in `auto`/`strict`),
not opt-in. `--force` alone is **never** sufficient to overwrite a committed file.
