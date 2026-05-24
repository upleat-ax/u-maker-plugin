---
name: u-tools-jenkins-deploy
description: "This skill should be used when the user asks to '/u-tools-jenkins-deploy', 'Jenkins 배포', 'jenkins deploy', 'jenkins job 만들어', 'jenkins ci 추가', 'docker hub push + ssh deploy', or wants to set up Jenkins CI/CD for a Docker-based deploy. Reads Jenkins/Docker/SSH credentials from `.u-maker/.env` (set once, never paste in chat). Covers: Jenkinsfile generation, Jenkins job creation via API, credentials registration, target host nginx + TLS setup, GitLab/GitHub webhook + cron polling fallback, end-to-end verification."
version: 1.0.0
---

# u-tools-jenkins-deploy — Jenkins CI/CD for Docker-based deploys

```
/u-tools-jenkins-deploy [--app PATH] [--domain DOMAIN] [--jenkins-job NAME] [--dry-run]
```

Build → push → ssh-deploy pipeline driven by Jenkins. Architecture matches a working Docker Hub + nginx-certbot + cron polling + tag-trigger setup.

Pattern this skill produces:

```
git tag dev-XXX → GitLab webhook OR Jenkins cron poll (≤5 min)
                 → Jenkins inline pipeline
                 → docker build (BuildKit cache mounts)
                 → docker push {NAMESPACE}/{IMAGE}:<sha> + :latest
                 → ssh root@{TARGET}: pull + rm -f + run + healthcheck
                 → state file dedup ($JENKINS_HOME/{JOB}-state/last-built-tag.txt)
nginx-certbot (existing) → proxy_pass http://172.17.0.1:{PORT}
```

## Phase 0 — Load credentials from `.u-maker/.env`

Load `.u-maker/.env` with `set -a; . .u-maker/.env; set +a` BEFORE asking the user for anything. **Precedence:** CLI flag → `.u-maker/.env` → interactive prompt. Never paste secrets into chat — write them only to `.u-maker/.env` (gitignored). If the file doesn't exist, run `/u-prepare-foldertree` first.

After loading, print a summary of resolved (`✓`) vs. missing (`✗`) keys — without the values.

Full env-var schema (Jenkins/Docker/Git/SSH/diagnostic keys) → **see `references/credentials.md` § Phase 0**.

## Required context (collect upfront — saves 50% of session time)

Anything not already in `.u-maker/.env` should still be confirmed upfront. The single biggest source of round-trips in prior runs was missing context up front — push the user to provide the rest before starting.

| Category | Items | What breaks without it |
|----------|-------|------------------------|
| **App** | Exact app folder path · build system (bun/npm/yarn) · existing Dockerfile? · NEXT_PUBLIC_* and runtime env vars needed | Wrong app deployed; missing client-side env breaks Kakao/Naver/etc. silently |
| **Jenkins** | URL · user/token (`.u-maker/.env`) · SSH access to Jenkins host (for firewall diagnosis) · existing similar job to model after | Plugin probes blocked; can't diagnose network blocks |
| **Git source** | Repo URL · base branch (develop/main) · PAT with push rights (`.u-maker/.env`: `GIT_HOST_PAT`) | Checkout fails; MR creation fails |
| **Docker registry** | Docker Hub namespace · access token with push rights (`.u-maker/.env`) · image name | Push fails after long build |
| **Deploy target** | Host IP · SSH user/pass (`.u-maker/.env`) · SSH port (default 22) · existing nginx/docker · cert state | nginx 502 forever; cert issuance fails |
| **Domain / DNS** | Domain · A-record points where? · cert covers it? (wildcard or new) | Cert issuance + nginx routing both broken |
| **Network** | Can GitLab → Jenkins reach :8888? (firewall awareness) | Webhook silently broken; polling fallback wasted if known upfront |
| **Policy** | Auto-merge allowed? · pre-push lint/build? · secrets in chat or `.u-maker/.env` / Jenkins UI only? | Wrong workflow; security |

A complete first message looks like the **Required context template** at the bottom of this file.

## Execution Flow

### Phase 1: Discovery (read-only)

1. **Repo state**:
   ```bash
   git rev-parse --abbrev-ref HEAD                # current branch
   git remote get-url origin                       # git host (GitLab/GitHub URL)
   cat package.json | jq '.workspaces'             # if monorepo
   ls apps/{APP}/docker/ 2>/dev/null               # existing Dockerfile?
   grep -rn 'process.env.NEXT_PUBLIC_' apps/{APP}/src | sort -u  # client env vars
   ```
2. **Jenkins env probe** (via `/scriptText` Groovy console, using `$JENKINS_URL` + `$JENKINS_USER:$JENKINS_TOKEN`):
   - Docker daemon version, docker compose, git, perl/python3/jq availability
   - Outbound reachability to Docker Hub + target SSH port
