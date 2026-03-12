#!/bin/bash
set -euo pipefail

readonly LOGFILE="/var/log/linux02-bootstrap.log"
exec > >(tee -a "$${LOGFILE}" /var/log/cloud-init-output.log) 2>&1

info() { printf '%s %s\n' "[INFO]" "$*"; }
warn() { printf '%s %s\n' "[WARN]" "$*"; }

readonly DEVOPS_PASSWORD="${devops_password}"
readonly NFS_EXPORT_CIDR="${nfs_export_cidr}"
readonly NFS_EXPORT_PATH="${nfs_export_path}"
readonly FLAG_APT29_LAB01_2="${flag_apt29_lab01_2}"
readonly FLAG_LAZARUS_LAB01_1="${flag_lazarus_lab01_1}"

configure_hostname() {
  local hostname="nyxera-rt-lateral-target-ubuntu-02"
  info "Setting hostname to $${hostname}"
  hostnamectl set-hostname "$${hostname}"
  if ! grep -qE "^[[:space:]]*127\\.0\\.1\\.1[[:space:]]+$${hostname}([[:space:]]|$)" /etc/hosts; then
    echo "127.0.1.1 $${hostname}" >>/etc/hosts
  fi
}

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
  info "Installing SSH, NFS server, and audit tooling"
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    auditd \
    nfs-kernel-server \
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

configure_nfs() {
  info "Configuring NFSv4 export at $${NFS_EXPORT_PATH} to $${NFS_EXPORT_CIDR}"
  mkdir -p "$${NFS_EXPORT_PATH}/finance" "$${NFS_EXPORT_PATH}/it" "$${NFS_EXPORT_PATH}/backups"

  cat <<'EOF' >"$${NFS_EXPORT_PATH}/backups/README.txt"
LumenWorks - Operations Share

This share simulates a typical internal file share used by IT/Finance.
EOF

  chown -R devops:devops "$${NFS_EXPORT_PATH}" || true
  chmod -R 0755 "$${NFS_EXPORT_PATH}" || true

  cat <<EOF >/etc/exports
$${NFS_EXPORT_PATH} $${NFS_EXPORT_CIDR}(rw,sync,no_subtree_check,fsid=0,no_root_squash)
EOF

  exportfs -ra
  systemctl enable --now nfs-server
}

seed_case_data() {
  info "Seeding lab-only case files and rotating flags"
  mkdir -p "$${NFS_EXPORT_PATH}/cases" "$${NFS_EXPORT_PATH}/flags"

  cat <<EOF >"$${NFS_EXPORT_PATH}/cases/README.md"
# LumenWorks - Internal Ops Share (Lab-Only)

This share contains dummy-but-realistic artifacts used by the APT-aligned exercise tracks.

Rules:
* Do not reuse these artifacts outside the lab.
* Flags rotate per lab deployment. Validate flags with the operator-side flag validator script.
EOF

  # Lateral objective flag (meant to be captured after accessing the internal host path).
  cat <<EOF >"$${NFS_EXPORT_PATH}/flags/APT29-LAB01-2.flag"
$${FLAG_APT29_LAB01_2}
EOF

  # Finance-oriented objective flag (Lazarus-aligned narrative).
  cat <<EOF >"$${NFS_EXPORT_PATH}/flags/LAZARUS-LAB01-1.flag"
$${FLAG_LAZARUS_LAB01_1}
EOF

  cat <<'EOF' >"$${NFS_EXPORT_PATH}/finance/Q1-forecast.notes.txt"
LumenWorks Finance (Dummy)

- Target: close-of-quarter numbers review
- Owner: Finance Ops
- Notes: Use this share for internal coordination.
EOF

  chown -R devops:devops "$${NFS_EXPORT_PATH}" || true
  chmod -R 0755 "$${NFS_EXPORT_PATH}" || true
}

main() {
  configure_hostname
  install_packages
  ensure_devops_user
  enable_password_ssh
  configure_auditd
  configure_nfs
  seed_case_data
  info "linux02 bootstrap completed"
}

main
