# nginx-tls — Target Host nginx + TLS Setup (Phase 6)

Reference for **Phase 6** of `/u-tools-jenkins-deploy`. Configures nginx + Let's Encrypt TLS on the deploy target, including the acme-challenge 404 workaround.

## Setup (per deploy domain)

For each deploy domain, SSH using `$DEPLOY_TARGET_HOST` / `$DEPLOY_TARGET_USER` / `$DEPLOY_TARGET_PASS`:

### 1. Cert check (reuse if possible)

```bash
openssl x509 -in /data/nginx/letsencrypt/live/{cert}/fullchain.pem -text -noout | grep DNS
```

If an existing wildcard (`*.domain`) covers the new subdomain → **reuse** (no issuance needed). Wildcard certs cover subdomains for free — always check before issuing a new cert.

### 2. Cert issue (if needed) — two-step to avoid acme-challenge 404

The `conf.d/default.conf`'s `server_name localhost` becomes default server on a fresh nginx-certbot image → it absorbs unknown Host headers → certbot HTTP-01 returns 404. Bypass by writing an HTTP-only stub server block FIRST, reloading nginx, running certbot, then writing the full HTTP+HTTPS config and reloading again:

```bash
# Step A: HTTP-only stub server block for the new domain
#   (acme location + 503 placeholder, written to /data/nginx/conf.d/{domain}.conf)

# Step B: reload
docker exec nginx nginx -s reload

# Step C: issue cert
docker exec nginx certbot certonly --webroot --webroot-path=/var/www/html \
  --non-interactive --agree-tos --register-unsafely-without-email -d {DOMAIN}
```

### 3. Server block (full HTTP+HTTPS)

Render from `templates/nginx-server-block.template`:
- HTTP→HTTPS redirect
- HTTPS `proxy_pass http://172.17.0.1:{PORT}` (Docker bridge gateway from inside the nginx container)
- Include `client_max_body_size 250m;` for apps with large image uploads

### 4. Reload

```bash
docker exec nginx nginx -t && docker exec nginx nginx -s reload
```

## Common failure: acme-challenge 404

If cert issuance returns 404 on `/.well-known/acme-challenge/...`:
- The `conf.d/default.conf` server block is absorbing the unknown Host header.
- Fix: write the HTTP-only stub for the new domain BEFORE running certbot (Step 2 above), then upgrade to full HTTP+HTTPS after issuance succeeds.

Never edit `default.conf` directly — leave it as-is and override per-domain via a higher-priority server block.
