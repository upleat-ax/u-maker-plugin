#!/usr/bin/env node
/**
 * doc-tracker.js — u-maker Document Tracking Library
 *
 * Tracks SSoT document status, updates, and cross-references.
 * Supports v2 per-app document structure (common/ + {app}/).
 *
 * Exports:
 *   getDocumentStatus(path) — parse SSoT header
 *   setDocumentStatus(path, status) — update Status field
 *   getDocPath(docName, appName) — resolve doc path by scope
 *   listAllDocuments(filterApp) — scan .u-maker/docs/ (common + per-app)
 *   checkTraceability() — verify cross-references
 */

const fs = require('fs');
const path = require('path');
const { loadConfig, getApps, getDocumentScopes } = require('./state');

// ============================================================
// Configuration
// ============================================================

const VALID_STATUSES = ['Draft', 'Review', 'Final'];

// Traceability matrix: document -> expected related docs
// Common docs reference other common docs; app docs reference within same app + common
const TRACEABILITY_MAP = {
  '1_Roadmap_PM.md': ['1_SRS_RA.md'],
  '1_SRS_RA.md': ['1_Roadmap_PM.md', '2_ERD_SA.md', '2_API_SA.md', '2_RTM_RA.md'],
  '1_IA_RA.md': ['2_Screen_UX.md', '2_UXGuide_UX.md'],
  '2_ERD_SA.md': ['1_SRS_RA.md', '2_API_SA.md'],
  '2_RTM_RA.md': ['1_SRS_RA.md', '1_IA_RA.md', '2_Screen_UX.md', '2_API_SA.md', '2_ERD_SA.md', '4_Case_QA.md'],
  '2_API_SA.md': ['1_SRS_RA.md', '2_ERD_SA.md', '2_Screen_UX.md'],
  '2_Screen_UX.md': ['1_IA_RA.md', '2_API_SA.md', '4_Case_QA.md'],
  '2_UXGuide_UX.md': ['1_IA_RA.md', '3_Screen_UX.md', '3_DesignToken_UX.md'],
  '3_Code_DV.md': ['2_ERD_SA.md', '2_API_SA.md'],
  '3_Screen_UX.md': ['2_Screen_UX.md', '2_UXGuide_UX.md', '3_UIComponents_UX.md'],
  '3_UIComponents_UX.md': ['2_UXGuide_UX.md', '3_Screen_UX.md', '3_DesignToken_UX.md'],
  '3_DesignToken_UX.md': ['2_UXGuide_UX.md', '3_UIComponents_UX.md'],
  '4_Case_QA.md': ['1_SRS_RA.md', '2_Screen_UX.md'],
  '4_Report_QA.md': ['4_Case_QA.md', '5_IterationLog_RA.md'],
  '5_Retrospective_PM.md': ['5_IterationLog_RA.md'],
};

// Pattern: 5_DailyReport_PM_yyyymmddhhmm.md
const DAILY_REPORT_DOC_PATTERN = /^5_DailyReport_PM_\d{12}\.md$/;

// ============================================================
// Helper: Phase detection
// ============================================================

/**
 * Get the phase directory name from a document name.
 * @param {string} docName — e.g., "1_SRS_RA.md"
 * @returns {string} Phase dir, e.g., "01-plan"
 */
function getPhaseDir(docName) {
  const prefix = docName.charAt(0);
  const phaseMap = { '1': '01-plan', '2': '02-design', '3': '03-dev', '4': '04-check', '5': '05-act' };
  return phaseMap[prefix] || '';
}

/**
 * Check if a document belongs to the common scope.
 * @param {string} docName — e.g., "1_Roadmap_PM.md"
 * @returns {boolean}
 */
function isCommonDoc(docName) {
  const scopes = getDocumentScopes();
  return scopes.common.includes(docName) || DAILY_REPORT_DOC_PATTERN.test(docName);
}

/**
 * Check if a document belongs to the root scope (.u-maker/docs/ root).
 * @param {string} docName — e.g., "5_IterationLog_RA.md"
 * @returns {boolean}
 */
function isRootDoc(docName) {
  const scopes = getDocumentScopes();
  return (scopes.root || []).includes(docName);
}

// ============================================================
// Helper: Get .u-maker/docs root
// ============================================================

function getUdocsRoot() {
  return path.join(process.cwd(), '.u-maker', 'docs');
}

/**
 * Check if the new v2 structure exists (common/ directory present).
 * @returns {boolean}
 */
function hasV2Structure() {
  return fs.existsSync(path.join(getUdocsRoot(), 'common'));
}

// ============================================================
// getDocPath
// ============================================================