3. **Target host probe** (SSH read-only, using `$DEPLOY_TARGET_*`):
   - Docker installed + version
   - Existing containers (`docker ps`) — anti-collision on container name + port
   - nginx container + sites-enabled/ contents
   - Existing TLS certs and their SANs (`openssl x509 -text`)
   - `/etc/nginx/conf.d/default.conf` — may absorb unknown Host headers (causes acme-challenge 404)
4. **Network probe**: `tcpdump -i any 'host {GITLAB_IP} and port {JENKINS_PORT}'` on Jenkins host (`$JENKINS_SSH_*`) during a webhook test — if 0 packets, block is upstream of Jenkins host (router/cloud firewall).
5. **DNS**: `dig +short {DOMAIN}` — confirm A-record points to the intended target.

### Phase 2: Decisions (AskUserQuestion)

Decisions that genuinely change behaviour — surface as a short menu:

1. **Registry**: Docker Hub `${DOCKERHUB_NAMESPACE}/{IMAGE}` (matches `.env`) vs alternate.
2. **Public exposure**: behind nginx + domain vs direct port; if domain, which.
3. **Build-time env**: reuse `.env.local` vs separate prod keys vs skip.
4. **Webhook vs polling**: if Jenkins host is behind a NAT/firewall, propose polling fallback (no router changes needed) with webhook as optional later.

Default everything else (branch=develop, container name=job name, restart=unless-stopped, image tag=`:<sha>` + `:latest`, etc.).

### Phase 3: Repo work — Jenkinsfile, Dockerfile, dockerignore

Work in an **isolated git worktree** so the user's main checkout isn't disturbed:

```bash
git fetch origin --quiet
git worktree add /tmp/{JOB}-wt -b feat/{JOB} origin/{BASE}
```

Generate three files from `templates/` (see end of file):

| File | Source template | What to fill in |
|------|----------------|-----------------|
| `apps/{APP}/docker/Jenkinsfile` | `templates/Jenkinsfile.template` | TARGET_HOST, APP_PORT, CONTAINER_NAME, REMOTE_ENV, image name, healthcheck path, env-file usage |
| `apps/{APP}/docker/Dockerfile` | `templates/Dockerfile.template` (or keep existing) | workspace package.json COPY list, build args, runner copies, EXPOSE, CMD |
| `apps/{APP}/docker/Dockerfile.dockerignore` | `templates/Dockerfile.dockerignore.template` | apps to exclude with `!apps/{x}/package.json` re-includes |

**Validate Jenkinsfile** against Jenkins's pipeline-model linter BEFORE committing:

```bash
curl -s -b $JAR -u "$JENKINS_USER:$JENKINS_TOKEN" -H "$CFIELD: $CVAL" \
  -F "jenkinsfile=</path/to/Jenkinsfile" \
  "$JENKINS_URL/pipeline-model-converter/validate"
# Expect: "Jenkinsfile successfully validated."
```

Run `bun run lint` (or framework equivalent) per CLAUDE.md push-gate, commit, push, open MR/PR. **Do NOT auto-merge.**

### Phase 4: Jenkins credentials

Register 3–4 credentials via API (POST to `/credentials/store/system/domain/_/createCredentials`). Source values directly from `.u-maker/.env` — do NOT prompt for already-loaded values. IDs: `dockerhub-{ns}`, `{job}-target-ssh`, `gitlab-clone-{user}` (or `github-clone-{user}`), `{job}-env-prod` (Secret File, skip if no env vars). Verify with XML API.

Full credential ID table + verification command → **see `references/credentials.md` § Phase 4**.

### Phase 5: Jenkins job creation

Use Groovy via `/scriptText` (POST to job/config.xml frequently 500s on this setup — Groovy is reliable):

```groovy
def job = Jenkins.instance.createProject(WorkflowJob, '{JOB_NAME}')
job.setDefinition(new CpsFlowDefinition(pipelineScript, /*sandbox*/ true))
job.setDescription('...')
job.addProperty(new ParametersDefinitionProperty([
  new StringParameterDefinition('IMAGE_NAMESPACE', '{NS}', '...'),
  new StringParameterDefinition('IMAGE_NAME', '{IMAGE}', '...'),
  new StringParameterDefinition('BRANCH', '{BASE}', '...'),
  new BooleanParameterDefinition('DEPLOY', true, '...'),
]))

// Register triggers directly so they work BEFORE first pipeline-evaluating build.
def trig = new com.dabsquared.gitlabjenkins.GitLabPushTrigger()
trig.setTriggerOnPush(true)
trig.setBranchFilterType(com.dabsquared.gitlabjenkins.trigger.filter.BranchFilterType.RegexBasedFilter)
trig.setTargetBranchRegex('.*dev.*')
job.addTrigger(trig)
job.addTrigger(new hudson.triggers.TimerTrigger('H/5 * * * *'))
job.save()
```

