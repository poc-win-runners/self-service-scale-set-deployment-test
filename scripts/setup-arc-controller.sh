#!/bin/bash
set -euo pipefail

NAMESPACE="${ARC_SYSTEMS_NS:-arc-systems}"
CONTROLLER_RELEASE="arc"
INSTALL_CONTROLLER="true"
CONTROLLER_VERSION=""

echo "Checking ARC Controller in namespace: $NAMESPACE"

if helm list -n "$NAMESPACE" | grep -q "$CONTROLLER_RELEASE"; then
  echo "ARC Controller already exists"
  EXISTING_VERSION=$(helm list -n "$NAMESPACE" -o json | jq -r ".[] | select(.name==\"$CONTROLLER_RELEASE\") | .chart" | sed 's/gha-runner-scale-set-controller-//')
  echo "CONTROLLER_VERSION=$EXISTING_VERSION" >> $GITHUB_ENV
  echo "Found existing controller version: $EXISTING_VERSION"
elif [[ "$INSTALL_CONTROLLER" == "true" ]]; then
  echo "Installing ARC Controller"
  VERSION_FLAG=""
  if [[ -n "$CONTROLLER_VERSION" ]]; then
    VERSION_FLAG="--version $CONTROLLER_VERSION"
  fi
  
  helm install "$CONTROLLER_RELEASE" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    $VERSION_FLAG \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
  
  sleep 5
  
  INSTALLED_VERSION=$(helm list -n "$NAMESPACE" -o json | jq -r ".[] | select(.name==\"$CONTROLLER_RELEASE\") | .chart" | sed 's/gha-runner-scale-set-controller-//')
  echo "CONTROLLER_VERSION=$INSTALLED_VERSION" >> $GITHUB_ENV
  echo "Installed controller version: $INSTALLED_VERSION"
else
  echo "Controller installation skipped and no existing controller found"
  exit 1
fi

SERVICE_ACCOUNT=$(kubectl get sa -n "$NAMESPACE" -o json | jq -r '.items[].metadata.name' | grep -E '(arc-gha-rs-controller|gha-rs-controller|arc-controller-gha-rs-controller)' | head -n 1)

if [[ -z "$SERVICE_ACCOUNT" ]]; then
  echo "Could not find ARC controller service account"
  exit 1
fi

echo "CONTROLLER_SERVICE_ACCOUNT=$SERVICE_ACCOUNT" >> $GITHUB_ENV
echo "Controller service account: $SERVICE_ACCOUNT"
