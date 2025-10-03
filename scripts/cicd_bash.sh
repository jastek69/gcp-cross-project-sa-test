#!/usr/bin/env bash
set -euo pipefail

USER_ACCOUNT="${USER_ACCOUNT:-jastek.sweeney@gmail.com}"
BALERICA_PROJECT="${BALERICA_PROJECT:-taaops}"
GENOSHA_PROJECT="${GENOSHA_PROJECT:-genosha-ops}"

echo "=== [STEP 1] Authenticating as $USER_ACCOUNT ==="
gcloud auth application-default login

echo "=== [STEP 2] Granting Service Account Admin ==="
gcloud projects add-iam-policy-binding "$BALERICA_PROJECT" \
  --member="user:$USER_ACCOUNT" --role="roles/iam.serviceAccountAdmin"
gcloud projects add-iam-policy-binding "$GENOSHA_PROJECT" \
  --member="user:$USER_ACCOUNT" --role="roles/iam.serviceAccountAdmin"

echo "=== [STEP 3] Terraform init + impersonation bindings ==="
terraform init
terraform apply -var="bootstrap_mode=true" \
  -target=google_service_account_iam_member.balerica_impersonation_token_creator \
  -target=google_service_account_iam_member.balerica_impersonation_sa_user \
  -target=google_service_account_iam_member.genosha_impersonation_token_creator \
  -target=google_service_account_iam_member.genosha_impersonation_sa_user

echo "=== [STEP 4] Verify impersonation ==="
gcloud auth print-access-token \
  --impersonate-service-account="terraform@$BALERICA_PROJECT.iam.gserviceaccount.com" | head -c 80; echo
gcloud auth print-access-token \
  --impersonate-service-account="terraform@$GENOSHA_PROJECT.iam.gserviceaccount.com" | head -c 80; echo

echo "✅ Bootstrap complete. Next: set bootstrap_mode=false and re-run Terraform."
