# 02 — LAB01 (Linux)

## What LAB01 Provides

LAB01 is designed to support end-to-end Linux exercises:

* **linux01**: an “initial foothold” host running intentionally vulnerable applications (lab-only)
* **linux02**: an internal “lateral target” host to practice pivoting and internal access

## Intended Weaknesses (Lab-Only)

LAB01 intentionally includes weak patterns for training:

* A shared local user (`devops`) exists on both hosts to simulate credential reuse.
* SSH password authentication is enabled for the shared user (lab-only).
* A simple internal file share is provided via NFSv4:
  * linux02 exports `/srv/ops-share`
  * linux01 mounts it at `/mnt/ops-share` (best effort)
* Minimal host telemetry via `auditd` is enabled.

Refer to `docs/ARCHITECTURE.md` for the full rationale and implementation notes.

## Exercise Themes (Linux)

Use LAB01 for exercises such as:

* recon and service enumeration (external and internal)
* privilege escalation (host-local, lab-scoped)
* lateral movement (linux01 → linux02) using an internal path
* internal file share discovery and access (NFS)
* basic operational hygiene (credential rotation, least privilege, teardown discipline)

## What to Collect (Artifacts)

During exercises, capture:

* timestamps and access paths used (operator → linux01, linux01 → linux02)
* process execution traces you intentionally triggered
* `auditd` records relevant to identity/sudoer changes
* NFS access evidence (mounted share usage and file access)

## Flags (Rotating)

LAB01 seeds rotating flags on deploy:

* linux01: `/opt/nyxera/flags/*.flag`
* linux02 / ops share: `/srv/ops-share/flags/*.flag`

Validate flags operator-side using `scripts/flagcheck.py` with the LAB01 seed from Terraform.

## Constraints (By Design)

* linux02 SSH should only be reachable:
  * from `ssh_cidr_blocks` (operator IP range), and
  * from the VPC CIDR (internal lab movement from linux01)

This helps keep the lateral target aligned with the “internal-only” objective.
