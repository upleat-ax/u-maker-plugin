#!/usr/bin/env node
// on-edit-guard.js — u-maker Side-Effect Gatekeeping (PreToolUse)
//
// GOAL: protect against silent side-effects (regressions) when the pipeline MODIFIES code that is
// already built — i.e. a **bug fix or a change to an already-implemented feature / UI-UX** — but ONLY
// when that change can actually ripple into OTHER features / UI. It must never nag during forward
// construction, and it must not nag when fixing a self-contained (leaf) file that nothing depends on.
//
// THREE signals are required (when the gate is enabled via `on`/`auto`; it is OFF by default) before we ask the user:
//   (A) ALREADY-IMPLEMENTED — detected via git, no intent flag:
//         • git-TRACKED and CLEAN vs HEAD → committed/shipped code → a change is a FIX → candidate.
//         • UNTRACKED (new) or DIRTY (uncommitted) → still being built → ALLOW (forward construction).
//   (B) HAS DEPENDENTS — other source files import/reference this module. If something depends on it,
//         a fix here can regress those dependents → a real cross-feature side-effect → candidate.
//         If NOTHING imports it (a leaf: a standalone page / route / entry / test), a fix cannot
//         side-effect other features → ALLOW silently.
//   (C) MODIFIES EXISTING CODE — the edit changes/removes existing lines, not just ADDS new ones.
//         A purely ADDITIVE edit (the new content keeps every existing line verbatim — e.g. a new
//         function / branch / import inserted around untouched code) leaves what dependents rely on
//         intact → it cannot regress them → ALLOW silently, even in a shared file. Only a MODIFYING
//         edit (existing behavior rewritten/deleted) is a real fix-with-blast-radius → ASK.
//         Edit/MultiEdit: additive iff every new_string contains its old_string verbatim. Write:
//         additive iff the new content contains the whole existing file verbatim (append/prepend/wrap).
//         Bash mutations (sed -i / redirect / rm / mv / …) are inherently modifying → always candidate.
// "fix하는 경우에만 다른 기능이나 UI/UX에 사이드이펙트가 있을지 검토하고, 있을 수 있는 경우에만 물어본다."
// (A) = "fix하는 경우", (B)+(C) = "사이드이펙트가 있을 수 있는 경우" (의존성 + 기존 동작 변경 검토).
//
// Boundary 3 (additive-edit heuristic): an INSERTION that still alters runtime behavior for existing
// callers (e.g. an early `return` spliced into a function) reads as additive here and passes silently.
// That residual semantic risk is the AGENT's to catch in the /u-dev Step 0.5 behavior-delta review;
// use `strict` to gate every modify+add to existing files regardless.
//
// NOTE on coverage: (B) is an import-graph heuristic. Cross-feature contracts that are NOT expressed as
// imports — e.g. an HTTP API route, a DB schema/migration, an env contract — are NOT caught here by
// design (to keep the gate low-noise). Those remain the AGENT's responsibility under the /u-dev Step
// 0.5 change-safety protocol (reverse-dependency + public-surface delta + AskUserQuestion).
//
// Gate mode (default `off`) — resolved PER PROJECT, highest precedence first: env `U_MAKER_EDIT_GATE`
// > state file `.u-maker/.state/edit-gate-mode` (set by the skill param `/u-dev`·`/u-build
// --sideeffect {off|on|strict}`) > default `off`. Mode values:
//   • off          — never gate (disable the side-effect gate entirely). DEFAULT — the gate does
//                    nothing unless a user explicitly opts in via `on`/`auto`/`strict`.
//   • on  (= auto) — gate only a MODIFYING fix to an already-implemented file THAT HAS DEPENDENTS
//                    (low-noise, fix-only). Additive edits / new / in-progress / leaf files pass.
//   • auto         — explicit synonym of `on` (back-compat with pre-default-off configs).
//   • strict       — gate EVERY change (modify OR add) to EVERY existing file (no implemented /
//                    dependent / additive checks; pre-4.0.0-alpha.24 always-on). git-less / max caution.
//
// This guard is INTENTIONALLY NOT routed through _dispatch.js, whose contract is
// "never block Claude / always exit(0)". A PreToolUse gate must be able to return a
// permission decision, so it is a standalone script wired directly in hooks.json.
//
// Decision primitive: `permissionDecision: "ask"` — the native Claude Code mechanism
// that forces the USER to confirm the tool call. We deliberately use ASK (not DENY) so the
// gate is strict but never bricks a run, and the user is always the final authority.
//
// Scope (when enabled — `on`/`auto` — only fires when ALL hold):
//   1. The target is inside a u-maker-managed project (a `.u-maker/` dir exists at/above it).
//   2. The target is an EXISTING file (already on disk) — NEW file creation is allowed freely.
//   3. The target is NOT under `.u-maker/` (SSoT docs/state are managed by other flows).
//   4. There is no fresh per-file approval marker (written after the user approved an impact
//      analysis via /u-dev Step 0.5 — see change-safety.md).
//   5. The file is already-implemented: git-tracked AND clean vs HEAD.
//   6. The file HAS DEPENDENTS: at least one other source file imports/references it.
//   7. The edit MODIFIES existing code (not a purely additive insertion). [file tools only; Bash
//      mutations are inherently modifying]
//
// Anything else → allow (exit 0). Internal errors → fail-open (allow).

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');

