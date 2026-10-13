# ezzcaddy — Caddy with batteries included

Docker image: `d3b0x0/caddy` ([Docker Hub](https://hub.docker.com/r/d3b0x0/caddy))

Stock `caddy:2` plus five modules, built via `xcaddy` for a file-driven
reverse-proxy edge. Drop-in replacement for the official image — same paths,
same defaults, nothing proprietary.

## What's inside

Base: Caddy `v2.11.7` on Alpine. Arch: **`linux/amd64` only**
(Raspberry Pi / ARM users: clone this repo and `docker build .` — takes
minutes on any modern box).

| module | what it gives you |
|---|---|
| `caddy-dns/cloudflare` | DNS-01 ACME challenges — real wildcard certs with no open port 80 |
| `caddy-crowdsec-bouncer/http` | `crowdsec` + `appsec` directives — L7 WAF, IP bans, captchas via your own CrowdSec LAPI |
| `caddy-maxmind-geolocation` | GeoIP matchers (`allow_countries` / `deny_countries`) — needs a `GeoLite2-*.mmdb` |
| `caddy-ratelimit` | `rate_limit` directive (zones, scoped with `match`) |
| `caddy-l4` | `layer4` app for raw TCP/UDP proxying (idle until you define a stream) |

## Quickstart

See `examples/` — copy both files and run:

```bash
docker compose up -d
docker logs -f caddy
```

Pin a dated tag in production (`d3b0x0/caddy:20261014`); `latest` moves.

## Updating

You don't rebuild by hand. Pushes that touch the `Dockerfile` rebuild and
push automatically, plus a **weekly scheduled build** (Sundays) that floats to
the newest `caddy:2` base and plugin releases — the `--with` lines are
unpinned on purpose. Short SHAs are also tagged, so any build is
reproducible. A manual run is one click: Actions → "Build and push Caddy
image" → Run workflow. Then on your box: `docker compose pull caddy &&
docker compose up -d`.

## Common setups

**Plain reverse proxy** — no modules needed, works out of the box:

```caddyfile
example.com {
    reverse_proxy app:3000
}
```

**Wildcard cert via Cloudflare DNS-01** (no port 80, works behind NAT):

```caddyfile
{
    acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
}

*.example.com {
    reverse_proxy app:3000
}
```

```bash
export CLOUDFLARE_API_TOKEN="..."   # Zone:Read + DNS:Edit on your zone
```

Token goes in the *environment*, never in the Caddyfile — this image reads
`{env.VAR}` at runtime, so secrets stay out of your config files.

**CrowdSec in front** (you run the LAPI yourself, e.g.
`crowdsecurity/crowdsec`):

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

Both containers must share a Docker network so `http://crowdsec:8080`
resolves by name. `order` lines are mandatory — without them Caddy rejects
the config.

**GeoIP country gate** (needs a MaxMind DB — use `mk-geoip-env.sh` with the
`geoipupdate` sidecar to fetch one, see `examples/docker-compose.yaml`):

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

**Sane rate limiting** — scope it, never blanket. One search page fires
10–20 subrequests (favicons, previews); a global zone 429s real users:

```caddyfile
example.com {
    rate_limit {
        zone login {
            match {
                path /login /oauth2/*
            }
            events 10
            window 1m
        }
    }
    reverse_proxy app:3000
}
```

**SSO in front (Pocket-ID / oauth2-proxy / Authelia)** — no caddy-security
module in this image by design; SSO stays outside Caddy via `forward_auth`:

```caddyfile
example.com {
    route {
        forward_auth auth:4180 {
            uri /oauth2/auth
            copy_headers X-Forwarded-User X-Forwarded-Email
        }
        reverse_proxy app:3000
    }
}
```

## Reference

**Ports.** `80`+`443` TCP for HTTP/S, same pair UDP for HTTP/3. The UDP
pair is optional but free — drop it if you don't want QUIC.

**Persistence.** `/data` holds ACME certs and state — back it up or use a
named volume (losing it just reissues certs; Let's Encrypt rate-limits to
50/week/domain, so don't churn it). `/config` is disposable.

**Validate before you reload:**

```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
```

`reload` is zero-downtime; a bad config keeps the old one serving.

**Admin API** listens on `:2019` inside the container (reachable via
`docker exec caddy wget -qO- http://127.0.0.1:2019/config/`). Don't publish
it.

**Logs.** `log { output stdout format json }` *per site* — a global `log`
block alone only configures the process logger, not access logs.

## Build it yourself

```bash
git clone https://codeberg.org/D3B-0x0/ezzcaddy.git
cd ezzcaddy
docker build -t ezzcaddy .
```

Needs Go module downloads at build time (`proxy.golang.org` +
`storage.googleapis.com`) — if your DNS filters those, the build fails with
`dial tcp 0.0.0.0:443`, which is a DNS problem, not a Dockerfile problem.

`mk-geoip-env.sh` assembles a `geoipupdate.env` from secrets already on the
box (values never leave it):

```bash
sudo ./mk-geoip-env.sh   # reads /opt/secrets, writes /opt/caddy/geoipupdate.env (600)
```
