#!/usr/bin/env bash
set -euo pipefail

# Migrates an existing single-stack LAB01 local state into a split-stack layout:
# - CORE (persistent): VPC/subnet/routes + redirector + EIP association + S3 bucket
# - LAB01 (ephemeral): Linux targets only
#
# This script is designed to be safe to re-run. It will only move resources that
# still exist in the LAB01 state and are not yet present in the CORE state.
#
# Assumptions:
# - Local backend state files (terraform.tfstate) are used.
# - You run this script from the RED-TEAM-Labs repo root (the folder that contains CORE/ and LAB01/).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="${CORE_DIR:-"${ROOT_DIR}/CORE"}"
LAB01_DIR="${LAB01_DIR:-"${ROOT_DIR}/LAB01"}"

if [[ ! -d "${CORE_DIR}" || ! -d "${LAB01_DIR}" ]]; then
  echo "ERROR: Expected CORE/ and LAB01/ directories under ${ROOT_DIR}"
  exit 1
fi

cd "${ROOT_DIR}"

echo "[INFO] Initializing Terraform in CORE and LAB01"
terraform -chdir="${CORE_DIR}" init -input=false >/dev/null
terraform -chdir="${LAB01_DIR}" init -input=false >/dev/null

LAB01_STATE="${LAB01_DIR}/terraform.tfstate"
CORE_STATE="${CORE_DIR}/terraform.tfstate"

if [[ ! -f "${LAB01_STATE}" ]]; then
  echo "ERROR: LAB01 state not found at ${LAB01_STATE}"
  echo "       If LAB01 was never applied on this machine, copy the state here first."
  exit 1
fi

timestamp="$(date +%Y%m%d%H%M%S)"
cp "${LAB01_STATE}" "${LAB01_DIR}/terraform.tfstate.backup.pre_core_migration.${timestamp}"
echo "[INFO] Backed up LAB01 state to terraform.tfstate.backup.pre_core_migration.${timestamp}"

lab01_has() {
  terraform -chdir="${LAB01_DIR}" state list 2>/dev/null | grep -Fxq "$1"
}

core_has() {
  if [[ ! -f "${CORE_STATE}" ]]; then
    return 1
  fi
  terraform -chdir="${CORE_DIR}" state list 2>/dev/null | grep -Fxq "$1"
}

move_if_present() {
  local addr="$1"
  if lab01_has "${addr}" && ! core_has "${addr}"; then
    echo "[INFO] Moving ${addr} -> CORE state"
    terraform -chdir="${LAB01_DIR}" state mv -state-out="../CORE/terraform.tfstate" "${addr}" "${addr}" >/dev/null
  else
    echo "[INFO] Skipping ${addr} (already moved or not present)"
  fi
}

echo "[INFO] Moving shared networking + redirector resources to CORE state"
move_if_present "aws_vpc.redteam_vpc"
move_if_present "aws_subnet.lab_subnet"
move_if_present "aws_internet_gateway.gw"
move_if_present "aws_route_table.lab_rt"
move_if_present "aws_route.internet_access"
move_if_present "aws_route_table_association.rt_assoc"
move_if_present "aws_security_group.redirector"
move_if_present "aws_instance.redirector"

# EIP association (existing allocation ID case)
move_if_present "aws_eip_association.existing_redirector[0]"

# EIP resource + association (if LAB01 previously created the EIP itself)
move_if_present "aws_eip.redirector_eip[0]"
move_if_present "aws_eip_association.new_redirector[0]"

BUCKET_NAME_DEFAULT="redteam-lab-payloads"
BUCKET_NAME="${BUCKET_NAME:-${BUCKET_NAME_DEFAULT}}"

if ! core_has "aws_s3_bucket.payloads"; then
  echo "[INFO] Importing S3 bucket into CORE state: ${BUCKET_NAME}"
  terraform -chdir="${CORE_DIR}" import "aws_s3_bucket.payloads" "${BUCKET_NAME}" >/dev/null
else
  echo "[INFO] Skipping S3 import (already in CORE state)"
fi

echo "[INFO] Done. Recommended next steps:"
echo "  1) terraform -chdir=CORE plan"
echo "  2) terraform -chdir=LAB01 plan"
echo "  3) terraform -chdir=CORE apply   (should be no-op)"
echo "  4) terraform -chdir=LAB01 apply  (should be no-op)"

