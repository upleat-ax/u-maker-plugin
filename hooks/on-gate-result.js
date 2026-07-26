// on-gate-result.js
// Trigger: loop-state.json updated
// Action: check if loop should continue or stop, and emit deploy-readiness
// PBGD v4.0: two thresholds — passThreshold (95) and deployThreshold (98).
//            Every run also emits .state/deploy-readiness.json for /um-deploy to consume.
const fs = require('fs');
const path = require('path');

const PASS_THRESHOLD = 95;
const DEPLOY_THRESHOLD = 98;

module.exports = async function onGateResult({ filePath, projectRoot }) {
  const umaker = path.join(projectRoot, '.u-maker');
  const statePath = path.join(umaker, '.state', 'loop-state.json');
  const deployReadinessPath = path.join(umaker, '.state', 'deploy-readiness.json');

  if (filePath !== statePath) return;

  const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));

  // Loop control (v3.x semantics, preserved)
  if (state.loopActive) {
    if (state.avgScore >= PASS_THRESHOLD) {
      state.loopActive = false;
      state.result = 'PASS';
      state.completedAt = new Date().toISOString();
    } else if (state.retryCount >= 3) {
      state.loopActive = false;
      state.result = 'ESCALATE';
      state.completedAt = new Date().toISOString();
    }
    fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
  }

  // Deploy-readiness emission (v4.0 — every run, regardless of loopActive)
  if (typeof state.avgScore === 'number') {
    const docScore = state.avgScore;
    const passed = docScore >= PASS_THRESHOLD;
    const deployReady = docScore >= DEPLOY_THRESHOLD;
    const readiness = {
      app: state.app || null,
      docScore,
      passThreshold: PASS_THRESHOLD,
      deployThreshold: DEPLOY_THRESHOLD,
      passed,
      deployReady,
      reason: deployReady
        ? 'docScore meets deployThreshold'
        : passed
          ? `docScore ${docScore} < deployThreshold ${DEPLOY_THRESHOLD}`
          : `docScore ${docScore} < passThreshold ${PASS_THRESHOLD}`,
      checkedAt: new Date().toISOString()
    };
    fs.mkdirSync(path.dirname(deployReadinessPath), { recursive: true });
    fs.writeFileSync(deployReadinessPath, JSON.stringify(readiness, null, 2));
  }
};
