# 04 — Sliver Workflows (Linux)

This chapter describes **lab-scoped** workflows for using Sliver against LAB01 Linux systems.

It focuses on *what to do* and *what to validate* in the lab, not on command syntax.

## Recommended Workflow Shape

1) **Preparation**
   * Confirm LAB01 is deployed and you have operator SSH access to linux01.
   * Confirm linux01 ↔ linux02 internal reachability on TCP/22.

2) **Listener and Agent Strategy**
   * Decide whether you are simulating “internet-origin” traffic via the redirector path or an internal-only path.
   * Ensure you understand Sliver’s operator (“multiplayer”) port vs beacon listener port (see `docs/ARCHITECTURE.md`).

3) **Execution (Lab-Only)**
   * Deploy a lab agent on linux01 using an approved method for your environment.
   * Validate check-in, stability, and basic tasking reliability.

4) **Pivot Simulation**
   * Use linux01 as the pivot point to reach linux02 over the internal network.
   * Validate that access to linux02 occurs via the internal lab path (not by opening broad inbound access).

5) **Evidence Collection**
   * Collect the artifacts you care about (process creation evidence, `auditd` entries, NFS access evidence).
   * Maintain a timeline with clear start/stop times.

## Safety Boundaries

* Keep all activity scoped to `RED-TEAM-Labs` environments you own and control.
* Do not reuse lab payloads, keys, or credentials outside the lab.
* Prefer ephemeral deployments: destroy `LAB01` after completing an exercise set.

## References

For Sliver-specific syntax and best practices, consult the official Sliver documentation for your installed version.

