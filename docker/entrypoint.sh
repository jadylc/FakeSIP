#!/bin/sh
# Entrypoint for the FakeSIP sidecar image.
# Runs inside the BT client's network namespace (network_mode: service:xxx /
# --network container:xxx) and installs NFQUEUE rules in THAT netns only,
# so the effect is limited to the attached container.
# FakeSIP obfuscates UDP traffic (DHT / UDP tracker announce) as SIP VoIP.

# NFQUEUE kernel modules live on the HOST kernel; ZimaOS ships them.
for m in nfnetlink_queue xt_NFQUEUE nf_tables nft_queue xt_connbytes xt_mark; do
    modprobe "$m" 2>/dev/null || true
done

URI_ARG="${FAKESIP_URI:-}"
TTL_ARG="${FAKESIP_TTL:-4}"
# -s (silent) keeps the log to errors only; extra args via FAKESIP_EXTRA.
# -w /dev/stdout lets `docker logs` work in silent mode.
# shellcheck disable=SC2086
exec /usr/local/bin/fakesip -i eth0 -t "$TTL_ARG" -s -w /dev/stdout ${URI_ARG:+-u "$URI_ARG"} ${FAKESIP_EXTRA}
