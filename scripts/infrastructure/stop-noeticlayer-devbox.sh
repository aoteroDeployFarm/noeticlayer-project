#!/usr/bin/env bash
set -euo pipefail

read -rp "GCP Project ID: " PROJECT_ID

read -rp "VM Name [noeticlayer-devbox]: " VM_NAME
VM_NAME=${VM_NAME:-noeticlayer-devbox}

read -rp "Zone [us-central1-a]: " ZONE
ZONE=${ZONE:-us-central1-a}

echo ""
echo "Stopping VM..."
echo ""

gcloud config set project "${PROJECT_ID}"

gcloud compute instances stop "${VM_NAME}" \
  --zone="${ZONE}"

echo ""
echo "VM stopped."
echo ""

gcloud compute instances list