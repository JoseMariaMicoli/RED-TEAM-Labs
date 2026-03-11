#!/bin/bash
set -euo pipefail

readonly LOGFILE="/var/log/target-lab-bootstrap.log"
exec > >(tee -a "${LOGFILE}" /var/log/cloud-init-output.log) 2>&1

apt-get update
apt-get install -y docker.io docker-compose-plugin

systemctl enable --now docker

TARGET_DIR="/opt/target-lab"
mkdir -p "${TARGET_DIR}"

cat <<'EOF' > "${TARGET_DIR}/docker-compose.yml"
version: "3.9"

services:
  juice-shop:
    image: bkimminich/juice-shop:latest
    restart: unless-stopped
    ports:
      - "3000:3000"

  crapi:
    image: owasp/crapi:latest
    restart: unless-stopped
    ports:
      - "8888:80"

  vampi:
    image: vampi/vampi:latest
    restart: unless-stopped
    ports:
      - "5000:5000"
EOF

docker compose -f "${TARGET_DIR}/docker-compose.yml" pull
docker compose -f "${TARGET_DIR}/docker-compose.yml" up -d
