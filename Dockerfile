# Super-caddy: stock Caddy + Cloudflare DNS-01 + CrowdSec bouncer + GeoIP + rate limit + L4.
# No caddy-security: SSO stays on oauth2-proxy + Pocket-ID via forward_auth.
FROM caddy:2-builder-alpine AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http \
  --with github.com/porech/caddy-maxmind-geolocation \
  --with github.com/mholt/caddy-ratelimit \
  --with github.com/mholt/caddy-l4
FROM caddy:2
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
