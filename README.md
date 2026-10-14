# ezzcaddy — Caddy with batteries included

Docker image: `d3b0x0/caddy` ([Docker Hub](https://hub.docker.com/r/d3b0x0/caddy))
Source: [Codeberg](https://codeberg.org/D3B-0x0/ezzcaddy) (mirrored to GitHub for CI builds)

A ready-made reverse proxy: one container that sits in front of your apps,
gives them `https://` addresses, and optionally adds a firewall (CrowdSec)
and a login page (Pocket-ID + oauth2-proxy). Drop-in replacement for the
official Caddy image — same paths, same defaults, nothing proprietary.

> **Philosophy:** the image *contains* everything; your compose + Caddyfile
> *choose* what runs. Uncomment = on, commented = off. Unused modules cost
> disk, zero CPU/RAM.

---

## New to self-hosting? Start here (2 min read)

A **reverse proxy** is a receptionist for your apps. Instead of exposing
every app on its own port (`http://server:3000`, `:8080`, …), you expose ONE
thing (Caddy on ports 80/443) and it routes by domain name:

```
internet → Caddy (https://app.example.com) → your app (port 3000, hidden)
                                           → another app (port 8080, hidden)
```

**Words you'll see in this repo, in plain language:**

| Word | What it actually is |
|---|---|
| `https://` / cert | A certificate proves your server is who it claims. Caddy gets + renews these automatically (Let's Encrypt). |
| DNS-01 | A way to prove you own a domain by adding a DNS record. Works behind home NAT/CGNAT, gives wildcard certs (`*.example.com`). Needs a token from your DNS company. |
| WAF (CrowdSec) | A bouncer that reads logs and blocks scanners/bots by IP. Optional. |
| SSO (Pocket-ID + oauth2-proxy) | A login page in front of private apps. Pocket-ID = where users log in (passkeys). oauth2-proxy = the guard that asks "logged in?" on every request. Optional. |
| GeoIP | Block/allow whole countries. Optional, needs a free MaxMind account. |
| Rate limit | "Max 10 login tries per minute" — slows password guessing. Optional. |
| Compose | Docker Compose = one YAML file describing which containers run + how they talk. `docker compose up -d` starts them. |

**What you need before starting:**

1. Docker + Docker Compose plugin (`docker compose version` must work).
2. A terminal. Every command below runs on your own machine/VPS.
3. A domain (optional for testing — see demo mode, required for real `https://`).

**The golden rule:** start SIMPLE, get one site working, THEN add firewall/login.
Students who jump straight to "Max mode" drown. Mode 0 first. Always.

---

## Choose your path

| | Simple | Full (universal) |
|---|---|---|
| Files | `examples/docker-compose.yaml` + `examples/Caddyfile` | `examples/docker-compose.full.yaml` + `examples/Caddyfile.full` + `*.env.example` |
| Runs | Caddy only | Caddy + CrowdSec + oauth2-proxy + Pocket-ID + GeoIP (each opt-in) |
| For | First-timers, one app, "just give it https" | Homelab / VPS edge, "I want firewall + login + country gates" |
| Secrets | `caddy.env` only (and only if using DNS-01) | Only the `.env` files for features you enable |

Both paths use the **same image**. Start simple, graduate to full. No reinstall.

---

## Quickstart — Simple (copy, edit, run)

```bash
cd examples
cp docker-compose.yaml compose.yaml
cp Caddyfile Caddyfile.local
cp caddy.env.example caddy.env
chmod 600 caddy.env
docker compose up -d
docker logs -f caddy
```

What each step did (no magic):

1. `cp docker-compose.yaml compose.yaml` — your local copy to run. The original stays pristine as reference.
2. `cp Caddyfile Caddyfile.local` — open it, change `demo.example.com` to YOUR domain, change `reverse_proxy demo:80` to YOUR app (`myapp:3000`). One site first.
3. `cp caddy.env.example caddy.env` — secret tokens live here, never in git. If you're NOT using DNS-01 (plain public server), leave it empty — HTTP-01 just works.
4. `docker compose up -d` — starts Caddy in the background. `docker logs -f caddy` — watch it fetch your cert. `Ctrl+C` exits the log view, container keeps running.

Open `https://YOUR-domain` — you should see your app with a valid lock icon.
If not, see [When something breaks](#when-something-breaks) below.

Pin a dated tag in production (`d3b0x0/caddy:20261014`); `latest` moves with
the weekly build.

---

## Quickstart — Full (universal stack)

Same idea, more pieces. **Do the Simple path first** — if Caddy alone doesn't
serve your domain, adding a firewall won't fix it.

```bash
cd examples
cp docker-compose.full.yaml compose.yaml
cp Caddyfile.full Caddyfile
cp caddy.env.example caddy.env
chmod 600 caddy.env
# --- ONLY the files for features YOU enable (leave the rest — they stay inert):
# cp oauth2.env.example oauth2.env            # SSO mode
# cp pocketid.env.example pocketid.env        # SSO mode
# cp geoipupdate.env.example geoipupdate.env  # GeoIP mode
# chmod 600 oauth2.env pocketid.env geoipupdate.env

docker compose config                         # lint — must exit 0, shows no secrets
docker compose up -d
docker logs -f caddy
```

### Pick your mode (uncomment = on, commented = off — nothing else)

| Mode | Plain meaning | Uncomment in compose | Fill env | Uncomment in Caddyfile |
|---|---|---|---|---|
| **0 — Minimal** (default) | Just `https://` for your apps | nothing (caddy only) | `caddy.env` if DNS-01 | Recipe A site |
| **1 — Standard** (firewall) | + bots/scanners get blocked | `crowdsec:` | `CROWDSEC_CADDY_KEY` (`cscli bouncers add caddy`) | global `crowdsec` block + `import crowdsec` |
| **2 — Login** (SSO) | + private pages ask for login | `pocket-id:` FIRST, then `oauth2-proxy:` | `pocketid.env` then `oauth2.env` | `(sso-gate)` + `import sso-gate` on private sites only |
| **3 — Max** (all) | Firewall + login + country + rate rules | all above + `geoipupdate:` | all above | all above + `import geoip-allow` + `import login-ratelimit` |

**SSO order matters (do it in this order or it won't work):**

1. Start `pocket-id` → open its URL → create your admin account.
2. In Pocket-ID, create an OIDC client for oauth2-proxy. Redirect URL =
   whatever you put as `OAUTH2_PROXY_REDIRECT_URL` (e.g.
   `https://sso.example.com/oauth2/callback`). Copy the client ID + secret.
3. Paste those into `oauth2.env`, start `oauth2-proxy`.
4. In the Caddyfile, add `import sso-gate` ONLY to sites you want private.
   Keep APIs with their own keys UNGATED — cookie login breaks API clients.

### File map (`examples/`)

```
docker-compose.yaml        simple: caddy + optional geoipupdate
Caddyfile                  simple: one site, commented crowdsec/dns
docker-compose.full.yaml   universal: caddy + crowdsec + oauth2 + pocket-id + geoip + demo
Caddyfile.full             universal: snippets + recipes A/B/C/D + SSO infra sites
caddy.env.example          DNS token + CROWDSEC_CADDY_KEY + ACME_EMAIL + SSO_DOMAIN
oauth2.env.example         OIDC issuer, client ID/secret, cookie domain/secret
pocketid.env.example       APP_URL, ENCRYPTION_KEY, optional SMTP/MaxMind
geoipupdate.env.example    MaxMind account ID + license key
```

Real `*.env` files are git-ignored. `git status --short` should NEVER show a
`.env`. Generate secrets with:

```bash
openssl rand -hex 32                # encryption keys
openssl rand -base64 32 | head -c 32  # cookie secrets
```

---

## When something breaks (read this before asking for help)

90% of failures are one of these three. Check in order:

```bash
# 1. Did compose even parse? (typo in YAML, missing env file)
docker compose config | head -20
# 2. Are containers running? (look for Restarting / Unhealthy)
docker ps --format 'table {{.Names}}\t{{.Status}}'
# 3. What does Caddy say? (cert errors, DNS failures, 502 causes all land here)
docker logs --tail 50 caddy
# 4. Is my Caddyfile even valid? (edit → validate → reload, never skip)
docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

| Symptom | Usual cause | Fix |
|---|---|---|
| `502 Bad Gateway` | App isn't on the same `proxy` network as Caddy | Add `networks: [proxy]` to your app (or run it in the same compose file) |
| Cert never issues, `dial tcp 0.0.0.0:443` at BUILD | Your DNS blocks Go module CDNs | Whitelist `proxy.golang.org` + `storage.googleapis.com`, rebuild |
| Cert never issues at RUNTIME | Wrong DNS token / token lacks DNS:Edit | Regenerate token, check `caddy.env`, `docker compose up -d` again |
| `429` on normal browsing | Blanket rate_limit zone counting every subrequest | Scope it to `/login` paths only (see recipe below), or remove it |
| Login loop (SSO bounces forever) | `OAUTH2_PROXY_REDIRECT_URL` ≠ Pocket-ID client URL | Make them character-identical, restart oauth2-proxy |
| CrowdSec 503s everything | Wrong/empty `CROWDSEC_CADDY_KEY` | `docker exec crowdsec cscli bouncers add caddy`, paste new key |

---

## What's inside (the full list)

Base: Caddy `v2` (floating, rebuilt weekly) on Alpine.
Arch: **`linux/amd64` only**.
ARM / Raspberry Pi: `git clone` + `docker build .` — works, just slower.

| Module | What it gives you | When it runs |
|---|---|---|
| `caddy-dns/*` (all ~95 providers) | DNS-01 ACME — wildcard certs, no open port 80, works behind NAT/CGNAT | When your Caddyfile has an `acme_dns <name>` line |
| `caddy-crowdsec-bouncer/http` | `crowdsec` + `appsec` directives — firewall + bans via your own CrowdSec | When you add `crowdsec` / `appsec` to a site |
| `caddy-maxmind-geolocation` | Country matchers (`allow_countries` / `deny_countries`) | When you add a `maxmind_geolocation` matcher (needs a `.mmdb`) |
| `caddy-ratelimit` | `rate_limit` zones (always scope with `match`) | When you add a `rate_limit` block |
| `caddy-l4` | Raw TCP/UDP proxying | When you define a `layer4` stream (idle otherwise) |

Deliberately absent: `caddy-security` (would duplicate oauth2-proxy +
Pocket-ID — one login system, not two), exec/script plugins (remote-execution
risk), cache (invalidation bugs cost more than the latency saved), Docker-label
auto-discovery (explicit Caddyfile beats magic for a security edge).

---

## Common setups (copy-paste shapes)

Full commented versions live in `Caddyfile.full` — these are the skeletons:

**Plain proxy** (Recipe A):

```caddyfile
example.com {
    import secure-headers
    reverse_proxy app:3000
}
```

**Wildcard cert via DNS-01** (token from `caddy.env`, never written here):

```caddyfile
{
    acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
}
*.example.com {
    reverse_proxy app:3000
}
```

**Firewall in front** (Recipe B — same Docker network; `order` is mandatory):

```caddyfile
{
    order crowdsec first
    order appsec after crowdsec
    crowdsec {
        api_url http://crowdsec:8080
        api_key {env.CROWDSEC_CADDY_KEY}
        appsec_url http://crowdsec:7422
    }
}
example.com {
    crowdsec
    appsec
    reverse_proxy app:3000
}
```

**Country gate** (Recipe D — needs `geoipupdate` service + shared volume):

```caddyfile
example.com {
    @blocked {
        not maxmind_geolocation {
            db_path /usr/share/GeoIP/GeoLite2-Country.mmdb
            allow_countries IN US DE IN
        }
    }
    respond @blocked 403
    reverse_proxy app:3000
}
```

**Login in front** (Recipe C — Pocket-ID via oauth2-proxy, bridge mode):

```caddyfile
example.com {
    import sso-gate
    reverse_proxy app:3000
}
```

> Host-mode alternative (author's VPS legacy): `forward_auth
> host.docker.internal:4180` + `extra_hosts:
> host.docker.internal:host-gateway` on caddy. The default bridge mode needs
> neither.

**Rate limit that doesn't hurt real users** — scope to login paths only (one
page load = 10–20 subrequests; a global zone 429s everyone):

```caddyfile
example.com {
    rate_limit {
        zone login {
            match { path /login /oauth2/* }
            events 10
            window 1m
        }
    }
    reverse_proxy app:3000
}
```

---

## Reference (for when you're comfortable)

**Ports.** `80`+`443` TCP for HTTP/S; same pair UDP for HTTP/3 (uncomment in
compose — free, drop if unwanted).

**Persistence.** `/data` = certs + ACME state — back it up (Let's Encrypt caps
at 50/week/domain; losing it reissues everything). `/config` = disposable.
`crowdsec-data` + `pocketid-data` = bans/users — back those up in WAF/SSO modes.

**Admin API** `:2019` inside the container only — never publish it.
(`docker exec caddy wget -qO- http://127.0.0.1:2019/config/`).

**Logs.** `log { output stdout format json }` *per site* = access logs. A
global `log` block alone only sets the process logger. For CrowdSec file
intake, log to `/shared-logs/access.log` (needs the `./logs` mount on both
caddy and crowdsec).

---

## Updating

No hand rebuilds. GitHub Actions rebuilds + pushes on every `Dockerfile`
change, every Sunday (floats to newest `caddy:2` + plugins), and on manual
dispatch. Tags: `latest` + `YYYYMMDD` + short SHA. `pull: true` stops weekly
builds silently reusing a stale base.

```bash
docker compose pull caddy && docker compose up -d
docker exec caddy caddy version
```

A bad upstream commit *can* break a Sunday build — fix = pin that module
(`module@version`) and push; SHA tags let you pull any proven build back.
Production: pin a dated tag, bump deliberately.

> GitHub quirk: schedules run only on default branch (`main`), disabled after
> 60 idle days. Any push (incl. Codeberg→GitHub mirror sync) counts as
> activity. Sunday builds stopped? Re-enable in Actions or push anything.

---

## Build it yourself

```bash
git clone https://codeberg.org/D3B-0x0/ezzcaddy.git
cd ezzcaddy
docker build -t ezzcaddy .     # ~10 min with all DNS providers, amd64
```

Build needs `proxy.golang.org` + `storage.googleapis.com` — `dial tcp
0.0.0.0:443` = your DNS filter, not the Dockerfile. To slim down, delete
`--with` lines you never use and rebuild.

`mk-geoip-env.sh` builds `geoipupdate.env` from on-box secrets (never leaves it):

```bash
sudo ./mk-geoip-env.sh
```

---

## Repo layout

```
Dockerfile                    the image (all DNS providers + 4 security modules)
examples/                     everything a user touches (see File map above)
mk-geoip-env.sh               helper: geoipupdate.env from /opt/secrets
.github/workflows/docker.yml  CI: build+push on change + weekly + manual
README.md                     you are here
```

Secrets in `*.env` (`chmod 600`), never in the Caddyfile, never in the repo,
never in screenshots you post for help. The `*.env.example` files ARE the
docs — if a variable isn't there, the stack doesn't need it.

---

## For students: how to actually learn this

1. Run the Simple path with the `demo` service. Break the Caddyfile on purpose, run `validate`, read the error, fix it. Repeat 5 times — that's the whole skill.
2. Add ONE site for a real app (something boring like a notes app). Get `https://` green.
3. Enable CrowdSec. Watch `docker logs crowdsec`, visit your site, see what gets logged. Trigger a ban on yourself (fail logins), unban yourself (`cscli decisions delete`).
4. Enable SSO last. Draw the flow on paper first: browser → Caddy → oauth2-proxy → Pocket-ID → back. Every login-loop bug becomes obvious once the drawing exists.
5. Only then touch GeoIP/rate-limit. By then you'll know which layer each problem lives in — and that's what separates people who run infra from people who copy-paste it.
