#!/usr/bin/env node
/**
 * gate.js — u-maker Phase Transition Gate Checks
 *
 * Validates conditions required for transitioning between PDCA phases.
 * Supports v2 per-app structure (common/ + {app}/).
 *
 * Exports:
 *   checkPlanToDesignGate() — common + perApp PLAN docs Final
 *   checkDesignToDoGate() — common + perApp DESIGN docs Final
 *   checkDoToCheckGate() — build success
 *   checkExitCriteria() — full 4-criteria check (across all apps)
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { getApps } = require('./state');
const { getDocPath, isCommonDoc } = require('./doc-tracker');

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
 * Get the .u-maker/docs root directory.
 * @returns {string}
 */
function getUdocsRoot() {
  return path.join(process.cwd(), '.u-maker', 'docs');
}

/**
 * Check if the new v2 structure exists.
 * @returns {boolean}
 */
function hasV2Structure() {
  return fs.existsSync(path.join(getUdocsRoot(), 'common'));
}

/**
 * Check a list of docs across common and all apps.
 * @param {string[]} commonDocs — Doc names expected in common/
 * @param {string[]} perAppDocs — Doc names expected in each app/
 * @returns {{ passed: boolean, details: string[] }}
 */
function checkCommonAndPerAppDocs(commonDocs, perAppDocs) {
  const udocs = getUdocsRoot();
  const v2 = hasV2Structure();
  const apps = getApps();
  const details = [];
  let allFinal = true;

  // Check common docs
  for (const docName of commonDocs) {
    const fullPath = v2
      ? getDocPath(docName)
      : path.join(udocs, getPhaseDir(docName), docName);
    const status = getDocStatus(fullPath);
    const label = `[common] ${docName.replace('.md', '')}`;

    if (!status) {
      details.push(`${label}: NOT FOUND`);
      allFinal = false;
    } else if (status !== 'Final') {
      details.push(`${label}: ${status} (needs Final)`);
      allFinal = false;
    } else {
      details.push(`${label}: Final`);
    }
  }

  // Check per-app docs
  for (const app of apps) {
    for (const docName of perAppDocs) {
      const fullPath = v2
        ? getDocPath(docName, app)
        : path.join(udocs, getPhaseDir(docName), docName);
      const status = getDocStatus(fullPath);
      const label = `[${app}] ${docName.replace('.md', '')}`;

      if (!status) {
        details.push(`${label}: NOT FOUND`);
        allFinal = false;
      } else if (status !== 'Final') {
        details.push(`${label}: ${status} (needs Final)`);
        allFinal = false;
      } else {
        details.push(`${label}: Final`);
      }
    }
  }

  return { passed: allFinal, details };
}

/**
 * Helper: get phase dir from doc name prefix.
 */
function getPhaseDir(docName) {
  const prefix = docName.charAt(0);
  const phaseMap = { '1': '01-plan', '2': '02-design', '3': '03-dev', '4': '04-check', '5': '05-act' };
  return phaseMap[prefix] || '';
}

// ============================================================
// Gate: PLAN -> DESIGN
// ============================================================

/**
 * Check if PLAN phase can transition to DESIGN.
 * Shared: 1_Roadmap_PM.md Final.
 * Per-app: 1_SRS_RA.md, 1_IA_RA.md Final for ALL apps.
 *
 * @returns {{ passed: boolean, details: string[] }}
 */
function checkPlanToDesignGate() {
  return checkCommonAndPerAppDocs(
    ['1_Roadmap_PM.md'],
    ['1_SRS_RA.md', '1_IA_RA.md']
  );
}

// ============================================================
// Gate: DESIGN -> DO
// ============================================================

/**
 * Check if DESIGN phase can transition to DO.
 * Shared: 2_ERD_SA.md Final.
 * Per-app: 2_API_SA.md, 2_Screen_UX.md Final for ALL apps.
 *
 * @returns {{ passed: boolean, details: string[] }}
 */
function checkDesignToDoGate() {
  return checkCommonAndPerAppDocs(
    ['2_ERD_SA.md'],
    ['2_API_SA.md', '2_Screen_UX.md']
  );
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
// Exit Criteria (Full 3-check)
// ============================================================

/**
 * Check all 3 exit criteria for iteration completion.
 * Aggregates across all apps for per-app documents.
 *
 * 1. No Critical/Major defects (all apps)
 * 2. All FR implemented (all apps)
 * 3. Build success
 *
 * @returns {{ passed: boolean, criteria: Array<{ name: string, passed: boolean, details: string[] }> }}
 */
function checkExitCriteria() {
  const apps = getApps();
  const criteria = [];

  // 1. Defect check (per-app: aggregate all apps)
  const defectResult = { name: 'No Critical/Major Defects', passed: true, details: [] };
  for (const app of apps) {
    const qaPath = getDocPath('4_Report_QA.md', app);
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
            defectResult.details.push(`[${app}] ${severity}: ${cells[0]} - ${cells[1]}`);
          }
        }
      }
    } catch {
      defectResult.details.push(`[${app}] Error reading QA report`);
    }
  }
  criteria.push(defectResult);

  // 2. FR completion check (per-app: aggregate all apps)
  const frResult = { name: 'All FR Implemented', passed: true, details: [] };
  let totalFrAllApps = 0;
  for (const app of apps) {
    const srsPath = getDocPath('1_SRS_RA.md', app);
    try {
      if (fs.existsSync(srsPath)) {
        const content = fs.readFileSync(srsPath, 'utf8');
        const frRows = content.match(/^\|\s*(FR-\d+)\s*\|([^|]+)\|([^|]+)\|/gm) || [];
        for (const row of frRows) {
          const cells = row.split('|').filter(c => c.trim()).map(c => c.trim());
          if (cells[0].startsWith('-')) continue;
          totalFrAllApps++;
          const status = (cells[2] || '').toLowerCase();
          if (!['done', 'implemented', 'complete', 'completed'].includes(status)) {
            frResult.passed = false;
            frResult.details.push(`[${app}] Unimplemented: ${cells[0]} - ${cells[1]}`);
          }
        }
      } else {
        frResult.passed = false;
        frResult.details.push(`[${app}] 1_SRS_RA.md not found`);
      }
    } catch {
      frResult.passed = false;
      frResult.details.push(`[${app}] Error reading SRS`);
    }
  }
  if (totalFrAllApps === 0) {
    frResult.passed = false;
    frResult.details.push('No FR entries found across all apps');
  }
  criteria.push(frResult);

  // 3. Build check
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
