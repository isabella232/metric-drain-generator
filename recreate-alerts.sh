#!/bin/sh
# generate-dashboards.sh

# Delete then create the alert rules defined in grafana/alert-group.json
# This isn't done by generate-dashboards.sh because it clears the rule's state history
set -o nounset

if [ "$#" -gt 2 ]; then
  echo "Usage: ${0} [environment_handle] [grafana_handle]"
  exit 1
fi

# Configuration
METRICS_ENVIRONMENT="${1:-"$METRICS_ENVIRONMENT"}"
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
alert_url="${GRAFANA_URL}/api/ruler/grafana/api/v1/rules/Aptible%20Generated"

echo 'Deleting alerts...'
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary '@grafana/empty-alert-group.json' "$alert_url"
echo

echo 'Creating alerts...'
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary '@grafana/alert-group.json' "$alert_url"
echo

echo 'Done!'
