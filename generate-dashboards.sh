#!/bin/sh
# generate-dashboards.sh

# Create or update grafana dashboards using the provided data or by pulling it from the App's config
set -o nounset

if [ "$#" -gt 1 ]; then
  echo "Usage: ${0} [environment_handle]"
  exit 1
fi

# Configuration
METRICS_ENVIRONMENT="${1:-"$METRICS_ENVIRONMENT"}"
: ${GRAFANA_HANDLE:='grafana'}

if [ -z "${GRAFANA_USER:-}" ] || [ -z "${GRAFANA_URL:-}" ]; then
  # Missing credentials or URL
  # Pull them from the App's config
  eval "$(aptible config --environment "$METRICS_ENVIRONMENT" --app "$GRAFANA_HANDLE" | grep -E '(GF_SECURITY_ADMIN_PASSWORD|GF_SERVER_ROOT_URL)=')"

  if [ -z "${GRAFANA_USER:-}" ]; then
    : ${GRAFANA_USER:="admin"}
    : ${GRAFANA_PASSWORD:="$GF_SECURITY_ADMIN_PASSWORD"}
  fi

  if [ -z "${GRAFANA_URL:-}" ]; then
    : ${GRAFANA_URL:="$GF_SERVER_ROOT_URL"}
  fi
fi

basic_auth="${GRAFANA_USER}:${GRAFANA_PASSWORD}"

# Create a folder for the generated dashboards
folder_uid='aptible-gen-folder'
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary @- "${GRAFANA_URL}/api/folders" <<EOF
  {
    "uid": "${folder_uid}",
    "title": "Aptible Generated"
  }
EOF
echo

# Create or update app metrics dashboard
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary @- "${GRAFANA_URL}/api/dashboards/db" <<EOF
    {
        "dashboard": {
            "annotations": {
                "list": [
                    {
                        "builtIn": 1,
                        "datasource": {
                            "type": "grafana",
                            "uid": "-- Grafana --"
                        },
                        "enable": true,
                        "hide": true,
                        "iconColor": "rgba(0, 211, 255, 1)",
                        "name": "Annotations & Alerts",
                        "target": {
                            "limit": 100,
                            "matchAny": false,
                            "tags": [],
                            "type": "dashboard"
                        },
                        "type": "dashboard"
                    }
                ]
            },
            "editable": true,
            "fiscalYearStartMonth": 0,
            "graphTooltip": 0,
            "id": null,
            "links": [],
            "liveNow": false,
            "panels": [
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "mbytes"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 11,
                        "w": 12,
                        "x": 0,
                        "y": 0
                    },
                    "id": 2,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_app - \$tag_service - \$tag_host",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_rss_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"app\" =~ /^\$app\$/\nAND \"service\" =~ /^\$service\$/\nAND \"host\" =~ /^\$host\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"app\", \"service\", \"host\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        },
                        {
                            "alias": "\$tag_environment - \$tag_app - \$tag_service - \$tag_host (Limit)",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_limit_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"app\" =~ /^\$app\$/\nAND \"service\" =~ /^\$service\$/\nAND \"host\" =~ /^\$host\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"app\", \"service\", \"host\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "B",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Memory Usage",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 11,
                        "w": 12,
                        "x": 12,
                        "y": 0
                    },
                    "id": 3,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_app - \$tag_service - \$tag_host",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_rss_mb\") / MAX(\"memory_limit_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"app\" =~ /^\$app\$/\nAND \"service\" =~ /^\$service\$/\nAND \"host\" =~ /^\$host\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"app\", \"service\", \"host\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Memory Utilization",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 11,
                        "w": 12,
                        "x": 0,
                        "y": 11
                    },
                    "id": 4,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_app - \$tag_service - \$tag_host",
                            "hide": false,
                            "query": "SELECT MEAN(\"milli_cpu_usage\") / 1000\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"app\" =~ /^\$app\$/\nAND \"service\" =~ /^\$service\$/\nAND \"host\" =~ /^\$host\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"app\", \"service\", \"host\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        },
                        {
                            "alias": "\$tag_environment - \$tag_app - \$tag_service - \$tag_host (Limit)",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_limit_mb\") / 4096\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"app\" =~ /^\$app\$/\nAND \"service\" =~ /^\$service\$/\nAND \"host\" =~ /^\$host\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"app\", \"service\", \"host\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "B",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "CPU Usage",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 11,
                        "w": 12,
                        "x": 12,
                        "y": 11
                    },
                    "id": 5,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_app - \$tag_service - \$tag_host",
                            "hide": false,
                            "query": "SELECT (MEAN(\"milli_cpu_usage\") / 1000) / (MAX(\"memory_limit_mb\") / 4096)\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"app\" =~ /^\$app\$/\nAND \"service\" =~ /^\$service\$/\nAND \"host\" =~ /^\$host\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"app\", \"service\", \"host\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "CPU Utilization",
                    "type": "timeseries"
                }
            ],
            "refresh": "5m",
            "schemaVersion": 36,
            "style": "dark",
            "tags": ["aptible-generated"],
            "templating": {
                "list": [
                    {
                        "current": {
                            "selected": true,
                            "text": "All",
                            "value": "\$__all"
                        },
                        "definition": "show tag values WITH key=\"environment\"",
                        "hide": 0,
                        "includeAll": true,
                        "label": "Environment",
                        "multi": false,
                        "name": "environment",
                        "options": [],
                        "query": "show tag values WITH key=\"environment\"",
                        "refresh": 2,
                        "regex": "",
                        "skipUrlSync": false,
                        "sort": 0,
                        "type": "query"
                    },
                    {
                        "current": {
                            "selected": true,
                            "text": "All",
                            "value": "\$__all"
                        },
                        "definition": "show tag values WITH key = \"app\" WHERE environment =~ /^\$environment\$/",
                        "hide": 0,
                        "includeAll": true,
                        "label": "App",
                        "multi": false,
                        "name": "app",
                        "options": [],
                        "query": "show tag values WITH key = \"app\" WHERE environment =~ /^\$environment\$/",
                        "refresh": 1,
                        "regex": "",
                        "skipUrlSync": false,
                        "sort": 0,
                        "type": "query"
                    },
                    {
                        "current": {
                            "selected": false,
                            "text": "All",
                            "value": "\$__all"
                        },
                        "definition": "show tag values WITH key=\"service\" WHERE environment =~ /^\$environment\$/ AND app =~ /^\$app\$/",
                        "hide": 0,
                        "includeAll": true,
                        "label": "Service",
                        "multi": false,
                        "name": "service",
                        "options": [],
                        "query": "show tag values WITH key=\"service\" WHERE environment =~ /^\$environment\$/ AND app =~ /^\$app\$/",
                        "refresh": 1,
                        "regex": "",
                        "skipUrlSync": false,
                        "sort": 0,
                        "type": "query"
                    },
                    {
                        "current": {
                            "selected": false,
                            "text": "All",
                            "value": "\$__all"
                        },
                        "definition": "SELECT \"host\",last(\"memory_rss_mb\") FROM \"metrics\" WHERE environment =~ /^\$environment\$/ AND app =~ /^\$app\$/ AND service =~ /^\$service\$/ AND \$timeFilter GROUP BY \"host\"",
                        "hide": 0,
                        "includeAll": true,
                        "label": "Container",
                        "multi": false,
                        "name": "host",
                        "options": [],
                        "query": "SELECT \"host\",last(\"memory_rss_mb\") FROM \"metrics\" WHERE environment =~ /^\$environment\$/ AND app =~ /^\$app\$/ AND service =~ /^\$service\$/ AND \$timeFilter GROUP BY \"host\"",
                        "refresh": 1,
                        "regex": "",
                        "skipUrlSync": false,
                        "sort": 0,
                        "type": "query"
                    }
                ]
            },
            "time": {
                "from": "now-6h",
                "to": "now"
            },
            "timepicker": {},
            "timezone": "",
            "title": "App Metrics",
            "uid": "aptible-gen-app-dash",
            "version": 0,
            "weekStart": "",
            "hideControls": false
        },
        "folderUid": "${folder_uid}",
        "overwrite": true
    }
