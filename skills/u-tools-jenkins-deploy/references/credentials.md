# credentials — `.u-maker/.env` loading + Jenkins credential registration

Reference for **Phase 0** (env loading) and **Phase 4** (credential creation) of `/u-tools-jenkins-deploy`. Defines which environment variables are consumed and which Jenkins credentials are registered from them.

## Phase 0 — Load credentials from `.u-maker/.env`

Before asking the user for anything, load credentials from the project's `.u-maker/.env` file. This is the single source of truth so the user does not paste tokens or passwords into chat.

```bash
ENV_FILE=".u-maker/.env"
if [ -f "$ENV_FILE" ]; then
  set -a; . "$ENV_FILE"; set +a
fi
```

### Keys consumed by this skill

All optional — missing values fall back to interactive prompts or CLI flags.

| Env var | Used by | Notes |
|---------|---------|-------|
| `JENKINS_URL`, `JENKINS_USER`, `JENKINS_TOKEN` | Phases 1, 4, 5, 7, 8 | Jenkins API auth. Token preferred over password. |
| `JENKINS_SSH_HOST`, `JENKINS_SSH_USER`, `JENKINS_SSH_PASS`, `JENKINS_SSH_PORT` | Phase 1 / Phase 7 diagnosis | Used only for `tcpdump` firewall diagnosis. Optional. |
| `DOCKERHUB_NAMESPACE`, `DOCKERHUB_USER`, `DOCKERHUB_TOKEN` | Phase 4 (credential `dockerhub-{ns}`) | Token must have push scope. |
| `GIT_HOST`, `GIT_HOST_USER`, `GIT_HOST_PAT` | Phase 4 (credential `{gitlab\|github}-clone-{user}`) | PAT must have push rights. |
| `DEPLOY_TARGET_HOST`, `DEPLOY_TARGET_USER`, `DEPLOY_TARGET_PASS`, `DEPLOY_TARGET_PORT` | Phases 1, 4, 6, 8 | Target host SSH + nginx + healthcheck. |

**Precedence (highest wins):** CLI flag → `.u-maker/.env` → interactive prompt.

If `.u-maker/.env` does not exist, run `/u-prepare-foldertree` first (or `cp .u-maker/.env.example .u-maker/.env` and fill in). Never write secrets the user pastes back into chat — write them only to `.u-maker/.env` (which is gitignored).

After loading, print a short summary of which keys were resolved vs. still missing — without printing the values themselves — so the user knows what they still need to provide.

```
.u-maker/.env loaded.
  ✓ JENKINS_URL, JENKINS_USER, JENKINS_TOKEN
  ✓ DOCKERHUB_NAMESPACE, DOCKERHUB_USER, DOCKERHUB_TOKEN
  ✓ DEPLOY_TARGET_HOST, DEPLOY_TARGET_USER, DEPLOY_TARGET_PASS
  ✗ GIT_HOST_PAT       (will ask)
  ✗ JENKINS_SSH_HOST   (diagnostic — optional)
```

## Phase 4 — Jenkins credentials registration

Register 3–4 credentials via API (POST to `/credentials/store/system/domain/_/createCredentials`). Source credentials directly from `.u-maker/.env` — do NOT prompt the user for values that are already loaded.

### Required credential IDs

| ID | Type | Contents (from `.u-maker/.env`) | Used by |
|----|------|---------------------------------|---------|
| `dockerhub-{ns}` | UsernamePassword | `$DOCKERHUB_USER` + `$DOCKERHUB_TOKEN` (namespace from `$DOCKERHUB_NAMESPACE`) | Push stage |
| `{job}-target-ssh` | UsernamePassword | `$DEPLOY_TARGET_USER` + `$DEPLOY_TARGET_PASS` | sshCommand in Deploy |
| `gitlab-clone-{user}` or `github-clone-{user}` | UsernamePassword | `$GIT_HOST_USER` + `$GIT_HOST_PAT` | GitSCM checkout |
| `{job}-env-prod` | Secret File | `.env` with NEXT_PUBLIC_* + runtime keys | Build (--build-arg) + Deploy (--env-file) |

If an env-file credential is not needed (app has no env vars), skip and remove the `withCredentials([file(...)])` blocks from the Jenkinsfile.

### Verification

Use XML API (JSON API is sometimes flaky on this Jenkins setup):

```bash
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" "$JENKINS_URL/credentials/store/system/domain/_/api/xml?depth=1"
```
