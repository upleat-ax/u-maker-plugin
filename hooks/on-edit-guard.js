#!/usr/bin/env node
// on-edit-guard.js — u-maker Side-Effect Gatekeeping (PreToolUse, STRICT)
//
// GOAL 2: Make modifications to EXISTING code in a u-maker project require explicit
// user approval, so the dev pipeline cannot introduce side-effects (regressions,
// scope creep) silently — especially during bug fixes.
//
// This guard is INTENTIONALLY NOT routed through _dispatch.js, whose contract is
// "never block Claude / always exit(0)". A PreToolUse gate must be able to return a
// permission decision, so it is a standalone script wired directly in hooks.json.
//
// Decision primitive: `permissionDecision: "ask"` — the native Claude Code mechanism
// that forces the USER to confirm the tool call. ("최소 사용자에게 승인" / "물어보고 확인".)
// We deliberately use ASK (not DENY) so the gate is strict but never bricks a run, and
// the user is always the final authority.
//
// Scope (only fires when ALL hold):
//   1. The target is inside a u-maker-managed project (a `.u-maker/` dir exists at/above it).
//   2. The target is an EXISTING file (already on disk) — NEW file creation is allowed freely.
//   3. The target is NOT under `.u-maker/` (SSoT docs/state are managed by other flows).
//   4. There is no fresh per-file approval marker (written by /u-dev Step 0.5 after the
//      user approved an impact analysis via AskUserQuestion).
//
// Anything else → allow (exit 0, no output). Internal errors → fail-open (allow), EXCEPT
// when we have positively identified an un-approved existing-source mutation, in which
// case we ask. See change-safety.md for the agent-side protocol and the marker contract.

'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

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
      ' Before editing existing code you MUST run the /u-dev Step 0.5 impact analysis ' +
      '(blast-radius + adversarial regression review) and get explicit user approval ' +
      '(AskUserQuestion). On approval, record a marker under ' +
      '.u-maker/.state/edit-approvals/ to authorize subsequent edits to this file ' +
      '(see skills/u-dev/references/change-safety.md). 특히 버그 수정 시 적용.',
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

// Resolve absolute path for a file-tool target.
function resolveAbs(p, cwd) {
  if (!p) return null;
  return path.isAbsolute(p) ? path.normalize(p) : path.normalize(path.join(cwd, p));
}

