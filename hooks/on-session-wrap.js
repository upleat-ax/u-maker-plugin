#!/usr/bin/env node
/**
 * on-session-wrap.js — u-maker PostToolUse Hook (Write)
 *
 * When a session file is written to _sessions/, detects if the session
 * is being wrapped (completed) and reminds to classify tagged items.
 *
 * Input: JSON from stdin with tool_input.file_path
 * Output: JSON { result: "success" } with optional classification reminder
 */

const fs = require('fs');
const path = require('path');

function readStdinSync() {
  try {
    return fs.readFileSync('/dev/stdin', 'utf8');
  } catch {
    return '{}';
  }
}

const rawInput = readStdinSync();
let input = {};
try {
  input = JSON.parse(rawInput);
} catch {}

const toolInput = input.tool_input || {};
const filePath = toolInput.file_path || '';

if (!filePath) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

const normalized = path.resolve(filePath);
const umakerPath = path.resolve(path.join(process.cwd(), '.u-maker'));

// Only process files under _sessions/
if (!normalized.startsWith(umakerPath) || !normalized.includes('_sessions')) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

const basename = path.basename(filePath);

// Only process session JSON files
if (!basename.endsWith('.json') || basename === '_index.json') {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

try {
  const session = JSON.parse(fs.readFileSync(normalized, 'utf8'));

  if (session.status !== 'completed') {
    console.log(JSON.stringify({ result: 'success' }));
    process.exit(0);
  }

  // Count items by type
  const items = session.items || [];
  const counts = {};
  for (const item of items) {
    counts[item.type] = (counts[item.type] || 0) + 1;
  }

  const classifiedIds = session.classifiedItems || [];

  const lines = [
    `[u-maker] Session "${session.topic || basename}" completed (${session.type}).`,
  ];

  if (items.length > 0) {
    const summary = Object.entries(counts).map(([t, c]) => `${t}: ${c}`).join(', ');
    lines.push(`  Items: ${summary}`);
  }

  if (classifiedIds.length > 0) {
    lines.push(`  Classified: ${classifiedIds.length} items sent to _classified/`);
  } else if (items.length > 0) {
    lines.push('  Reminder: Run engine-analyzer to classify tagged items into _classified/.');
    lines.push('  /idea → _classified/requirements/ | /decide → _classified/decisions/ | /concern → _classified/constraints/');
  }

  console.log(JSON.stringify({
    result: 'success',
    hookSpecificOutput: {
      hookEventName: 'PostToolUse',
      additionalContext: lines.join('\n'),
    },
  }));
} catch {
  console.log(JSON.stringify({ result: 'success' }));
}

process.exit(0);
