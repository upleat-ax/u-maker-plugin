#!/usr/bin/env node
/**
 * stop-state-save.js — u-maker Stop Hook
 *
 * Saves current loop status, phase, and iteration to .u-maker/u-maker.config.json.
 *
 * Output: JSON matching Stop hook schema (top-level fields only, no hookSpecificOutput)
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// Configuration
// ============================================================

const PLUGIN_ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(process.cwd(), '.u-maker/u-maker.config.json');
const FALLBACK_CONFIG_PATH = path.join(PLUGIN_ROOT, '.u-maker/u-maker.config.json');

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

  // v2: Count pending assumptions across all apps
  let pendingAssumptions = 0;
  try {
    const umakerRoot = path.join(process.cwd(), '.u-maker');
    const assumptionPaths = [
      path.join(umakerRoot, '_assumptions', '_index.json'),
    ];
    // Check apps
    const appsDir = path.join(umakerRoot, 'apps');
    if (fs.existsSync(appsDir)) {
      const apps = fs.readdirSync(appsDir).filter(d =>
        fs.statSync(path.join(appsDir, d)).isDirectory()
      );
      for (const app of apps) {
        assumptionPaths.push(path.join(appsDir, app, '_assumptions', '_index.json'));
      }
    }
    for (const ap of assumptionPaths) {
      if (fs.existsSync(ap)) {
        const data = JSON.parse(fs.readFileSync(ap, 'utf8'));
        const items = data.items || data.assumptions || [];
        pendingAssumptions += items.filter(a => a.status === 'pending-review').length;
      }
    }
  } catch {}

  const saved = saveConfig(config);

  const assumptionNote = pendingAssumptions > 0
    ? `, pending-assumptions=${pendingAssumptions}`
    : '';
  const stopReason = saved
    ? `State saved: phase=${config.currentPhase}, iteration=${config.currentIteration}, loop=${config.loopStatus}${assumptionNote}`
    : 'Warning: Could not save state to config file.';

  console.log(JSON.stringify({ stopReason }));
} catch (err) {
  console.log(JSON.stringify({
    stopReason: `Stop hook warning: ${err.message}`,
  }));
}

process.exit(0);
