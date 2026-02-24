#!/bin/bash
set -e

REPO_NAME=$1
ENV=$2
COMPONENT=$3  # optional: deploy specific component only

if [ -z "$REPO_NAME" ] || [ -z "$ENV" ]; then
  echo "Usage: bash helm_manual_deploy_ui.sh <repo_name> <env> [component_name]"
  echo "Example: bash helm_manual_deploy_ui.sh project1 prod"
  echo "         bash helm_manual_deploy_ui.sh project1 prod project1-ui"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_DIR="${SCRIPT_DIR}/common-chart"
NAMESPACE="${ENV}-${REPO_NAME}"  # namespace: {env}-{repo}
ENV_YAML="${SCRIPT_DIR}/${REPO_NAME}/image/${ENV}.yaml"

if [ ! -f "$ENV_YAML" ]; then
  echo "Error: ${ENV_YAML} not found"
  exit 1
fi

echo "Deploying ${REPO_NAME} to ${ENV} (namespace: ${NAMESPACE})"

# Function to deploy a single component
deploy_component() {
  local comp_name=$1
  local comp_dir="${SCRIPT_DIR}/${REPO_NAME}/${comp_name}"
  local common_yaml="${comp_dir}/common.yaml"

  if [ ! -f "$common_yaml" ]; then
    echo "Warning: ${common_yaml} not found, skipping ${comp_name}"
    return
  fi

  echo ""
  echo "→ Deploying component: ${comp_name}"
  echo "  Common: ${common_yaml}"
  echo "  Image:  ${ENV_YAML}"

  # Read deployment name from common.yaml (app.name or appname)
  DEPLOY_NAME=$(grep -E '^\s*(app\.name|appname):' "$common_yaml" | head -1 | sed -E 's/.*:\s*(.+)/\1/' | tr -d '"' || echo "$comp_name")

  # If grep failed or empty, use component name
  if [ -z "$DEPLOY_NAME" ]; then
    DEPLOY_NAME="$comp_name"
  fi

  echo "  Deploy name: ${DEPLOY_NAME}"

  helm upgrade --install "${DEPLOY_NAME}" "${CHART_DIR}" \
    -f "${common_yaml}" \
    -f "${ENV_YAML}" \
    --set env="${ENV}" \
    --namespace "${NAMESPACE}" --create-namespace

  echo "  ✓ ${comp_name} deployed"
}

# Deploy specific component or all -ui components
if [ -n "$COMPONENT" ]; then
  # Deploy single component
  echo "Deploying single component: ${COMPONENT}"
  deploy_component "$COMPONENT"
else
  # Deploy all components ending with -ui
  echo "Deploying all -ui components in ${REPO_NAME}"

  component_count=0
  for comp_dir in "${SCRIPT_DIR}/${REPO_NAME}"/*-ui; do
    if [ -d "$comp_dir" ]; then
      comp_name=$(basename "$comp_dir")
      deploy_component "$comp_name"
      component_count=$((component_count + 1))
    fi
  done

  if [ $component_count -eq 0 ]; then
    echo "Warning: No -ui components found in ${REPO_NAME}"
    exit 1
  fi

  echo ""
  echo "✓ All ${component_count} components deployed to ${NAMESPACE}"
fi

echo ""
echo "Done: ${REPO_NAME} deployed to ${NAMESPACE}"
