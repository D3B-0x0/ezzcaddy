# ezzcaddy: stock Caddy + EVERY DNS-01 provider + security modules.
# Base + security modules are always on. DNS providers are ALL compiled in —
# you CHOOSE one at runtime in your Caddyfile (acme_dns <name>). Unused
# providers cost disk (~100MB extra) but zero CPU/RAM. Nothing runs unless
# your Caddyfile references it.
#
# To slim down: delete lines you never use, keep only your provider(s).
# Rebuild via CI (weekly) or: docker build -t ezzcaddy .
#
# NOTE: template / lego-deprecated / acmeproxy are intentionally excluded
# (not real DNS providers). Everything else from org caddy-dns is included.
FROM caddy:2-builder-alpine AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/acmedns \
  --with github.com/caddy-dns/alidns \
  --with github.com/caddy-dns/all-inkl \
  --with github.com/caddy-dns/arvancloud \
  --with github.com/caddy-dns/autodns \
  --with github.com/caddy-dns/azure \
  --with github.com/caddy-dns/bluecat \
  --with github.com/caddy-dns/bunny \
  --with github.com/caddy-dns/civo \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/caddy-dns/cloudns \
  --with github.com/caddy-dns/conoha \
  --with github.com/caddy-dns/ddnss \
  --with github.com/caddy-dns/desec \
  --with github.com/caddy-dns/digitalocean \
  --with github.com/caddy-dns/dinahosting \
  --with github.com/caddy-dns/directadmin \
  --with github.com/caddy-dns/dnsexit \
  --with github.com/caddy-dns/dnsimple \
  --with github.com/caddy-dns/dnsmadeeasy \
  --with github.com/caddy-dns/dnspod \
  --with github.com/caddy-dns/dode \
  --with github.com/caddy-dns/domainnameshop \
  --with github.com/caddy-dns/dreamhost \
  --with github.com/caddy-dns/duckdns \
  --with github.com/caddy-dns/dynu \
  --with github.com/caddy-dns/dynv6 \
  --with github.com/caddy-dns/easydns \
  --with github.com/caddy-dns/edgeone \
  --with github.com/caddy-dns/ednsde \
  --with github.com/caddy-dns/enum \
  --with github.com/caddy-dns/exoscale \
  --with github.com/caddy-dns/gandi \
  --with github.com/caddy-dns/gcore \
  --with github.com/caddy-dns/glesys \
  --with github.com/caddy-dns/godaddy \
  --with github.com/caddy-dns/googleclouddns \
  --with github.com/caddy-dns/google-domains \
  --with github.com/caddy-dns/he \
  --with github.com/caddy-dns/hetzner \
  --with github.com/caddy-dns/hexonet \
  --with github.com/caddy-dns/hosttech \
  --with github.com/caddy-dns/httpnet \
  --with github.com/caddy-dns/huaweicloud \
  --with github.com/caddy-dns/infomaniak \
  --with github.com/caddy-dns/inwx \
  --with github.com/caddy-dns/ionos \
  --with github.com/caddy-dns/katapult \
  --with github.com/caddy-dns/leaseweb \
  --with github.com/caddy-dns/liara \
  --with github.com/caddy-dns/linode \
  --with github.com/caddy-dns/loopia \
  --with github.com/caddy-dns/luadns \
  --with github.com/caddy-dns/mailinabox \
  --with github.com/caddy-dns/metaname \
  --with github.com/caddy-dns/mijnhost \
  --with github.com/caddy-dns/mittwald \
  --with github.com/caddy-dns/mythicbeasts \
  --with github.com/caddy-dns/namecheap \
  --with github.com/caddy-dns/namedotcom \
  --with github.com/caddy-dns/namesilo \
  --with github.com/caddy-dns/nanelo \
  --with github.com/caddy-dns/neoserv \
  --with github.com/caddy-dns/netcup \
  --with github.com/caddy-dns/netlify \
  --with github.com/caddy-dns/netnod \
  --with github.com/caddy-dns/nfsn \
  --with github.com/caddy-dns/nicrudns \
  --with github.com/caddy-dns/njalla \
  --with github.com/caddy-dns/openstack-designate \
  --with github.com/caddy-dns/oraclecloud \
  --with github.com/caddy-dns/ovh \
  --with github.com/caddy-dns/parspack \
  --with github.com/caddy-dns/porkbun \
  --with github.com/caddy-dns/powerdns \
  --with github.com/caddy-dns/pph \
  --with github.com/caddy-dns/regery \
  --with github.com/caddy-dns/regfish \
  --with github.com/caddy-dns/rfc2136 \
  --with github.com/caddy-dns/route53 \
  --with github.com/caddy-dns/scaleway \
  --with github.com/caddy-dns/selectel \
  --with github.com/caddy-dns/servercow \
  --with github.com/caddy-dns/simplydotcom \
  --with github.com/caddy-dns/spaceship \
  --with github.com/caddy-dns/tecnocratica \
  --with github.com/caddy-dns/tencentcloud \
  --with github.com/caddy-dns/thelittlehost \
  --with github.com/caddy-dns/timeweb \
  --with github.com/caddy-dns/totaluptime \
  --with github.com/caddy-dns/transip \
  --with github.com/caddy-dns/unifi \
  --with github.com/caddy-dns/vercel \
  --with github.com/caddy-dns/volcengine \
  --with github.com/caddy-dns/vultr \
  --with github.com/caddy-dns/websupport \
  --with github.com/caddy-dns/wedos \
  --with github.com/hslatman/caddy-crowdsec-bouncer/http \
  --with github.com/porech/caddy-maxmind-geolocation \
  --with github.com/mholt/caddy-ratelimit \
  --with github.com/mholt/caddy-l4
FROM caddy:2
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
