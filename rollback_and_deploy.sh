#!/bin/bash
set -e

# Usage: bash rollback_and_deploy.sh {repo_name} {env} {version}
# This script:
# 1. Updates image/{env}.yaml with the target version
# 2. Commits the change
# 3. Creates/updates git tag: {repo}-{env}-{version}
# 4. Pushes to remote
# 5. Deploys to K8s using helm_manual_deploy_ui.sh

REPO_NAME=$1
ENV=$2
VERSION=$3

if [ -z "$REPO_NAME" ] || [ -z "$ENV" ] || [ -z "$VERSION" ]; then
  echo "Error: Missing arguments"
  echo "Usage: bash rollback_and_deploy.sh <repo_name> <env> <version>"
  echo "Example: bash rollback_and_deploy.sh app1 prod v0.1.0"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_YAML="${SCRIPT_DIR}/${REPO_NAME}/image/${ENV}.yaml"
TAG_NAME="${REPO_NAME}-${ENV}-${VERSION}"

echo "============================================"
echo "Rollback and Deploy"
echo "  Repo:    ${REPO_NAME}"
echo "  Env:     ${ENV}"
echo "  Version: ${VERSION}"
echo "  Tag:     ${TAG_NAME}"
echo "============================================"

# Check if image yaml exists
if [ ! -f "$IMAGE_YAML" ]; then
  echo "Error: ${IMAGE_YAML} not found"
  exit 1
fi

# Step 1: Update image yaml
echo ""
echo "Step 1: Updating ${IMAGE_YAML}"
cat > "$IMAGE_YAML" <<EOF
image:
  tag: ${VERSION}
EOF

echo "✓ Updated to version ${VERSION}"

# Step 2: Git commit
echo ""
echo "Step 2: Committing changes"
git config user.email "admin-dashboard@banana.local" || true
git config user.name "admin-dashboard" || true
git add "$IMAGE_YAML"

if git diff --staged --quiet; then
  echo "⚠ No changes to commit (already at version ${VERSION})"
else
  git commit -m "deploy: ${REPO_NAME} ${ENV} to ${VERSION}"
  echo "✓ Committed"
fi

# Step 3: Create/update git tag
echo ""
echo "Step 3: Creating/updating tag ${TAG_NAME}"

# Delete tag if exists (locally and remotely)
if git tag -l "$TAG_NAME" | grep -q "$TAG_NAME"; then
  echo "  Tag exists locally, deleting..."
  git tag -d "$TAG_NAME" || true
fi

# Create new tag
git tag "$TAG_NAME"
echo "✓ Tag created: ${TAG_NAME}"

# Step 4: Push to remote
echo ""
echo "Step 4: Pushing to remote"
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin "$BRANCH" || echo "⚠ Git push failed (network issue or no GIT_TOKEN)"

# Force push tag (overwrite if exists on remote)
git push origin "$TAG_NAME" --force || echo "⚠ Tag push failed (network issue or no GIT_TOKEN)"
echo "✓ Pushed to origin/${BRANCH}"

# Step 5: Deploy to K8s
echo ""
echo "Step 5: Deploying to K8s"
bash "${SCRIPT_DIR}/helm_manual_deploy_ui.sh" "$REPO_NAME" "$ENV"

echo ""
echo "============================================"
echo "✓ Rollback and deployment completed!"
echo "  ${REPO_NAME} ${ENV} → ${VERSION}"
echo "============================================"
