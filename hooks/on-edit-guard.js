#!/usr/bin/env node
// on-edit-guard.js — u-maker Side-Effect Gatekeeping (PreToolUse)
//
// GOAL: protect against silent side-effects (regressions) when the pipeline MODIFIES code that is
// already built — i.e. a **bug fix or a change to an already-implemented feature / UI-UX** — but ONLY
// when that change can actually ripple into OTHER features / UI. It must never nag during forward
// construction, and it must not nag when fixing a self-contained (leaf) file that nothing depends on.
//
// Two signals are required (in the default `auto` mode) before we ask the user:
//   (A) ALREADY-IMPLEMENTED — detected via git, no intent flag:
//         • git-TRACKED and CLEAN vs HEAD → committed/shipped code → a change is a FIX → candidate.
//         • UNTRACKED (new) or DIRTY (uncommitted) → still being built → ALLOW (forward construction).
//   (B) HAS DEPENDENTS — other source files import/reference this module. If something depends on it,
//         a fix here can regress those dependents → a real cross-feature side-effect → ASK.
//         If NOTHING imports it (a leaf: a standalone page / route / entry / test), a fix cannot
//         side-effect other features → ALLOW silently.
// "fix하는 경우에만 다른 기능이나 UI/UX에 사이드이펙트가 있을지 검토하고, 있을 수 있는 경우에만 물어본다."
// (A) = "fix하는 경우", (B) = "사이드이펙트가 있을 수 있는 경우" (reverse-dependency 검토).
//
// NOTE on coverage: (B) is an import-graph heuristic. Cross-feature contracts that are NOT expressed as
// imports — e.g. an HTTP API route, a DB schema/migration, an env contract — are NOT caught here by
// design (to keep the gate low-noise). Those remain the AGENT's responsibility under the /u-dev Step
// 0.5 change-safety protocol (reverse-dependency + public-surface delta + AskUserQuestion).
//
// Gate mode — `U_MAKER_EDIT_GATE` (default `auto`):
//   • auto   — gate only already-implemented files THAT HAVE DEPENDENTS. DEFAULT (low-noise, fix-only).
//   • strict — gate EVERY existing file (no implemented / dependent checks; pre-4.0.0-alpha.24 always-on).
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
// Scope (in `auto`, only fires when ALL hold):
//   1. The target is inside a u-maker-managed project (a `.u-maker/` dir exists at/above it).
//   2. The target is an EXISTING file (already on disk) — NEW file creation is allowed freely.
//   3. The target is NOT under `.u-maker/` (SSoT docs/state are managed by other flows).
//   4. There is no fresh per-file approval marker (written after the user approved an impact
//      analysis via /u-dev Step 0.5 — see change-safety.md).
//   5. The file is already-implemented: git-tracked AND clean vs HEAD.
//   6. The file HAS DEPENDENTS: at least one other source file imports/references it.
//
// Anything else → allow (exit 0). Internal errors → fail-open (allow).

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

const NOT_GATED = { gated: false, dependents: [] };

function exitAllow() { process.exit(0); }

// Build a short human summary of the dependents that a change could regress.
function depSummary(deps) {
  if (!deps || deps.length === 0) return '';
  const sample = deps.slice(0, 5).join(', ');
  const more = deps.length > 5 ? ` (+${deps.length - 5} more)` : '';
  return ` ${deps.length} other file(s) import/reference it: ${sample}${more}.`;
}

function ask(reason) {
  const payload = {
    hookSpecificOutput: {
      hookEventName: 'PreToolUse',
      permissionDecision: 'ask',
      permissionDecisionReason: reason,
    },
    systemMessage:
      '[u-maker side-effect gate] ' + reason +
      ' (Gate mode: ' + GATE_MODE + '.) In `auto`, only already-implemented (committed) files that ' +
      'OTHER code imports/depends on are gated — new, in-progress, and leaf (no-dependent) files pass ' +
      'freely. Run the /u-dev Step 0.5 impact analysis (reverse-dependency / blast-radius + adversarial ' +
      'regression review), get explicit user approval (AskUserQuestion), then record a marker under ' +
      '.u-maker/.state/edit-approvals/ to authorize subsequent edits to this file ' +
      '(see skills/u-dev/references/change-safety.md). ' +
      'Note: HTTP API routes, DB schema/migrations, and env contracts are cross-feature surfaces NOT ' +
      'detected by the import-graph heuristic — assess those in Step 0.5 even if this gate stays silent. ' +
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

// Assess whether a target is GATED, and (in `auto`) which dependents a change could regress.
// auto → gated iff: existing real file inside a u-maker project, outside `.u-maker/`, no fresh
// marker, ALREADY-IMPLEMENTED (tracked+clean), AND HAS DEPENDENTS (other files import it).
// strict → gated for every existing file (no implemented/dependent checks). off → never.
function gateInfo(abs, cwd) {
  if (GATE_MODE === 'off') return NOT_GATED;
  try {
    if (!abs) return NOT_GATED;
    if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) return NOT_GATED; // new / not a regular file
    const root = findUmakerRoot(path.dirname(abs)) || findUmakerRoot(cwd);
    if (!root) return NOT_GATED;                        // not inside a u-maker project
    if (isUnderUmakerState(abs, root)) return NOT_GATED; // SSoT/state → managed elsewhere
    if (hasFreshApprovalMarker(abs, root)) return NOT_GATED; // already approved this session
    if (GATE_MODE === 'strict') return { gated: true, dependents: [] };
    if (!isImplementedFile(abs)) return NOT_GATED;      // new/in-progress → forward construction
    const deps = dependentsOf(abs);
    if (deps.length === 0) return NOT_GATED;            // leaf → a fix can't side-effect other features
    return { gated: true, dependents: deps };
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
    if (info.gated) return { abs, dependents: info.dependents, root: umakerRootFor(abs, cwd) };
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
    if (GATE_MODE === 'off') return exitAllow(); // gate disabled entirely

    // ---- File tools: Write / Edit / MultiEdit ----
    if (toolName === 'Write' || toolName === 'Edit' || toolName === 'MultiEdit') {
      const abs = resolveAbs(toolInput.file_path || toolInput.path, cwd);
      const info = gateInfo(abs, cwd);
      if (!info.gated) return exitAllow();
      const root = umakerRootFor(abs, cwd);
      return ask(
        'Modifying already-implemented file "' + path.relative(root, abs) + '" can regress code that ' +
        'depends on it.' + depSummary(info.dependents) + ' It requires explicit user approval.'
      );
    }

    // ---- Bash: catch sed -i / redirects / rm / mv / interpreter writes / patch on implemented code ----
    if (toolName === 'Bash') {
      const cmd = toolInput.command || '';
      // Patch application mutates tracked files we cannot enumerate from argv → blast radius is
      // unknowable. Only gate in `strict`; in `auto` we cannot prove a side-effect → allow.
      if (GATE_MODE === 'strict' && PATCH_LIKE.test(cmd) &&
          (findUmakerRoot(cwd) || findUmakerRoot(process.cwd()))) {
        return ask(
          'This Bash command applies a patch / restores tracked files, mutating already-implemented ' +
          'code whose blast radius cannot be enumerated. It requires explicit user approval.'
        );
      }
      const g = bashGate(cmd, cwd);
      if (g) {
        return ask(
          'This Bash command modifies already-implemented file "' + path.relative(g.root, g.abs) +
          '" (in-place edit / redirect / rm / mv / interpreter write), which can regress code that ' +
          'depends on it.' + depSummary(g.dependents) + ' It requires explicit user approval.'
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
