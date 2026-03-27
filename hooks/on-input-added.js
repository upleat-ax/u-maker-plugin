#!/usr/bin/env node
/**
 * on-input-added.js — u-maker PostToolUse Hook (Write)
 *
 * Detects when a file is written to _input/ and suggests running /u-ingest.
 *
 * Input: JSON from stdin with tool_input.file_path
 * Output: JSON { result: "success" } with optional suggestion
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

// Check if file is under _input/
const isInputFile =
  normalized.startsWith(path.join(umakerPath, '_input')) ||
  (normalized.startsWith(path.join(umakerPath, 'apps')) && normalized.includes('_input'));

if (!isInputFile) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// Determine scope from path
const relPath = path.relative(umakerPath, normalized);
const parts = relPath.split(path.sep);
let scope = '';

if (parts[0] === 'apps' && parts.length >= 3) {
  scope = parts[1]; // app name
}

const scopeArg = scope ? ` ${scope}` : '';

console.log(JSON.stringify({
  result: 'success',
  hookSpecificOutput: {
    hookEventName: 'PostToolUse',
    additionalContext: [
      `[u-maker] New input file detected: ${relPath}`,
      `Run \`/u-ingest${scopeArg}\` to analyze and classify this data into _classified/.`,
      `Use \`/u-ingest${scopeArg} --incremental\` to process only new files.`,
    ].join('\n'),
  },
}));

process.exit(0);
