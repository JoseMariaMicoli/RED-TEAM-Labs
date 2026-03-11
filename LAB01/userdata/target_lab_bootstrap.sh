#!/bin/bash
set -euo pipefail

readonly LOGFILE="/var/log/target-lab-bootstrap.log"
exec > >(tee -a "${LOGFILE}" /var/log/cloud-init-output.log) 2>&1

info() { printf '%s %s\n' "[INFO]" "$*"; }
warn() { printf '%s %s\n' "[WARN]" "$*"; }

wait_for_apt() {
  local attempts=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "${attempts}" -gt 60 ]; then
      warn "apt locks persist after $((attempts * 5)) seconds; proceeding anyway"
      break
    fi
    info "Waiting for apt lock release..."
    sleep 5
  done
}

install_packages() {
  wait_for_apt
  info "Updating apt cache"
  DEBIAN_FRONTEND=noninteractive apt-get update -y

  # Ubuntu repos ship docker.io + docker-compose (v1). We use docker-compose here
  # to avoid relying on Docker's upstream repo or the v2 plugin package name.
  wait_for_apt
  info "Installing docker + docker-compose"
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    docker.io \
    docker-compose \
    jq
}

TARGET_DIR="/opt/target-lab"
mkdir -p "${TARGET_DIR}/apps" "${TARGET_DIR}/crapi"

configure_apps_compose() {
  info "Writing Juice Shop + VAmPI docker-compose.yml"
  cat <<'EOF' > "${TARGET_DIR}/apps/docker-compose.yml"
version: "3.9"

services:
  juice-shop:
    image: bkimminich/juice-shop:latest
    restart: unless-stopped
    ports:
      - "3000:3000"

  vampi:
    image: erev0s/vampi:latest
    restart: unless-stopped
    ports:
      - "5000:5000"
EOF
}

configure_crapi() {
  info "Fetching upstream crAPI docker-compose.yml"
  curl -fsSL \
    "https://raw.githubusercontent.com/OWASP/crAPI/develop/deploy/docker/docker-compose.yml" \
    -o "${TARGET_DIR}/crapi/docker-compose.yml"

  info "Writing crAPI .env (bind ports on 0.0.0.0)"
  cat <<'EOF' > "${TARGET_DIR}/crapi/.env"
LISTEN_IP=0.0.0.0
TLS_ENABLED=false
VERSION=latest
LOG_LEVEL=INFO
EOF
}

bring_up() {
  info "Starting Juice Shop + VAmPI"
  docker-compose -f "${TARGET_DIR}/apps/docker-compose.yml" pull
  docker-compose -f "${TARGET_DIR}/apps/docker-compose.yml" up -d

  info "Starting crAPI stack (this can take a few minutes on first boot)"
  (cd "${TARGET_DIR}/crapi" && docker-compose pull)
  (cd "${TARGET_DIR}/crapi" && docker-compose up -d)
}

main() {
  install_packages
  systemctl enable --now docker
  configure_apps_compose
  configure_crapi
  bring_up
  info "Target lab bootstrap completed"
}

main
