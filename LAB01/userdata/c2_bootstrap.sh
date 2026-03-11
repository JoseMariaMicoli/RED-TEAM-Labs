#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/c2-setup.log"
exec > >(tee -a "${LOGFILE}" /var/log/cloud-init-output.log) 2>&1
export HOME=/root

readonly GO_VERSION="1.25.0"
readonly SWAP_FILE="/swapfile"
readonly TMP_DIR="/tmp/c2-install"
readonly NGINX_CONF="/etc/nginx/nginx.conf"
readonly STREAM_DIR="/etc/nginx/stream.d"
readonly STREAM_CONF="${STREAM_DIR}/c2-stream.conf"
readonly MSFRPCD_PASSWORD="${MSFRPCD_PASSWORD:-RedTeam123}"
readonly SLIVER_VERSION="v1.7.3"
readonly SLIVER_ASSET="sliver-server_linux-amd64"

readonly CERTBOT_DOMAINS="${CERTBOT_DOMAINS:-}"
readonly CERTBOT_EMAIL="${CERTBOT_EMAIL:-security@example.com}"

info() { printf '%s %s\n' "[INFO]" "$*"; }
warn() { printf '%s %s\n' "[WARN]" "$*"; }
error() {
  printf '%s %s\n' "[ERROR]" "$*" >&2
  exit 1
}

wait_for_apt() {
  local attempts=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "${attempts}" -gt 60 ]; then
      error "apt lock still held after $((attempts * 5)) seconds"
    fi
    info "Waiting for apt lock release..."
    sleep 5
  done
}

ensure_swap() {
  if swapon --show | grep -q "${SWAP_FILE}"; then
    info "Swap ${SWAP_FILE} already active"
    return
  fi

  if [ ! -f "${SWAP_FILE}" ]; then
    info "Creating 4 GB swap at ${SWAP_FILE}"
    fallocate -l 4G "${SWAP_FILE}"
    chmod 600 "${SWAP_FILE}"
    mkswap "${SWAP_FILE}"
    echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
  fi

  swapon "${SWAP_FILE}"
  info "Swap enabled"
}

prepare_packages() {
  wait_for_apt
  info "Updating apt sources"
  DEBIAN_FRONTEND=noninteractive apt-get update -y

  local packages=(
    ca-certificates
    curl
    wget
    git
    gnupg
    lsb-release
    build-essential
    gcc
    make
    unzip
    jq
    rsync
    psmisc
    software-properties-common
    python3
    python3-pip
    nginx
    certbot
    python3-certbot-nginx
  )

  wait_for_apt
  DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
}

install_go() {
  if [ -x "/usr/local/go/bin/go" ]; then
    info "Go already installed"
    return
  fi

  local go_archive="go${GO_VERSION}.linux-amd64.tar.gz"
  info "Installing Go ${GO_VERSION}"
  mkdir -p "${TMP_DIR}"
  wget -q "https://go.dev/dl/${go_archive}" -O "${TMP_DIR}/${go_archive}"
  rm -rf /usr/local/go
  tar -C /usr/local -xzf "${TMP_DIR}/${go_archive}"
  ln -sf /usr/local/go/bin/go /usr/local/bin/go
  ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
  printf 'export PATH=$PATH:/usr/local/go/bin\n' >/etc/profile.d/go.sh
  chmod 644 /etc/profile.d/go.sh
  export PATH=$PATH:/usr/local/go/bin
  info "Go ${GO_VERSION} installed"
}

install_sliver() {
  if command -v sliver >/dev/null 2>&1; then
    info "Sliver already installed"
    return
  fi

  info "Deploying Sliver server binary"
  local sliver_url="https://github.com/BishopFox/sliver/releases/download/${SLIVER_VERSION}/${SLIVER_ASSET}"
  if ! wget -q -O /usr/local/bin/sliver-server "${sliver_url}"; then
    error "Failed to download Sliver binary from ${sliver_url}"
  fi
  chmod +x /usr/local/bin/sliver-server
  ln -sf /usr/local/bin/sliver-server /usr/local/bin/sliver
}

install_metasploit() {
  if command -v msfconsole >/dev/null 2>&1; then
    info "Metasploit already present"
    return
  fi

  info "Installing Metasploit Framework"
  curl -sSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o /tmp/msfinstall
  chmod +x /tmp/msfinstall
  /tmp/msfinstall || warn "Metasploit installer returned non-zero; proceeding anyway"
}

