#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "========================================="
echo " NoeticLayer IAM Role Configuration"
echo "========================================="
echo ""

DEFAULT_GCLOUD_ACCOUNT="alex.otero@precisionneural.systems"
DEFAULT_PRINCIPAL_EMAIL="alex.otero@precisionneural.systems"

ACTIVE_ACCOUNT="$(gcloud config get-value account 2>/dev/null || true)"
ACTIVE_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"

echo "Current gcloud account: ${ACTIVE_ACCOUNT:-none}"
echo "Current gcloud project: ${ACTIVE_PROJECT:-none}"
echo ""

read -rp "GCP Project ID [${ACTIVE_PROJECT}]: " PROJECT_ID
PROJECT_ID=${PROJECT_ID:-$ACTIVE_PROJECT}

read -rp "gcloud admin account to use [${DEFAULT_GCLOUD_ACCOUNT}]: " GCLOUD_ACCOUNT
GCLOUD_ACCOUNT=${GCLOUD_ACCOUNT:-$DEFAULT_GCLOUD_ACCOUNT}

read -rp "Principal Type [user/group/serviceAccount]: " PRINCIPAL_TYPE
PRINCIPAL_TYPE=${PRINCIPAL_TYPE:-user}

read -rp "Principal Email [${DEFAULT_PRINCIPAL_EMAIL}]: " PRINCIPAL_EMAIL
PRINCIPAL_EMAIL=${PRINCIPAL_EMAIL:-$DEFAULT_PRINCIPAL_EMAIL}

if [[ -z "${PROJECT_ID}" || -z "${GCLOUD_ACCOUNT}" || -z "${PRINCIPAL_EMAIL}" ]]; then
  echo "ERROR: Project ID, gcloud account, and principal email are required."
  exit 1
fi

PRINCIPAL="${PRINCIPAL_TYPE}:${PRINCIPAL_EMAIL}"

echo ""
echo "IAM Configuration"
echo "-----------------------------------------"
echo "Project ID:       ${PROJECT_ID}"
echo "gcloud Account:   ${GCLOUD_ACCOUNT}"
echo "Principal:        ${PRINCIPAL}"
echo ""

read -rp "Continue? (y/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

echo ""
echo "Checking whether gcloud account is authenticated..."
if ! gcloud auth list --filter="account:${GCLOUD_ACCOUNT}" --format="value(account)" | grep -q "${GCLOUD_ACCOUNT}"; then
  echo "Account is not authenticated:"
  echo " - ${GCLOUD_ACCOUNT}"
  echo ""
  echo "Run:"
  echo "gcloud auth login ${GCLOUD_ACCOUNT}"
  echo ""
  exit 1
fi

echo ""
echo "Setting gcloud account and project..."
gcloud config set account "${GCLOUD_ACCOUNT}"
gcloud config set project "${PROJECT_ID}"

echo ""
echo "Validating project access..."
gcloud projects describe "${PROJECT_ID}" >/dev/null

echo ""
echo "Checking organization policy constraints..."
echo ""

ORG_POLICY_OUTPUT="$(gcloud resource-manager org-policies describe \
  constraints/iam.allowedPolicyMemberDomains \
  --project="${PROJECT_ID}" 2>/dev/null || true)"

if [[ -n "${ORG_POLICY_OUTPUT}" ]]; then
  echo "Organization policy detected:"
  echo " - constraints/iam.allowedPolicyMemberDomains"
  echo ""

  if [[ "${PRINCIPAL_EMAIL}" == *"@gmail.com" ]]; then
    echo "WARNING:"
    echo "This project restricts IAM members to approved organization domains."
    echo ""
    echo "Blocked principal:"
    echo " - ${PRINCIPAL}"
    echo ""
    echo "Use a Google Workspace / organization-approved account instead."
    echo ""
    echo "No IAM changes were applied."
    exit 1
  fi
else
  echo "No allowedPolicyMemberDomains constraint detected or accessible."
fi

echo ""
echo "Applying IAM roles..."
echo ""

ROLES=(
  "roles/compute.osLogin"
  "roles/compute.instanceAdmin.v1"
  "roles/iam.serviceAccountUser"
)

for ROLE in "${ROLES[@]}"; do
  echo "Applying role: ${ROLE}"

  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="${PRINCIPAL}" \
    --role="${ROLE}" \
    --quiet
done

echo ""
echo "Attempting external OS Login role..."
echo "Note: roles/compute.osLoginExternalUser may require organization-level admin permissions."
echo ""

if gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="${PRINCIPAL}" \
  --role="roles/compute.osLoginExternalUser" \
  --quiet; then
  echo "Applied role: roles/compute.osLoginExternalUser"
else
  echo ""
  echo "WARNING:"
  echo "Could not apply roles/compute.osLoginExternalUser at the project level."
  echo ""
  echo "If SSH still fails, this role may need to be granted at the organization level:"
  echo " - Organization: precisionneural.systems"
  echo " - Organization ID: 104961726519"
  echo " - Role: roles/compute.osLoginExternalUser"
fi

echo ""
echo "IAM role configuration complete."
echo ""
echo "Principal configured:"
echo " - ${PRINCIPAL}"