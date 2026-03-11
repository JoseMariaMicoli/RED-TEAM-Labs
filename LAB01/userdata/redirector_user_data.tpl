#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/redirector-setup.log"
exec > >(tee -a "$${LOGFILE}" /var/log/cloud-init-output.log) 2>&1
export HOME=/root

info() { printf '%s %s\n' "[INFO]" "$*"; }
warn() { printf '%s %s\n' "[WARN]" "$*"; }

readonly WG_PRIVATE_KEY="${wireguard_private_key}"
readonly WG_PEER_PUBLIC_KEY="${wireguard_peer_public_key}"
readonly WG_PEER_ENDPOINT="${wireguard_peer_endpoint}"
readonly WG_ALLOWED_IPS="${wireguard_peer_allowed_ips}"
readonly WG_LISTEN_PORT="${wireguard_listen_port}"
readonly WG_INTERFACE_ADDR="10.13.13.2/24"
readonly CLOUDFLARE_TUNNEL_CREDENTIALS_B64="${cloudflare_tunnel_credentials_b64}"
readonly CLOUDFLARE_TUNNEL_NAME="${cloudflare_tunnel_name}"

wait_for_apt() {
  local attempts=0
  while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$${attempts}" -gt 60 ]; then
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

  local packages=(
    ca-certificates
    curl
    nginx
    openssl
    wireguard
    fail2ban
    wget
  )

  wait_for_apt
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$${packages[@]}"
}

install_cloudflared() {
  local target="/tmp/cloudflared.deb"
  local url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"

  info "Installing cloudflared from $${url}"
  if ! curl -fsSL "$${url}" -o "$${target}"; then
    warn "Unable to download cloudflared"
    return
  fi

  if ! dpkg -i "$${target}"; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y -f
    dpkg -i "$${target}"
  fi

  rm -f "$${target}"
}

configure_nginx() {
  info "Configuring nginx as stealth redirector for ${lab_domain}"
  rm -f /etc/nginx/sites-enabled/default

  # Cloudflare (Full) expects the origin to answer on 443. Use a local self-signed
  # cert by default so the lab works without any manual cert provisioning.
  mkdir -p /etc/nginx/tls
  if [ ! -f /etc/nginx/tls/lab.key ] || [ ! -f /etc/nginx/tls/lab.crt ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
      -subj "/CN=${lab_domain}" \
      -keyout /etc/nginx/tls/lab.key \
      -out /etc/nginx/tls/lab.crt >/dev/null 2>&1 || true
    chmod 600 /etc/nginx/tls/lab.key || true
  fi

  cat <<'EOF' >/etc/nginx/conf.d/redirector.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${lab_domain};

    location = / {
        default_type text/plain;
        return 200 'Nyxera Cloud';
    }

    location ^~ /cdn/api/v3 {
        proxy_pass http://${proxy_upstream};
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_connect_timeout 2s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
        proxy_intercept_errors on;
        error_page 502 503 504 =404 /notfound;
    }

    location / {
        return 404 'Not Found';
    }
}

server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    server_name ${lab_domain};

    ssl_certificate     /etc/nginx/tls/lab.crt;
    ssl_certificate_key /etc/nginx/tls/lab.key;

    location = / {
        default_type text/plain;
        return 200 'Nyxera Cloud';
    }

    location ^~ /cdn/api/v3 {
        proxy_pass http://${proxy_upstream};
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_connect_timeout 2s;
        proxy_send_timeout 5s;
        proxy_read_timeout 5s;
        proxy_intercept_errors on;
        error_page 502 503 504 =404 /notfound;
    }

    location / {
        return 404 'Not Found';
    }
}
EOF

  nginx -t
  systemctl enable nginx
  # nginx may have been auto-started by the package before this config exists.
  # Restart ensures it reloads the new listeners (including 443).
  systemctl restart nginx
}

configure_fail2ban() {
  info "Configuring fail2ban for nginx"
  cat <<'EOF' >/etc/fail2ban/jail.d/redirector.local
[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/*error*.log
maxretry = 3
EOF

  systemctl enable --now fail2ban
}

enable_ip_forwarding() {
  cat <<EOF >/etc/sysctl.d/99-wireguard.conf
net.ipv4.ip_forward=1
EOF
  if ! sysctl --system >/dev/null 2>&1; then
    warn "sysctl --system failed"
  fi
}

configure_wireguard() {
  if [ -z "$${WG_PRIVATE_KEY}" ] || [ -z "$${WG_PEER_PUBLIC_KEY}" ] || [ -z "$${WG_PEER_ENDPOINT}" ]; then
    warn "WireGuard key material or endpoint missing; skipping tunnel configuration"
    return
  fi

  info "Writing WireGuard configuration"
  cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
Address = $WG_INTERFACE_ADDR
ListenPort = $WG_LISTEN_PORT
PrivateKey = $WG_PRIVATE_KEY

[Peer]
PublicKey = $WG_PEER_PUBLIC_KEY
Endpoint = $WG_PEER_ENDPOINT
AllowedIPs = $WG_ALLOWED_IPS
PersistentKeepalive = 25
EOF

  chmod 600 /etc/wireguard/wg0.conf
  systemctl enable --now wg-quick@wg0
}

configure_cloudflared() {
  if [ -z "$${CLOUDFLARE_TUNNEL_CREDENTIALS_B64}" ]; then
    warn "Cloudflare tunnel credentials missing; skipping CA-managed tunnel"
    return
  fi

  local cloudflared_bin
  cloudflared_bin="$(command -v cloudflared 2>/dev/null || true)"
  if [ -z "$${cloudflared_bin}" ]; then
    warn "cloudflared binary not found; cannot start tunnel"
    return
  fi

  info "Writing Cloudflare tunnel configuration"
  mkdir -p /etc/cloudflared
  printf '%s' "$${CLOUDFLARE_TUNNEL_CREDENTIALS_B64}" | base64 -d >/etc/cloudflared/credentials.json
  chmod 600 /etc/cloudflared/credentials.json

  cat <<EOF >/etc/cloudflared/config.yml
tunnel: $CLOUDFLARE_TUNNEL_NAME
credentials-file: /etc/cloudflared/credentials.json

ingress:
  - hostname: ${lab_domain}
    service: http://localhost:80
  - service: http_status:404
EOF

  cat <<EOF >/etc/systemd/system/cloudflared-lab.service
[Unit]
Description=Cloudflare Tunnel for ${lab_domain}
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$cloudflared_bin tunnel --config /etc/cloudflared/config.yml run
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now cloudflared-lab || warn "cloudflared-lab service failed to start"
}

main() {
  install_packages
  install_cloudflared
  configure_nginx
  configure_fail2ban
  enable_ip_forwarding
  configure_cloudflared
  configure_wireguard
  info "Redirector bootstrap completed"
}

main