/**
 * Resolve the correct file path for a document based on its scope.
 * - Common docs: .u-maker/docs/common/{phase}/{docName}
 * - App docs: .u-maker/docs/{appName}/{phase}/{docName}
 *
 * Falls back to old flat structure if v2 doesn't exist.
 *
 * @param {string} docName — e.g., "1_SRS_RA.md"
 * @param {string} [appName] — e.g., "web" (required for app-scoped docs)
 * @returns {string} Resolved absolute path
 */
function getDocPath(docName, appName) {
  const udocs = getUdocsRoot();
  const phaseDir = getPhaseDir(docName);

  if (hasV2Structure()) {
    if (isRootDoc(docName)) {
      return path.join(udocs, docName);
    }
    if (isCommonDoc(docName)) {
      return path.join(udocs, 'common', phaseDir, docName);
    }
    const app = appName || getApps()[0] || 'web';
    return path.join(udocs, app, phaseDir, docName);
  }

  // Backwards compatibility: old flat structure
  return path.join(udocs, phaseDir, docName);
}

// ============================================================
// getDocumentStatus
// ============================================================

/**
 * Parse the SSoT header from a document and return structured metadata.
 * @param {string} filePath — Absolute or relative path to .md file
 * @returns {{ owner: string|null, status: string|null, version: string|null, lastUpdated: string|null, relatedDocs: string[] }}
 */
function getDocumentStatus(filePath) {
  const result = {
    owner: null,
    status: null,
    version: null,
    lastUpdated: null,
    relatedDocs: [],
  };

  try {
    const resolvedPath = path.isAbsolute(filePath)
      ? filePath
      : path.resolve(filePath);

    if (!fs.existsSync(resolvedPath)) return result;

    const content = fs.readFileSync(resolvedPath, 'utf8');

    // Parse header fields
    const ownerMatch = content.match(/^\s*-\s*\*\*Owner\*\*:\s*(.+)/m);
    if (ownerMatch) result.owner = ownerMatch[1].trim();

    const statusMatch = content.match(/^\s*-\s*\*\*Status\*\*:\s*(Draft|Review|Final)/m);
    if (statusMatch) result.status = statusMatch[1];

    const versionMatch = content.match(/^\s*-\s*\*\*Version\*\*:\s*(v\d+\.\d+\.\d+)/m);
    if (versionMatch) result.version = versionMatch[1];

    const dateMatch = content.match(/^\s*-\s*\*\*Last Updated\*\*:\s*(\d{4}-\d{2}-\d{2})/m);
    if (dateMatch) result.lastUpdated = dateMatch[1];

    const relatedMatch = content.match(/^\s*-\s*\*\*Related Docs\*\*:\s*(.+)/m);
    if (relatedMatch) {
      const links = relatedMatch[1].match(/\[([^\]]*)\]\(([^)]+)\)/g) || [];
      result.relatedDocs = links.map(link => {
        const m = link.match(/\[([^\]]*)\]\(([^)]+)\)/);
        return m ? m[2] : link;
      });
    }
  } catch {
    // Return partial result
  }

  return result;
}

// ============================================================
// setDocumentStatus
// ============================================================

/**
 * Update the Status field in an SSoT document.
 * @param {string} filePath — Path to .md file
 * @param {string} status — New status (Draft, Review, Final)
 * @returns {boolean} True if updated
 */
function setDocumentStatus(filePath, status) {
  if (!VALID_STATUSES.includes(status)) {
    throw new Error(`Invalid status: ${status}. Valid: ${VALID_STATUSES.join(', ')}`);
  }

  try {
    const resolvedPath = path.isAbsolute(filePath)
      ? filePath
      : path.resolve(filePath);

    if (!fs.existsSync(resolvedPath)) return false;

    let content = fs.readFileSync(resolvedPath, 'utf8');
    const pattern = /^(\s*-\s*\*\*Status\*\*:\s*)(Draft|Review|Final)/m;

    if (pattern.test(content)) {
      content = content.replace(pattern, `$1${status}`);

      // Also update Last Updated date
      const datePattern = /^(\s*-\s*\*\*Last Updated\*\*:\s*)\d{4}-\d{2}-\d{2}/m;
      const today = new Date().toISOString().split('T')[0];
      if (datePattern.test(content)) {
        content = content.replace(datePattern, `$1${today}`);
      }

      fs.writeFileSync(resolvedPath, content, 'utf8');
      return true;
    }

    return false;
  } catch {
    return false;
  }
}

// ============================================================
// listAllDocuments
// ============================================================

/**
 * Scan .u-maker/docs/ and return all documents with their status.
 * Supports both v2 (common/ + per-app) and v1 (flat) structures.
 *
 * @param {string} [filterApp] — If provided, only include this app's docs + common docs
 * @returns {Array<{ path: string, relPath: string, name: string, status: string|null, phase: string, scope: string, app: string|null }>}
 */
