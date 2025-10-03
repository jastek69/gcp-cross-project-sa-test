#!/usr/bin/env bash
set -euo pipefail

# ========================================
# Safe cleanup of Terraform state locks
# ========================================

BACKEND_FILE="01-providers.tf"
LOCK_ID_FILE=".last_lock_id"

echo "🔍 Parsing backend configuration from $BACKEND_FILE ..."

BUCKET=$(grep 'bucket' "$BACKEND_FILE" | awk -F '"' '{print $2}')
PREFIX=$(grep 'prefix' "$BACKEND_FILE" | awk -F '"' '{print $2}')

LOCK_PATH="gs://${BUCKET}/${PREFIX}/default.tflock"

echo "Parsed backend:"
echo "  Bucket: $BUCKET"
echo "  Prefix: $PREFIX"
echo "  Lock file: $LOCK_PATH"
echo ""

# Check if lock file exists in GCS
if gsutil -q stat "$LOCK_PATH"; then
  echo "⚠️  Lock file found in GCS at $LOCK_PATH"
  read -p "Do you want to delete it? (y/N) " yn
  case $yn in
    [Yy]* ) gsutil rm "$LOCK_PATH" && echo "✅ Lock file removed from GCS.";;
    * ) echo "❌ Aborted by user."; exit 1;;
  esac
else
  echo "ℹ️  No lock file present in GCS."
  # Check if we saved a Lock ID from last Terraform error
  if [[ -f "$LOCK_ID_FILE" ]]; then
    LOCK_ID=$(cat "$LOCK_ID_FILE")
    echo "⚠️  Found a stale lock ID: $LOCK_ID"
    read -p "Do you want to run 'terraform force-unlock -force $LOCK_ID'? (y/N) " yn
    case $yn in
      [Yy]* ) terraform force-unlock -force "$LOCK_ID"; echo "✅ Lock force-unlocked.";;
      * ) echo "❌ Aborted by user."; exit 1;;
    esac
  else
    echo "No saved Lock ID. Nothing to do."
  fi
fi
