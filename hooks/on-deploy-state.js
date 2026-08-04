// on-deploy-state.js
// Trigger: any SSoT doc under .u-maker/docs/ changes OR generated code tree changes
// Action: detect source-hash drift against data/deploy/manifest.json; mark affected
//         artifacts as status:"stale" and write .state/deploy-stale.json so the next
//         /u-deploy run knows what to regenerate (continuous regeneration).
// PBGD v4.0.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Maps relative-to-app doc path → manifest sourceHash key.
const DOC_KEY_MAP = {
  'plan/srs.md': 'srs',
  'plan/ia.md': 'ia',
  'design/erd.md': 'erd',
  'design/api.md': 'api',
  'design/screens.md': 'screens',
  'design/design-system.md': 'designSystem',
  'gatekeeping/testcases.md': 'testcases',
  'gatekeeping/test-results.md': 'testResults'
};

function hashFile(p) {
  if (!fs.existsSync(p)) return null;
  const buf = fs.readFileSync(p);
  return 'sha256:' + crypto.createHash('sha256').update(buf).digest('hex');
}

// Parse `.u-maker/docs/{app}/{rel}` from an absolute filePath.
function parseDocPath(filePath, docsRoot) {
  if (!filePath.startsWith(docsRoot + path.sep)) return null;
  const rel = filePath.slice(docsRoot.length + 1); // e.g. "my-app/design/erd.md"
  const firstSep = rel.indexOf(path.sep);
  if (firstSep < 0) return null;
  const app = rel.slice(0, firstSep);
  if (app === 'common') return null;
  const relInApp = rel.slice(firstSep + 1); // e.g. "design/erd.md"
  const key = DOC_KEY_MAP[relInApp];
  if (!key) return null; // not an SSoT doc we track
  return { app, relInApp, key };
}

module.exports = async function onDeployState({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const docsRoot = path.join(umaker, 'docs');
  const manifestPath = path.join(umaker, 'data', 'deploy', 'manifest.json');
  const stalePath = path.join(umaker, '.state', 'deploy-stale.json');

  // Scope: only the exact SSoT doc that was modified.
  const parsed = parseDocPath(filePath, docsRoot);
  if (!parsed) return;

  // If no manifest, there's nothing to invalidate yet (Deploy hasn't run).
  if (!fs.existsSync(manifestPath)) return;

  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  } catch (e) {
    console.warn('[u-maker] on-deploy-state: manifest parse failed at ' + manifestPath + ': ' + e.message);
    return;
  }

  const recorded = manifest.sourceHashes && manifest.sourceHashes[parsed.key];
  if (!recorded) return; // doc not yet tracked by manifest

  // Early-return: if already marked drifted for this doc, skip rewrite.
  let existingStale = null;
  if (fs.existsSync(stalePath)) {
    try {
      existingStale = JSON.parse(fs.readFileSync(stalePath, 'utf8'));
    } catch (e) {
      console.warn('[u-maker] on-deploy-state: deploy-stale.json parse failed: ' + e.message);
    }
  }
  if (
    existingStale &&
    Array.isArray(existingStale.drift) &&
    existingStale.drift.some(d => d.app === parsed.app && d.doc === parsed.key)
  ) {
    return;
  }

  const currentHash = hashFile(filePath);
  if (!currentHash || currentHash === recorded) return;

  const driftEntry = { app: parsed.app, doc: parsed.key, recorded, current: currentHash };

  // Mark fresh artifacts as stale; conservative (template dependency map TBD).
  if (Array.isArray(manifest.artifacts)) {
    for (const a of manifest.artifacts) {
      if (a.status === 'fresh') a.status = 'stale';
    }
  }

  manifest._lastDriftAt = new Date().toISOString();
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

  const driftList = existingStale && Array.isArray(existingStale.drift) ? existingStale.drift : [];
  driftList.push(driftEntry);

  fs.mkdirSync(path.dirname(stalePath), { recursive: true });
  fs.writeFileSync(
    stalePath,
    JSON.stringify(
      {
        detectedAt: new Date().toISOString(),
        drift: driftList,
        note:
          'Run /u-deploy to regenerate stale artifacts. Only drifted sources ' +
          'require regeneration; manifest marks affected artifacts with status:"stale".'
      },
      null,
      2
    )
  );
};
