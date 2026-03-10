#!/bin/bash
set -euo pipefail

export CERTBOT_DOMAINS="${certbot_domains}"
export CERTBOT_EMAIL="${certbot_email}"

cat <<'BOOTSTRAP_SCRIPT' >/tmp/c2_bootstrap.sh
${bootstrap}
BOOTSTRAP_SCRIPT

chmod +x /tmp/c2_bootstrap.sh
/tmp/c2_bootstrap.sh
