# Nyxera Red Team Lab Architecture

## Overview

This repository deploys a **hybrid red team infrastructure** designed to simulate realistic adversary operations while maintaining strong operational security and minimal cloud costs.

Unlike traditional infrastructures where the Command & Control (C2) servers run in cloud environments, this lab keeps the **C2 infrastructure local on the operator laptop**, while cloud infrastructure is used exclusively for:

* traffic redirection
* staging infrastructure
* attack surface simulation

The architecture implements **multiple layers of indirection** similar to those used by real-world adversaries.

---

# High Level Architecture

The lab uses a layered infrastructure designed to hide the real command and control servers.

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
Havoc / Sliver C2
```

This layered architecture ensures that the **real C2 server is never directly exposed to the internet**.

---

# Infrastructure Components

## 1. Operator Laptop

The operator laptop hosts the **command and control servers** used during operations.

Installed components:

* Havoc C2
* Sliver C2
* WireGuard client
* offensive tooling

The laptop acts as the **final destination for all command and control communications**.

No services running on the laptop are exposed publicly.

### Sliver ports (important)

Sliver uses a dedicated TLS port for the operator console ("multiplayer") that is **not** the same as the HTTP(S) listener you might front with nginx/Cloudflare.

Typical split:

* `sliver-client` → Sliver server multiplayer (TLS/gRPC): `10.13.13.1:31337`
* Redirected beacon/listener traffic (HTTP[S]) behind a hidden URI: `10.13.13.1:8443` (if you run an HTTP listener there)

If you see:

```
sliver-client
Connecting to 10.13.13.1:8443 ...
Connection to server failed context deadline exceeded
```

it usually means the operator config is pointing at the **wrong port** (8443 is plain HTTP in this lab path). Use the multiplayer port (`31337`) for `sliver-client`.

### Network Configuration

Operator public IP:

```
190.18.171.24/32
```

WireGuard network:

```
10.13.13.0/24
```

Operator tunnel address:

```
10.13.13.1
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

A record configuration:

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

_Important: The Elastic IP backing `lab.nyxera.cloud` must stay constant. Terraform will not replace or detach an existing allocation if you provide its `allocation_id` via `existing_eip_allocation_id`; keep that EIP reserved so Cloudflare’s A record and free-tier billing remain stable._

Using the Cloudflare proxy hides the real origin IP.

---

# Cloudflare Tunnel

Cloudflare Tunnel securely connects the Cloudflare network to the AWS redirector.

The tunnel prevents direct exposure of services.

Example configuration:

```
tunnel: nyxera-redteam
credentials-file: /root/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: lab.nyxera.cloud
    service: http://localhost:80
  - service: http_status:404
```

The tunnel forwards external traffic to nginx running on the redirector.

The `cloudflared` daemon runs as a system service on the redirector.

_Note: the Cloudflare tunnel credentials JSON is intentionally kept out of this repository for OPSEC. Provide your own copy via the `cloudflare_tunnel_credentials_file` Terraform variable and drop it into the local `cloudflared/` directory before running `terraform apply`; the bootstrap script will materialize `/etc/cloudflared/config.yml` and start `cloudflared-lab.service` automatically._

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

Software installed automatically:

* nginx
* wireguard
* cloudflared
* fail2ban

---

# Nginx Redirector Design

The nginx redirector hides the command and control infrastructure behind a specific URI.

Example C2 endpoint:

```
/cdn/api/v3
```

Normal requests return a benign response:

```
Nyxera Cloud
```

Proxy behavior:

```
/cdn/api/v3
        │
        ▼
10.13.13.1:8443
```

This forwards traffic through the WireGuard tunnel to the operator laptop.

---

# Security Controls

Multiple protections restrict access to the redirector.

SSH access restricted to:

```
190.18.171.24/32
```

Additional protections:

* nginx reverse proxy filtering
* fail2ban intrusion prevention
* hidden C2 endpoints
* TLS termination at Cloudflare

Direct scanning should **not reveal the real C2 infrastructure**.

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

All command and control communications flow through this encrypted tunnel.

---

# 5. Vulnerable Lab Infrastructure

A separate EC2 instance hosts intentionally vulnerable applications for testing and training.

These applications run inside Docker containers.

Applications deployed include:

* OWASP Juice Shop
* VAmPI
* OWASP crAPI

Example access:

```
http://target-ip:3000 → Juice Shop
http://target-ip:8888 → crAPI
http://target-ip:5000 → VAmPI
```

These targets allow testing of:

* web application exploitation
* API security flaws
* authentication bypass
* data exposure
* lateral movement scenarios

---

# 6. Payload Delivery Infrastructure

Lab artifact staging is performed using an S3 bucket (Terraform output: `payload_bucket_url`).

Purpose:

* payload hosting
* binary staging
* script distribution

Example payload URL:

```
https://redteam-lab-payloads.s3.amazonaws.com/payload.exe
```

In this repo’s default posture, the bucket is typically **private** (public access blocks enabled). To share a single object for authorized testing without making the bucket public, prefer **pre-signed URLs**:

```
aws s3 cp ./artifact.bin s3://redteam-lab-payloads/artifacts/artifact.bin
aws s3 presign s3://redteam-lab-payloads/artifacts/artifact.bin --expires-in 3600
```

_Note: Terraform defaults to referencing an existing payload bucket (`payload_bucket_name`) instead of creating one. Set `manage_payload_bucket` to `true` if you want Terraform to create `redteam-lab-payloads`; otherwise point `payload_bucket_name` at the bucket you already own (and ignore the JSON credentials for it, as they are not stored here)._

---

# Terraform Responsibilities

Terraform provisions the cloud infrastructure components:

* VPC
* EC2 instances
* security groups
* Elastic IP
* S3 bucket
* bootstrap scripts via `user_data`

Terraform **does not manage local command and control infrastructure**.

SSH key pairs are looked up by name (`key_pair_name`, default `redteam-lab-key`), so Terraform expects you to create or import the key outside of this stack before running `terraform apply`.

---

# Deployment Workflow

Typical deployment steps:

Initialize Terraform:

```
terraform init
```

Validate configuration:

```
terraform validate
```

Review planned infrastructure:

```
terraform plan
```

Deploy infrastructure:

```
terraform apply
```

Retrieve redirector IP:

```
terraform output redirector_ip
```

Configure Cloudflare DNS:

```
lab.nyxera.cloud → redirector IP
```

Start Cloudflare tunnel:

```
systemctl start cloudflared
```

---

# Repository Structure

```
LAB01/
│
├ terraform files
├ userdata/
│   ├ redirector bootstrap
│   └ target lab bootstrap
│
└ scripts/
    operational helpers
```

---

# OPSEC Improvements

The architecture incorporates several operational security measures inspired by real-world adversary infrastructure.

Examples:

* layered redirector architecture
* CDN masking
* encrypted operator tunnels
* hidden C2 endpoints
* benign web responses for scanners

Future improvements may include:

* multi-hop redirectors
* domain fronting style endpoints
* JA3 traffic camouflage
* rotating staging domains

---

# Purpose of the Lab

This lab environment is designed for:

* red team training
* adversary simulation
* offensive security experimentation
* infrastructure research

The architecture enables realistic attack simulations while maintaining **clear separation between operator infrastructure and cloud resources**.
