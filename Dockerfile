# ezzcaddy: stock Caddy + 29 curated DNS-01 providers + security modules.
# You CHOOSE one provider at runtime in your Caddyfile (acme_dns <name>).
# Unused providers cost disk (~extra MB) but zero CPU/RAM. Nothing runs unless
# your Caddyfile references it.
#
# THE 29: the most-used DNS providers (homelab + VPS + registrar + hyperscaler
# + regional cloud), curated 2026-10-14. Covers ~95% of real users. Deliberately
# EXCLUDED: exotic regional APIs, resellers, empty/abandoned repos, and 4
# providers whose libs never adapted to the libdns v1 API (leaseweb, katapult,
# exoscale, civo — they cannot compile alongside modern providers in one
# binary; verified 2026-10-14, re-add if upstream fixes them).
# To add one back: append `--with github.com/caddy-dns/<name>` below.
# To slim down: delete lines you never use, keep only your provider(s).
#
# PIN NOTE: digitalocean/vultr never cut a version tag, so a bare --with
# fails with "no matching versions for query upgrade". Those two are pinned
# to @master — same float-by-design as the rest.
# REPLACE NOTE: caddy-dns/vercel still pulls libdns/vercel v0.0.2 (old API);
# the --replace below forces v0.1.0 (new API). Drop the replace if the wrapper
# ever updates its requirement. Syntax per xcaddy wiki: old@v= new@v.
FROM caddy:2-builder-alpine AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/alidns \
  --with github.com/caddy-dns/azure \
  --with github.com/caddy-dns/bunny \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/caddy-dns/desec \
  --with github.com/caddy-dns/digitalocean@master \
  --with github.com/caddy-dns/duckdns \
  --with github.com/caddy-dns/gandi \
  --with github.com/caddy-dns/godaddy \
  --with github.com/caddy-dns/googleclouddns \
  --with github.com/caddy-dns/hetzner \
  --with github.com/caddy-dns/huaweicloud \
  --with github.com/caddy-dns/infomaniak \
  --with github.com/caddy-dns/inwx \
  --with github.com/caddy-dns/ionos \
  --with github.com/caddy-dns/linode \
  --with github.com/caddy-dns/namecheap \
  --with github.com/caddy-dns/netcup \
  --with github.com/caddy-dns/netlify \
  --with github.com/caddy-dns/njalla \
  --with github.com/caddy-dns/oraclecloud \
  --with github.com/caddy-dns/ovh \
  --with github.com/caddy-dns/porkbun \
  --with github.com/caddy-dns/rfc2136 \
  --with github.com/caddy-dns/route53 \
  --with github.com/caddy-dns/scaleway \
  --with github.com/caddy-dns/tencentcloud \
  --with github.com/caddy-dns/vercel \
  --replace github.com/libdns/vercel@v0.0.2=github.com/libdns/vercel@v0.1.0 \
  --with github.com/caddy-dns/vultr@master \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http \
  --with github.com/porech/caddy-maxmind-geolocation \
  --with github.com/mholt/caddy-ratelimit \
  --with github.com/mholt/caddy-l4
FROM caddy:2
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
