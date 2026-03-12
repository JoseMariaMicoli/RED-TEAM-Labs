# Nyxera Red Team Lab — User Guide

This user guide is a **lab-only, operator-focused** walkthrough for deploying and using Nyxera Red Team Lab.

It is written for **authorized training environments** and assumes you control the AWS account and Cloudflare zone used by the lab.

## Important Note (Tooling)

This repository may reference offensive security tooling (Sliver, Havoc, enumeration utilities, etc.).
To reduce misuse risk, this guide avoids copy/paste-ready C2 or exploitation commands and instead focuses on:

* lab setup and safe operations
* exercise objectives and success criteria
* lab-specific constraints (networking, allowed access paths, reset workflow)
* what to observe/collect (telemetry, artifacts) while you run your own approved workflows

## Table of Contents

1) `01-getting-started.md` — prerequisites, deployment workflow, connectivity checks
2) `02-lab01-linux.md` — LAB01 (Linux) topology, intended exercises, artifacts
3) `03-lab02-windows.md` — LAB02 (Windows/AD) topology, intended exercises, artifacts
4) `04-sliver-linux-workflows.md` — Sliver usage guidance (lab-scoped, non-prescriptive)
5) `05-havoc-windows-workflows.md` — Havoc usage guidance (lab-scoped, non-prescriptive)
6) `06-exercises-catalog.md` — chaptered exercise catalog (objectives + checkpoints)
7) `07-s3-staging.md` — secure staging with short-lived presigned URLs (S3)
8) `08-campaigns/README.md` — APT-aligned campaign playbooks (APT28/APT29/Lazarus)
9) `09-metasploit-track.md` — Metasploit-assisted lab track (non-prescriptive)
10) `10-tooling-matrix.md` — phase-by-phase tooling map (placeholders + validation targets)
