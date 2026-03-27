#!/usr/bin/env node
/**
 * on-gate-pass.js — u-maker PostToolUse Hook (Write)
 *
 * When a gate-rules result or phase transition document is written,
 * checks if all gate conditions are met and suggests automatic phase transition.
 *
 * Input: JSON from stdin with tool_input.file_path
 * Output: JSON { result: "success" } with optional phase transition suggestion
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

if (!normalized.startsWith(umakerPath)) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// Only trigger on _index.json writes (status changes) or SSoT doc writes with "Final" status
const basename = path.basename(filePath);

if (basename !== '_index.json') {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

// Check if this is an app-level _index.json
const relPath = path.relative(umakerPath, normalized);
const parts = relPath.split(path.sep);

if (parts[0] !== 'apps' || parts.length < 3) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

const appName = parts[1];

// Read app config to get current phase
const appConfigPath = path.join(umakerPath, 'apps', appName, 'app.config.json');
if (!fs.existsSync(appConfigPath)) {
  console.log(JSON.stringify({ result: 'success' }));
  process.exit(0);
}

try {
  const appConfig = JSON.parse(fs.readFileSync(appConfigPath, 'utf8'));
  const currentPhase = appConfig.phase || 'plan';

  // Phase gate conditions
  const GATE_CONDITIONS = {
    plan: { required: ['srs', 'ia', 'roadmap'], status: 'Final', next: 'design' },
    design: { required: ['erd', 'rtm', 'screen', 'api'], status: 'Final', next: 'do' },
    do: { required: ['code'], status: 'Final', next: 'check' },
    check: { required: ['test-cases', 'test-report'], status: 'Final', next: 'act' },
  };

  const gate = GATE_CONDITIONS[currentPhase];
  if (!gate) {
    console.log(JSON.stringify({ result: 'success' }));
    process.exit(0);
  }

  // Read the app's _index.json to check document statuses
  const appIndexPath = path.join(umakerPath, 'apps', appName, '_index.json');
  if (!fs.existsSync(appIndexPath)) {
    console.log(JSON.stringify({ result: 'success' }));
    process.exit(0);
  }

  const appIndex = JSON.parse(fs.readFileSync(appIndexPath, 'utf8'));
  const docs = appIndex.documents || [];

  const met = [];
  const unmet = [];

  for (const reqDoc of gate.required) {
    const doc = docs.find(d => d.id === reqDoc);
    if (doc && doc.status === gate.status) {
      met.push(reqDoc);
    } else {
      unmet.push(`${reqDoc} (${doc ? doc.status : 'missing'})`);
    }
  }

  if (unmet.length === 0) {
    console.log(JSON.stringify({
      result: 'success',
      hookSpecificOutput: {
        hookEventName: 'PostToolUse',
        additionalContext: [
          `[u-maker] GATE PASS: All ${currentPhase} phase conditions met for "${appName}"!`,
          `  Met: ${met.join(', ')}`,
          '',
          `Ready to transition to ${gate.next} phase.`,
          `Run \`/u-gate ${appName}\` to validate and transition.`,
        ].join('\n'),
      },
    }));
  } else {
    // Not all conditions met, just report progress
    const progress = Math.round((met.length / gate.required.length) * 100);
    if (progress >= 50) {
      console.log(JSON.stringify({
        result: 'success',
        hookSpecificOutput: {
          hookEventName: 'PostToolUse',
          additionalContext: [
            `[u-maker] Gate progress for "${appName}" (${currentPhase} → ${gate.next}): ${progress}%`,
            `  Remaining: ${unmet.join(', ')}`,
          ].join('\n'),
        },
      }));
    } else {
      console.log(JSON.stringify({ result: 'success' }));
    }
  }
} catch {
  console.log(JSON.stringify({ result: 'success' }));
}

process.exit(0);
