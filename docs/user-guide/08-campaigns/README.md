# 08 — APT-Aligned Campaign Playbooks

These campaign playbooks are **APT-aligned** (inspired by publicly reported tradecraft) and constrained to what this lab actually deploys.

They are designed for:

* repeatable, portfolio-grade lab runs
* clear success criteria (flags + evidence)
* MITRE ATT&CK technique mapping (at a high level)

## Campaign Index

* `apt28-aligned.md`
* `apt29-aligned.md`
* `lazarus-aligned.md`

## Flags and Validation

Flags rotate per lab deployment.

To validate a captured flag:

1) Retrieve the lab seed from Terraform (sensitive output).
2) Validate using:
   * `scripts/flagcheck.py`

This avoids hardcoding static flags in documentation while keeping verification deterministic.

