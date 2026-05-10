#!/usr/bin/env bash
set -euo pipefail

DEFAULT_PROJECT_ID="regulatory-monitor-ai"
DEFAULT_ORG_ID="104961726519"
DEFAULT_ADMIN_ACCOUNT="alex.otero@precisionneural.systems"
DEFAULT_LOGIN_PRINCIPAL="alex.otero@precisionneural.systems"
DEFAULT_VM_NAME="noeticlayer-devbox"
DEFAULT_ZONE="us-central1-a"

echo ""
echo "========================================="
echo " NoeticLayer Dev Box Login Configuration"
echo "========================================="
echo ""

read -rp "GCP Project ID [${DEFAULT_PROJECT_ID}]: " PROJECT_ID
PROJECT_ID=${PROJECT_ID:-$DEFAULT_PROJECT_ID}

read -rp "Organization ID [${DEFAULT_ORG_ID}]: " ORG_ID
ORG_ID=${ORG_ID:-$DEFAULT_ORG_ID}

read -rp "Admin gcloud account [${DEFAULT_ADMIN_ACCOUNT}]: " ADMIN_ACCOUNT
ADMIN_ACCOUNT=${ADMIN_ACCOUNT:-$DEFAULT_ADMIN_ACCOUNT}

read -rp "Login principal email [${DEFAULT_LOGIN_PRINCIPAL}]: " LOGIN_EMAIL
LOGIN_EMAIL=${LOGIN_EMAIL:-$DEFAULT_LOGIN_PRINCIPAL}

read -rp "VM Name [${DEFAULT_VM_NAME}]: " VM_NAME
VM_NAME=${VM_NAME:-$DEFAULT_VM_NAME}

read -rp "Zone [${DEFAULT_ZONE}]: " ZONE
ZONE=${ZONE:-$DEFAULT_ZONE}

LOGIN_MEMBER="user:${LOGIN_EMAIL}"

echo ""
echo "Configuration"
echo "-----------------------------------------"
echo "Project:         ${PROJECT_ID}"
echo "Organization:    ${ORG_ID}"
echo "Admin Account:   ${ADMIN_ACCOUNT}"
echo "Login Principal: ${LOGIN_MEMBER}"
echo "VM Name:         ${VM_NAME}"
echo "Zone:            ${ZONE}"
echo ""

read -rp "Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 1
fi

echo ""
echo "Checking admin account authentication..."
if ! gcloud auth list --filter="account:${ADMIN_ACCOUNT}" --format="value(account)" | grep -q "${ADMIN_ACCOUNT}"; then
  echo ""
  echo "Admin account is not authenticated."
  echo "Run this first:"
  echo ""
  echo "gcloud auth login ${ADMIN_ACCOUNT}"
  echo ""
  exit 1
fi

echo ""
echo "Setting active gcloud account and project..."
gcloud config set account "${ADMIN_ACCOUNT}"
gcloud config set project "${PROJECT_ID}"

echo ""
echo "Validating project..."
gcloud projects describe "${PROJECT_ID}" >/dev/null

echo ""
echo "Applying project-level IAM roles..."
PROJECT_ROLES=(
  "roles/compute.osLogin"
  "roles/compute.instanceAdmin.v1"
  "roles/iam.serviceAccountUser"
)

for ROLE in "${PROJECT_ROLES[@]}"; do
  echo "Applying project role: ${ROLE}"
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="${LOGIN_MEMBER}" \
    --role="${ROLE}" \
    --quiet
done

echo ""
echo "Applying organization-level OS Login External User role..."
echo "This requires organization admin permissions."
echo ""

if gcloud organizations add-iam-policy-binding "${ORG_ID}" \
  --member="${LOGIN_MEMBER}" \
  --role="roles/compute.osLoginExternalUser" \
  --quiet; then
  echo "Applied organization role: roles/compute.osLoginExternalUser"
else
  echo ""
  echo "WARNING:"
  echo "Could not apply organization role."
  echo "If SSH fails, manually grant this at the organization level:"
  echo ""
  echo "Organization ID: ${ORG_ID}"
  echo "Principal:       ${LOGIN_MEMBER}"
  echo "Role:            roles/compute.osLoginExternalUser"
fi

echo ""
echo "Generating gcloud SSH key if missing..."
if [[ ! -f "${HOME}/.ssh/google_compute_engine.pub" ]]; then
  ssh-keygen -t rsa -f "${HOME}/.ssh/google_compute_engine" -C "${ADMIN_ACCOUNT}" -N ""
fi

echo ""
echo "Registering SSH key with OS Login..."
gcloud compute os-login ssh-keys add \
  --key-file="${HOME}/.ssh/google_compute_engine.pub" \
  --project="${PROJECT_ID}" || true

echo ""
echo "Refreshing SSH config..."
gcloud compute config-ssh \
  --project="${PROJECT_ID}" || true

echo ""
echo "Testing VM visibility..."
gcloud compute instances describe "${VM_NAME}" \
  --zone="${ZONE}" \
  --project="${PROJECT_ID}" \
  --format="table(name,status,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP)"

echo ""
echo "Login configuration complete."
echo ""
echo "Try connecting with:"
echo ""
echo "gcloud compute ssh ${VM_NAME} --project=${PROJECT_ID} --zone=${ZONE}"
echo ""
echo "If needed, troubleshoot with:"
echo ""
echo "gcloud compute ssh ${VM_NAME} --project=${PROJECT_ID} --zone=${ZONE} --troubleshoot"