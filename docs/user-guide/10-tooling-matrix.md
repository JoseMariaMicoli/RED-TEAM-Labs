# 10 — Tooling Matrix (By Phase)

This chapter provides a phase-by-phase tooling map for the lab.

It is designed to help you document “what tool category you used” without turning this repository into a copy/paste offensive runbook.

## Recon / Discovery

Examples (use what is appropriate for your run):

* Web discovery: `<WEB_SCANNER>`, `<DIR_ENUM_TOOL>`
* Network discovery: `<PORT_SCANNER>`
* Cloud/infrastructure: Terraform outputs, AWS CLI

Validation targets:
* inventory of exposed services (LAB01 linux01)
* internal reachability (linux01 ↔ linux02, DC/workstations inside VPC)

## Initial Access (Lab-Only)

Examples:
* Sliver (Linux track) — agent deployment via your approved lab workflow
* Havoc (Windows track) — agent deployment via your approved lab workflow
* Metasploit-assisted — controlled lab-only usage

Validation targets:
* stable session / check-in
* clear timeline and scoping notes

## Privilege & Credential Work (Lab-Only)

Examples:
* Linux local enumeration: `linpeas.sh`, `linenum.sh`, `pspy64` (see S3 inventory)
* Windows local enumeration: `winpeas.exe`, `Seatbelt`, `SharpUp` (see S3 inventory)

Validation targets:
* “before/after” privilege snapshot (documented)
* artifacts collected and evidence references

## Lateral Movement / Pivoting (Lab-Only)

Examples:
* Pivot helpers staged in S3: `chisel`, `ligolo-agent`, `socat`

Validation targets:
* linux01 → linux02 access via internal VPC path
* DC/workstation internal movement (if your scenario includes it)

## Collection & Exfil Simulation

Examples:
* Dummy artifacts on NFS share (`/mnt/ops-share`) and Windows case directories
* Exfil simulation using staged transfer paths and time-bound URLs

Validation targets:
* flags captured
* evidence package (what you accessed + why + constraints respected)