// --- Gate mode resolution: env > project state file > default off -----------------------------
// off (DEFAULT) | on (= auto) | auto | strict. The side-effect gate is OFF by default — it only runs
// when explicitly enabled. The effective mode for a target is resolved PER PROJECT, highest first:
//   1. env `U_MAKER_EDIT_GATE`                       — lets a shell / CI force a mode everywhere.
//   2. state file `<root>/.u-maker/.state/edit-gate-mode` — written by the skill param
//      `/u-dev`·`/u-build --sideeffect {off|on|strict}`; persists the choice for the project.
//   3. default `off`.
// `on` is the friendly alias of `auto` (both → the 3-signal low-noise policy); `strict` gates every
// add+modify to every existing file. A source that is unset/unrecognized ABSTAINS (falls through).
function parseMode(v) {
  if (typeof v !== 'string') return null;
  const s = v.trim().toLowerCase();
  if (s === 'strict') return 'strict';
  if (s === 'on' || s === 'auto') return 'auto';        // `on` normalizes to `auto`
  if (s === 'off') return 'off';
  return null;                                          // unset / unrecognized → abstain
}

// Env override (highest precedence). null when unset/unrecognized → defer to state file / default.
const ENV_MODE = parseMode(process.env.U_MAKER_EDIT_GATE);

// Project-persisted mode written by the skill param. The file holds either a raw token (`on`) or a
// small JSON object (`{"mode":"on"}`). Missing / unreadable / blank → abstain (null).
function stateMode(umakerRoot) {
  if (!umakerRoot) return null;
  try {
    const raw = fs.readFileSync(
      path.join(umakerRoot, '.u-maker', '.state', 'edit-gate-mode'), 'utf8').trim();
    if (!raw) return null;
    const tok = raw[0] === '{' ? (JSON.parse(raw) || {}).mode : raw;
    return parseMode(tok);
  } catch (_) {
    return null;                                        // no file / bad JSON → no opinion
  }
}

// Effective mode for a target whose u-maker root is `umakerRoot`: env > state > default off.
function effectiveMode(umakerRoot) {
  return ENV_MODE || stateMode(umakerRoot) || 'off';
}

// --- approval marker TTL (minutes). Override via env. Default ~ one working session. ---
const TTL_MIN = (() => {
  const v = parseInt(process.env.U_MAKER_EDIT_APPROVAL_TTL_MIN || '', 10);
  return Number.isFinite(v) && v > 0 ? v : 480;
})();

const NOT_GATED = { gated: false, dependents: [] };

function exitAllow() { process.exit(0); }

// Build a short human summary of the dependents that a change could regress.
function depSummary(deps) {
  if (!deps || deps.length === 0) return '';
  const sample = deps.slice(0, 5).join(', ');
  const more = deps.length > 5 ? ` (+${deps.length - 5} more)` : '';
  return ` ${deps.length} other file(s) import/reference it: ${sample}${more}.`;
}

