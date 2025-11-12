#!/bin/bash
set -euo pipefail

TEMPLATE_FILE="${TEMPLATE_PATH:-}"
OUTPUT_FILE="values-scaleset.yaml"

if [[ -z "$TEMPLATE_FILE" ]]; then
  echo "TEMPLATE_PATH environment variable is required"
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Template file not found: $TEMPLATE_FILE"
  exit 1
fi

echo "Preparing values file from template: $TEMPLATE_FILE"

cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

yq eval -i ".controllerServiceAccount.name = \"${CONTROLLER_SERVICE_ACCOUNT}\"" "$OUTPUT_FILE"
yq eval -i ".controllerServiceAccount.namespace = \"${ARC_SYSTEMS_NS}\"" "$OUTPUT_FILE"
yq eval -i ".githubConfigUrl = \"${GITHUB_CONFIG_URL}\"" "$OUTPUT_FILE"
yq eval -i ".githubConfigSecret = \"${GITHUB_SECRET_NAME}\"" "$OUTPUT_FILE"
yq eval -i ".template.spec.containers[0].image = \"${RUNNER_IMAGE}\"" "$OUTPUT_FILE"
# yq eval -i ".runnerGroup = \"${RUNNER_GROUP}\"" "$OUTPUT_FILE"
yq eval -i ".minRunners = ${MIN_RUNNERS}" "$OUTPUT_FILE"
yq eval -i ".maxRunners = ${MAX_RUNNERS}" "$OUTPUT_FILE"

if [[ -n "${RUNNER_LABELS:-}" ]]; then
  echo "Adding runner labels: $RUNNER_LABELS"
  yq eval -i ".template.metadata.labels = {}" "$OUTPUT_FILE"
  IFS=',' read -ra LABEL_ARRAY <<< "$RUNNER_LABELS"
  for label in "${LABEL_ARRAY[@]}"; do
    label=$(echo "$label" | xargs)
    yq eval -i ".template.metadata.labels[\"$label\"] = \"true\"" "$OUTPUT_FILE"
  done
fi

echo "Values file prepared successfully:"
cat "$OUTPUT_FILE"