EOF
echo

# Create or update database metrics dashboard
curl -u "$basic_auth" -X POST -H "Content-Type: application/json" --data-binary @- "${GRAFANA_URL}/api/dashboards/db" <<EOF
    {
        "dashboard": {
            "annotations": {
                "list": [
                    {
                        "builtIn": 1,
                        "datasource": {
                            "type": "grafana",
                            "uid": "-- Grafana --"
                        },
                        "enable": true,
                        "hide": true,
                        "iconColor": "rgba(0, 211, 255, 1)",
                        "name": "Annotations & Alerts",
                        "target": {
                            "limit": 100,
                            "matchAny": false,
                            "tags": [],
                            "type": "dashboard"
                        },
                        "type": "dashboard"
                    }
                ]
            },
            "editable": true,
            "fiscalYearStartMonth": 0,
            "graphTooltip": 0,
            "id": null,
            "links": [],
            "liveNow": false,
            "panels": [
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "mbytes"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 0,
                        "y": 0
                    },
                    "id": 2,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_rss_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        },
                        {
                            "alias": "\$tag_environment - \$tag_database (Limit)",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_limit_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "B",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Memory Usage",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 12,
                        "y": 0
                    },
                    "id": 3,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_rss_mb\") / MAX(\"memory_limit_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Memory Utilization",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 0,
                        "y": 9
                    },
                    "id": 4,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MEAN(\"milli_cpu_usage\") / 1000\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        },
                        {
                            "alias": "\$tag_environment - \$tag_database (Limit)",
                            "hide": false,
                            "query": "SELECT MAX(\"memory_limit_mb\") / 4096\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "B",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "CPU Usage",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 12,
                        "y": 9
                    },
                    "id": 5,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT (MEAN(\"milli_cpu_usage\") / 1000) / (MAX(\"memory_limit_mb\") / 4096)\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "CPU Utilization",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "decmbytes"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 0,
                        "y": 18
                    },
                    "id": 6,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MAX(\"disk_usage_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        },
                        {
                            "alias": "\$tag_environment - \$tag_database (Limit)",
                            "hide": false,
                            "query": "SELECT MAX(\"disk_limit_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "B",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Disk Usage",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "percentunit"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 12,
                        "y": 18
                    },
                    "id": 7,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MAX(\"disk_usage_mb\") / MAX(\"disk_limit_mb\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Disk Utilization",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "short"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 0,
                        "y": 27
                    },
                    "id": 8,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MAX(\"disk_read_iops\") + MAX(\"disk_write_iops\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Disk IOPS",
                    "type": "timeseries"
                },
                {
                    "fieldConfig": {
                        "defaults": {
                            "color": {
                                "mode": "palette-classic"
                            },
                            "custom": {
                                "axisLabel": "",
                                "axisPlacement": "auto",
                                "barAlignment": 0,
                                "drawStyle": "line",
                                "fillOpacity": 0,
                                "gradientMode": "none",
                                "hideFrom": {
                                    "legend": false,
                                    "tooltip": false,
                                    "viz": false
                                },
                                "lineInterpolation": "linear",
                                "lineStyle": {
                                    "fill": "solid"
                                },
                                "lineWidth": 1,
                                "pointSize": 5,
                                "scaleDistribution": {
                                    "type": "linear"
                                },
                                "showPoints": "auto",
                                "spanNulls": 60000,
                                "stacking": {
                                    "group": "A",
                                    "mode": "none"
                                },
                                "thresholdsStyle": {
                                    "mode": "off"
                                }
                            },
                            "mappings": [],
                            "thresholds": {
                                "mode": "absolute",
                                "steps": [
                                    {
                                        "color": "green",
                                        "value": null
                                    },
                                    {
                                        "color": "red",
                                        "value": 80
                                    }
                                ]
                            },
                            "unit": "KBs"
                        },
                        "overrides": []
                    },
                    "gridPos": {
                        "h": 9,
                        "w": 12,
                        "x": 12,
                        "y": 27
                    },
                    "id": 9,
                    "options": {
                        "legend": {
                            "calcs": [],
                            "displayMode": "list",
                            "placement": "bottom"
                        },
                        "tooltip": {
                            "mode": "single",
                            "sort": "none"
                        }
                    },
                    "targets": [
                        {
                            "alias": "\$tag_environment - \$tag_database",
                            "hide": false,
                            "query": "SELECT MAX(\"disk_read_kbps\") + MAX(\"disk_write_kbps\")\nFROM \"metrics\"\nWHERE \$timeFilter\nAND \"environment\" =~ /^\$environment\$/\nAND \"database\" =~ /^\$database\$/\nGROUP BY\n        time(\$__interval),\n        \"environment\", \"database\"\n        fill(null)",
                            "rawQuery": true,
                            "refId": "A",
                            "resultFormat": "time_series"
                        }
                    ],
                    "title": "Disk Throughput",
                    "type": "timeseries"
                }
            ],
            "refresh": "5m",
            "schemaVersion": 36,
            "style": "dark",
            "tags": ["aptible-generated"],
            "templating": {
                "list": [
                    {
                        "current": {
                            "selected": false,
                            "text": "All",
                            "value": "\$__all"
                        },
                        "definition": "show tag values WITH key=\"environment\"",
                        "hide": 0,
                        "includeAll": true,
                        "label": "Environment",
                        "multi": false,
                        "name": "environment",
                        "options": [],
                        "query": "show tag values WITH key=\"environment\"",
                        "refresh": 2,
                        "regex": "",
                        "skipUrlSync": false,
                        "sort": 0,
                        "type": "query"
                    },
                    {
                        "current": {
                            "selected": false,
                            "text": "All",
                            "value": "\$__all"
                        },
                        "definition": "show tag values WITH key = \"database\" WHERE environment =~ /^\$environment\$/",
                        "hide": 0,
                        "includeAll": true,
                        "label": "Database",
                        "multi": false,
                        "name": "database",
                        "options": [],
                        "query": "show tag values WITH key = \"database\" WHERE environment =~ /^\$environment\$/",
                        "refresh": 1,
                        "regex": "",
                        "skipUrlSync": false,
                        "sort": 0,
                        "type": "query"
                    }
                ]
            },
            "time": {
                "from": "now-6h",
                "to": "now"
            },
            "timepicker": {},
            "timezone": "",
            "title": "Database Metrics",
            "uid": "aptible-gen-database-dash",
            "version": 0,
            "weekStart": "",
            "hideControls": false
       },
       "folderUid": "${folder_uid}",
       "overwrite": true
    }
EOF
echo
