# jenkins-gotchas — Key gotchas baked into the templates

Detailed catalogue of real failure modes from prior `/u-tools-jenkins-deploy` runs. The templates in `templates/*.template` are written to avoid each of these — this reference exists so anyone editing the templates (or debugging an unusual setup) knows WHY each pattern is the way it is.

## 1. Jenkins agent has no python3 / jq (BlueOcean image)

Use `grep -oE '"name":"[^"]+"'` + `sed` for trivial JSON parsing. For complex JSON, install `pipeline-utility-steps` plugin to get `readJSON`.

## 2. Pipeline runs in sandbox by default

`new java.io.File(String)` is rejected. Use `sh "cat ${path}"` and `sh "printf '%s\n' '${val}' > '${path}'"` for state file I/O.

## 3. `parameters {}` block resets job-level defaults on first build

Set the right values in the Jenkinsfile directly. Don't rely on UI-set defaults that get clobbered by the first pipeline-evaluating build.

## 4. Bash heredoc + Groovy `${...}` collision

When building Groovy via shell heredoc, use **non-expanding** `<<'EOF'` + placeholder substitution (`__B64__`) via Python, not bash variable expansion:

```bash
B64=$(base64 -i Jenkinsfile)
python3 -c "
import base64
t = open('template.groovy').read()
print(t.replace('__B64__', base64.b64encode(open('Jenkinsfile','rb').read()).decode()))
" > final.groovy
```

## 5. `docker image prune` in deploy stalls

Multi-minute hangs on hosts with 30+ dangling layers. The template omits it. Run via separate cron if disk needs reclaim.

## 6. First-build cache mounts populate; subsequent builds hit them

Communicate this expectation to the user:
- First build ~7–10 min
- Repeats ~30 s on no-change
- 2–4 min on source change

## 7. `Dockerfile*` excluded by `.dockerignore` — Jenkinsfile is NOT

Jenkinsfile commits invalidate the COPY layer. If many CI-only commits are expected, add `**/Jenkinsfile` to `.dockerignore` (the template does).

## 8. `conf.d/default.conf`'s `server_name localhost` becomes default server

On a fresh nginx-certbot image it absorbs unknown Host headers → certbot HTTP-01 returns 404. Add the HTTP-only stub server block for the new domain FIRST, then certbot, then upgrade to full HTTP+HTTPS. See `nginx-tls.md` § Step 2.

## 9. Wildcard certs (`*.example.com`) cover subdomains for free

Always check before issuing a new cert. See `nginx-tls.md` § Step 1.

## 10. Two jobs deploy on the same `dev-*` tag

Both polling and both webhooks fire independently per job. State files dedup per job (via `$JENKINS_HOME/{JOB}-state/last-built-tag.txt`). If unintended, narrow tag regex per job (e.g. `dev-foo-.*` vs `dev-bar-.*`).
