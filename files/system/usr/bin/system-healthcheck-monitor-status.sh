#!/usr/bin/env bash
set -euo pipefail

HEALTH_URL="https://system-healthcheck-monitor.bearded-draco.ts.net/status"
DEVICE="$(hostname)"

failed_tests=0

IGNORE_SERVICES=(
    "systemd-remount-fs.service"
)

failed_units="$(
    systemctl --failed --no-legend --no-pager |
        awk -v ignore="$(printf '%s\n' "${IGNORE_SERVICES[@]}")" '
            BEGIN {
                split(ignore, a, "\n")
                for (i in a)
                    x[a[i]] = 1
            }
            !($2 in x)
        '
)"

if [[ -n "$failed_units" ]]; then
    failed_tests+=1
fi

if (( failed_tests == 0 )); then
    status="healthy"
else
    status="unhealthy"
fi

timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"

payload="$(jq -n \
    --arg device "$DEVICE" \
    --arg status "$status" \
    --arg timestamp "$timestamp" \
    --argjson failedTests "$failed_tests" \
    '{
        device: $device,
        status: $status,
        timestamp: $timestamp,
        failedTests: $failedTests
    }'
)"

curl --fail --silent --show-error \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$HEALTH_URL"
