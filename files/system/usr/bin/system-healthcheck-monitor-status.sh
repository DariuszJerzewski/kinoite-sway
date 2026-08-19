#!/usr/bin/env bash
set -euo pipefail

HEALTH_URL="https://system-healthcheck-monitor.bearded-draco.ts.net/status"
DEVICE="$(hostname)"

failed_tests=0

# Check for failed systemd units
if ! systemctl --failed --quiet; then
    failed_tests=1
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
