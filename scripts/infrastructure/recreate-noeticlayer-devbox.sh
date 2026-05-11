#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="regulatory-monitor-ai"
ZONE="us-central1-a"
VM_NAME="noeticlayer-devbox"

echo ""
echo "========================================="
echo " Recreate NoeticLayer Dev Box"
echo "========================================="
echo ""

read -rp "GCP Project ID [${PROJECT_ID}]: " INPUT_PROJECT
PROJECT_ID=${INPUT_PROJECT:-$PROJECT_ID}

read -rp "Zone [${ZONE}]: " INPUT_ZONE
ZONE=${INPUT_ZONE:-$ZONE}

read -rp "VM Name [${VM_NAME}]: " INPUT_VM
VM_NAME=${INPUT_VM:-$VM_NAME}

echo ""
echo "This will DELETE and RECREATE:"
echo "Project: ${PROJECT_ID}"
echo "Zone:    ${ZONE}"
echo "VM:      ${VM_NAME}"
echo ""

read -rp "Continue? Type DELETE to proceed: " CONFIRM

if [[ "${CONFIRM}" != "DELETE" ]]; then
  echo "Cancelled."
  exit 1
fi

gcloud config set project "${PROJECT_ID}"

echo ""
echo "Deleting existing VM if present..."
if gcloud compute instances describe "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" >/dev/null 2>&1; then

  gcloud compute instances delete "${VM_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONE}" \
    --quiet
else
  echo "VM does not exist. Continuing."
fi

echo ""
echo "Recreating dev box..."
./scripts/infrastructure/create-noeticlayer-devbox.sh

echo ""
echo "Registering OS Login SSH key..."
if [[ -f "${HOME}/.ssh/google_compute_engine.pub" ]]; then
  gcloud compute os-login ssh-keys add \
    --key-file="${HOME}/.ssh/google_compute_engine.pub" \
    --project="${PROJECT_ID}"
else
  echo "No google_compute_engine.pub key found."
  echo "Run:"
  echo "ssh-keygen -t rsa -f \"\$HOME/.ssh/google_compute_engine\" -C \"alex.otero@precisionneural.systems\" -N \"\""
fi

echo ""
echo "Done."
echo ""
echo "Test SSH:"
echo "gcloud compute ssh ${VM_NAME} --project=${PROJECT_ID} --zone=${ZONE}"