function listAllDocuments(filterApp) {
  const udocs = getUdocsRoot();
  const documents = [];

  if (!fs.existsSync(udocs)) return documents;

  const v2 = hasV2Structure();

  if (v2) {
    // Scan common/
    const commonRoot = path.join(udocs, 'common');
    if (fs.existsSync(commonRoot)) {
      scanPhaseDir(commonRoot, udocs, 'common', null, documents);
    }

    // Scan each app
    const apps = getApps();
    for (const app of apps) {
      if (filterApp && app !== filterApp) continue;
      const appRoot = path.join(udocs, app);
      if (fs.existsSync(appRoot)) {
        scanPhaseDir(appRoot, udocs, 'app', app, documents);
      }
    }
  } else {
    // Backwards compatibility: old flat structure
    scanFlatDir(udocs, documents);
  }

  return documents;
}

/**
 * Scan phase subdirectories within a scope root (common/ or {app}/).
 */
function scanPhaseDir(scopeRoot, udocs, scope, app, documents) {
  const entries = fs.readdirSync(scopeRoot, { withFileTypes: true });
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    if (entry.name === 'assets' || entry.name === 'iterations') continue;

    const phaseDir = path.join(scopeRoot, entry.name);
    const files = fs.readdirSync(phaseDir, { withFileTypes: true });
    for (const file of files) {
      if (!file.isFile() || !file.name.endsWith('.md') || file.name.toLowerCase() === 'readme.md') continue;

      const fullPath = path.join(phaseDir, file.name);
      const relPath = path.relative(udocs, fullPath);
      const meta = getDocumentStatus(fullPath);

      documents.push({
        path: fullPath,
        relPath,
        name: file.name,
        status: meta.status,
        phase: entry.name,
        scope,
        app: app || null,
      });
    }
  }
}

/**
 * Scan old flat .u-maker/docs/ structure (v1 backwards compatibility).
 */
function scanFlatDir(udocs, documents) {
  function scanDir(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name !== 'iterations' && entry.name !== 'assets' && entry.name !== 'common') {
          scanDir(fullPath);
        }
      } else if (entry.name.endsWith('.md') && entry.name.toLowerCase() !== 'readme.md') {
        const relPath = path.relative(udocs, fullPath);
        const parts = relPath.split(path.sep);
        const phase = parts[0] || '';
        const meta = getDocumentStatus(fullPath);
        const common = isCommonDoc(entry.name);

        documents.push({
          path: fullPath,
          relPath,
          name: entry.name,
          status: meta.status,
          phase,
          scope: common ? 'common' : 'app',
          app: common ? null : 'web',
        });
      }
    }
  }

  scanDir(udocs);
}

// ============================================================
// checkTraceability
// ============================================================

/**
 * Verify cross-references between SSoT documents.
 * Checks that Related Docs links point to existing files.
 * Scope-aware: common docs reference common, app docs reference within same app + common.
 *
 * @returns {{ passed: boolean, issues: Array<{ doc: string, issue: string }> }}
 */
function checkTraceability() {
  const issues = [];
  const documents = listAllDocuments();
  const docNames = new Set(documents.map(d => d.name));

  // Build a lookup by name + app for scope-aware checking
  const docsByNameApp = new Map();
  for (const doc of documents) {
    const key = doc.app ? `${doc.app}:${doc.name}` : `common:${doc.name}`;
    docsByNameApp.set(key, doc);
  }

  for (const doc of documents) {
    const basename = doc.name;
    const expected = TRACEABILITY_MAP[basename];

    if (!expected) continue;

    const meta = getDocumentStatus(doc.path);
    const relatedFiles = meta.relatedDocs.map(p => path.basename(p));

    for (const expectedDoc of expected) {
      // Only check if the expected doc actually exists in .u-maker/docs/
      if (!docNames.has(expectedDoc)) continue;

      if (!relatedFiles.some(f => f === expectedDoc || f.includes(expectedDoc.replace('.md', '')))) {
        const scopeLabel = doc.app ? `[${doc.app}] ` : '[common] ';
        issues.push({
          doc: `${scopeLabel}${basename}`,
          issue: `Missing reference to ${expectedDoc} in Related Docs`,
        });
      }
    }
  }

  return {
    passed: issues.length === 0,
    issues,
  };
}

// ============================================================
// Exports
// ============================================================

module.exports = {
  getDocumentStatus,
  setDocumentStatus,
  getDocPath,
  getPhaseDir,
  isCommonDoc,
  listAllDocuments,
  checkTraceability,
};
