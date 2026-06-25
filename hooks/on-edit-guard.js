#!/usr/bin/env node
// on-edit-guard.js — u-maker Side-Effect Gatekeeping (PreToolUse)
//
// GOAL: protect against silent side-effects (regressions, scope creep) when the pipeline
// MODIFIES code that is already built — i.e. a **bug fix or a change to an already-implemented
// feature / UI-UX**. It must NOT nag during forward construction (building something new, or
// iterating on a file that is still in progress).
//
// "Already-implemented" is detected automatically, with no intent flag, via git:
//   • file is git-TRACKED and CLEAN vs HEAD  → committed/shipped code → a change to it is a FIX → GATE
//   • file is UNTRACKED (new) or DIRTY (uncommitted changes) → you are still building it → ALLOW
// This makes the gate fire (in the default `auto` mode) only for fixes to existing, committed
// code — matching "버그/이미 구현된 기능/UI·UX를 fix하는 경우에만".
//
// Gate mode — `U_MAKER_EDIT_GATE` (default `auto`):
//   • auto   — gate only already-implemented (tracked & clean) files. DEFAULT.
//   • strict — gate EVERY existing file (the pre-4.0.0-alpha.24 always-on behavior).
//   • off    — never gate (disable the side-effect gate entirely).
//
// This guard is INTENTIONALLY NOT routed through _dispatch.js, whose contract is
// "never block Claude / always exit(0)". A PreToolUse gate must be able to return a
// permission decision, so it is a standalone script wired directly in hooks.json.
//
// Decision primitive: `permissionDecision: "ask"` — the native Claude Code mechanism
// that forces the USER to confirm the tool call. We deliberately use ASK (not DENY) so the
// gate is strict but never bricks a run, and the user is always the final authority.
//
// Scope (in `auto`/`strict`, only fires when ALL hold):
//   1. The target is inside a u-maker-managed project (a `.u-maker/` dir exists at/above it).
//   2. The target is an EXISTING file (already on disk) — NEW file creation is allowed freely.
//   3. The target is NOT under `.u-maker/` (SSoT docs/state are managed by other flows).
//   4. There is no fresh per-file approval marker (written after the user approved an impact
//      analysis via /u-dev Step 0.5 — see change-safety.md).
//   5. (`auto` only) The file is already-implemented: git-tracked AND clean vs HEAD.
//
// Anything else → allow (exit 0). Internal errors → fail-open (allow), EXCEPT when we have
// positively identified an un-approved mutation of already-implemented code, in which case we ask.

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');

// --- Gate mode: off | strict | auto (default). Override via env. ---
const GATE_MODE = (() => {
  const v = (process.env.U_MAKER_EDIT_GATE || 'auto').trim().toLowerCase();
  return (v === 'off' || v === 'strict') ? v : 'auto';
})();

// --- approval marker TTL (minutes). Override via env. Default ~ one working session. ---
const TTL_MIN = (() => {
  const v = parseInt(process.env.U_MAKER_EDIT_APPROVAL_TTL_MIN || '', 10);
  return Number.isFinite(v) && v > 0 ? v : 480;
})();

function exitAllow() { process.exit(0); }

function ask(reason) {
  const payload = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'ask',
      permissionDecisionReason: reason,
    },
    systemMessage:
      '[u-maker side-effect gate] ' + reason +
      ' This file is already-implemented (committed) code, so changing it is treated as a ' +
      'bug-fix / feature-or-UI fix that can regress dependents. Run the /u-dev Step 0.5 impact ' +
      'analysis (blast-radius + adversarial regression review), get explicit user approval ' +
      '(AskUserQuestion), then record a marker under .u-maker/.state/edit-approvals/ to authorize ' +
      'subsequent edits to this file (see skills/u-dev/references/change-safety.md). ' +
      'New files and in-progress (uncommitted) files are not gated. ' +
      'To change scope: U_MAKER_EDIT_GATE=off|strict|auto (default auto).',
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

// --- git "already-implemented" probe -----------------------------------------------------
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

// Resolve absolute path for a file-tool target.
function resolveAbs(p, cwd) {
  if (!p) return null;
  return path.isAbsolute(p) ? path.normalize(p) : path.normalize(path.join(cwd, p));
}

// A target is GATED iff: gate is on; it is an existing real file inside a u-maker project, outside
// `.u-maker/`, with no fresh approval marker; and — in `auto` — it is already-implemented
// (git tracked & clean). `strict` skips the implemented check (gates every existing file).
function isGatedTarget(abs, cwd) {
  if (GATE_MODE === 'off') return false;
  try {
    if (!abs) return false;
    if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) return false; // new / not a regular file
    const root = findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
    if (!root) return false;                            // not inside a u-maker project
    if (isUnderUmakerState(abs, root)) return false;    // SSoT/state → managed elsewhere
    if (hasFreshApprovalMarker(abs, root)) return false; // already approved this session
    if (GATE_MODE === 'auto' && !isImplementedFile(abs)) return false; // new/in-progress → building
    return true;
  } catch (_) {
    return false;
  }
}

function umakerRootFor(abs, cwd) {
  return findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
}

// --- Bash command analysis: collect the WRITE targets of a command -----------------------
// Patch application mutates EXISTING tracked files whose names live in the patch BODY (not argv),
// so we can't enumerate targets cheaply → ASK whenever we're inside a u-maker project.
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

function bashTargetsImplemented(command, cwd) {
  if (!command || typeof command !== 'string') return false;
  const cmd = stripHeredocs(command);
  for (const t of collectWriteTargets(cmd)) {
    if (isGatedTarget(resolveAbs(t, cwd), cwd)) return true;
  }
  return false;
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
    if (GATE_MODE === 'off') return exitAllow(); // gate disabled entirely

    // ---- File tools: Write / Edit / MultiEdit ----
    if (toolName === 'Write' || toolName === 'Edit' || toolName === 'MultiEdit') {
      const abs = resolveAbs(toolInput.file_path || toolInput.path, cwd);
      if (!isGatedTarget(abs, cwd)) return exitAllow();
      const root = umakerRootFor(abs, cwd);
      return ask(
        'Modifying already-implemented file "' + path.relative(root, abs) + '" can cause ' +
        'side-effects (regressions in code that depends on it). It requires explicit user approval.'
      );
    }

    // ---- Bash: catch sed -i / redirects / rm / mv / interpreter writes / patch on implemented code ----
    if (toolName === 'Bash') {
      const cmd = toolInput.command || '';
      // Patch application mutates existing tracked files we cannot enumerate from argv → ask when
      // inside a u-maker project (resolved from cwd or process.cwd()), unless gate is off.
      if (PATCH_LIKE.test(cmd) && (findUmakerRoot(cwd) || findUmakerRoot(process.cwd()))) {
        return ask(
          'This Bash command applies a patch / restores tracked files, mutating already-implemented ' +
          'code. It requires explicit user approval.'
        );
      }
      if (bashTargetsImplemented(cmd, cwd)) {
        return ask(
          'This Bash command modifies an already-implemented project file (in-place edit / redirect / ' +
          'rm / mv / interpreter write). Mutating committed code can cause side-effects and requires ' +
          'explicit user approval.'
        );
      }
      return exitAllow();
    }

    return exitAllow();
  } catch (_) {
    // Any unexpected internal error → fail-open so the guard can never brick the session.
    return exitAllow();
  }
})();
