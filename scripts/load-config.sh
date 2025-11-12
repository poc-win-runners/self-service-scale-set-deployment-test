#!/bin/bash
set -euo pipefail

CONFIG_FILE="${1:-}"

if [[ -z "$CONFIG_FILE" ]]; then
  echo "Usage: $0 <config-file>"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Configuration file not found: $CONFIG_FILE"
  exit 1
fi

echo "Loading configuration from: $CONFIG_FILE"

SCALESET_NAME=$(jq -r '.[] | select(.ParameterKey=="ScaleSetName") | .ParameterValue' "$CONFIG_FILE")
RUNNERS_NAMESPACE=$(jq -r '.[] | select(.ParameterKey=="RunnersNamespace") | .ParameterValue' "$CONFIG_FILE")
AWS_REGION=$(jq -r '.[] | select(.ParameterKey=="AWSRegion") | .ParameterValue' "$CONFIG_FILE")
CLUSTER_NAME=$(jq -r '.[] | select(.ParameterKey=="ClusterName") | .ParameterValue' "$CONFIG_FILE")
ARC_SYSTEMS_NS=$(jq -r '.[] | select(.ParameterKey=="ARCSystemsNamespace") | .ParameterValue' "$CONFIG_FILE")
TEMPLATE_PATH=$(jq -r '.[] | select(.ParameterKey=="TemplatePath") | .ParameterValue' "$CONFIG_FILE")
RUNNER_IMAGE=$(jq -r '.[] | select(.ParameterKey=="RunnerImage") | .ParameterValue' "$CONFIG_FILE")
GITHUB_CONFIG_URL=$(jq -r '.[] | select(.ParameterKey=="GitHubConfigURL") | .ParameterValue' "$CONFIG_FILE")
GITHUB_SECRET_NAME=$(jq -r '.[] | select(.ParameterKey=="GitHubSecretName") | .ParameterValue' "$CONFIG_FILE")
RUNNER_GROUP=$(jq -r '.[] | select(.ParameterKey=="RunnerGroup") | .ParameterValue' "$CONFIG_FILE")
RUNNER_LABELS=$(jq -r '.[] | select(.ParameterKey=="RunnerLabels") | .ParameterValue' "$CONFIG_FILE")
MIN_RUNNERS=$(jq -r '.[] | select(.ParameterKey=="MinRunners") | .ParameterValue' "$CONFIG_FILE")
MAX_RUNNERS=$(jq -r '.[] | select(.ParameterKey=="MaxRunners") | .ParameterValue' "$CONFIG_FILE")

ARC_RUN_NS="${RUNNERS_NAMESPACE}"

# Note: Sensitive values (AWS_ROLE_NAME, AWS_ACCOUNT_ID, GH_APP_ID, GH_INSTALLATION_ID, GH_PRIVATE_KEY)
# are expected to be set by the workflow from GitHub secrets, not from the config file

echo "SCALESET_NAME=$SCALESET_NAME" >> $GITHUB_ENV
echo "RUNNERS_NAMESPACE=$RUNNERS_NAMESPACE" >> $GITHUB_ENV
echo "AWS_REGION=$AWS_REGION" >> $GITHUB_ENV
echo "CLUSTER_NAME=$CLUSTER_NAME" >> $GITHUB_ENV
echo "ARC_SYSTEMS_NS=$ARC_SYSTEMS_NS" >> $GITHUB_ENV
echo "ARC_RUN_NS=$ARC_RUN_NS" >> $GITHUB_ENV
echo "TEMPLATE_PATH=$TEMPLATE_PATH" >> $GITHUB_ENV
echo "RUNNER_IMAGE=$RUNNER_IMAGE" >> $GITHUB_ENV
echo "GITHUB_CONFIG_URL=$GITHUB_CONFIG_URL" >> $GITHUB_ENV
echo "GITHUB_SECRET_NAME=$GITHUB_SECRET_NAME" >> $GITHUB_ENV
echo "RUNNER_GROUP=$RUNNER_GROUP" >> $GITHUB_ENV
echo "RUNNER_LABELS=$RUNNER_LABELS" >> $GITHUB_ENV
echo "MIN_RUNNERS=$MIN_RUNNERS" >> $GITHUB_ENV
echo "MAX_RUNNERS=$MAX_RUNNERS" >> $GITHUB_ENV

echo "Configuration loaded successfully"
echo "  Scale Set: $SCALESET_NAME"
echo "  Namespace: $ARC_RUN_NS"
echo "  Region: $AWS_REGION"
echo "  Cluster: $CLUSTER_NAME"
