#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "========================================="
echo " NoeticLayer GCP VPC Provisioner"
echo "========================================="
echo ""

read -rp "GCP Project ID: " PROJECT_ID

read -rp "VPC Name [noeticlayer-vpc]: " VPC_NAME
VPC_NAME=${VPC_NAME:-noeticlayer-vpc}

read -rp "Region [us-central1]: " REGION
REGION=${REGION:-us-central1}

read -rp "Subnet Name [noeticlayer-subnet-us-central1]: " SUBNET_NAME
SUBNET_NAME=${SUBNET_NAME:-noeticlayer-subnet-us-central1}

read -rp "Subnet CIDR [10.10.0.0/24]: " SUBNET_CIDR
SUBNET_CIDR=${SUBNET_CIDR:-10.10.0.0/24}

echo ""
echo "Provisioning Configuration"
echo "-----------------------------------------"
echo "Project ID:   ${PROJECT_ID}"
echo "VPC Name:     ${VPC_NAME}"
echo "Region:       ${REGION}"
echo "Subnet Name:  ${SUBNET_NAME}"
echo "Subnet CIDR:  ${SUBNET_CIDR}"
echo ""

read -rp "Continue? (y/n): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Provisioning cancelled."
  exit 1
fi

echo "Setting active project..."
gcloud config set project "${PROJECT_ID}"

echo "Enabling required APIs..."
gcloud services enable \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

echo "Checking for VPC..."
if gcloud compute networks describe "${VPC_NAME}" >/dev/null 2>&1; then
  echo "VPC already exists: ${VPC_NAME}"
else
  echo "Creating VPC: ${VPC_NAME}"
  gcloud compute networks create "${VPC_NAME}" \
    --subnet-mode=custom
fi

echo "Checking for subnet..."
if gcloud compute networks subnets describe "${SUBNET_NAME}" \
  --region="${REGION}" >/dev/null 2>&1; then
  echo "Subnet already exists: ${SUBNET_NAME}"
else
  echo "Creating subnet: ${SUBNET_NAME}"
  gcloud compute networks subnets create "${SUBNET_NAME}" \
    --network="${VPC_NAME}" \
    --region="${REGION}" \
    --range="${SUBNET_CIDR}"
fi

echo "Checking firewall rule..."
if gcloud compute firewall-rules describe noeticlayer-allow-ssh >/dev/null 2>&1; then
  echo "Firewall rule already exists: noeticlayer-allow-ssh"
else
  echo "Creating firewall rule: noeticlayer-allow-ssh"
  gcloud compute firewall-rules create noeticlayer-allow-ssh \
    --network="${VPC_NAME}" \
    --allow=tcp:22 \
    --target-tags=ssh \
    --description="Allow SSH access to NoeticLayer dev box"
fi

echo ""
echo "VPC provisioning complete."
echo ""
echo "Use these values in your dev box script:"
echo "VPC:    ${VPC_NAME}"
echo "Subnet: ${SUBNET_NAME}"