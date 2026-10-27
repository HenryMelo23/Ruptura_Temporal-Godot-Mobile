#!/bin/sh
set -eu

# Dedicated ACME state and pinned client; never renew another project's certs.
exec 9>/opt/ruptura/acme-renew.lock
flock -n 9 || exit 0
certificate=/opt/ruptura/acme-config/live/rupturatemporal.cloud/fullchain.pem
before=$(sha256sum "$certificate")
/usr/bin/docker run --rm \
    -v /opt/ruptura/acme-config:/opt/ruptura/acme-config \
    -v /opt/ruptura/acme-work:/opt/ruptura/acme-work \
    -v /opt/ruptura/acme-logs:/opt/ruptura/acme-logs \
    -v /opt/ruptura/acme-webroot:/opt/ruptura/acme-webroot \
    certbot/certbot@sha256:f70ad0adbb7e117f0fe42a63c553f28ea451edabc0148757b6efcd9735acaa20 \
    renew --non-interactive --no-random-sleep-on-renew \
    --cert-name rupturatemporal.cloud \
    --config-dir /opt/ruptura/acme-config \
    --work-dir /opt/ruptura/acme-work \
    --logs-dir /opt/ruptura/acme-logs
after=$(sha256sum "$certificate")
if [ "$before" != "$after" ]; then
    /usr/sbin/nginx -t
    /usr/bin/systemctl reload nginx
fi
