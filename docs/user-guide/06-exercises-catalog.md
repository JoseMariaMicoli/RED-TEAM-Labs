# 06 — Exercises Catalog (Lab-Only)

This catalog provides **chaptered, step-by-step exercise structure** for the lab.

It intentionally avoids copy/paste-ready exploitation and C2 command sequences. Where you need tool-specific syntax, use your approved internal playbooks or the upstream tool documentation.

## Flags (Rotating) and Validation

Flags rotate per lab deployment and are meant to be verified operator-side.

Validation workflow:

1) Retrieve the secret seed for the lab stack:
   * LAB01: `terraform -chdir=RED-TEAM-Labs/LAB01 output -raw lab01_flag_seed`
   * LAB02: `terraform -chdir=RED-TEAM-Labs/LAB02 output -raw lab02_flag_seed`
2) Validate a captured flag:
   * `python3 scripts/flagcheck.py --seed "<SEED>" --id "<FLAG_ID>" --flag "<CAPTURED_FLAG>"`

Tip:
* Use the campaign playbooks (`08-campaigns/`) to understand which flags are expected for a scenario.

## Linux Exercises (LAB01)

### L1 — Validate Initial Access and Operator Hygiene

Objective:
* Establish a repeatable “start condition” and confirm you can operate within the lab boundaries.

Steps:
1) Deploy `CORE` and `LAB01`.
2) Confirm operator SSH access to linux01 using the restricted `ssh_cidr_blocks` model.
3) Record baseline details: instance IDs, public IPs, private IPs, and boot timestamps.
4) Confirm the vulnerable services on linux01 behave as expected.
5) Define your reporting template for the rest of the exercises (timeline, commands used, artifacts collected).

Success criteria:
* You can access linux01 from the operator IP range.
* You can explain exactly what is exposed externally and why.

Flag:
* `APT29-LAB01-1` (linux01)

### L2 — Internal Lateral Path (linux01 → linux02)

Objective:
* Reach the lateral target via the intended internal route, not by widening inbound exposure.

Steps:
1) From linux01, validate internal network reachability to linux02 on TCP/22.
2) Use an approved internal movement method (lab-only) to access linux02 from linux01.
3) Verify linux02 remains restricted from arbitrary external sources (only `ssh_cidr_blocks` + VPC CIDR).
4) Access the NFS share and identify the “operations share” structure.

Success criteria:
* linux02 access is demonstrated via the internal lab path.
* You can document the exact network path taken.

Flag:
* `APT29-LAB01-2` (internal share / linux02 objective)

### L3 — Telemetry Collection (auditd + Share Access)

Objective:
* Practice collecting simple host telemetry and correlating it with your actions.

Steps:
1) Trigger a small, controlled set of identity/privilege-related actions in LAB01 (lab-only).
2) Collect `auditd` records and confirm they reflect the actions taken.
3) Access files on the NFS share and record evidence of access.
4) Produce a short timeline correlating actions to evidence.

Success criteria:
* You can show a consistent mapping between “what you did” and “what the host observed”.

## Windows / AD Exercises (LAB02)

### W1 — Domain Discovery and Baseline Mapping

Objective:
* Build a reproducible map of the LAB02 domain and hosts.

Steps:
1) Deploy `CORE` and `LAB02`.
2) Wait for the DC bootstrap to complete and validate DNS/domain availability.
3) Inventory hosts (DC, workstations), IPs, and roles.
4) Identify intended privilege relationships (as configured by automation).

Success criteria:
* You can describe the environment, roles, and relationships without ambiguity.

Flag (optional extension):
* `APT29-LAB02-1` (IT workstation)

### W2 — Privilege Relationship Validation (Local Admin Paths)

Objective:
* Confirm the “who is admin where” scenarios configured by the lab.

Steps:
1) Select a starting Windows host for your scenario.
2) Use approved methods to authenticate as the intended lab user and validate local admin rights on the target host.
3) Document authentication paths, session boundaries, and observed results.
4) Collect event evidence for the actions you took.

Success criteria:
* You can demonstrate and document the intended relationship path end-to-end.

Flag (optional extension):
* `LAZARUS-LAB02-1` (finance workstation)

## Reporting Template (Recommended)

For each exercise, capture:

* start/stop time (UTC recommended)
* initial access point
* movement path(s) and constraints respected
* credentials used (lab-only) and where they were used
* artifacts collected (logs, screenshots, outputs)
* teardown confirmation (`terraform destroy` for the lab stack)
