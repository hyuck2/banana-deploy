#!/bin/bash
set -e

TAG=$1

if [ -z "$TAG" ]; then
  echo "Usage: bash rollback-helm-deploy.sh <banana-deploy-tag>"
  echo "Example: bash rollback-helm-deploy.sh app1-prod-v1.0.0"
  echo ""
  echo "Available tags:"
  git tag -l | sort
  exit 1
fi

# Parse tag: {appname}-{env}-{version}
# e.g. app1-prod-v1.0.0 → appname=app1, env=prod, version=v1.0.0
# e.g. app1-stage-v1.0.0rc1 → appname=app1, env=stage, version=v1.0.0rc1
APPNAME=$(echo "$TAG" | sed -E 's/^(.+)-(prod|stage)-v.+$/\1/')
ENV=$(echo "$TAG" | sed -E 's/^.+-(prod|stage)-v.+$/\1/')
VERSION=$(echo "$TAG" | sed -E 's/^.+-(prod|stage)-(v.+)$/\2/')

if [ -z "$APPNAME" ] || [ -z "$ENV" ] || [ -z "$VERSION" ]; then
  echo "Error: Failed to parse tag '${TAG}'"
  echo "Expected format: {appname}-{env}-{version} (e.g. app1-prod-v1.0.0)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_YAML_PATH="${APPNAME}/image/${ENV}.yaml"

echo "Rollback: ${APPNAME} ${ENV} → ${VERSION}"
echo "  Tag:  ${TAG}"
echo "  File: ${ENV_YAML_PATH}"

# Verify tag exists
if ! git tag -l "$TAG" | grep -q "$TAG"; then
  echo "Error: Tag '${TAG}' not found"
  echo ""
  echo "Available tags:"
  git tag -l | sort
  exit 1
fi

# Restore the env yaml from the tagged commit
cd "$SCRIPT_DIR"
git show "${TAG}:${ENV_YAML_PATH}" > "${ENV_YAML_PATH}"

# Commit the rollback
git add "${ENV_YAML_PATH}"
git commit -m "rollback: ${APPNAME} ${ENV} to ${VERSION}"

echo "Committed rollback. Deploying..."

# Auto-deploy
bash "${SCRIPT_DIR}/helm-deploy.sh" "${APPNAME}" "${ENV}"

echo "Rollback complete: ${APPNAME} ${ENV} → ${VERSION}"
