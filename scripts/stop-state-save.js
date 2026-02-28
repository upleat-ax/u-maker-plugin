#!/usr/bin/env node
/**
 * stop-state-save.js — u-ssot Stop Hook
 *
 * Saves current loop status, phase, and iteration to u-ssot.config.json.
 *
 * Output: JSON { result: "success" }
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// Configuration
// ============================================================

const PLUGIN_ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(process.cwd(), 'u-ssot.config.json');
const FALLBACK_CONFIG_PATH = path.join(PLUGIN_ROOT, 'u-ssot.config.json');

// ============================================================
// State Management
// ============================================================

function loadConfig() {
  const configPath = fs.existsSync(CONFIG_PATH) ? CONFIG_PATH : FALLBACK_CONFIG_PATH;

  try {
    if (fs.existsSync(configPath)) {
      const raw = fs.readFileSync(configPath, 'utf8');
      return JSON.parse(raw);
    }
  } catch {
    // Ignore parse errors
  }

  return {
    currentPhase: 'plan',
    currentIteration: 1,
    loopStatus: 'STOPPED',
  };
}

function saveConfig(config) {
  const configPath = fs.existsSync(CONFIG_PATH) ? CONFIG_PATH : FALLBACK_CONFIG_PATH;

  try {
    // Preserve existing fields, update session-specific ones
    let existing = {};
    try {
      if (fs.existsSync(configPath)) {
        existing = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      }
    } catch {
      // Use empty
    }

    const merged = {
      ...existing,
      currentPhase: config.currentPhase,
      currentIteration: config.currentIteration,
      loopStatus: config.loopStatus,
      lastSessionEnd: new Date().toISOString(),
    };

    fs.writeFileSync(configPath, JSON.stringify(merged, null, 2) + '\n', 'utf8');
    return true;
  } catch {
    return false;
  }
}

// ============================================================
// Read stdin (Stop hook input)
// ============================================================

function readStdinSync() {
  try {
    return fs.readFileSync('/dev/stdin', 'utf8');
  } catch {
    return '{}';
  }
}

// ============================================================
// Main
// ============================================================

try {
  const rawInput = readStdinSync();
  const config = loadConfig();

  // If loop was running, mark as paused on stop
  if (config.loopStatus === 'RUNNING') {
    config.loopStatus = 'PAUSED';
  }

  const saved = saveConfig(config);

  console.log(JSON.stringify({
    result: 'success',
    hookSpecificOutput: {
      hookEventName: 'Stop',
      additionalContext: saved
        ? `State saved: phase=${config.currentPhase}, iteration=${config.currentIteration}, loop=${config.loopStatus}`
        : 'Warning: Could not save state to config file.',
    },
  }));
} catch (err) {
  console.log(JSON.stringify({
    result: 'success',
    hookSpecificOutput: {
      hookEventName: 'Stop',
      additionalContext: `Stop hook warning: ${err.message}`,
    },
  }));
}

process.exit(0);