Send the Jenkinsfile content into the Groovy via **base64 + placeholder substitution** (not heredoc — Groovy's `${...}` collides with bash variable expansion):

```bash
B64=$(base64 -i Jenkinsfile)
python3 -c "
import base64
t = open('template.groovy').read()
print(t.replace('__B64__', base64.b64encode(open('Jenkinsfile','rb').read()).decode()))
" > final.groovy
```

### Phase 6: Target host — nginx + TLS

For each deploy domain: cert check (reuse wildcard if covers subdomain) → cert issue with two-step workaround for acme-challenge 404 (HTTP-only stub first → reload → certbot → full HTTP+HTTPS) → server block from `templates/nginx-server-block.template` → `nginx -t && nginx -s reload`.

Full protocol + acme-challenge 404 workaround → **see `references/nginx-tls.md`**.

### Phase 7: Webhook (GitLab) or skip

POST to `/api/v4/projects/{enc}/hooks` with `tag_push_events: true, push_events: false`. URL = `http://{JENKINS_URL_HOST}/project/{JOB_NAME}` (gitlab-plugin convention).

After creation, test from GitLab UI ("Test push events"). If it fails with TCP timeout, the issue is upstream of Jenkins host — verify with `tcpdump` on Jenkins host using `$JENKINS_SSH_*`:

```bash
ssh "$JENKINS_SSH_USER@$JENKINS_SSH_HOST" "sudo timeout 25 tcpdump -i any 'host {GITLAB_IP}'"
# Then trigger webhook test from GitLab
# If 0 packets captured → router/firewall block, NOT host firewall
```

When blocked, document the polling fallback as the active path and the webhook as inert-but-ready.

### Phase 8: First build + verify

```bash
curl -X POST -u "$JENKINS_USER:$JENKINS_TOKEN" -H "$CFIELD: $CVAL" \
  --data-urlencode "IMAGE_NAMESPACE=$DOCKERHUB_NAMESPACE" \
  --data-urlencode "BRANCH={BUILD_BRANCH}" \
  --data-urlencode "DEPLOY=true" \
  "$JENKINS_URL/job/{JOB}/buildWithParameters"
```

Poll status via Groovy (XML API on this Jenkins is flaky; Groovy is reliable). When finished:

- ✅ Container running: `docker ps --filter name={CONTAINER}` on `$DEPLOY_TARGET_HOST`
- ✅ External 200: `curl -sI https://{DOMAIN}/{health-path}`
- ✅ Docker Hub tag visible: `curl https://hub.docker.com/v2/repositories/$DOCKERHUB_NAMESPACE/{IMAGE}/tags/`

Update CLAUDE.md and memory if useful for future invocations.

## Key gotchas baked into the templates

10 known failure modes from prior runs (sandbox restrictions, BlueOcean-image missing tools, Groovy/bash `${...}` collision, docker prune stalls, cache-mount expectations, dockerignore Jenkinsfile, nginx default-server absorbing acme-challenge, wildcard cert reuse, multi-job tag collisions). Templates in `templates/*.template` are written to avoid each.

Full catalogue with mitigations → **see `references/jenkins-gotchas.md`**.

## Templates (in this skill's directory)

| File | Purpose |
|------|---------|
| `templates/Jenkinsfile.template` | Full working pipeline (Validate → Resolve ref → Checkout → Build → Push → Deploy → post.success state write). Placeholders: `{{TARGET_HOST}}`, `{{APP_PORT}}`, `{{CONTAINER_NAME}}`, `{{HEALTH_PATH}}`, `{{IMAGE_NAME}}`, `{{STATE_DIR}}`, `{{USE_ENV_FILE}}`, `{{BUILD_ARGS_BLOCK}}` |
| `templates/Dockerfile.template` | Multi-stage Next.js + Turborepo + bun Dockerfile with BuildKit cache mounts. Placeholders: `{{APP_NAME}}`, workspace package.json COPY list |
| `templates/Dockerfile.dockerignore.template` | Excludes other apps' source, re-includes their `package.json` for workspace install |
| `templates/nginx-server-block.template` | HTTP→HTTPS + HTTPS proxy_pass + wildcard cert reuse |

Render placeholders with simple `str.replace()` or `sed` — the placeholders are unambiguous (`{{NAME}}` syntax).

## Options

| Option | Default | Description |
|--------|---------|-------------|
| `--app PATH` | (ask) | App folder path (e.g. `apps/myapp`) |
| `--domain DOMAIN` | (ask) | Public domain (e.g. `myapp.example.com`) |
| `--jenkins-job NAME` | derived from `--app` | Jenkins job name (e.g. `myapp-dev`) |
| `--target IP` | `$DEPLOY_TARGET_HOST` | Target host IP for ssh deploy |
| `--port N` | (from app dev script) | Container port |
| `--registry-image NAME` | `$DOCKERHUB_NAMESPACE/{IMAGE}` | Docker image (e.g. `acme/myapp`) |
| `--base BRANCH` | `develop` | Base branch for MR/PR |
| `--no-env-file` | OFF | App has no env vars; skip secret-file credential and `--env-file` |
| `--dry-run` | OFF | Show the plan and templates that would be rendered without writing or executing |

## Error handling

| Error | Action |
|-------|--------|
| `.u-maker/.env` missing | Suggest `/u-prepare-foldertree` (or `cp .u-maker/.env.example .u-maker/.env`) before retrying; fall back to interactive prompts if user proceeds anyway |
| Jenkinsfile linter fails | Show error, do NOT push or create job |
| `pipeline-utility-steps` missing AND complex JSON parsing needed | Suggest install or fall back to grep+sed |
| Sandbox `new File(...)` rejection | Replace with `sh "cat ${path}"` / `sh "printf > ${path}"` |
| `docker push` fails with auth error | Verify `DOCKERHUB_TOKEN` in `.u-maker/.env` has push scope |
| `sshCommand` hangs on `docker image prune` | Remove that step from deploy (already absent in template) |
| Cert issuance 404 on acme-challenge | The conf.d default server is absorbing. Write HTTP-only stub for the new domain, reload, retry certbot |
| Webhook test "Failed to open TCP connection" | tcpdump on Jenkins host. If 0 packets → router/firewall, offer polling-only |
| Two jobs both deploy on every tag | Confirm with user that's intended. If not, narrow tag regex per job (e.g. `dev-foo-.*` vs `dev-bar-.*`) |

## Examples

```bash
# Full interactive — Claude reads .u-maker/.env and asks only for what's missing
/u-tools-jenkins-deploy

# Most details upfront (CLI flags override .env)
/u-tools-jenkins-deploy --app apps/myapp --domain myapp.example.com \
  --target 10.0.0.10 --port 3000 --registry-image acme/myapp

# Preview without writing/executing
/u-tools-jenkins-deploy --app apps/myapp --domain myapp.example.com --dry-run

# App has no env vars — skip secret-file credential
/u-tools-jenkins-deploy --app apps/myapp --domain myapp.example.com --no-env-file
```

## Required context template (paste this in the first message for fastest setup)

For credentials, populate `.u-maker/.env` (NEVER paste secrets in chat). Then provide only the non-secret context:

```
이 레포의 {APP_PATH} 앱을 Jenkins 로 자동 배포해줘.
/u-tools-jenkins-deploy 흐름대로 진행.
Jenkins / Docker Hub / Git PAT / 배포 타겟 SSH 자격증명은 .u-maker/.env 에 적어뒀어.

[App]
  - 폴더: {APP_PATH}              예: apps/myapp
  - 빌드: {bun|pnpm|npm} / {Next.js|Vite|NestJS|...}
  - 모노레포면 root workspaces: {list or "see package.json"}
  - 기존 Dockerfile: {YES + 경로 | NO}
  - 빌드타임 env (NEXT_PUBLIC_*): {list or "see .env.local"}
  - 런타임 env: {list or "none"}

[Jenkins]
  - 기존 비슷한 잡: {NAME or "none"}                   # 참고 모델

[Git source]
  - 호스트: {GitLab|GitHub} {URL}
  - 베이스 브랜치: {develop|main}

[배포 타겟]
  - 도메인: {DOMAIN}                                   # DNS A-record 확인 부탁
  - 컨테이너 포트: {PORT}
  - nginx-certbot 동작 중? {YES + cert 도메인 | NO}

[Docker registry]
  - 이미지 이름: {NS}/{IMAGE}                          # 또는 .env DOCKERHUB_NAMESPACE 사용

[정책]
  - 자동 머지 금지 / 사용자가 직접
  - push 전 lint 필수

파괴적 단계 (Jenkins job 생성, nginx reload, 첫 빌드 트리거) 전마다
확인 받아.
```

## Related skills

- `u-prepare-foldertree` — Creates `.u-maker/.env.example` and bootstraps `.u-maker/.env`. Run this once per project before `/u-tools-jenkins-deploy`.
- `commit-commands:commit-push-pr` — used inside Phase 3 (commit + push + MR), the no-merge policy is honored.
- `u-tools-git-pr` — for splitting Jenkins setup commits into separate MRs if the user prefers.
- `verify` — run after Phase 8 to confirm end-to-end via browser.
