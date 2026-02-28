#!/usr/bin/env node
/**
 * state.js — u-agent-ssot State Management Library
 *
 * Manages PDCA phase, iteration, and loop status.
 * Reads/writes from u-agent-ssot.config.json.
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
  const projectConfig = path.join(process.cwd(), 'u-agent-ssot.config.json');
  if (fs.existsSync(projectConfig)) {
    return projectConfig;
  }
  return path.resolve(__dirname, '..', 'u-agent-ssot.config.json');
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
// Exports
// ============================================================

module.exports = {
  getCurrentPhase,
  setPhase,
  getCurrentIteration,
  incrementIteration,
  getLoopStatus,
  setLoopStatus,
  // Internal (for testing)
  loadConfig,
  saveConfig,
};
