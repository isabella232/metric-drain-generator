#!/bin/sh
# generate-dashboards.sh

# Create or update grafana dashboards using the provided data or by pulling it from the App's config
set -o nounset

if [ "$#" -gt 2 ]; then
  echo "Usage: ${0} [environment_handle] [grafana_handle]"
  exit 1
fi

# Configuration
METRICS_ENVIRONMENT="${1:-"${METRICS_ENVIRONMENT:-}"}"
GRAFANA_HANDLE="${2:-"${GRAFANA_HANDLE:-grafana}"}"

if [ -z "${GRAFANA_USER:-}" ] || [ -z "${GRAFANA_URL:-}" ]; then
  # Missing credentials or URL
  # Pull them from the App's config
  eval "$(aptible config --environment "$METRICS_ENVIRONMENT" --app "$GRAFANA_HANDLE" | grep -E '(GF_SECURITY_ADMIN_PASSWORD|GF_SERVER_ROOT_URL)=')"

  if [ -z "${GRAFANA_USER:-}" ]; then
    GRAFANA_USER="admin"
    GRAFANA_PASSWORD="$GF_SECURITY_ADMIN_PASSWORD"
  fi

  if [ -z "${GRAFANA_URL:-}" ]; then
    : ${GRAFANA_URL:="$GF_SERVER_ROOT_URL"}
  fi
fi

basic_auth="${GRAFANA_USER}:${GRAFANA_PASSWORD}"

echo 'Creating folder for generated dashboards...'
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary '@grafana/folder.json' "${GRAFANA_URL}/api/folders"
echo

echo 'Generating dashboards...'
for dashboard in grafana/dashboards/*.json; do
  curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary "@${dashboard}" "${GRAFANA_URL}/api/dashboards/db"
  echo
done

echo 'Creating alerts...'
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary '@grafana/alert-group.json' "${GRAFANA_URL}/api/ruler/grafana/api/v1/rules/Aptible%20Generated"
echo

echo 'Done!'
