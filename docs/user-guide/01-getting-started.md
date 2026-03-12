# 01 — Getting Started

## Prerequisites

Operator machine:

* Terraform installed
* AWS credentials configured (able to create EC2/VPC/S3 resources)
* WireGuard installed (for redirector ↔ operator tunnel)
* Access to a Cloudflare zone for the lab domain (optional, but recommended for the full redirector flow)

AWS:

* An EC2 key pair available in the target region (see `key_pair_name`)
* A region that supports the instance types used (defaults are in each stack’s variables)

## Repository Layout

This repository is split into Terraform stacks with separate state:

* `CORE/` (persistent): VPC/subnet/routes, redirector + Elastic IP association, payload S3 bucket
* `LAB01/` (ephemeral): Linux targets (linux01 initial foothold + linux02 lateral target)
* `LAB02/` (ephemeral): Windows environment (DC/DNS + workstations)

## Management Access Model (SSH)

LAB01 uses a security group that allows SSH (TCP/22):

* From the operator IP range configured by `ssh_cidr_blocks` (example: `190.18.171.24/32`)
* From inside the VPC CIDR (to allow linux01 → linux02 lateral movement inside the lab)

If your operator IP changes, update `ssh_cidr_blocks` in the relevant `terraform.tfvars` and re-apply.

## Deploy: CORE (Persistent)

1) Change into the stack directory:
   * `cd RED-TEAM-Labs/CORE`
2) Initialize Terraform:
   * `terraform init`
3) Review planned changes:
   * `terraform plan`
4) Apply:
   * `terraform apply`
5) Record the outputs you need (example):
   * `terraform output redirector_public_ip`

## Deploy: LAB01 (Linux)

1) Change into the stack directory:
   * `cd RED-TEAM-Labs/LAB01`
2) Review `terraform.tfvars`:
   * Confirm `key_pair_name` exists in AWS
   * Confirm `ssh_cidr_blocks` matches your operator IP range
3) Initialize/apply:
   * `terraform init`
   * `terraform apply`
4) Record the outputs:
   * `terraform output target_ubuntu_01_public_ip`
   * `terraform output lateral_target_ubuntu_02_public_ip`

## Deploy: LAB02 (Windows)

1) Change into the stack directory:
   * `cd RED-TEAM-Labs/LAB02`
2) Initialize/apply:
   * `terraform init`
   * `terraform apply`
3) Record the outputs you’ll use for access and validation.

## Cloudflare (Optional, Full Redirector Path)

If you use the external redirector path, follow `docs/ARCHITECTURE.md` for:

* DNS record pointing your lab hostname to the redirector Elastic IP
* Cloudflare Tunnel configuration on the redirector

## Connectivity Checks (Recommended)

Before running any exercises:

* Confirm you can SSH to LAB01 linux01 from your operator host.
* Confirm linux01 can reach linux02 on TCP/22 over the VPC network (this validates the intended lateral path).
* Confirm the vulnerable services on linux01 are reachable only as intended (depending on your security group settings).
* Confirm you can generate presigned URLs for staged tools (see `07-s3-staging.md`).
* Confirm you can validate rotating flags with `scripts/flagcheck.py` (see `06-exercises-catalog.md`).

## Tear Down / Reset

To reset labs while keeping shared infrastructure:

* Destroy LAB01:
  * `cd RED-TEAM-Labs/LAB01 && terraform destroy`
* Destroy LAB02:
  * `cd RED-TEAM-Labs/LAB02 && terraform destroy`

Keep `CORE` persistent unless you intentionally want to remove the redirector and bucket.
