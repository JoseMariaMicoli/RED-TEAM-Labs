# 03 — LAB02 (Windows / AD)

## What LAB02 Provides

LAB02 simulates a small Windows environment suitable for AD-focused exercises:

* Domain Controller (AD DS + DNS)
* Windows workstations/servers intended for workstation-to-workstation movement and privilege relationship testing

Refer to `docs/ARCHITECTURE.md` for naming, domain details, and bootstrap behavior.

## Exercise Themes (Windows / AD)

Use LAB02 for exercises such as:

* domain discovery and directory enumeration
* credential hygiene validation (lab users, service accounts as configured)
* privilege relationship analysis (who is local admin where)
* internal movement between Windows hosts (lab-scoped)
* reporting: timelines, impacted assets, and reproducibility notes

## What to Collect (Artifacts)

During exercises, capture:

* hostnames, IPs, and roles (DC vs workstations)
* authentication events and session boundaries you intentionally created
* privilege changes you intentionally performed (group membership, local admin)
* operator notes: what worked, what failed, and why

## Flags (Rotating)

LAB02 seeds rotating flags on deploy:

* `C:\ProgramData\Nyxera\LAB02\Flags\*.flag`

Validate flags operator-side using `scripts/flagcheck.py` with the LAB02 seed from Terraform.