// --- Bash command analysis: detect a mutation of an existing project source file. ---
// In-place / overwrite verbs (incl. installers and git file-restore).
const IN_PLACE_VERB = /(^|\s|;|&&|\|\|)(rm|unlink|shred|truncate|mv|cp|install|tee|dd)(\s|$)|(\bsed\b[^|;]*\s-[a-z]*i)|(\bperl\b[^|;]*\s-[a-z]*i)|(\bgit\s+rm\b)|(\bgit\s+checkout\b[^|;]*--)|(\bgit\s+restore\b)/i;
// Patch application mutates EXISTING tracked files whose names live in the patch BODY (not argv),
// so we can't enumerate targets cheaply → ASK whenever we're inside a u-maker project.
const PATCH_LIKE = /\bgit\s+apply\b|\bgit\s+stash\s+(pop|apply)\b|(^|\s)patch\b[^|;]*(\s-p?\d|<)/i;
// Interpreter run with inline code (python -c / node -e / …) that ALSO contains a write op.
// Requiring a write-indicator avoids false-positives on read-only one-liners (e.g. the
// marker-hash helper `node -e 'require("crypto")…'`), while catching `python -c open(…, "w")`.
const INTERPRETER = /\b(python3?|node|deno|bun|ruby|perl|php|osascript|tclsh|Rscript)\b/i;
const WRITE_INDICATOR = /(['"][wax]\+?b?['"]|writeFileSync|writeFile\b|\.write\s*\(|\btruncate\b|Files?\.write|fs\.(write|append|truncate))/i;
// Redirect overwrite/append, incl. fd-prefixed (`1>`) and clobber-override (`>|`). The leading
// class allows a digit fd; `2>&1`/`&>` style yield a `&…` target which is skipped below.
const REDIRECT = /(^|[^>&])>>?\|?\s*("[^"]+"|'[^']+'|[^\s|&>;]+)/g;
// Maximal path-like runs (also isolates paths embedded inside quotes/argv, e.g. open("a/b.ts","w")).
const PATHRUN = /[A-Za-z0-9_.@~/-]+/g;

// Remove heredoc BODIES so a `>` or path that is mere heredoc data isn't read as a redirect/target.
function stripHeredocs(cmd) {
  try {
    return cmd.replace(/<<-?\s*['"]?(\w+)['"]?[\s\S]*?\n\s*\1\b/g, ' <<HEREDOC ');
  } catch (_) {
    return cmd;
  }
}

// A candidate path is gated iff it is an existing file inside a u-maker project (resolved from the
// candidate's OWN directory, not just cwd — fixes monorepo / CLAUDE_PROJECT_DIR≠project-root cases),
// outside .u-maker/, and without a fresh approval marker.
function candidateIsGatedSource(c, cwd) {
  const abs = resolveAbs(c, cwd);
  if (!abs) return false;
  try {
    if (!fs.existsSync(abs)) return false;          // new file / not present → not gated
    if (!fs.statSync(abs).isFile()) return false;
    const root = findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
    if (!root) return false;                         // candidate not inside any u-maker project
    if (isUnderUmakerState(abs, root)) return false; // managed by other flows
    if (hasFreshApprovalMarker(abs, root)) return false; // already approved
    return true; // existing, un-approved, in-project source file
  } catch (_) {
    return false;
  }
}

function bashTargetsExistingSource(command, cwd) {
  if (!command || typeof command !== 'string') return false;
  const cmd = stripHeredocs(command);

  const inPlace = IN_PLACE_VERB.test(cmd);
  const interpWrite = INTERPRETER.test(cmd) && WRITE_INDICATOR.test(cmd);

  // Broad mutation (rm/mv/sed -i/tee/dd/cp/install, or interpreter inline write): scan EVERY
  // path-like substring — incl. paths embedded in quotes/argv — for an existing source file.
  if (inPlace || interpWrite) {
    let m;
    PATHRUN.lastIndex = 0;
    while ((m = PATHRUN.exec(cmd)) !== null) {
      const tok = m[0];
      if (tok.startsWith('-')) continue;
      if (!(tok.includes('/') || /\.[A-Za-z0-9]{1,8}$/.test(tok))) continue;
      if (candidateIsGatedSource(tok, cwd)) return true;
    }
    return false;
  }

  // Redirect-only (no in-place verb, no interpreter write): only the redirect TARGET is mutated;
  // inputs are merely read. Avoids false positives like `cat existing.ts > /tmp/new`.
  let m;
  REDIRECT.lastIndex = 0;
  while ((m = REDIRECT.exec(cmd)) !== null) {
    const t = m[2].replace(/^['"]|['"]$/g, '');
    if (t === '/dev/null' || t.startsWith('&')) continue;
    if (candidateIsGatedSource(t, cwd)) return true;
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

    // ---- File tools: Write / Edit / MultiEdit ----
    if (toolName === 'Write' || toolName === 'Edit' || toolName === 'MultiEdit') {
      const target = toolInput.file_path || toolInput.path;
      const abs = resolveAbs(target, cwd);
      if (!abs) return exitAllow();

      const umakerRoot = findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
      if (!umakerRoot) return exitAllow();            // not a u-maker project → out of scope

      if (isUnderUmakerState(abs, umakerRoot)) return exitAllow(); // SSoT/state → allowed

      let exists = false;
      try { exists = fs.existsSync(abs) && fs.statSync(abs).isFile(); } catch (_) { exists = false; }
      if (!exists) return exitAllow();                // NEW file → create freely

      if (hasFreshApprovalMarker(abs, umakerRoot)) return exitAllow(); // approved this session

      return ask(
        'Modifying EXISTING file "' + path.relative(umakerRoot, abs) + '" can cause side-effects ' +
        '(regressions in code that depends on it). It requires explicit user approval.'
      );
    }

    // ---- Bash: catch sed -i / redirects / rm / mv / interpreter writes / patch on existing source ----
    if (toolName === 'Bash') {
      const cmd = toolInput.command || '';
      // Patch application mutates existing tracked files we cannot enumerate from argv → ask when
      // inside a u-maker project (resolved from cwd or process.cwd()).
      if (PATCH_LIKE.test(cmd) && (findUmakerRoot(cwd) || findUmakerRoot(process.cwd()))) {
        return ask(
          'This Bash command applies a patch / restores tracked files, mutating EXISTING code. ' +
          'It requires explicit user approval.'
        );
      }
      // Per-candidate root resolution (no cwd-only short-circuit) so a mutation of an existing file
      // inside a u-maker project is gated even when cwd is outside that project (monorepo / odd cwd).
      if (bashTargetsExistingSource(cmd, cwd)) {
        return ask(
          'This Bash command modifies an EXISTING project file (in-place edit / redirect / rm / mv / interpreter write). ' +
          'Mutating existing code can cause side-effects and requires explicit user approval.'
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
