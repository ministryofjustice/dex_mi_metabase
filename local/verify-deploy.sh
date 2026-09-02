#!/usr/bin/env bash
# Verifies a deployed Metabase instance is up and running the expected
# image version, by polling the public /api/health and
# /api/session/properties endpoints. Read-only: makes no authenticated
# requests and changes nothing on the target instance, so it's safe to run
# against staging or production.
#
# Usage: ./local/verify-deploy.sh <url> <expected-version> [timeout-seconds]
#   url               e.g. https://dex-mi-production.apps.live.cloud-platform.service.justice.gov.uk
#   expected-version  e.g. v0.58.24 (as it appears in .metabase_version)
#   timeout-seconds   defaults to 300 (rolling updates can take a few minutes)

set -euo pipefail

log() { printf '\033[33m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1" >&2; exit 1; }

[ $# -ge 2 ] || fail "Usage: $0 <url> <expected-version> [timeout-seconds]"

URL="${1%/}"
EXPECTED_VERSION="$2"
TIMEOUT_SECS="${3:-300}"

for bin in curl jq; do
  command -v "$bin" >/dev/null 2>&1 || fail "Fatal: '$bin' is required but not installed."
done

log "--------------------------------------------------"
log "Verifying deploy: ${URL} (expecting ${EXPECTED_VERSION})"
log "--------------------------------------------------"

# With replicas > 1 and a zero-downtime RollingUpdate, /api/health stays
# green throughout the rollout while the load balancer still spreads
# requests across old and new pods, so a single passing check proves
# nothing. Poll until several consecutive requests agree on the new
# version, which only happens once every old pod has been replaced.
REQUIRED_CONSECUTIVE_MATCHES=3
consecutive_matches=0
elapsed=0
last_seen_version=""

log "Waiting for all pods to report ${EXPECTED_VERSION} (timeout ${TIMEOUT_SECS}s)..."
while [ "$consecutive_matches" -lt "$REQUIRED_CONSECUTIVE_MATCHES" ]; do
  if [ "$elapsed" -ge "$TIMEOUT_SECS" ]; then
    fail "Timed out after ${TIMEOUT_SECS}s waiting for all pods to report '${EXPECTED_VERSION}' (last seen: '${last_seen_version:-none}'). The rollout may still be in progress, stuck, or running the wrong image."
  fi

  if curl -sf "${URL}/api/health" >/dev/null 2>&1; then
    last_seen_version=$(curl -sf "${URL}/api/session/properties" | jq -r '.version.tag // empty')
    if [ "$last_seen_version" = "$EXPECTED_VERSION" ]; then
      consecutive_matches=$((consecutive_matches + 1))
    else
      consecutive_matches=0
    fi
  else
    consecutive_matches=0
  fi

  sleep 5
  elapsed=$((elapsed + 5))
done

log "Deploy verified: ${URL} is healthy and consistently running ${EXPECTED_VERSION}."
