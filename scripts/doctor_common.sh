#!/usr/bin/env bash
# Shared doctor check for manual + CI/CD scripts

doctor_check() {
  echo "=========================================="
  echo "      🩺 Doctor: GCP/Terraform Checks"
  echo "=========================================="

  # Check tools
  for tool in gcloud terraform jq; do
    if ! command -v $tool >/dev/null; then
      echo "❌ Missing tool: $tool"
      exit 1
    fi
  done
  echo "✅ Tools present"

  # ADC file
  if [ -f "$APPDATA/gcloud/application_default_credentials.json" ]; then
    file="$APPDATA/gcloud/application_default_credentials.json"
  elif [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
    file="$HOME/.config/gcloud/application_default_credentials.json"
  else
    echo "❌ No ADC credentials file found"
    exit 1
  fi

  email=$(jq -r .client_email "$file")
  echo "🔑 ADC client_email: $email (from $file)"

  if [ -z "$email" ] || [ "$email" = "null" ]; then
    echo "❌ Invalid ADC client_email"
    exit 1
  fi

  if [ "${CI:-false}" = "true" ]; then
    if grep -q "bootstrap_mode *= *true" terraform.tfvars; then
      echo "❌ CI/CD ERROR: bootstrap_mode=true not allowed"
      exit 1
    fi
    echo "✅ bootstrap_mode=false (enforced for CI/CD)"
  else
    if grep -q "bootstrap_mode *= *true" terraform.tfvars; then
      echo "⚠️  WARNING: bootstrap_mode=true (manual Owner mode)"
    else
      echo "✅ bootstrap_mode=false (impersonation active)"
    fi
  fi
}
