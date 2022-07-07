#!/bin/sh
# create-drain-stack.sh

# Create or configure InfluxDB, Metric Drain, PostgreSQL, and Grafana
set -o nounset

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 environment_handle"
  exit 1
fi

parse_url() {
  # cf http://stackoverflow.com/a/17287984
  protocol="$(echo "$1" | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  # remove the protocol
  url=$(echo $1 | sed -e s,$protocol,,g)
  # extract the user and password (if any)
  user_and_password="$(echo $url | grep @ | cut -d@ -f1)"
  password="$(echo $user_and_password | grep : | cut -d: -f2)"
  if [ -n "$password" ]; then
    user="$(echo $user_and_password | grep : | cut -d: -f1)"
  else
    user="$user_and_password"
  fi

  # extract the host
  host_and_port="$(echo $url | sed -e s,$user_and_password@,,g | cut -d/ -f1)"
  port="$(echo $host_and_port | grep : | cut -d: -f2)"
  if [ -n "$port" ]; then
    host="$(echo $host_and_port | grep : | cut -d: -f1)"
  else
    host="$host_and_port"
  fi

  database="$(echo $url | grep / | cut -d/ -f2-)"
}

pg_exec() {
  # Tunnel into the postgresql database and execute commands from stdin
  aptible db:tunnel --environment "$METRICS_ENVIRONMENT" "$POSTGRES_HANDLE" --port 54321 &

  parse_url "$pg_url"
  url="${protocol}${user}:${password}@localhost:54321/${database}"
  sleep 5

  until pg_isready -d "$url"; do
    echo "Waiting for tunnel to come up..." >&2
    sleep 2
  done

  psql "$url" "$@"

  # INT isn't working for some reason so kill the tunnel and the port forwarder child process separately
  pkill -P $!
  kill $!
}

gen_password() {
  # Return a random 32 character base64 string (alphanumeric and + /)
  size=${1:-32}
  openssl rand -base64 "$size" | head -c "$size" | tr '/' '-' | tr '+' '_'
}

ensure_database() {
  # Create the Database if it doesn't exist and get its URL
  if aptible db:list --environment "$1" | grep "$2" &> /dev/null; then
    aptible db:url --environment "$1" "$2"
  else
    echo "Creating ${3} Database ${1} - ${2}" >&2
    aptible db:create --environment "$1" "$2" --type "$3"
  fi
}

# Configuration
environment="$1"
: ${METRICS_ENVIRONMENT:="$environment"}
: ${INFLUX_HANDLE:="influx"}
: ${DRAIN_HANDLE:="influx-drain"}
: ${POSTGRES_HANDLE:="pg-grafana"}
: ${GRAFANA_HANDLE:="grafana"}
: ${GRAFANA_IMAGE:="latest"}
: ${GRAFANA_DB_USER:="grafana"}
: ${GRAFANA_DB_PASSWORD:="$(gen_password)"}
: ${GRAFANA_ADMIN_PASSWORD:="$(gen_password)"}
: ${GRAFANA_SECRET_KEY:="$(gen_password 40)"}

# Set up InfluxDB drain
influx_url="$(ensure_database "$METRICS_ENVIRONMENT" "$INFLUX_HANDLE" influxdb)"

# Determine what type of drain to use based on what database InfluxDB is in
# Technically a custom drain would work for both but I already wrote the conditional
# Only works for environments on the same stack
if [ "$METRICS_ENVIRONMENT" = "$environment" ]; then
  aptible metric_drain:create:influxdb "$DRAIN_HANDLE" --environment "$environment" --db "$INFLUX_HANDLE"
else
  parse_url "$influx_url"
  aptible metric_drain:create:influxdb:custom "$DRAIN_HANDLE" --environment "$environment" \
    --username "$user" --password "$password" --url "https://${host}:${port}" --db db
fi

# Create PostgreSQL database and Grafana App if the App doesn't exist
if ! aptible config --environment "$METRICS_ENVIRONMENT" --app "${GRAFANA_HANDLE}" &> /dev/null; then
  # Set up PostgreSQL database
  pg_url="$(ensure_database "$METRICS_ENVIRONMENT" "$POSTGRES_HANDLE" postgresql)"
  pg_exec <<EOF
    CREATE DATABASE sessions;
    \c sessions;
    CREATE TABLE IF NOT EXISTS session (
      key     CHAR(16) NOT NULL,
      data    BYTEA,
      expiry  INTEGER NOT NULL,
      PRIMARY KEY (key)
    );

    CREATE USER "${GRAFANA_DB_USER}" WITH PASSWORD '${GRAFANA_DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE db, sessions to "${GRAFANA_DB_USER}";
EOF

  # Set up Grafana
  parse_url "$pg_url"
  aptible apps:create --environment "$METRICS_ENVIRONMENT" "$GRAFANA_HANDLE"
  aptible deploy --environment "$METRICS_ENVIRONMENT" --app "$GRAFANA_HANDLE" --docker-image "grafana/grafana:${GRAFANA_IMAGE}" \
    "GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}" \
    "GF_SECURITY_SECRET_KEY=${GRAFANA_SECRET_KEY}" \
    "GF_DEFAULT_INSTANCE_NAME=aptible" \
    "GF_SESSION_PROVIDER=postgres" \
    "GF_SESSION_PROVIDER_CONFIG=user=${GRAFANA_DB_USER} password=${GRAFANA_DB_PASSWORD} host=${host} port=${port} dbname=sessions sslmode=require" \
    "GF_LOG_MODE=console" \
    "GF_DATABASE_TYPE=postgres" \
    "GF_DATABASE_HOST=${host}:${port}" \
    "GF_DATABASE_NAME=db" \
    "GF_DATABASE_USER=${GRAFANA_DB_USER}" \
    "GF_DATABASE_PASSWORD=${GRAFANA_DB_PASSWORD}" \
    "GF_DATABASE_SSL_MODE=require" \
    "FORCE_SSL=true"

  grafana_url="https://$(
    aptible endpoints:https:create --environment "$METRICS_ENVIRONMENT" --app "$GRAFANA_HANDLE" cmd --default-domain |
    grep -E -o 'app-[0-9]+\.on-aptible\.com'
  )"

  aptible config:set --environment "$METRICS_ENVIRONMENT" --app "$GRAFANA_HANDLE" "GF_SERVER_ROOT_URL=${grafana_url}"

  # Create the data source
  parse_url "$influx_url"
  basic_auth="admin:${GRAFANA_ADMIN_PASSWORD}"
  influx_source_uid="aptible-gen-influx-source"

  curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary @- "${grafana_url}/api/datasources" <<EOF
    {
      "uid": "${influx_source_uid}",
      "name": "Aptible InfluxDB",
      "type": "influxdb",
      "isDefault": true,
      "url": "https://${host}:${port}",
      "access": "proxy",
      "database": "db",
      "user": "${user}",
      "secureJsonData": {
        "password": "${password}"
      }
    }
EOF
  echo

  echo
  echo "Log into Grafana at ${grafana_url} with username admin and password ${GRAFANA_ADMIN_PASSWORD}"
fi
