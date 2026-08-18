#!/usr/bin/env bash
# Smoke test for a Metabase Docker image change.
#
# Spins up an isolated, throwaway copy of the local stack (its own compose
# project, network, volumes and ports, distinct from the persistent dev
# stack started via docker-compose.yml) using the image tag from
# .metabase_version, then verifies:
#   1. The container starts and /api/health becomes healthy.
#   2. The running Metabase reports the expected version tag.
#   3. The first-run setup wizard (admin account creation) succeeds.
#   4. A Postgres database connection can be added and queried end-to-end.
#
# Everything is torn down on exit, pass or fail. Requires docker, curl, jq.
#
# Usage: ./local/smoke-test.sh [metabase-version]
#   metabase-version defaults to the contents of .metabase_version.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

METABASE_VERSION="${1:-$(cat "${REPO_ROOT}/.metabase_version")}"

PROJECT="dex-mi-smoke-test"
METABASE_PORT=13001
POSTGRES_PORT=15433
METABASE_URL="http://localhost:${METABASE_PORT}"
ADMIN_EMAIL="smoke-test@localhost.local"
ADMIN_PASSWORD="SmokeTest123!"

HEALTH_TIMEOUT_SECS=180

log() { printf '\033[33m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1" >&2; exit 1; }

for bin in docker curl jq; do
  command -v "$bin" >/dev/null 2>&1 || fail "Fatal: '$bin' is required but not installed."
done

cleanup() {
  local status=$?
  if [ "$status" -ne 0 ]; then
    log "--- Smoke test failed: dumping container logs for diagnosis ---"
    docker compose -p "$PROJECT" -f - logs --tail=100 2>/dev/null <<EOF || true
$(compose_config)
EOF
  fi
  log "Tearing down smoke test stack..."
  docker compose -p "$PROJECT" -f - down -v --remove-orphans >/dev/null 2>&1 <<EOF || true
$(compose_config)
EOF
  if [ "$status" -eq 0 ]; then
    log "Smoke test PASSED for metabase/metabase:${METABASE_VERSION}"
  else
    log "Smoke test FAILED for metabase/metabase:${METABASE_VERSION}"
  fi
  exit "$status"
}

compose_config() {
  cat <<EOF
networks:
  dex-mi-smoke-net:
    name: dex-mi-smoke-net

volumes:
  dex-mi-smoke-metabase-data:
  dex-mi-smoke-postgres-data:

services:
  postgres:
    image: postgres:15
    container_name: dex-mi-postgres-smoke-test
    environment:
      POSTGRES_DB: track_a_query_sample
      POSTGRES_USER: metabase
      POSTGRES_PASSWORD: metabase
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - dex-mi-smoke-postgres-data:/var/lib/postgresql/data
      - ${REPO_ROOT}/local/sample_data.sql:/docker-entrypoint-initdb.d/sample_data.sql:ro
    networks:
      - dex-mi-smoke-net

  metabase:
    image: metabase/metabase:${METABASE_VERSION}
    container_name: dex-mi-metabase-smoke-test
    environment:
      MB_DB_FILE: /metabase-data/metabase.db
    ports:
      - "${METABASE_PORT}:3000"
    volumes:
      - dex-mi-smoke-metabase-data:/metabase-data
    networks:
      - dex-mi-smoke-net
    depends_on:
      - postgres
EOF
}

trap cleanup EXIT

log "--------------------------------------------------"
log "Smoke testing metabase/metabase:${METABASE_VERSION}"
log "--------------------------------------------------"

log "Starting isolated stack (project: ${PROJECT})..."
compose_config | docker compose -p "$PROJECT" -f - up -d

log "Waiting for Metabase to report healthy (timeout ${HEALTH_TIMEOUT_SECS}s)..."
elapsed=0
until curl -sf "${METABASE_URL}/api/health" >/dev/null 2>&1; do
  if [ "$elapsed" -ge "$HEALTH_TIMEOUT_SECS" ]; then
    fail "Metabase did not become healthy within ${HEALTH_TIMEOUT_SECS}s."
  fi
  sleep 3
  elapsed=$((elapsed + 3))
done
log "Metabase is healthy after ${elapsed}s."

log "Checking reported version..."
PROPS=$(curl -sf "${METABASE_URL}/api/session/properties")
REPORTED_VERSION=$(echo "$PROPS" | jq -r '.version.tag // empty')
[ -n "$REPORTED_VERSION" ] || fail "Could not read version tag from /api/session/properties."
[ "$REPORTED_VERSION" = "$METABASE_VERSION" ] || \
  fail "Version mismatch: expected '${METABASE_VERSION}', Metabase reported '${REPORTED_VERSION}'."
log "Reported version matches: ${REPORTED_VERSION}"

log "Running first-run setup wizard..."
SETUP_TOKEN=$(echo "$PROPS" | jq -r '."setup-token"')
[ -n "$SETUP_TOKEN" ] && [ "$SETUP_TOKEN" != "null" ] || fail "No setup token available (unexpected instance state)."

SETUP_RESPONSE=$(curl -sf -X POST "${METABASE_URL}/api/setup" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "token": "${SETUP_TOKEN}",
  "user": {
    "first_name": "Smoke",
    "last_name": "Test",
    "email": "${ADMIN_EMAIL}",
    "password": "${ADMIN_PASSWORD}"
  },
  "prefs": {
    "site_name": "Smoke Test",
    "allow_tracking": false
  }
}
EOF
) || fail "Setup request failed."
SESSION=$(echo "$SETUP_RESPONSE" | jq -r '.id')
[ -n "$SESSION" ] && [ "$SESSION" != "null" ] || fail "Setup did not return a session id."
log "Admin account created and session established."

