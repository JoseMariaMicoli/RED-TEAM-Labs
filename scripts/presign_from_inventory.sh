#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
presign_from_inventory.sh

Generates short-lived presigned URLs for objects listed in docs/s3_inventory.txt.

Usage:
  scripts/presign_from_inventory.sh --bucket <bucket> [--expires <seconds>] [--inventory <path>] [--out <path>]

Defaults:
  --expires   900  (15 minutes)
  --inventory docs/s3_inventory.txt
  --out       docs/presigned_urls.txt

Notes:
  - Requires AWS CLI configured with permission to GetObject for the bucket.
  - Skips "directory placeholder" keys (ending with /) and 0-byte entries.
EOF
}

bucket=""
expires="900"
inventory="docs/s3_inventory.txt"
out="docs/presigned_urls.txt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bucket)
      bucket="${2:-}"; shift 2;;
    --expires)
      expires="${2:-}"; shift 2;;
    --inventory)
      inventory="${2:-}"; shift 2;;
    --out)
      out="${2:-}"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2;;
  esac
done

if [[ -z "$bucket" ]]; then
  echo "--bucket is required" >&2
  usage
  exit 2
fi

if [[ ! -f "$inventory" ]]; then
  echo "Inventory not found: $inventory" >&2
  exit 2
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "# Bucket: $bucket"
  echo "# Expires: ${expires}s"
  echo "# Format: <s3_key><TAB><presigned_url>"
  echo
} >"$tmp"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  # Expected inventory format (aws s3 ls --recursive output style):
  # YYYY-MM-DD HH:MM:SS  <size>  <key>
  key="$(awk '{print $NF}' <<<"$line")"

  # Skip if we failed to parse.
  [[ -z "$key" ]] && continue

  # Skip directory placeholders and 0-byte keys (common in inventories).
  [[ "$key" == */ ]] && continue
  size_hint="$(awk '{print $3" "$4}' <<<"$line")"
  [[ "$size_hint" == "0 Bytes" ]] && continue

  url="$(aws s3 presign "s3://${bucket}/${key}" --expires-in "$expires")"
  printf '%s\t%s\n' "$key" "$url" >>"$tmp"
done <"$inventory"

mv "$tmp" "$out"
echo "Wrote: $out"
