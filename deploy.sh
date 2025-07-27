#!/bin/bash

set -euo pipefail

# Expects the image tag as the first argument
IMAGE_TAG=${1:?Usage: $0 <image_tag>} # Require image tag as argument

SERVICE_NAME="sdlc-middleware" # Name of your service folder

echo "Deploying ${SERVICE_NAME} with image tag ${IMAGE_TAG}"

# Path to deployment and service YAMLs
DEPLOYMENT_YAML="${SERVICE_NAME}/deployment.yaml"
SERVICE_YAML="${SERVICE_NAME}/service.yaml"

# Temporarily modify deployment.yaml to set the image tag
# Create a backup first
cp "${DEPLOYMENT_YAML}" "${DEPLOYMENT_YAML}.bak"

# Replace the placeholder {{IMAGE_TAG}} with the actual tag
sed -i "s|{{IMAGE_TAG}}|${IMAGE_TAG}|" "${DEPLOYMENT_YAML}"

echo "Applying Kubernetes manifests for ${SERVICE_NAME}..."
kubectl apply -f "${DEPLOYMENT_YAML}"
kubectl apply -f "${SERVICE_YAML}"

# Check the rollout status
echo "Checking deployment rollout status..."
# Assuming deployment name is sdlc-middleware-dev based on your modified deployment.yaml
kubectl rollout status deployment/${SERVICE_NAME}-dev --timeout=5m

# Restore the original deployment.yaml
echo "Restoring original ${DEPLOYMENT_YAML}"
mv "${DEPLOYMENT_YAML}.bak" "${DEPLOYMENT_YAML}"

echo "Deployment process completed for ${SERVICE_NAME}."