install_havoc() {
  if [ -x "/opt/havoc/havoc" ]; then
    info "Havoc already built"
    return
  fi

  info "Building Havoc teamserver"
  rm -rf /opt/havoc
  git clone --depth 1 https://github.com/HavocFramework/Havoc.git /opt/havoc
  cd /opt/havoc
  local havoc_gopath="/opt/havoc/.go"
  export GOPATH="${havoc_gopath}"
  export GOMODCACHE="${GOPATH}/pkg/mod"
  mkdir -p "${GOMODCACHE}"
  export GOCACHE="${GOPATH}/.cache"
  mkdir -p "${GOCACHE}"
  GOMAXPROCS=1 GOGC=50 make ts-build

  update_havoc_profile
  write_havoc_helper
}

ensure_stream_include() {
  local include_line="include /etc/nginx/stream.d/*.conf;"
  if grep -qF "${include_line}" "${NGINX_CONF}"; then
    return
  fi

  python3 <<PY
from pathlib import Path

path = Path("${NGINX_CONF}")
text = path.read_text()
line = "${include_line}"
if line in text:
    raise SystemExit
marker = "http {"
if marker not in text:
    raise SystemExit("missing http block")
idx = text.index(marker)
text = text[:idx] + line + "\n\n" + text[idx:]
path.write_text(text)
PY
}

write_stream_proxy() {
  mkdir -p "${STREAM_DIR}"
  cat <<'EOF' > "${STREAM_CONF}"
stream {
    upstream sliver_stream {
        server 127.0.0.1:31337;
    }

    upstream havoc_stream {
        server 127.0.0.1:4444;
    }

    upstream metasploit_stream {
        server 127.0.0.1:55553;
    }

    server {
        listen 443;
        proxy_pass sliver_stream;
        proxy_timeout 300s;
        proxy_connect_timeout 10s;
    }

    server {
        listen 8443;
        proxy_pass havoc_stream;
        proxy_timeout 300s;
        proxy_connect_timeout 10s;
    }

    server {
        listen 5555;
        proxy_pass metasploit_stream;
        proxy_timeout 300s;
        proxy_connect_timeout 10s;
    }
}
EOF
}

configure_nginx() {
  info "Configuring nginx stream proxy"
  rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
  write_stream_proxy
  ensure_stream_include
  nginx -t
  systemctl enable --now nginx
}

update_havoc_profile() {
  local profile="/opt/havoc/profiles/havoc.yaotl"
  if [ -f "${profile}" ]; then
    perl -0pi -e 's/Port = \d+/Port = 4444/' "${profile}"
  fi
}

write_havoc_helper() {
  cat <<'EOF' > /usr/local/bin/havoc-ts
#!/bin/bash
cd /opt/havoc
./havoc server --profile profiles/havoc.yaotl --debug
EOF
  chmod +x /usr/local/bin/havoc-ts
}

configure_sliver_service() {
  info "Configuring systemd service for Sliver"
  cat <<EOF >/etc/systemd/system/sliver-server.service
[Unit]
Description=Sliver C2 teamserver
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/sliver-server daemon -p 31337
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

configure_metasploit_service() {
  info "Configuring systemd service for Metasploit RPC"
  cat <<EOF >/etc/systemd/system/metasploit.service
[Unit]
Description=Metasploit RPC daemon
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/msfrpcd -f -P ${MSFRPCD_PASSWORD} -a 127.0.0.1 -p 55553 -U msf --ssl
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

configure_havoc_service() {
  info "Configuring systemd service for Havoc"
  cat <<EOF >/etc/systemd/system/havoc-ts.service
[Unit]
Description=Havoc teamserver
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/havoc
ExecStart=/usr/local/bin/havoc-ts
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

configure_services() {
  configure_sliver_service
  configure_metasploit_service
  configure_havoc_service
  systemctl daemon-reload
  systemctl enable --now sliver-server metasploit havoc-ts
}

install_certbot_cert() {
  if [ -z "${CERTBOT_DOMAINS}" ]; then
    warn "CERTBOT_DOMAINS not set; skipping automated certificate request"
    return
  fi

  info "Requesting certificates for ${CERTBOT_DOMAINS}"
  wait_for_apt
  if ! certbot --nginx --non-interactive --agree-tos --email "${CERTBOT_EMAIL}" -d "${CERTBOT_DOMAINS}"; then
    warn "certbot could not issue certificates; re-run manually once DNS is in place"
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    info "Docker already installed"
    return
  fi

  info "Installing Docker and Compose plugin"
  DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose-plugin
  systemctl enable --now docker
  usermod -aG docker ubuntu || true
}

cleanup() {
  rm -rf "${TMP_DIR}"
}

main() {
  info "Starting C2 bootstrap"
  ensure_swap
  prepare_packages
  install_go
  install_sliver
  install_metasploit
  install_havoc
  configure_nginx
  configure_services
  install_certbot_cert
  install_docker
  cleanup
  info "C2 bootstrap completed"
}

main