// EMPHASIZED banner shown at the top of every side-effect prompt so the impact is unmistakable
// ("사이드이펙트 영향도가 있다는 강조된 표현"). Kept on its own line for prominence in the native prompt.
const IMPACT_BANNER = '⚠️  SIDE-EFFECT IMPACT — 사이드이펙트 영향도 있음  ⚠️';

// Compose an emphasized approval reason that NAMES the affected dependents and the mutation channel.
function impactReason(relPath, deps, channel) {
  const chan = channel ? ' (' + channel + ')' : '';
  return IMPACT_BANNER +
    '\nThis fix MODIFIES already-implemented, depended-upon code — "' + relPath + '"' + chan +
    ' — changing existing behavior that OTHER features/UI rely on, so it MAY REGRESS them.' +
    depSummary(deps) +
    ' Explicit user approval is required before this side-effecting change is applied.';
}

function ask(reason, mode) {
  const payload = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'ask',
      permissionDecisionReason: reason,
    },
    systemMessage:
      '[u-maker side-effect gate] ' + reason +
      ' (Gate mode: ' + mode + '.) In `on`/`auto`, only already-implemented (committed) files that ' +
      'OTHER code imports/depends on are gated — new, in-progress, and leaf (no-dependent) files pass ' +
      'freely. Run the /u-dev Step 0.5 impact analysis (reverse-dependency / blast-radius + adversarial ' +
      'regression review), get explicit user approval (AskUserQuestion), then record a marker under ' +
      '.u-maker/.state/edit-approvals/ to authorize subsequent edits to this file ' +
      '(see skills/u-dev/references/change-safety.md). ' +
      'Note: HTTP API routes, DB schema/migrations, and env contracts are cross-feature surfaces NOT ' +
      'detected by the import-graph heuristic — assess those in Step 0.5 even if this gate stays silent. ' +
      'To change mode: `/u-dev` or `/u-build --sideeffect on|off|strict` (persists to ' +
      '.u-maker/.state/edit-gate-mode), or env U_MAKER_EDIT_GATE=on|auto|strict|off (env overrides ' +
      'the state file; default off).',
  };
  process.stdout.write(JSON.stringify(payload));
  process.exit(0);
}

function readStdin() {
  return new Promise((resolve) => {
    if (process.stdin.isTTY) return resolve('');
    let buf = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => { buf += c; });
    process.stdin.on('end', () => resolve(buf));
    process.stdin.on('error', () => resolve(buf));
  });
}

