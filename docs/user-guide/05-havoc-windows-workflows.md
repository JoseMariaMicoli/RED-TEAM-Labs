# 05 — Havoc Workflows (Windows)

This chapter describes **lab-scoped** workflows for using Havoc in LAB02.

It focuses on exercise structure and validation rather than tool command syntax.

## Recommended Workflow Shape

1) **Preparation**
   * Confirm LAB02 is deployed and the DC is fully bootstrapped before starting workstation exercises.
   * Record hostnames/IPs/roles so your reporting is reproducible.

2) **Access Model**
   * Decide which host represents the initial access point for your scenario.
   * Keep movement paths consistent with the lab design (internal reachability and intended privilege relationships).

3) **Execution (Lab-Only)**
   * Deploy a lab agent on a chosen initial Windows host using an approved method for your environment.
   * Validate check-in, stability, and tasking reliability.

4) **Lateral / Privilege Relationship Validation**
   * Test the intended relationship scenarios (for example, “user A is local admin on workstation B”).
   * Keep notes of which credentials were used and where (for lab reporting).

5) **Evidence Collection**
   * Collect relevant Windows event evidence for authentication and privilege changes.
   * Maintain a timeline with clear start/stop times.

## Safety Boundaries

* Keep all activity scoped to `RED-TEAM-Labs` environments you own and control.
* Avoid broad inbound exposure of Windows management ports; prefer internal-only paths.
* Destroy `LAB02` after completing an exercise set.

## References

For Havoc-specific syntax and best practices, consult the official Havoc documentation for your installed version.

