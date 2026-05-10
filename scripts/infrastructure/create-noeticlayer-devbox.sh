#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "========================================="
echo " NoeticLayer GCP Dev Box Provisioner"
echo "========================================="
echo ""

read -rp "GCP Project ID: " PROJECT_ID

read -rp "VM Name [noeticlayer-devbox]: " VM_NAME
VM_NAME=${VM_NAME:-noeticlayer-devbox}

read -rp "Region [us-central1]: " REGION
REGION=${REGION:-us-central1}

read -rp "Zone [us-central1-a]: " ZONE
ZONE=${ZONE:-us-central1-a}

read -rp "Machine Type [e2-medium]: " MACHINE_TYPE
MACHINE_TYPE=${MACHINE_TYPE:-e2-medium}

read -rp "Boot Disk Size [50GB]: " BOOT_DISK_SIZE
BOOT_DISK_SIZE=${BOOT_DISK_SIZE:-50GB}

read -rp "Boot Disk Type [pd-balanced]: " BOOT_DISK_TYPE
BOOT_DISK_TYPE=${BOOT_DISK_TYPE:-pd-balanced}

read -rp "VPC Name [noeticlayer-vpc]: " VPC_NAME
VPC_NAME=${VPC_NAME:-noeticlayer-vpc}

read -rp "Subnet Name [noeticlayer-subnet-us-central1]: " SUBNET_NAME
SUBNET_NAME=${SUBNET_NAME:-noeticlayer-subnet-us-central1}

echo ""
echo "Detecting current public IP for SSH restriction..."
CURRENT_IP="$(curl -s https://ifconfig.me || true)"

read -rp "Allowed SSH Source CIDR [${CURRENT_IP}/32]: " SSH_SOURCE_CIDR
SSH_SOURCE_CIDR=${SSH_SOURCE_CIDR:-${CURRENT_IP}/32}

IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

NETWORK_TAGS="noeticlayer-devbox,ssh"

echo ""
echo "Provisioning Configuration"
echo "-----------------------------------------"
echo "Project ID:        ${PROJECT_ID}"
echo "VM Name:           ${VM_NAME}"
echo "Region:            ${REGION}"
echo "Zone:              ${ZONE}"
echo "Machine Type:      ${MACHINE_TYPE}"
echo "Disk Size:         ${BOOT_DISK_SIZE}"
echo "Disk Type:         ${BOOT_DISK_TYPE}"
echo "VPC:               ${VPC_NAME}"
echo "Subnet:            ${SUBNET_NAME}"
echo "SSH Source CIDR:   ${SSH_SOURCE_CIDR}"
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

echo "Validating VPC..."
if ! gcloud compute networks describe "${VPC_NAME}" >/dev/null 2>&1; then
  echo "ERROR: VPC not found: ${VPC_NAME}"
  echo "Run scripts/infrastructure/create-noeticlayer-vpc.sh first."
  exit 1
fi

echo "Validating subnet..."
if ! gcloud compute networks subnets describe "${SUBNET_NAME}" \
  --region="${REGION}" >/dev/null 2>&1; then
  echo "ERROR: Subnet not found: ${SUBNET_NAME} in ${REGION}"
  echo "Run scripts/infrastructure/create-noeticlayer-vpc.sh first."
  exit 1
fi

echo "Creating or updating restricted SSH firewall rule..."
if gcloud compute firewall-rules describe noeticlayer-allow-ssh >/dev/null 2>&1; then
  gcloud compute firewall-rules update noeticlayer-allow-ssh \
    --source-ranges="${SSH_SOURCE_CIDR}" \
    --allow=tcp:22 \
    --target-tags=ssh
else
  gcloud compute firewall-rules create noeticlayer-allow-ssh \
    --network="${VPC_NAME}" \
    --allow=tcp:22 \
    --source-ranges="${SSH_SOURCE_CIDR}" \
    --target-tags=ssh \
    --description="Allow restricted SSH access to NoeticLayer dev box"
fi

echo "Creating NoeticLayer dev VM..."
gcloud compute instances create "${VM_NAME}" \
  --zone="${ZONE}" \
  --machine-type="${MACHINE_TYPE}" \
  --boot-disk-size="${BOOT_DISK_SIZE}" \
  --boot-disk-type="${BOOT_DISK_TYPE}" \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --network="${VPC_NAME}" \
  --subnet="${SUBNET_NAME}" \
  --tags="${NETWORK_TAGS}" \
  --metadata=startup-script='#!/usr/bin/env bash
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
  postgresql-server-dev-all

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
chmod 755 /opt/noeticlayer

echo "NoeticLayer dev box startup complete."
'

echo ""
echo "Dev box creation requested."
echo ""
echo "Verify with:"
echo "gcloud compute instances list"
echo ""
echo "Connect with:"
echo "gcloud compute ssh ${VM_NAME} --zone=${ZONE}"