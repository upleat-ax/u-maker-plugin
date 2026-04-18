---
name: u-deploy
description: "This skill should be used when the user asks to 'deploy', 'ship', 'release', 'generate CI/CD', '/u-deploy'. Interactive: asks for target platform(s) and artifact scope. Gates on Gatekeeping doc score ≥ 98. Supports continuous regeneration when SSoT changes."
version: 4.0.0
triggers:
  - "/u-deploy"
  - "deploy phase"
  - "ship"
  - "release"
  - "CI/CD"
---

# u-deploy — Deploy Phase (PBGD Deploy)

`/u-deploy [--auto] [--loop] [--app {name}] [--target {platform,...}] [--artifacts {type,...}] [--force]`

Generate Deploy-phase artifacts: CI/CD pipelines, platform configs, deploy scripts, runbooks, env templates, release notes, smoke tests. Interactive by default — asks the user which target platforms and which artifact types to generate. Gated on Gatekeeping doc score ≥ 98. Designed for continuous regeneration: re-runs detect SSoT hash changes and mark stale artifacts for refresh.

**Primary Agent:** u-agent-deploy
**Engine Dependencies:** doc-engine, dep-engine
**Gate Prerequisite:** `.state/deploy-readiness.json` has `deployReady: true` (Gatekeeping avg ≥ 98)
**PBGD Phase:** Deploy

## Arguments

| Argument | Description |
|----------|-------------|
| `--auto` | Skip interactive prompts; require `--target` and `--artifacts` explicitly |
| `--app {name}` | App scope |
| `--loop` | After generation, re-check the deploy gate and source-hash drift; re-runs generation for stale artifacts up to `loopMaxRetries`. Complements `hooks/on-deploy-state.js` by making the recheck explicit within a single invocation. |
| `--target {platform,…}` | Comma-separated: `vercel`, `netlify`, `cloudflare-pages`, `github-pages`, `docker`, `cloud-run`, `aws-amplify`, `aws-ecs`, `aws-lambda`, `kubernetes`, `fly-io`, `railway`, `render`, `custom` |
| `--artifacts {type,…}` | Comma-separated: `ci-pipeline`, `platform-config`, `deploy-script`, `runbook`, `env-template`, `release-notes`, `smoke-test` |
| `--force` | Regenerate even if `.state/deploy-readiness.json` says `deployReady: false` (NOT recommended; writes warning comments into artifacts) |

## Execution Flow

### Step 0: Gate Precondition

1. Read `.state/deploy-readiness.json`.
2. If file missing → error `"Run /u-gatekeeping first."`.
3. If `deployReady: false` and `--force` not set → error with the `reason` field; exit.
4. Record `gate.docScore` and `gate.deployReady` into the in-progress manifest.

### Step 1: Target selection (interactive)

If `--target` not provided:

```
Select deploy target platform(s) [multi-select]:
  [ ] vercel
  [ ] netlify
  [ ] cloudflare-pages
  [ ] github-pages
  [ ] docker
  [ ] cloud-run
  [ ] aws-amplify
  [ ] aws-ecs
  [ ] aws-lambda
  [ ] kubernetes
  [ ] fly-io
  [ ] railway
  [ ] render
  [ ] custom (enter name)
```

Multiple targets allowed. See `references/target-matrix.md` for what each target implies.

### Step 2: Artifact selection (interactive)

If `--artifacts` not provided:

```
Select artifact types to generate [multi-select]:
  [x] ci-pipeline       (default — GitHub Actions / GitLab CI / …)
  [x] platform-config   (default — per-target config file)
  [ ] deploy-script     (shell script to trigger deploy)
  [x] runbook           (default — deployment runbook .md)
  [x] env-template      (default — .env.example + secrets checklist)
  [ ] release-notes     (release notes template)
  [ ] smoke-test        (post-deploy smoke test checklist)
```

See `references/artifact-scope.md` for contents of each artifact type.

### Step 3: Source-hash snapshot

Compute SHA-256 of each SSoT document:

- `docs/{app}/plan/srs.md`, `ia.md`
- `docs/{app}/design/{erd,api,screens,design-system}.md`
- `docs/{app}/gatekeeping/{testcases,test-results}.md`
- Aggregate hash of generated code trees (FE/BE/DB)

Store in `sourceHashes{}` of the deploy manifest.

### Step 4: Generate artifacts

For each (target, artifact) pair:

1. Pick the appropriate template from `_meta/templates/ci-*.template.*`, `deploy-runbook.template.md`, `env.template`, etc.
2. Render with app/target/threshold variables.
3. Write to `.u-maker/deploy/{target}/{artifact-file}` (e.g., `.u-maker/deploy/vercel/vercel.json`).
4. Record in `artifacts[]` of the deploy manifest with `status: "fresh"` and `generatedFrom: [template-path]`.

Some artifacts are target-specific (e.g., `vercel.json` only for vercel); others are platform-agnostic (e.g., runbook).

### Step 5: Write deploy manifest

Emit `.u-maker/data/deploy/manifest.json` conforming to `_meta/schemas/deploy-manifest.schema.json`. This is the SSoT for the Deploy phase and the key input for continuous regeneration.

### Step 6: Update links.json

For each generated artifact, add a node with `type: "deploy-artifact"`, `phase: "deploy"`, and a `deploys` edge from the SSoT doc whose hash contributed to its generation.

### Step 7: Summary

```
Deploy artifacts ready.
  App:          {app}
  Gate:         docScore {N}/100  (deployReady: true)
  Targets:      vercel, docker
  Artifacts:    ci-pipeline, platform-config, runbook, env-template
  Manifest:     .u-maker/data/deploy/manifest.json
  Next:         Commit, push, and trigger your CI. Re-run /u-deploy to refresh on SSoT changes.
```

## Continuous regeneration

`hooks/on-deploy-state.js` watches for changes in SSoT docs. When a source-hash drift is detected, the hook:

1. Marks the affected artifacts as `status: "stale"` in the manifest.
2. Writes a notice to `.state/deploy-stale.json` with the drift details.
3. On the next `/u-deploy` invocation (or on demand), the agent regenerates only the stale artifacts.

## Preconditions

- `.u-maker/` exists and is v4-compliant.
- `/u-gatekeeping` has produced a current `deploy-readiness.json` with `deployReady: true`.
- The relevant SSoT docs exist for the hashes to be computed.

## Postconditions

- `.u-maker/data/deploy/manifest.json` is valid against `deploy-manifest.schema.json`.
- Every artifact listed in the manifest exists on disk.
- Every SSoT doc used as a hash source is referenced in `sourceHashes{}`.
- `links.json` has `deploys` edges for each artifact.

## Reference Files

- **`references/target-matrix.md`** — Per-target capabilities and constraint matrix.
- **`references/artifact-scope.md`** — Contents of each artifact type.
- **`references/gate-check.md`** — ≥ 98 gate enforcement rules.

## Related Commands

- `/u-gatekeeping` — Must pass with avg ≥ 98 before Deploy can run.
- `/u-output` — Orthogonal (HTML output of SSoT docs); may be included in certain deploy targets (e.g., github-pages).
