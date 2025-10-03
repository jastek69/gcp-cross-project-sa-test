#!/usr/bin/env bash
set -euo pipefail
CI=true

# Load doctor
. ./scripts/doctor_common.sh
doctor_check

echo "=== [CI/CD] Terraform init & apply under impersonation ==="
terraform init -input=false
terraform apply -var="bootstrap_mode=false" -auto-approve -input=false

echo "✅ CI/CD apply complete."
echo "   Terraform should now run entirely under impersonated SAs."