#!/bin/bash

set -euo pipefail

# This script deploys a specific service based on input.
# It expects:
# 1. SERVICE_FOLDER (e.g., "sdlc-middleware")
# 2. IMAGE_TAG (e.g., "abcd123")

SERVICE_FOLDER=${1:?Usage: $0 <service_folder> <image_tag>}
TARGET_IMAGE_TAG=${2:?Usage: $0 <service_folder> <image_tag>}

echo "Deploying service '${SERVICE_FOLDER}' with image tag '${TARGET_IMAGE_TAG}'"

# Define paths relative to the current working directory (root of sdlc-deploy repo)
DEPLOYMENT_YAML_PATH="${SERVICE_FOLDER}/deployment.yaml"
SERVICE_YAML_PATH="${SERVICE_FOLDER}/service.yaml"

# Check if files exist
if [ ! -f "${DEPLOYMENT_YAML_PATH}" ] || [ ! -f "${SERVICE_YAML_PATH}" ]; then
  echo "Error: Deployment or Service YAML not found for ${SERVICE_FOLDER}."
  exit 1
fi

# --- Dynamic Image Tag Replacement ---
# Create a backup of the original deployment.yaml
cp "${DEPLOYMENT_YAML_PATH}" "${DEPLOYMENT_YAML_PATH}.bak"

# Dynamically determine the full image name for sed replacement
# Assuming your image names follow a pattern like "paritoshvikram/{{service_folder}}"
# This needs to be robust if your image names differ from folder names
IMAGE_REPO_NAME="paritoshvikram/${SERVICE_FOLDER}" # Example: paritoshvikram/sdlc-middleware

# Use sed to replace the __IMAGE_TAG__ placeholder with the actual tag
# Finds the pattern "image: <repo_name>:__IMAGE_TAG__"
sed -i "s|image: ${IMAGE_REPO_NAME}:__IMAGE_TAG__|image: ${IMAGE_REPO_NAME}:${TARGET_IMAGE_TAG}|" "${DEPLOYMENT_YAML_PATH}"

echo "Applying Kubernetes manifests for ${SERVICE_FOLDER}..."
kubectl apply -f "${DEPLOYMENT_YAML_PATH}"
kubectl apply -f "${SERVICE_YAML_PATH}"

echo "Checking deployment rollout status for ${SERVICE_FOLDER}-dev..."
# Assuming deployment name is "${SERVICE_FOLDER}-dev"
kubectl rollout status deployment/${SERVICE_FOLDER}-dev --timeout=5m

# --- Cleanup: Restore the original deployment.yaml ---
echo "Restoring original ${DEPLOYMENT_YAML_PATH}"
mv "${DEPLOYMENT_YAML_PATH}.bak" "${DEPLOYMENT_YAML_PATH}"

echo "Deployment process completed for ${SERVICE_FOLDER}."
