#!/bin/sh
# Assembles /opt/caddy/geoipupdate.env from /opt/secrets (values never leave the box).
set -e
A=$(cat /opt/secrets/geoipupdate_account_id)
K=$(cat /opt/secrets/geoipupdate_license_key)
printf "%s\n" "GEOIPUPDATE_EDITION_IDS=GeoLite2-Country GeoLite2-City GeoLite2-ASN" "GEOIPUPDATE_FREQUENCY=24" "GEOIPUPDATE_ACCOUNT_ID=$A" "GEOIPUPDATE_LICENSE_KEY=$K" > /opt/caddy/geoipupdate.env
chmod 600 /opt/caddy/geoipupdate.env
wc -c /opt/caddy/geoipupdate.env
