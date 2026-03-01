#!/usr/bin/env node
/**
 * state.js — u-ssot State Management Library
 *
 * Manages PDCA phase, iteration, and loop status.
 * Reads/writes from u-ssot.config.json.
 *
 * Exports:
 *   getCurrentPhase() / setPhase(phase)
 *   getCurrentIteration() / incrementIteration()
 *   getLoopStatus() / setLoopStatus(status)
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// Config Path Resolution
// ============================================================

const VALID_PHASES = ['plan', 'design', 'do', 'check', 'act'];
const VALID_LOOP_STATUSES = ['RUNNING', 'PAUSED', 'STOPPED'];

function getConfigPath() {
  // Prefer project-level config, fall back to plugin root
  const projectConfig = path.join(process.cwd(), 'u-ssot.config.json');
  if (fs.existsSync(projectConfig)) {
    return projectConfig;
  }
  return path.resolve(__dirname, '..', 'u-ssot.config.json');
}

function loadConfig() {
  const configPath = getConfigPath();
  try {
    if (fs.existsSync(configPath)) {
      return JSON.parse(fs.readFileSync(configPath, 'utf8'));
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
  const configPath = getConfigPath();
  try {
    let existing = {};
    try {
      if (fs.existsSync(configPath)) {
        existing = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      }
    } catch {
      // Use empty
    }
    const merged = { ...existing, ...config, lastUpdated: new Date().toISOString() };
    fs.writeFileSync(configPath, JSON.stringify(merged, null, 2) + '\n', 'utf8');
  } catch (err) {
    throw new Error(`Failed to save config: ${err.message}`);
  }
}

// ============================================================
// Phase Management
// ============================================================

/**
 * Get the current PDCA phase.
 * @returns {string} One of: plan, design, do, check, act
 */
function getCurrentPhase() {
  const config = loadConfig();
  return config.currentPhase || 'plan';
}

/**
 * Set the current PDCA phase.
 * @param {string} phase — One of: plan, design, do, check, act
 */
function setPhase(phase) {
  const normalized = phase.toLowerCase();
  if (!VALID_PHASES.includes(normalized)) {
    throw new Error(`Invalid phase: ${phase}. Valid: ${VALID_PHASES.join(', ')}`);
  }
  saveConfig({ currentPhase: normalized });
}

// ============================================================
// Iteration Management
// ============================================================

/**
 * Get the current iteration number.
 * @returns {number}
 */
function getCurrentIteration() {
  const config = loadConfig();
  return config.currentIteration || 1;
}

/**
 * Increment the iteration number by 1.
 * @returns {number} The new iteration number
 */
function incrementIteration() {
  const config = loadConfig();
  const next = (config.currentIteration || 1) + 1;
  saveConfig({ currentIteration: next });
  return next;
}

// ============================================================
// Loop Status Management
// ============================================================

/**
 * Get the current loop status.
 * @returns {string} One of: RUNNING, PAUSED, STOPPED
 */
function getLoopStatus() {
  const config = loadConfig();
  return config.loopStatus || 'STOPPED';
}

/**
 * Set the loop status.
 * @param {string} status — One of: RUNNING, PAUSED, STOPPED
 */
function setLoopStatus(status) {
  const normalized = status.toUpperCase();
  if (!VALID_LOOP_STATUSES.includes(normalized)) {
    throw new Error(`Invalid loop status: ${status}. Valid: ${VALID_LOOP_STATUSES.join(', ')}`);
  }
  saveConfig({ loopStatus: normalized });
}

// ============================================================
// Monorepo Helpers
// ============================================================

/**
 * Get the list of apps from config.
 * @returns {string[]} Array of app names (e.g., ['web', 'admin'])
 */
function getApps() {
  const config = loadConfig();
  return (config.techStack && config.techStack.monorepo && config.techStack.monorepo.structure && config.techStack.monorepo.structure.apps) || ['web'];
}

/**
 * Get document scopes from config.
 * @returns {{ shared: string[], app: string[] }}
 */
function getDocumentScopes() {
  const config = loadConfig();
  return config.documentScopes || {
    shared: ['1_Roadmap_PM.md', '1_Index_PM.md', '2_ERD_SA.md', '2_DesignSystem_UX.md', '3_UIComponents_UX.md', '3_DesignToken_UX.md', '5_Backlog_RA.md', '5_IterationLog_RA.md', '5_Retrospective_PM.md'],
    app: ['1_SRS_RA.md', '1_IA_RA.md', '2_API_SA.md', '2_Screen_UX.md', '3_Code_DV.md', '3_Screen_UX.md', '4_Case_QA.md', '4_Report_QA.md']
  };
}

// ============================================================
// Exports
// ============================================================

module.exports = {
  getCurrentPhase,
  setPhase,
  getCurrentIteration,
  incrementIteration,
  getLoopStatus,
  setLoopStatus,
  getApps,
  getDocumentScopes,
  // Internal (for testing)
  loadConfig,
  saveConfig,
};