log "Adding Postgres database connection..."
DB_RESPONSE=$(curl -sf -X POST "${METABASE_URL}/api/database" \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: ${SESSION}" \
  -d '{
    "engine": "postgres",
    "name": "Smoke Test DB",
    "details": {
      "host": "postgres",
      "port": 5432,
      "dbname": "track_a_query_sample",
      "user": "metabase",
      "password": "metabase",
      "ssl": false,
      "tunnel-enabled": false
    }
  }') || fail "Adding database connection failed."
DB_ID=$(echo "$DB_RESPONSE" | jq -r '.id')
[ -n "$DB_ID" ] && [ "$DB_ID" != "null" ] || fail "Database connection did not return an id."
log "Database connection added (id ${DB_ID})."

log "Waiting for initial schema sync..."
elapsed=0
SYNC_TIMEOUT_SECS=60
until [ "$(curl -sf "${METABASE_URL}/api/database/${DB_ID}" -H "X-Metabase-Session: ${SESSION}" | jq -r '.initial_sync_status')" = "complete" ]; do
  if [ "$elapsed" -ge "$SYNC_TIMEOUT_SECS" ]; then
    fail "Database schema sync did not complete within ${SYNC_TIMEOUT_SECS}s."
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
log "Schema sync complete."

log "Running an end-to-end query against the connected database..."
QUERY_RESPONSE=$(curl -sf -X POST "${METABASE_URL}/api/dataset" \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: ${SESSION}" \
  -d "{
    \"type\": \"native\",
    \"native\": {\"query\": \"select count(*) from warehouse_case_reports\"},
    \"database\": ${DB_ID}
  }") || fail "Query execution failed."
QUERY_STATUS=$(echo "$QUERY_RESPONSE" | jq -r '.status')
[ "$QUERY_STATUS" = "completed" ] || fail "Query did not complete successfully: $(echo "$QUERY_RESPONSE" | jq -c '.error // .')"
ROW_COUNT=$(echo "$QUERY_RESPONSE" | jq -r '.data.rows[0][0]')
log "Query returned ${ROW_COUNT} row(s) from warehouse_case_reports."

log "All checks passed."