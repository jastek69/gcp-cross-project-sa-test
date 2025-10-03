#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Terraform IAM/VPN Bootstrap Script
# ============================================================================
# This script bootstraps GCP IAM so Terraform can manage projects entirely
# under impersonated service accounts (no persistent Owner roles).
#
# Steps:
#   1. Grant temporary Owner to your user account in both projects
#   2. Run terraform apply to seed impersonation bindings
#   3. Verify impersonation works (print token for each Terraform SA)
#   4. Remove temporary Owner from your user
# ============================================================================

# --------------------------
# CONFIG - edit these values
# --------------------------
USER_ACCOUNT="user:jastek.sweeney@gmail.com"
BALERICA_PROJECT="taaops"
GENOSHA_PROJECT="genosha-ops"

BALERICA_SA="terraform@${BALERICA_PROJECT}.iam.gserviceaccount.com"
GENOSHA_SA="terraform@${GENOSHA_PROJECT}.iam.gserviceaccount.com"

# ============================================================================
# Step 1. Grant temporary Owner roles
# ============================================================================
echo "[1/4] Granting temporary Owner role to ${USER_ACCOUNT} ..."
gcloud projects add-iam-policy-binding "$BALERICA_PROJECT" \
  --member="$USER_ACCOUNT" \
  --role="roles/owner"

gcloud projects add-iam-policy-binding "$GENOSHA_PROJECT" \
  --member="$USER_ACCOUNT" \
  --role="roles/owner"

# ============================================================================
# Step 2. Apply Terraform targets for impersonation bindings
# ============================================================================
echo "[2/4] Running Terraform to seed impersonation bindings ..."
terraform init -upgrade

terraform apply -auto-approve \
  -target=google_service_account_iam_member.balerica_impersonation_token_creator \
  -target=google_service_account_iam_member.balerica_impersonation_sa_user \
  -target=google_service_account_iam_member.genosha_impersonation_token_creator \
  -target=google_service_account_iam_member.genosha_impersonation_sa_user

# ============================================================================
# Step 3. Verify impersonation works
# ============================================================================
echo "[3/4] Verifying impersonation for Terraform SAs ..."

echo "→ Testing Balerica SA (${BALERICA_SA})"
gcloud auth print-access-token \
  --impersonate-service-account="${BALERICA_SA}" >/dev/null && \
  echo "✅ Balerica impersonation works"

echo "→ Testing Genosha SA (${GENOSHA_SA})"
gcloud auth print-access-token \
  --impersonate-service-account="${GENOSHA_SA}" >/dev/null && \
  echo "✅ Genosha impersonation works"

# ============================================================================
# Step 4. Remove temporary Owner roles
# ============================================================================
echo "[4/4] Removing temporary Owner role from ${USER_ACCOUNT} ..."
gcloud projects remove-iam-policy-binding "$BALERICA_PROJECT" \
  --member="$USER_ACCOUNT" \
  --role="roles/owner"

gcloud projects remove-iam-policy-binding "$GENOSHA_PROJECT" \
  --member="$USER_ACCOUNT" \
  --role="roles/owner"

echo "🎉 Bootstrap complete. Terraform should now run entirely under impersonated SAs."
