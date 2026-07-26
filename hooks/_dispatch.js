#!/usr/bin/env node
// _dispatch.js
// Bridge between Claude Code's plugin hook contract (stdin JSON, exec as command)
// and the legacy CommonJS modules in this folder that export
//   async function({ filePath, projectRoot })
//
// Usage (from hooks.json):
//   node "${CLAUDE_PLUGIN_ROOT}/hooks/_dispatch.js" <hook-name>
// where <hook-name> resolves to ./<hook-name>.js next to this file.
//
// Failure policy: never block Claude. Path/tool filtering is enforced both here
// and inside each hook module, so a noisy event just no-ops.

const fs = require('fs');
const path = require('path');

const ALLOWED_TOOLS = new Set(['Write', 'Edit', 'MultiEdit']);

function exit(code) {
  process.exit(code);
}

function readStdin() {
  return new Promise(resolve => {
    if (process.stdin.isTTY) {
      resolve('');
      return;
    }
    let buf = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => { buf += chunk; });
    process.stdin.on('end', () => resolve(buf));
    process.stdin.on('error', () => resolve(buf));
  });
}

(async () => {
  const hookName = process.argv[2];
  if (!hookName || !/^[a-zA-Z0-9_-]+$/.test(hookName)) {
    process.stderr.write('[umaker hook] missing/invalid hook name\n');
    return exit(0);
  }

  const raw = await readStdin();
  let payload = {};
  if (raw.trim()) {
    try {
      payload = JSON.parse(raw);
    } catch (e) {
      process.stderr.write('[umaker hook ' + hookName + '] invalid stdin JSON\n');
      return exit(0);
    }
  }

  const toolName = payload.tool_name;
  if (toolName && !ALLOWED_TOOLS.has(toolName)) return exit(0);

  const filePath =
    (payload.tool_input && (payload.tool_input.file_path || payload.tool_input.path)) || null;
  if (!filePath) return exit(0);

  const projectRoot =
    process.env.CLAUDE_PROJECT_DIR || payload.cwd || process.cwd();

  const modPath = path.join(__dirname, hookName + '.js');
  if (!fs.existsSync(modPath)) {
    process.stderr.write('[umaker hook] module not found: ' + modPath + '\n');
    return exit(0);
  }

  let mod;
  try {
    mod = require(modPath);
  } catch (e) {
    process.stderr.write('[umaker hook ' + hookName + '] require failed: ' + e.message + '\n');
    return exit(0);
  }

  const fn = typeof mod === 'function' ? mod : (mod && mod.default);
  if (typeof fn !== 'function') {
    process.stderr.write('[umaker hook ' + hookName + '] module does not export a function\n');
    return exit(0);
  }

  try {
    await fn({ filePath, projectRoot });
  } catch (e) {
    process.stderr.write('[umaker hook ' + hookName + '] ' + (e && e.stack || e) + '\n');
  }
  return exit(0);
})();
