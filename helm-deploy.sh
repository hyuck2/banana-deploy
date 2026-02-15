#!/bin/bash
set -e

APPNAME=$1
ENV=$2

if [ -z "$APPNAME" ] || [ -z "$ENV" ]; then
  echo "Usage: bash helm-deploy.sh <appname> <env>"
  echo "Example: bash helm-deploy.sh app1 prod"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMON_YAML="${SCRIPT_DIR}/${APPNAME}/common.yaml"
ENV_YAML="${SCRIPT_DIR}/${APPNAME}/image/${ENV}.yaml"
CHART_DIR="${SCRIPT_DIR}/common-chart"
NAMESPACE="${APPNAME}-${ENV}"

if [ ! -f "$COMMON_YAML" ]; then
  echo "Error: ${COMMON_YAML} not found"
  exit 1
fi

if [ ! -f "$ENV_YAML" ]; then
  echo "Error: ${ENV_YAML} not found"
  exit 1
fi

echo "Deploying ${APPNAME} to ${ENV} (namespace: ${NAMESPACE})"
echo "  Chart:  ${CHART_DIR}"
echo "  Values: ${COMMON_YAML}, ${ENV_YAML}"

helm upgrade --install "${APPNAME}" "${CHART_DIR}" \
  -f "${COMMON_YAML}" \
  -f "${ENV_YAML}" \
  --set env="${ENV}" \
  --namespace "${NAMESPACE}" --create-namespace

echo "Done: ${APPNAME} deployed to ${NAMESPACE}"
