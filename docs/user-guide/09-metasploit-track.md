# 09 — Metasploit-Assisted Track (Lab-Only)

This chapter provides a Metasploit-assisted track that stays **strictly scoped** to this lab.

It is intentionally non-prescriptive:
* Use placeholders for modules and payloads.
* Focus on validation targets and evidence.

## When to Use This Track

Use Metasploit in the lab for:

* service validation and controlled exploitation (where applicable)
* session handling and post-exploitation validation (lab-only)
* demonstrating a clean “handoff” to a C2 workflow (Sliver on Linux, Havoc on Windows)

## Workflow (High-Level)

1) Confirm the lab stack is deployed and reachable as intended.
2) Identify the specific lab service you are targeting (LAB01 web apps or LAB02 services).
3) Use a placeholder module selection:
   * `<MODULE>`
4) Validate the outcome using lab-specific success criteria:
   * flags captured
   * evidence collected
   * constraints respected (no unnecessary inbound exposure)

## Deliverables (Portfolio)

* A short report describing: target surface, selected approach, outcome, and evidence.
* A clear statement of lab scope and authorization.