// Walk up from startDir to filesystem root; return the dir that contains `.u-maker/`.
function findUmakerRoot(startDir) {
  let dir = startDir;
  for (let i = 0; i < 64 && dir; i++) {
    try {
      if (fs.existsSync(path.join(dir, '.u-maker')) &&
          fs.statSync(path.join(dir, '.u-maker')).isDirectory()) {
        return dir;
      }
    } catch (_) { /* ignore */ }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return null;
}

function isUnderUmakerState(absPath, umakerRoot) {
  const rel = path.relative(umakerRoot, absPath);
  return rel === '.u-maker' || rel.startsWith('.u-maker' + path.sep);
}

function hasFreshApprovalMarker(absPath, umakerRoot) {
  try {
    const sha = crypto.createHash('sha1').update(absPath).digest('hex');
    const marker = path.join(umakerRoot, '.u-maker', '.state', 'edit-approvals', sha + '.json');
    if (!fs.existsSync(marker)) return false;
    const ageMs = Date.now() - fs.statSync(marker).mtimeMs;
    return ageMs >= 0 && ageMs <= TTL_MIN * 60 * 1000;
  } catch (_) {
    return false;
  }
}

// --- git probes --------------------------------------------------------------------------
// Run git from the file's own directory (monorepo / CLAUDE_PROJECT_DIR≠repo-root safe).
function gitExit(dir, gitArgs) {
  try {
    const r = spawnSync('git', gitArgs, {
      cwd: dir,
      timeout: 2500,
      stdio: ['ignore', 'ignore', 'ignore'],
    });
    if (r.error) return null;                           // git missing / spawn failed
    return typeof r.status === 'number' ? r.status : null;
  } catch (_) {
    return null;
  }
}

function gitStdout(dir, gitArgs) {
  try {
    const r = spawnSync('git', gitArgs, {
      cwd: dir,
      timeout: 2500,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    if (r.error) return null;
    return { status: typeof r.status === 'number' ? r.status : 1, out: r.stdout || '' };
  } catch (_) {
    return null;
  }
}

function gitStdoutTrim(dir, gitArgs) {
  const r = gitStdout(dir, gitArgs);
  return r && r.status === 0 ? r.out.trim() : null;
}

// "Already-implemented" = git-TRACKED and CLEAN vs HEAD (no working-tree changes) → committed,
// shipped code. UNTRACKED (new) or DIRTY (uncommitted edits) → still being built. No git / not a
// repo / no HEAD → NOT implemented (fail toward low friction; use `strict` for git-less projects).
function isImplementedFile(abs) {
  const dir = path.dirname(abs);
  const tracked = gitExit(dir, ['ls-files', '--error-unmatch', '--', abs]);
  if (tracked !== 0) return false;                      // untracked / not-a-repo / git missing
  const diff = gitExit(dir, ['diff', '--quiet', 'HEAD', '--', abs]);
  return diff === 0;                                    // 0 = no diff vs HEAD = clean/implemented
}

// --- reverse-dependency probe ------------------------------------------------------------
// Framework ENTRY points are loaded by convention, not imported by name → never have import
// dependents → treated as leaves. `index.*` is referenced by its PARENT directory name.
const ENTRY_BASENAMES = /^(page|route|layout|loading|error|not-found|template|default|global-error|sitemap|robots|manifest|opengraph-image|twitter-image|icon|apple-icon|middleware|instrumentation|_app|_document)$/i;
const DEP_EXTS = ['*.ts', '*.tsx', '*.js', '*.jsx', '*.mjs', '*.cjs', '*.mts', '*.cts',
  '*.vue', '*.svelte', '*.astro', '*.css', '*.scss', '*.sass', '*.less'];

function escapeRe(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

// The token another module would use to import this file (its module name). null → not import-
// referenceable (a framework entry) → treat as a leaf.
function importToken(abs) {
  const ext = path.extname(abs);
  const base = path.basename(abs, ext);
  if (/^index$/i.test(base)) {
    const parent = path.basename(path.dirname(abs));
    if (!parent || ENTRY_BASENAMES.test(parent)) return null;
    return parent;
  }
  if (ENTRY_BASENAMES.test(base)) return null;
  return base;
}

// Return the list of OTHER source files that import/reference this module (sample, repo-relative).
// Empty array = a leaf (no dependents) OR undeterminable (git/grep unavailable) → fail toward ALLOW.
function dependentsOf(abs) {
  const token = importToken(abs);
  if (!token) return [];
  const startDir = path.dirname(abs);
  const root = gitStdoutTrim(startDir, ['rev-parse', '--show-toplevel']);
  if (!root) return [];
  // Match an import-ish keyword + a quoted module specifier whose LAST path segment is `token`
  // (segment boundary avoids matching `./dateFormat` when token is `format`). Case-sensitive.
  const esc = escapeRe(token);
  const pattern =
    `(^|[^A-Za-z0-9_])(import|require|from)[^"']*["']([^"']*/)?${esc}(\\.[A-Za-z0-9]+)?["']`;
  const r = gitStdout(root, ['grep', '-lIE', '-e', pattern, '--', ...DEP_EXTS]);
  if (!r || r.status !== 0) return [];                  // 1 = no matches, >1 = error → no provable deps
  const rel = path.relative(root, abs);
  return r.out
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
    .filter((f) => f !== rel);                          // exclude the target itself
}

// Resolve absolute path for a file-tool target.
function resolveAbs(p, cwd) {
  if (!p) return null;
  return path.isAbsolute(p) ? path.normalize(p) : path.normalize(path.join(cwd, p));
}

// Signal (C): does this file-tool call MODIFY existing code (change/remove existing lines) — vs
// purely ADD to it? An additive edit keeps every existing line dependents rely on verbatim, so it
// cannot regress them → not gated. A modifying edit rewrites/deletes existing behavior → gated.
//   Edit       → additive iff new_string contains old_string verbatim (an insertion around it);
//                empty old_string is a pure insertion → additive.
//   MultiEdit  → additive iff EVERY sub-edit is additive (any modifying sub-edit ⇒ modifying).
//   Write      → additive iff the new content contains the entire existing file verbatim
//                (append / prepend / wrap); unreadable or empty-new → treat as modifying.
// Unknown / malformed input → MODIFYING (conservative, default-deny posture).
function isAdditivePair(oldS, newS) {
  if (typeof oldS !== 'string' || typeof newS !== 'string') return false; // unknown → not additive
  if (oldS === '') return true;                 // pure insertion, nothing existing replaced
  return newS.includes(oldS);                   // new keeps old verbatim → wrapped/extended → additive
}

function isModifyingEdit(toolName, toolInput, abs) {
  try {
    if (toolName === 'Edit') {
      return !isAdditivePair(toolInput.old_string, toolInput.new_string);
    }
    if (toolName === 'MultiEdit') {
      const edits = Array.isArray(toolInput.edits) ? toolInput.edits : null;
      if (!edits || edits.length === 0) return true;
      return !edits.every((e) => e && isAdditivePair(e.old_string, e.new_string));
    }
    if (toolName === 'Write') {
      const content = toolInput.content;
      if (typeof content !== 'string' || content === '') return true; // truncate/clear → modifying
      let existing = null;
      try { existing = fs.readFileSync(abs, 'utf8'); } catch (_) { existing = null; }
      if (existing == null) return true;          // can't compare old → modifying (conservative)
      if (existing === '') return false;          // writing into an empty file → additive
      return !content.includes(existing);         // new keeps whole old file verbatim → additive
    }
  } catch (_) {
    return true;
  }
  return true;
}

// Assess whether a target is GATED at the PATH level, and (in `on`/`auto`) which dependents a change
// could regress. This covers signals (A) ALREADY-IMPLEMENTED and (B) HAS DEPENDENTS. Signal (C)
// MODIFIES-vs-ADDITIVE is content-dependent and applied by the CALLER (isModifyingEdit) for file
// tools; Bash mutations are inherently modifying so they gate on (A)+(B) alone. The effective mode is
// resolved PER PROJECT (env > state file > off) from the target's own u-maker root, and returned on
// the result so the caller can apply the additive bypass and label the prompt.
// on/auto → path-gated iff: existing real file inside a u-maker project, outside `.u-maker/`, no fresh
// marker, ALREADY-IMPLEMENTED (tracked+clean), AND HAS DEPENDENTS (other files import it).
// strict → gated for every existing file (no implemented/dependent/additive checks). off → never.
function gateInfo(abs, cwd) {
  try {
    if (!abs) return NOT_GATED;
    if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) return NOT_GATED; // new / not a regular file
    const root = findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
    if (!root) return NOT_GATED;                        // not inside a u-maker project
    const mode = effectiveMode(root);                   // env > state file > default off (per project)
    if (mode === 'off') return NOT_GATED;               // gate disabled for this project
    if (isUnderUmakerState(abs, root)) return NOT_GATED; // SSoT/state → managed elsewhere
    if (hasFreshApprovalMarker(abs, root)) return NOT_GATED; // already approved this session
    if (mode === 'strict') return { gated: true, dependents: [], mode };
    if (!isImplementedFile(abs)) return NOT_GATED;      // new/in-progress → forward construction
    const deps = dependentsOf(abs);
    if (deps.length === 0) return NOT_GATED;            // leaf → a fix can't side-effect other features
    return { gated: true, dependents: deps, mode };
  } catch (_) {
    return NOT_GATED;
  }
}

function umakerRootFor(abs, cwd) {
  return findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
}

// --- Bash command analysis: collect the WRITE targets of a command -----------------------
// Patch application mutates EXISTING tracked files whose names live in the patch BODY (not argv),
// so we can't enumerate targets — and therefore cannot assess their blast radius. We only gate
// patches in `strict` (max caution); in `auto` we cannot prove a side-effect → allow.
const PATCH_LIKE = /\bgit\s+apply\b|\bgit\s+stash\s+(pop|apply)\b|(^|\s)patch\b[^|;]*(\s-p?\d|<)/i;
// Verbs that mutate EACH of their named path args in place: rm/unlink/shred/truncate (delete/zero),
// mv (source removed + dest written), sed -i / perl -i (in-place edit), git rm / git checkout -- /
// git restore (restore tracked). `cp`/`tee`/`dd` are handled separately (destination-only), and
// `install` is intentionally NOT here (it matched package managers: `pip install -r req.txt` etc.).
const INPLACE_ALLARGS = /(^|\s|;|&&|\|\|)(rm|unlink|shred|truncate|mv)(\s|$)|(\bsed\b[^|;]*\s-[a-z]*i)|(\bperl\b[^|;]*\s-[a-z]*i)|(\bgit\s+rm\b)|(\bgit\s+checkout\b[^|;]*--)|(\bgit\s+restore\b)/i;
// Interpreter run with inline code (python -c / node -e / …) that ALSO contains a write op.
const INTERPRETER = /\b(python3?|node|deno|bun|ruby|perl|php|osascript|tclsh|Rscript)\b/i;
const WRITE_INDICATOR = /(['"][wax]\+?b?['"]|writeFileSync|writeFile\b|\.write\s*\(|\btruncate\b|Files?\.write|fs\.(write|append|truncate))/i;
// Redirect overwrite/append, incl. fd-prefixed (`1>`) and clobber-override (`>|`).
const REDIRECT = /(^|[^>&])>>?\|?\s*("[^"]+"|'[^']+'|[^\s|&>;]+)/g;
// Maximal path-like runs (also isolates paths embedded inside quotes/argv, e.g. open("a/b.ts","w")).
const PATHRUN = /[A-Za-z0-9_.@~/-]+/g;

function unquote(s) { return s.replace(/^['"]|['"]$/g, ''); }
function looksLikePath(tok) {
  if (!tok || tok.startsWith('-')) return false;
  return tok.includes('/') || /\.[A-Za-z0-9]{1,8}$/.test(tok);
}
function allPathTokens(s) {
  const out = [];
  let m; PATHRUN.lastIndex = 0;
  while ((m = PATHRUN.exec(s)) !== null) {
    if (looksLikePath(m[0])) out.push(m[0]);
  }
  return out;
}

// Remove heredoc BODIES so a `>` or path that is mere heredoc data isn't read as a redirect/target.
function stripHeredocs(cmd) {
  try {
    return cmd.replace(/<<-?\s*['"]?(\w+)['"]?[\s\S]*?\n\s*\1\b/g, ' <<HEREDOC ');
  } catch (_) {
    return cmd;
  }
}

// Split a command line into rough segments so cp/tee/dd can be parsed per-invocation.
function splitSegments(cmd) {
  return cmd.split(/(?:;|&&|\|\||\|)/);
}

// Collect the set of path tokens a command actually WRITES to (not its read-only inputs).
function collectWriteTargets(cmd) {
  const targets = new Set();

  // 1) redirect destinations: > >> (incl `1>`, `>|`). Inputs are only read.
  let m; REDIRECT.lastIndex = 0;
  while ((m = REDIRECT.exec(cmd)) !== null) {
    const t = unquote(m[2]);
    if (t === '/dev/null' || t.startsWith('&')) continue;
    targets.add(t);
  }

  // 2) in-place verbs that mutate EVERY named path arg (rm/mv/sed -i/perl -i/git rm|checkout --|restore).
  if (INPLACE_ALLARGS.test(cmd)) {
    for (const t of allPathTokens(cmd)) targets.add(t);
  }

  // 3) interpreter inline writes (python -c open(…,"w"), node -e fs.writeFileSync(…)) — can't tell
  //    which path is the write target, so consider all path-like tokens.
  if (INTERPRETER.test(cmd) && WRITE_INDICATOR.test(cmd)) {
    for (const t of allPathTokens(cmd)) targets.add(t);
  }

  // 4) cp / tee / dd → DESTINATION only (their sources / stdin are read-only).
  for (const seg of splitSegments(cmd)) {
    const s = seg.trim();
    if (!s) continue;
    const toks = s.split(/\s+/);
    const verb = toks[0];
    if (/^cp$/i.test(verb)) {
      for (let i = toks.length - 1; i >= 1; i--) {
        if (looksLikePath(toks[i])) { targets.add(unquote(toks[i])); break; }
      }
    } else if (/^tee$/i.test(verb)) {
      for (let i = 1; i < toks.length; i++) {
        if (toks[i].startsWith('-')) continue;
        if (looksLikePath(toks[i])) targets.add(unquote(toks[i]));
      }
    } else if (/^dd$/i.test(verb)) {
      for (const t of toks) {
        const mm = /^of=(.+)$/i.exec(t);
        if (mm) targets.add(unquote(mm[1]));
      }
    }
  }
  return targets;
}

// Find the first WRITE target of a Bash command that is gated, with its dependents.
function bashGate(command, cwd) {
  if (!command || typeof command !== 'string') return null;
  const cmd = stripHeredocs(command);
  for (const t of collectWriteTargets(cmd)) {
    const abs = resolveAbs(t, cwd);
    const info = gateInfo(abs, cwd);
    if (info.gated) return { abs, dependents: info.dependents, root: umakerRootFor(abs, cwd), mode: info.mode };
  }
  return null;
}

(async () => {
  let payload = {};
  try {
    const raw = await readStdin();
    if (raw && raw.trim()) payload = JSON.parse(raw);
  } catch (_) {
    return exitAllow(); // can't parse input → don't block unrelated tools
  }

  try {
    const toolName = payload.tool_name;
    const toolInput = payload.tool_input || {};
    const cwd = process.env.CLAUDE_PROJECT_DIR || payload.cwd || process.cwd();

    if (!toolName) return exitAllow();
    if (ENV_MODE === 'off') return exitAllow(); // env explicitly disables the gate everywhere → fast exit

    // ---- File tools: Write / Edit / MultiEdit ----
    if (toolName === 'Write' || toolName === 'Edit' || toolName === 'MultiEdit') {
      const abs = resolveAbs(toolInput.file_path || toolInput.path, cwd);
      const info = gateInfo(abs, cwd);
      if (!info.gated) return exitAllow();
      // Signal (C): in `on`/`auto`, a purely ADDITIVE edit to a shared file leaves existing behavior
      // intact → it cannot side-effect dependents → allow silently. Only a MODIFYING edit is gated.
      // `strict` gates both add and modify (its result.mode is 'strict', so it skips this bypass).
      if (info.mode === 'auto' && !isModifyingEdit(toolName, toolInput, abs)) return exitAllow();
      const root = umakerRootFor(abs, cwd);
      return ask(impactReason(path.relative(root, abs), info.dependents, null), info.mode);
    }

    // ---- Bash: catch sed -i / redirects / rm / mv / interpreter writes / patch on implemented code ----
    if (toolName === 'Bash') {
      const cmd = toolInput.command || '';
      // Patch application mutates tracked files we cannot enumerate from argv → blast radius is
      // unknowable. Only gate in `strict`; in `on`/`auto` we cannot prove a side-effect → allow.
      const bashRoot = findUmakerRoot(cwd) || findUmakerRoot(process.cwd());
      if (bashRoot && effectiveMode(bashRoot) === 'strict' && PATCH_LIKE.test(cmd)) {
        return ask(
          IMPACT_BANNER +
          '\nThis Bash command applies a patch / restores tracked files, mutating already-implemented ' +
          'code whose blast radius cannot be enumerated. Explicit user approval is required.',
          'strict'
        );
      }
      const g = bashGate(cmd, cwd);
      if (g) {
        return ask(impactReason(
          path.relative(g.root, g.abs), g.dependents,
          'in-place edit / redirect / rm / mv / interpreter write'
        ), g.mode);
      }
      return exitAllow();
    }

    return exitAllow();
  } catch (_) {
    // Any unexpected internal error → fail-open so the guard can never brick the session.
    return exitAllow();
  }
})();
