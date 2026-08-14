<div align="center">

<a id="readme-top"></a>

<br>

<img alt="MoJ logo" src="https://moj-logos.s3.eu-west-2.amazonaws.com/moj-uk-logo.png" width="200">

# CDPT - Metabase

[![repo standards badge](https://img.shields.io/endpoint?labelColor=231f20&color=005ea5&style=for-the-badge&label=MoJ%20Compliant&url=https%3A%2F%2Foperations-engineering-reports.cloud-platform.service.justice.gov.uk%2Fapi%2Fv1%2Fcompliant_public_repositories%2Fendpoint%2Fdex_mi_metabase&logo=data:image/png;base64,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)](https://operations-engineering-reports.cloud-platform.service.justice.gov.uk/public-report/dex_mi_metabase)

</div>

Repository for tools and scripts relating to CDPT Metabase installation. Currently used to analyse information and generate customisable reports for Correspondence Tool.

---

The production installation is accessible at https://dex-mi-production.apps.live.cloud-platform.service.justice.gov.uk/.

## Data available

The metabase installation has readonly connections to:
- Correspondence Tool QA
- Correspondence Tool Production
- Peoplefinder Production

The metabase user only has permissions to access certain tables and views

## Data updates

Metabase has a live connection to the databases, but manual work is required to make new types of data available to Metabase.

For Correspondence Tool, warehouse tables have been created to be used by Metabase that contains no PII. This table may need updating to add new types of case data.

1. Update SQL script to add in new data e.g. https://github.com/ministryofjustice/dex_mi_metabase/blob/main/products/correspondence_tool_staff/views.sql
2. Connect to the relevant database via kubectl (see below)
3. Copy and paste the updated SQL and run.
4. Sync database schema and re-scan fields in Metabase

### Connect to database

Example to connect to Correspondence Tool QA database:

1. `kubectl exec -it [pod-id] -n track-a-query-qa -- ash`
2. `bundle exec rails db`
3. Get password from kubernetes secret e.g. `cloud-platform decode-secret -s track-a-query-rds-output -n track-a-query-qa`
4. Paste SQL and run


## Local setup

A local Metabase instance with a Postgres database of synthetic sample data (mimicking the Correspondence Tool warehouse tables) can be run via Docker Compose.

1. Create the external network and volumes (first time only):
   ```
   docker network create dex-mi-net
   docker volume create dex-mi-metabase-data
   docker volume create dex-mi-postgres-sample-data
   ```
2. Start the stack (the Metabase image tag is read from [`.metabase_version`](.metabase_version), the single source of truth also used by the Kubernetes manifests):
   ```
   export METABASE_VERSION=$(cat .metabase_version)
   docker compose -f local/docker-compose.yml up -d
   ```
3. Metabase will be available at http://localhost:3001 (port 3000 is assumed to be taken by a local Rails dev server; change the port mapping in `local/docker-compose.yml` if needed).
4. Postgres is available on `localhost:5433` (db `track_a_query_sample`, user/password `metabase`/`metabase`). The sample data in `local/sample_data.sql` is only loaded automatically on the first boot of a fresh `dex-mi-postgres-sample-data` volume.
5. On a fresh `dex-mi-metabase-data` volume, run the setup script to skip Metabase's setup wizard and preconfigure an admin account plus a database connection to the sample Postgres data:
   ```
   ./local/setup-metabase.sh
   ```
   This creates the admin account below and adds a "Local Sample Data" database connection (host `postgres`, port `5432`). It's a no-op if an admin account already exists. Requires `curl` and `jq`.

   - URL: http://localhost:3001
   - Email: `admin@localhost.local`
   - Password: `MetabaseLocal123`

   These are local-only throwaway credentials with no access to real data — override them with the `ADMIN_EMAIL` / `ADMIN_PASSWORD` env vars if desired.

To reset everything and start from scratch:
```
docker compose -f local/docker-compose.yml down
docker volume rm dex-mi-postgres-sample-data dex-mi-metabase-data
docker volume create dex-mi-postgres-sample-data
docker volume create dex-mi-metabase-data
export METABASE_VERSION=$(cat .metabase_version)
docker compose -f local/docker-compose.yml up -d
./local/setup-metabase.sh
```

### Upgrading the Metabase version

The image tag is defined once in [`.metabase_version`](.metabase_version) and consumed by `local/docker-compose.yml` and the Kubernetes deployment manifests (`kubernetes/staging/deployment.yaml`, `kubernetes/production/deployment.yaml`) via `${METABASE_VERSION}`. To upgrade, update `.metabase_version` — `deploy.sh` substitutes it into the Kubernetes manifests automatically at deploy time (via `envsubst`), and Docker Compose picks it up from the exported env var as above.

## TODO list
- Create a docker image based on the metabase image, then we can install some tools we want for our own usage
- Write a script to export/import the dashboard and reports from different servers
- Add a monitor dashboard for tracking the metabase memory usage and user request
  will set up alerts too
