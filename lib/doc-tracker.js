#!/usr/bin/env node
/**
 * doc-tracker.js — u-agent-ssot Document Tracking Library
 *
 * Tracks SSoT document status, updates, and cross-references.
 *
 * Exports:
 *   getDocumentStatus(path) — parse SSoT header
 *   setDocumentStatus(path, status) — update Status field
 *   listAllDocuments() — scan u-docs/
 *   checkTraceability() — verify cross-references
 */

const fs = require('fs');
const path = require('path');

// ============================================================
// Configuration
// ============================================================

const VALID_STATUSES = ['Draft', 'Review', 'Final'];

// Traceability matrix: document -> expected related docs
const TRACEABILITY_MAP = {
  '1PM_Roadmap.md': ['1A_SRS.md'],
  '1A_SRS.md': ['1PM_Roadmap.md', '2A_ERD.md', '2A_API.md'],
  '1CX_IA.md': ['2CX_Screen.md'],
  '2A_ERD.md': ['1A_SRS.md', '2A_API.md'],
  '2A_API.md': ['1A_SRS.md', '2A_ERD.md', '2CX_Screen.md'],
  '2CX_Screen.md': ['1CX_IA.md', '2A_API.md', '4QA_Case.md'],
  '3DV_Code.md': ['2A_ERD.md', '2A_API.md'],
  '4QA_Case.md': ['1A_SRS.md', '2CX_Screen.md'],
  '4QA_Report.md': ['4QA_Case.md', '5ACT_Backlog.md'],
  '5ACT_Backlog.md': ['4QA_Report.md'],
};

// ============================================================
// Helper: Get u-docs root
// ============================================================

function getUdocsRoot() {
  return path.join(process.cwd(), 'u-docs');
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
 * Scan u-docs/ and return all documents with their status.
 * @returns {Array<{ path: string, relPath: string, name: string, status: string|null, phase: string }>}
 */
function listAllDocuments() {
  const udocs = getUdocsRoot();
  const documents = [];

  if (!fs.existsSync(udocs)) return documents;

  function scanDir(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        // Skip iterations and assets
        if (entry.name !== 'iterations' && entry.name !== 'assets') {
          scanDir(fullPath);
        }
      } else if (entry.name.endsWith('.md') && entry.name.toLowerCase() !== 'readme.md') {
        const relPath = path.relative(udocs, fullPath);
        const parts = relPath.split(path.sep);
        const phase = parts[0] || '';
        const meta = getDocumentStatus(fullPath);

        documents.push({
          path: fullPath,
          relPath,
          name: entry.name,
          status: meta.status,
          phase,
        });
      }
    }
  }

  scanDir(udocs);
  return documents;
}

// ============================================================
// checkTraceability
// ============================================================

/**
 * Verify cross-references between SSoT documents.
 * Checks that Related Docs links point to existing files.
 *
 * @returns {{ passed: boolean, issues: Array<{ doc: string, issue: string }> }}
 */
function checkTraceability() {
  const udocs = getUdocsRoot();
  const issues = [];
  const documents = listAllDocuments();
  const docNames = new Set(documents.map(d => d.name));

  for (const doc of documents) {
    const basename = doc.name;
    const expected = TRACEABILITY_MAP[basename];

    if (!expected) continue;

    const meta = getDocumentStatus(doc.path);
    const relatedFiles = meta.relatedDocs.map(p => path.basename(p));

    for (const expectedDoc of expected) {
      // Only check if the expected doc actually exists in u-docs/
      if (!docNames.has(expectedDoc)) continue;

      if (!relatedFiles.some(f => f === expectedDoc || f.includes(expectedDoc.replace('.md', '')))) {
        issues.push({
          doc: basename,
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
  listAllDocuments,
  checkTraceability,
};
