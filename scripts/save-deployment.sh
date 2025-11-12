#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1:-}"
OPERATION="${2:-deploy}"

if [[ -z "$CONFIG_FILE" ]]; then
  echo "Usage: $0 <config-file> <operation>"
  exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%d-%H%M%S")
SNAPSHOT_DIR="snapshots"
DEPLOYMENT_FILE="${SNAPSHOT_DIR}/${TIMESTAMP}-snapshot-${SCALESET_NAME}.json"

mkdir -p "$SNAPSHOT_DIR"

echo "Creating deployment snapshot: $DEPLOYMENT_FILE"

cp "$CONFIG_FILE" "$DEPLOYMENT_FILE"

jq '. += [
  {"ParameterKey": "DeploymentTimestamp", "ParameterValue": "'"$TIMESTAMP"'"},
  {"ParameterKey": "ControllerServiceAccount", "ParameterValue": "'"${CONTROLLER_SERVICE_ACCOUNT}"'"},
  {"ParameterKey": "ControllerVersionUsed", "ParameterValue": "'"${CONTROLLER_VERSION}"'"},
  {"ParameterKey": "Operation", "ParameterValue": "'"$OPERATION"'"}
]' "$DEPLOYMENT_FILE" > temp.json && mv temp.json "$DEPLOYMENT_FILE"

echo "DEPLOYMENT_FILE=$DEPLOYMENT_FILE" >> $GITHUB_ENV

echo "Committing deployment snapshot"
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

git add "$DEPLOYMENT_FILE"
git commit -m "deployment: ${SCALESET_NAME} - ${OPERATION}" || echo "No changes to commit"
git push || echo "Nothing to push"

echo "Deployment snapshot saved: $DEPLOYMENT_FILE"
