#!/usr/bin/env node
/**
 * gate.js — u-agent-ssot Phase Transition Gate Checks
 *
 * Validates conditions required for transitioning between PDCA phases.
 *
 * Exports:
 *   checkPlanToDesignGate() — all PLAN docs Final
 *   checkDesignToDoGate() — all DESIGN docs Final
 *   checkDoToCheckGate() — build success
 *   checkExitCriteria() — full 4-criteria check
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ============================================================
// Helper: Parse document status from SSoT header
// ============================================================

/**
 * Extract the Status field from an SSoT document.
 * @param {string} filePath — Absolute path to .md file
 * @returns {string|null} Status value or null if not found
 */
function getDocStatus(filePath) {
  try {
    if (!fs.existsSync(filePath)) return null;
    const content = fs.readFileSync(filePath, 'utf8');
    const match = content.match(/^\s*-\s*\*\*Status\*\*:\s*(Draft|Review|Final)/m);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

/**
 * Get the u-docs root directory.
 * @returns {string}
 */
function getUdocsRoot() {
  return path.join(process.cwd(), 'u-docs');
}

// ============================================================
// Gate: PLAN -> DESIGN
// ============================================================

/**
 * Check if PLAN phase can transition to DESIGN.
 * Requires: 1PM_Roadmap.md, 1A_SRS.md, 1CX_IA.md all Final.
 *
 * @returns {{ passed: boolean, details: string[] }}
 */
function checkPlanToDesignGate() {
  const udocs = getUdocsRoot();
  const requiredDocs = [
    { file: '01-plan/1PM_Roadmap.md', name: '1PM_Roadmap' },
    { file: '01-plan/1A_SRS.md', name: '1A_SRS' },
    { file: '01-plan/1CX_IA.md', name: '1CX_IA' },
  ];

  const details = [];
  let allFinal = true;

  for (const doc of requiredDocs) {
    const fullPath = path.join(udocs, doc.file);
    const status = getDocStatus(fullPath);

    if (!status) {
      details.push(`${doc.name}: NOT FOUND`);
      allFinal = false;
    } else if (status !== 'Final') {
      details.push(`${doc.name}: ${status} (needs Final)`);
      allFinal = false;
    } else {
      details.push(`${doc.name}: Final`);
    }
  }

  return { passed: allFinal, details };
}

// ============================================================
// Gate: DESIGN -> DO
// ============================================================

/**
 * Check if DESIGN phase can transition to DO.
 * Requires: 2A_ERD.md, 2A_API.md, 2CX_Screen.md all Final.
 *
 * @returns {{ passed: boolean, details: string[] }}
 */
function checkDesignToDoGate() {
  const udocs = getUdocsRoot();
  const requiredDocs = [
    { file: '02-design/2A_ERD.md', name: '2A_ERD' },
    { file: '02-design/2A_API.md', name: '2A_API' },
    { file: '02-design/2CX_Screen.md', name: '2CX_Screen' },
  ];

  const details = [];
  let allFinal = true;

  for (const doc of requiredDocs) {
    const fullPath = path.join(udocs, doc.file);
    const status = getDocStatus(fullPath);

    if (!status) {
      details.push(`${doc.name}: NOT FOUND`);
      allFinal = false;
    } else if (status !== 'Final') {
      details.push(`${doc.name}: ${status} (needs Final)`);
      allFinal = false;
    } else {
      details.push(`${doc.name}: Final`);
    }
  }

  return { passed: allFinal, details };
}

// ============================================================
// Gate: DO -> CHECK
// ============================================================

/**
 * Check if DO phase can transition to CHECK.
 * Requires: build success (bun run build).
 *
 * @returns {{ passed: boolean, details: string[] }}
 */
function checkDoToCheckGate() {
  const details = [];

  try {
    execSync('bun run build', {
      stdio: 'pipe',
      timeout: 120000,
    });
    details.push('Build: SUCCESS');
    return { passed: true, details };
  } catch (err) {
    const stderr = err.stderr ? err.stderr.toString().trim() : '';
    details.push('Build: FAILED');
    if (stderr) {
      const lines = stderr.split('\n').slice(-3);
      for (const line of lines) {
        if (line.trim()) details.push(`  ${line.trim()}`);
      }
    }
    return { passed: false, details };
  }
}

// ============================================================
// Exit Criteria (Full 4-check)
// ============================================================

/**
 * Check all 4 exit criteria for iteration completion.
 *
 * 1. All backlog items Done
 * 2. No Critical/Major defects
 * 3. All FR implemented
 * 4. Build success
 *
 * @returns {{ passed: boolean, criteria: Array<{ name: string, passed: boolean, details: string[] }> }}
 */
function checkExitCriteria() {
  const udocs = getUdocsRoot();
  const criteria = [];

  // 1. Backlog check
  const backlogPath = path.join(udocs, '05-act/5ACT_Backlog.md');
  const backlogResult = { name: 'Backlog All Done', passed: true, details: [] };
  try {
    if (fs.existsSync(backlogPath)) {
      const content = fs.readFileSync(backlogPath, 'utf8');
      const rows = content.match(/^\|([^|]+)\|([^|]+)\|([^|]+)\|/gm) || [];
      for (const row of rows) {
        const cells = row.split('|').filter(c => c.trim()).map(c => c.trim());
        if (cells[0].startsWith('-') || cells[0].toLowerCase() === 'id') continue;
        if (cells[2] && cells[2].toLowerCase() !== 'done') {
          backlogResult.passed = false;
          backlogResult.details.push(`Open: ${cells[0]} - ${cells[1]}`);
        }
      }
    }
  } catch {
    backlogResult.details.push('Error reading backlog');
  }
  criteria.push(backlogResult);

  // 2. Defect check
  const qaPath = path.join(udocs, '04-check/4QA_Report.md');
  const defectResult = { name: 'No Critical/Major Defects', passed: true, details: [] };
  try {
    if (fs.existsSync(qaPath)) {
      const content = fs.readFileSync(qaPath, 'utf8');
      const rows = content.match(/^\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|/gm) || [];
      for (const row of rows) {
        const cells = row.split('|').filter(c => c.trim()).map(c => c.trim());
        if (cells[0].startsWith('-') || cells[0].toLowerCase() === 'id') continue;
        const severity = (cells[2] || '').toLowerCase();
        const status = (cells[3] || '').toLowerCase();
        if (['resolved', 'closed', 'fixed', 'done'].includes(status)) continue;
        if (severity === 'critical' || severity === 'major') {
          defectResult.passed = false;
          defectResult.details.push(`${severity}: ${cells[0]} - ${cells[1]}`);
        }
      }
    }
  } catch {
    defectResult.details.push('Error reading QA report');
  }
  criteria.push(defectResult);

  // 3. FR completion check
  const srsPath = path.join(udocs, '01-plan/1A_SRS.md');
  const frResult = { name: 'All FR Implemented', passed: true, details: [] };
  try {
    if (fs.existsSync(srsPath)) {
      const content = fs.readFileSync(srsPath, 'utf8');
      const frRows = content.match(/^\|\s*(FR-\d+)\s*\|([^|]+)\|([^|]+)\|/gm) || [];
      let totalFr = 0;
      for (const row of frRows) {
        const cells = row.split('|').filter(c => c.trim()).map(c => c.trim());
        if (cells[0].startsWith('-')) continue;
        totalFr++;
        const status = (cells[2] || '').toLowerCase();
        if (!['done', 'implemented', 'complete', 'completed'].includes(status)) {
          frResult.passed = false;
          frResult.details.push(`Unimplemented: ${cells[0]} - ${cells[1]}`);
        }
      }
      if (totalFr === 0) {
        frResult.passed = false;
        frResult.details.push('No FR entries found');
      }
    } else {
      frResult.passed = false;
      frResult.details.push('1A_SRS.md not found');
    }
  } catch {
    frResult.passed = false;
    frResult.details.push('Error reading SRS');
  }
  criteria.push(frResult);

  // 4. Build check
  const buildResult = checkDoToCheckGate();
  criteria.push({ name: 'Build Success', ...buildResult });

  const allPassed = criteria.every(c => c.passed);
  return { passed: allPassed, criteria };
}

// ============================================================
// Exports
// ============================================================

module.exports = {
  checkPlanToDesignGate,
  checkDesignToDoGate,
  checkDoToCheckGate,
  checkExitCriteria,
  // Internal (for testing)
  getDocStatus,
};
