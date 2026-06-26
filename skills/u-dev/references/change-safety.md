# Change-Safety / Side-Effect Gatekeeping (ADVERSARIAL · 사용자 승인 필수)

**Purpose:** stop the dev pipeline from introducing **side-effects** (regressions, breakage of
dependent code, scope creep) when it **fixes a bug or changes an already-implemented feature / UI-UX**
— i.e. when it modifies code that is **already built and committed** *and that other code depends on*.
Forward construction (building something new, or iterating on a file that is still in progress) is
**not** gated, and neither is fixing a self-contained **leaf** file that nothing else imports (a fix
there cannot ripple into other features). Minimum bar when a fix *can* ripple = **explicit user
approval per already-implemented, depended-upon file change** ("최소 사용자에게 승인 / 물어보고 확인").

> **Policy (사용자 지시):** *"fix하는 경우에만 다른 기능이나 UI/UX에 사이드이펙트가 있을지 검토하고,
> 사이드이펙트가 있을 수 있는 경우에만 사용자에게 물어본다."* The native prompt fires **only** when a fix
> to committed code can actually regress dependents — not on every edit.

This protocol is the agent-side counterpart of the PreToolUse guard `hooks/on-edit-guard.js`.
The guard makes it **non-bypassable for risky fixes**: any Edit/Write/MultiEdit/Bash that mutates an
**already-implemented, depended-upon**, un-approved file in a u-maker project is forced to a native
user-approval prompt (`permissionDecision: "ask"`) that names the affected dependents. The Bash
coverage is broad — `sed -i` / `perl -i`, output redirects (incl. `1>` / `>|`), `rm` / `mv` /
`cp`-or-`tee`-or-`dd` **destinations**, `git rm` / `git checkout --` / `git restore`, and
**interpreter inline writes** (`python -c open(…, "w")`, `node -e fs.writeFileSync(…)`, etc.) — so you
cannot route a risky fix around the gate through the shell. Follow this protocol so approval is
**informed**, not a bare prompt.

### Gate mode — `U_MAKER_EDIT_GATE` (default `auto`)

| Mode | What gets gated |
| --- | --- |
| `auto` *(default)* | **Only already-implemented files that have dependents** — git-**tracked AND clean vs HEAD** AND imported/referenced by at least one other source file. New (untracked), in-progress (dirty/uncommitted), and **leaf** (no-dependent) files all pass freely. This is the "fix-with-real-blast-radius-only" policy. |
| `strict` | **Every existing file** (the pre-`4.0.0-alpha.24` always-on behavior; no implemented/dependent checks; `git apply`/`patch` also gated). Use for git-less projects or maximum caution. |
| `off` | Nothing — the side-effect gate is disabled. |

> **Boundary 1 (commit):** `auto` protects already-**committed** code. It does **not** guard
> uncommitted in-progress work (e.g. `git restore` on a dirty file) — commit to make work "implemented",
> or set `U_MAKER_EDIT_GATE=strict`.
>
> **Boundary 2 (import-graph heuristic):** the guard's "has dependents" check is an **import/require
> reverse-dependency scan** (`git grep`). Cross-feature contracts that are **not** expressed as imports
> — an **HTTP API route, a DB schema / migration, an env contract** — will NOT trip the guard even
> though other features depend on them. The guard stays silent there on purpose (to keep noise low);
> **you must still run §2 below for those public-surface changes** and `AskUserQuestion` when warranted.
> `git apply` / `patch` are likewise not gated in `auto` (their targets live in the patch body, so the
> blast radius is unknowable) — assess them yourself before applying.

---

## 1. Classify every target path: NEW · IN-PROGRESS · IMPLEMENTED (LEAF | SHARED)

- **NEW** — path does not exist on disk → create freely, **no gate**.
- **IN-PROGRESS** — exists but is **untracked** (never committed) or **dirty** (has uncommitted
  changes) → you are still building it → **no gate** in `auto`.
- **IMPLEMENTED** — exists, git-**tracked AND clean vs HEAD** (committed/shipped) → a change here is a
  **fix to already-built code**. Sub-classify by blast radius:
  - **IMPLEMENTED · LEAF** — **nothing imports/references it** (a standalone page / route / framework
    entry / test, or a module no one depends on) → a fix cannot side-effect *other* features →
    **no gate** in `auto`. Still make the smallest correct change, but no approval prompt is forced.
  - **IMPLEMENTED · SHARED** — **at least one other source file imports/references it** (a component,
    hook, util, type, client, token…) → a fix can regress those dependents → **gated** (edits,
    refactors, renames, deletions all gated). The guard names the dependents in its prompt.
- **Ambiguous** (symlink, generated-but-hand-edited) → treat as **IMPLEMENTED · SHARED** (default-deny posture).

`.u-maker/**` (SSoT docs / state) is out of scope here — it is managed by the doc/sync flows.

> **Reminder:** API routes / DB schema / env contracts are cross-feature surfaces the import-graph
> can't see (Boundary 2). Treat them as **SHARED** in your own analysis even though the guard stays
> silent, and `AskUserQuestion` when you change their public surface.

## 2. Impact / Blast-Radius Analysis — required per IMPLEMENTED · SHARED target

Run step 1 first: it both **classifies** LEAF vs SHARED and **drives** the gate. If the reverse-
dependency scan comes back empty (a true LEAF, and not a hidden API/DB/env contract per Boundary 2),
the file is not gated — make the smallest correct change and move on. If it has dependents (SHARED),
produce the full analysis BEFORE proposing the edit:

1. **Reverse dependencies** — `grep -rn` / import graph for who imports or calls the symbols you will change. **This is the gating signal** — dependents present ⇒ SHARED ⇒ gated.
2. **Public-surface delta** — are you changing an **exported signature, component prop, API route, DB column/schema, or env contract**? (these are the highest-risk, blast-radius-wide changes)
3. **Behavior delta** — what runtime behavior changes for existing callers? Any change in defaults, ordering, side-effects, error paths?
4. **Test/spec coverage** — which TC / tests / specs exercise this file? Are they still valid after the change?
5. **Necessity** — is this edit **strictly required** by the current spec delta or bug, or is it opportunistic (**scope creep**)?

> **Verdict defaults to UNSAFE** if any of the above is unknown or unverifiable.

## 3. Adversarial self-review

Argue **against** your own change: write the single worst plausible regression it could cause.
If you cannot rule it out with evidence (deps + tests), the verdict stays **UNSAFE** and the change
must be the **smallest reversible step** that fixes the issue — no drive-by refactors.

## 4. Approval gate — mandatory `AskUserQuestion` (default-deny) for IMPLEMENTED · SHARED

For each IMPLEMENTED · SHARED file (or, under `--auto`, one consolidated batch), present (LEAF files
skip this — they are not gated):

- file path · **NEW/IN-PROGRESS/IMPLEMENTED·LEAF/IMPLEMENTED·SHARED** · the exact intent + diff · blast-radius summary (who depends on it) · top regression risk · verdict

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
