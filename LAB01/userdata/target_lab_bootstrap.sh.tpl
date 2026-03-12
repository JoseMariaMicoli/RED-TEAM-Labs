#!/bin/bash
set -euo pipefail

readonly LOGFILE="/var/log/target-lab-bootstrap.log"
exec > >(tee -a "$${LOGFILE}" /var/log/cloud-init-output.log) 2>&1

info() { printf '%s %s\n' "[INFO]" "$*"; }
warn() { printf '%s %s\n' "[WARN]" "$*"; }

readonly DEVOPS_PASSWORD="${devops_password}"
readonly NFS_SERVER_IP="${nfs_server_ip}"
readonly NFS_EXPORT_PATH="${nfs_export_path}"
readonly NFS_MOUNT_PATH="${nfs_mount_path}"

wait_for_apt() {
  local attempts=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$${attempts}" -gt 60 ]; then
      warn "apt locks persist after $$((attempts * 5)) seconds; proceeding anyway"
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

  wait_for_apt
  info "Installing docker + docker-compose (targets) plus SSH/NFS/audit tooling"
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    auditd \
    ca-certificates \
    curl \
    docker.io \
    docker-compose \
    jq \
    nfs-common \
    openssh-server
}

ensure_devops_user() {
  if id -u devops >/dev/null 2>&1; then
    info "User devops already exists"
  else
    info "Creating user devops"
    useradd -m -s /bin/bash devops
  fi

  info "Setting lab-only password for devops (credential reuse simulation)"
  echo "devops:$${DEVOPS_PASSWORD}" | chpasswd

  info "Adding devops to sudo group"
  usermod -aG sudo devops
}

enable_password_ssh() {
  info "Enabling SSH password authentication (lab-only)"
  sed -i 's/^#\\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/^#\\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
  systemctl enable --now ssh
  systemctl restart ssh || true
}

configure_auditd() {
  info "Enabling auditd"
  systemctl enable --now auditd || true

  cat <<'EOF' >/etc/audit/rules.d/nyxera-lab.rules
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
EOF

  augenrules --load || true
}

mount_nfs_share() {
  info "Mounting NFS share from $${NFS_SERVER_IP}:$${NFS_EXPORT_PATH} to $${NFS_MOUNT_PATH}"
  mkdir -p "$${NFS_MOUNT_PATH}"

  if ! grep -qE "^[^#].*$${NFS_MOUNT_PATH}[[:space:]]" /etc/fstab; then
    echo "$${NFS_SERVER_IP}:$${NFS_EXPORT_PATH} $${NFS_MOUNT_PATH} nfs4 defaults,vers=4.1,_netdev,nofail 0 0" >>/etc/fstab
  fi

  local attempts=0
  until mountpoint -q "$${NFS_MOUNT_PATH}"; do
    attempts=$((attempts + 1))
    if [ "$${attempts}" -gt 60 ]; then
      warn "NFS mount did not succeed after retries; continuing"
      break
    fi
    mount -a || true
    sleep 5
  done
}

TARGET_DIR="/opt/target-lab"
mkdir -p "$${TARGET_DIR}/apps" "$${TARGET_DIR}/crapi"

configure_apps_compose() {
  info "Writing Juice Shop + VAmPI docker-compose.yml"
  cat <<'EOF' > "$${TARGET_DIR}/apps/docker-compose.yml"
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
    -o "$${TARGET_DIR}/crapi/docker-compose.yml"

  info "Writing crAPI .env (bind ports on 0.0.0.0)"
  cat <<'EOF' > "$${TARGET_DIR}/crapi/.env"
LISTEN_IP=0.0.0.0
TLS_ENABLED=false
VERSION=latest
LOG_LEVEL=INFO
EOF
}

bring_up() {
  info "Starting Juice Shop + VAmPI"
  docker-compose -f "$${TARGET_DIR}/apps/docker-compose.yml" pull
  docker-compose -f "$${TARGET_DIR}/apps/docker-compose.yml" up -d

  info "Starting crAPI stack (this can take a few minutes on first boot)"
  (cd "$${TARGET_DIR}/crapi" && docker-compose pull)
  (cd "$${TARGET_DIR}/crapi" && docker-compose up -d)
}

main() {
  install_packages
  systemctl enable --now docker
  ensure_devops_user
  enable_password_ssh
  configure_auditd
  mount_nfs_share
  configure_apps_compose
  configure_crapi
  bring_up
  info "Target lab bootstrap completed"
}

main
