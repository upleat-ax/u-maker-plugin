// on-deploy-state.js
// Trigger: any SSoT doc under .u-maker/docs/ changes OR generated code tree changes
// Action: detect source-hash drift against data/deploy/manifest.json; mark affected
//         artifacts as status:"stale" and write .state/deploy-stale.json so the next
//         /u-deploy run knows what to regenerate (continuous regeneration).
// PBGD v4.0.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const SSOT_DOCS = [
  ['plan/srs.md', 'srs'],
  ['plan/ia.md', 'ia'],
  ['design/erd.md', 'erd'],
  ['design/api.md', 'api'],
  ['design/screens.md', 'screens'],
  ['design/design-system.md', 'designSystem'],
  ['gatekeeping/testcases.md', 'testcases'],
  ['gatekeeping/test-results.md', 'testResults']
];

function hashFile(p) {
  if (!fs.existsSync(p)) return null;
  const buf = fs.readFileSync(p);
  return 'sha256:' + crypto.createHash('sha256').update(buf).digest('hex');
}

module.exports = async function onDeployState({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const manifestPath = path.join(umaker, 'data', 'deploy', 'manifest.json');
  const stalePath = path.join(umaker, '.state', 'deploy-stale.json');

  // Only react to changes inside .u-maker/docs/ or the generated code tree marker
  if (!filePath.startsWith(path.join(umaker, 'docs'))) return;

  // If no manifest, there's nothing to invalidate yet (Deploy hasn't run)
  if (!fs.existsSync(manifestPath)) return;

  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  } catch {
    return; // corrupted manifest; skip
  }

  const apps = fs.readdirSync(path.join(umaker, 'docs')).filter(n => n !== 'common');
  const drift = [];

  for (const app of apps) {
    for (const [rel, key] of SSOT_DOCS) {
      const full = path.join(umaker, 'docs', app, rel);
      const currentHash = hashFile(full);
      const recorded = manifest.sourceHashes && manifest.sourceHashes[key];
      if (currentHash && recorded && currentHash !== recorded) {
        drift.push({ app, doc: key, recorded, current: currentHash });
      }
    }
  }

  if (drift.length === 0) return;

  // Mark all artifacts as stale; a more nuanced mapping could mark only artifacts
  // whose template depends on the drifted doc, but conservative is fine here.
  if (Array.isArray(manifest.artifacts)) {
    for (const a of manifest.artifacts) {
      if (a.status === 'fresh') a.status = 'stale';
    }
  }

  manifest._lastDriftAt = new Date().toISOString();
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

  fs.mkdirSync(path.dirname(stalePath), { recursive: true });
  fs.writeFileSync(
    stalePath,
    JSON.stringify(
      {
        detectedAt: new Date().toISOString(),
        drift,
        note:
          'Run /u-deploy to regenerate stale artifacts. Only drifted sources ' +
          'require regeneration; manifest marks affected artifacts with status:"stale".'
      },
      null,
      2
    )
  );
};
