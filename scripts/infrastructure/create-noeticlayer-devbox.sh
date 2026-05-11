#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="regulatory-monitor-ai"
ZONE="us-central1-a"
VM_NAME="noeticlayer-devbox"
REGION="us-central1"
MACHINE_TYPE="e2-medium"
BOOT_DISK_SIZE="50GB"
BOOT_DISK_TYPE="pd-balanced"
VPC_NAME="noeticlayer-vpc"
SUBNET_NAME="noeticlayer-subnet-us-central1"
SSH_FIREWALL_RULE="noeticlayer-allow-ssh"

echo ""
echo "========================================="
echo " NoeticLayer GCP Dev Box Provisioner"
echo "========================================="
echo ""

read -rp "GCP Project ID [${PROJECT_ID}]: " INPUT_PROJECT
PROJECT_ID=${INPUT_PROJECT:-$PROJECT_ID}

read -rp "VM Name [${VM_NAME}]: " INPUT_VM
VM_NAME=${INPUT_VM:-$VM_NAME}

read -rp "Region [${REGION}]: " INPUT_REGION
REGION=${INPUT_REGION:-$REGION}

read -rp "Zone [${ZONE}]: " INPUT_ZONE
ZONE=${INPUT_ZONE:-$ZONE}

read -rp "Machine Type [${MACHINE_TYPE}]: " INPUT_MACHINE
MACHINE_TYPE=${INPUT_MACHINE:-$MACHINE_TYPE}

read -rp "Boot Disk Size [${BOOT_DISK_SIZE}]: " INPUT_DISK_SIZE
BOOT_DISK_SIZE=${INPUT_DISK_SIZE:-$BOOT_DISK_SIZE}

read -rp "Boot Disk Type [${BOOT_DISK_TYPE}]: " INPUT_DISK_TYPE
BOOT_DISK_TYPE=${INPUT_DISK_TYPE:-$BOOT_DISK_TYPE}

read -rp "VPC Name [${VPC_NAME}]: " INPUT_VPC
VPC_NAME=${INPUT_VPC:-$VPC_NAME}

read -rp "Subnet Name [${SUBNET_NAME}]: " INPUT_SUBNET
SUBNET_NAME=${INPUT_SUBNET:-$SUBNET_NAME}

IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
NETWORK_TAGS="noeticlayer-devbox,ssh"

echo ""
echo "Provisioning Configuration"
echo "-----------------------------------------"
echo "Project ID:     ${PROJECT_ID}"
echo "VM Name:        ${VM_NAME}"
echo "Region:         ${REGION}"
echo "Zone:           ${ZONE}"
echo "Machine Type:   ${MACHINE_TYPE}"
echo "Disk Size:      ${BOOT_DISK_SIZE}"
echo "Disk Type:      ${BOOT_DISK_TYPE}"
echo "VPC:            ${VPC_NAME}"
echo "Subnet:         ${SUBNET_NAME}"
echo "Firewall Rule:  ${SSH_FIREWALL_RULE}"
echo "OS Login:       TRUE"
echo ""

read -rp "Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Provisioning cancelled."
  exit 1
fi

echo ""
echo "Setting active project..."
gcloud config set project "${PROJECT_ID}"

echo ""
echo "Enabling required APIs..."
gcloud services enable \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

echo ""
echo "Validating VPC..."
gcloud compute networks describe "${VPC_NAME}" \
  --project="${PROJECT_ID}" >/dev/null

echo "Validating subnet..."
gcloud compute networks subnets describe "${SUBNET_NAME}" \
  --project="${PROJECT_ID}" \
  --region="${REGION}" >/dev/null

echo "Validating SSH firewall rule..."
if gcloud compute firewall-rules describe "${SSH_FIREWALL_RULE}" \
  --project="${PROJECT_ID}" >/dev/null 2>&1; then
  echo "Firewall rule exists: ${SSH_FIREWALL_RULE}"
  echo "Skipping firewall changes."
else
  echo "ERROR: Firewall rule missing: ${SSH_FIREWALL_RULE}"
  echo "Run scripts/infrastructure/create-noeticlayer-vpc.sh first."
  exit 1
fi

echo ""
echo "Checking whether VM already exists..."
if gcloud compute instances describe "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" >/dev/null 2>&1; then
  echo "ERROR: VM already exists: ${VM_NAME}"
  echo "Delete it first or use scripts/infrastructure/recreate-noeticlayer-devbox.sh"
  exit 1
fi

echo ""
echo "Creating NoeticLayer dev VM with OS Login enabled..."
gcloud compute instances create "${VM_NAME}" \
  --project="${PROJECT_ID}" \
  --zone="${ZONE}" \
  --machine-type="${MACHINE_TYPE}" \
  --boot-disk-size="${BOOT_DISK_SIZE}" \
  --boot-disk-type="${BOOT_DISK_TYPE}" \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --network="${VPC_NAME}" \
  --subnet="${SUBNET_NAME}" \
  --tags="${NETWORK_TAGS}" \
  --metadata=enable-oslogin=TRUE,startup-script='#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y \
  git \
  curl \
  wget \
  unzip \
  build-essential \
  python3 \
  python3-pip \
  python3-venv \
  postgresql \
  postgresql-contrib \
  postgresql-server-dev-all \
  google-compute-engine-oslogin \
  google-guest-agent

systemctl enable google-guest-agent || true
systemctl restart google-guest-agent || true

cd /tmp
if [ ! -d pgvector ]; then
  git clone https://github.com/pgvector/pgvector.git
fi

cd /tmp/pgvector
make
make install

systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '\''noetic'\''
   ) THEN
      CREATE ROLE noetic WITH LOGIN PASSWORD '\''noetic'\'';
   END IF;
END
\$\$;
SQL

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '\''noeticlayer'\''" | grep -q 1 || \
  sudo -u postgres createdb -O noetic noeticlayer

sudo -u postgres psql -d noeticlayer <<SQL
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
SQL

mkdir -p /opt/noeticlayer
chmod 775 /opt/noeticlayer

echo "NoeticLayer dev box startup complete."
'

echo ""
echo "Dev box creation requested."
echo ""
echo "Register your SSH key if needed:"
echo "gcloud compute os-login ssh-keys add --key-file=\"\$HOME/.ssh/google_compute_engine.pub\" --project=${PROJECT_ID}"
echo ""
echo "Connect with:"
echo "gcloud compute ssh ${VM_NAME} --project=${PROJECT_ID} --zone=${ZONE}"