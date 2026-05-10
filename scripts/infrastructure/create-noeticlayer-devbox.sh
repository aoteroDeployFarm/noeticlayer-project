#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# NoeticLayer GCP Dev Box Setup
# -----------------------------

PROJECT_ID="YOUR_GCP_PROJECT_ID"
ZONE="us-central1-a"
REGION="us-central1"

VM_NAME="noeticlayer-devbox"
MACHINE_TYPE="e2-medium"
BOOT_DISK_SIZE="50GB"
BOOT_DISK_TYPE="pd-balanced"
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

TAGS="noeticlayer-dev,ssh"

echo "Setting active project..."
gcloud config set project "${PROJECT_ID}"

echo "Enabling required APIs..."
gcloud services enable \
  compute.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com

echo "Creating NoeticLayer dev VM..."
gcloud compute instances create "${VM_NAME}" \
  --zone="${ZONE}" \
  --machine-type="${MACHINE_TYPE}" \
  --boot-disk-size="${BOOT_DISK_SIZE}" \
  --boot-disk-type="${BOOT_DISK_TYPE}" \
  --image-family="${IMAGE_FAMILY}" \
  --image-project="${IMAGE_PROJECT}" \
  --tags="${TAGS}" \
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

# Install pgvector from source
cd /tmp
git clone https://github.com/pgvector/pgvector.git
cd pgvector
make
make install

# Enable and start PostgreSQL
systemctl enable postgresql
systemctl start postgresql

# Create NoeticLayer database and user
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

CREATE DATABASE noeticlayer OWNER noetic;
SQL

# Enable extensions
sudo -u postgres psql -d noeticlayer <<SQL
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
SQL

# Create workspace directory
mkdir -p /opt/noeticlayer
chown -R $USER:$USER /opt/noeticlayer || true

echo "NoeticLayer dev box startup complete."
'

echo "Creating firewall rule for SSH if missing..."
if ! gcloud compute firewall-rules describe allow-ssh-noeticlayer >/dev/null 2>&1; then
  gcloud compute firewall-rules create allow-ssh-noeticlayer \
    --allow=tcp:22 \
    --target-tags=ssh \
    --description="Allow SSH access to NoeticLayer dev box"
else
  echo "Firewall rule already exists."
fi

echo ""
echo "Dev box created."
echo ""
echo "Connect with:"
echo "gcloud compute ssh ${VM_NAME} --zone=${ZONE}"