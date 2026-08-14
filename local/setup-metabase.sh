#!/usr/bin/env bash
# Bootstraps the local Metabase instance with a preconfigured admin account
# and a database connection to the local sample-data Postgres.
#
# Run after `docker compose -f local/docker-compose.yml up -d` on a fresh
# dex-mi-metabase-data volume. If an admin already exists (setup already
# completed), this script exits without making changes.
set -euo pipefail

METABASE_URL="${METABASE_URL:-http://localhost:3001}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@localhost.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-MetabaseLocal123}"

echo "Waiting for Metabase to be ready..."
until curl -sf "${METABASE_URL}/api/health" > /dev/null; do
  sleep 2
done

HAS_USER=$(curl -s "${METABASE_URL}/api/session/properties" | jq -r '."has-user-setup"')

if [ "$HAS_USER" = "true" ]; then
  echo "Metabase already has an admin account. Skipping setup."
  exit 0
fi

SETUP_TOKEN=$(curl -s "${METABASE_URL}/api/session/properties" | jq -r '."setup-token"')

SETUP_STATUS=$(curl -s -o /tmp/mb-setup-response.json -w '%{http_code}' -X POST "${METABASE_URL}/api/setup" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "token": "${SETUP_TOKEN}",
  "user": {
    "first_name": "Admin",
    "last_name": "User",
    "email": "${ADMIN_EMAIL}",
    "password": "${ADMIN_PASSWORD}"
  },
  "prefs": {
    "site_name": "CDPT Metabase (local)",
    "allow_tracking": false
  }
}
EOF
)

if [ "$SETUP_STATUS" != "200" ]; then
  echo "Admin setup failed (HTTP ${SETUP_STATUS}): $(cat /tmp/mb-setup-response.json)" >&2
  exit 1
fi

SESSION=$(jq -r '.id' /tmp/mb-setup-response.json)
rm -f /tmp/mb-setup-response.json

DB_STATUS=$(curl -s -o /tmp/mb-db-response.json -w '%{http_code}' -X POST "${METABASE_URL}/api/database" \
  -H "Content-Type: application/json" \
  -H "X-Metabase-Session: ${SESSION}" \
  -d '{
    "engine": "postgres",
    "name": "Local Sample Data",
    "details": {
      "host": "postgres",
      "port": 5432,
      "dbname": "track_a_query_sample",
      "user": "metabase",
      "password": "metabase",
      "ssl": false,
      "tunnel-enabled": false
    }
  }')

if [ "$DB_STATUS" != "200" ]; then
  echo "Database connection setup failed (HTTP ${DB_STATUS}): $(cat /tmp/mb-db-response.json)" >&2
  exit 1
fi
rm -f /tmp/mb-db-response.json

echo "Metabase admin account created: ${ADMIN_EMAIL} / ${ADMIN_PASSWORD}"
echo "Database connection 'Local Sample Data' added."
