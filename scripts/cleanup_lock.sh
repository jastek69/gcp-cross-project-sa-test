#!/bin/bash
set -euo pipefail

# Parse backend config from 01-providers.tf
BACKEND_FILE="01-providers.tf"
BUCKET=$(grep -A2 'backend "gcs"' "$BACKEND_FILE" | grep bucket | awk -F'"' '{print $2}')
PREFIX=$(grep -A2 'backend "gcs"' "$BACKEND_FILE" | grep prefix | awk -F'"' '{print $2}')
LOCK_FILE="gs://${BUCKET}/${PREFIX}/default.tflock"

echo "Parsed backend:"
echo "  Bucket: $BUCKET"
echo "  Prefix: $PREFIX"
echo "  Lock file: $LOCK_FILE"

# Check and delete stale lock file
if gsutil -q stat "$LOCK_FILE"; then
  echo "Deleting stale lock file..."
  gsutil rm "$LOCK_FILE"
else
  echo "No lock file present in bucket."
fi

# Clean local Terraform state cache
echo "Cleaning local Terraform cache..."
rm -rf .terraform/ || true
rm -f .terraform.lock.hcl || true

# Reinitialize Terraform
echo "Reinitializing Terraform backend..."
terraform init -reconfigure
