# APT29-Aligned Campaign (Lab-Only)

## Narrative (Dummy)

Target organization: **LumenWorks** (dummy company).

Focus:
* quiet internal movement and controlled collection
* consistent documentation of evidence and constraints

## Objectives

* Establish initial foothold on LAB01 linux01.
* Use linux01 as a pivot point to reach LAB01 linux02 via the internal lab path.
* Perform internal discovery to identify the hidden internal subnet and host reference (`backup.internal`) before pivoting.
* Validate internal share access and capture:
  * `APT29-LAB01-1` (linux01)
  * `APT29-LAB01-2` (internal share / linux02 objective)

Optional Windows extension:
* Establish a foothold on LAB02 IT workstation and capture:
  * `APT29-LAB02-1`
  * `APT29-LAB02-2` (DC objective)

## Success Criteria

* linux02 is accessed via internal path (VPC CIDR), not by widening inbound exposure.
* You produce a clear evidence package (what you did + what the systems recorded).

## Evidence to Collect

Linux:
* `auditd` records for identity/sudoer related changes (if triggered by your run)
* NFS access evidence (files accessed under `/mnt/ops-share` or `/srv/ops-share`)

Windows:
* authentication and privilege evidence relevant to your run

## ATT&CK Mapping (High-Level)

Document techniques appropriate to your run (examples):
* Discovery (network/service/identity)
* Lateral Movement (lab-scoped)
* Collection (dummy artifacts)
