# Nyxera Red Team Lab

Nyxera Red Team Lab is a **hybrid adversary infrastructure simulation environment** designed for offensive security research, red team training, and infrastructure experimentation.

The project deploys a **layered command-and-control redirector architecture** using Terraform while keeping the actual C2 infrastructure isolated on the operator machine.

This design mirrors techniques used by modern adversaries and professional red teams to separate **command infrastructure from cloud-facing components**.

---

# Architecture Overview

The lab uses multiple infrastructure layers to simulate realistic adversary operations while maintaining strong operational isolation.

```
Victim
  │
  ▼
lab.nyxera.cloud
  │
  ▼
Cloudflare Edge Network
(DNS + CDN + WAF + TLS)
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
Compromised Host (LAB01 linux01)
  │
  ▼
Internal Pivot
  │
  ▼
Internal Host (LAB01 linux02)
```

The real command-and-control servers **never run in cloud infrastructure**.

---

# Features

Key capabilities of the lab environment include:

* layered redirector architecture (Cloudflare → Tunnel → AWS redirector)
* encrypted operator tunnel (WireGuard redirector ↔ operator)
* payload staging infrastructure (S3 bucket)
* vulnerable target lab services (LAB01 linux01)
* internal lateral movement simulation (LAB01 linux01 → linux02)
* Windows “company” environment for AD exercises (LAB02)
* reproducible infrastructure-as-code deployment (Terraform stacks)

The design allows testing offensive tooling in a controlled environment without exposing real command infrastructure.

---

# Terraform Layout (CORE / LAB01 / LAB02)

This repo is split into independent Terraform stacks (separate state per folder):

* `CORE` (persistent) → shared VPC/subnet/routes, redirector + Elastic IP association, payload bucket
* `LAB01` (ephemeral) → Linux targets (initial foothold + lateral target)
* `LAB02` (ephemeral) → Windows target company environment (DC/DNS + workstations)

Only tear down the labs with `terraform destroy` in `LAB01` and/or `LAB02`.
`CORE` is designed to stay up (EIP + bucket) to keep external references stable.

---

# Infrastructure Components

## Operator Environment

The operator laptop hosts the command-and-control framework and offensive tooling.

Typical components:

* Havoc C2
* Sliver C2
* WireGuard client
* supporting tooling (Terraform, AWS CLI)

All C2 communications terminate on the operator machine.

---

## Cloudflare Edge Layer

Cloudflare provides an external masking and protection layer.

Services used:

* DNS
* CDN
* TLS termination
* WAF
* Cloudflare Tunnel

Domain used:

```
lab.nyxera.cloud
```

This prevents the real origin infrastructure from being easily discovered.

---

## AWS Redirector

The redirector server acts as the public-facing infrastructure.

Responsibilities:

* receive HTTP traffic
* proxy C2 communications
* return benign responses to scanners
* forward traffic through WireGuard

Software installed automatically:

* nginx
* wireguard
* cloudflared
* fail2ban

---

## Vulnerable Target Lab

The lab includes intentionally vulnerable applications for testing offensive techniques.

Applications include:

* OWASP Juice Shop
* VAmPI
* OWASP crAPI

These run inside Docker containers on a separate EC2 instance.

Example services:

```
http://target-ip:3000
http://target-ip:8888
http://target-ip:5000
```

---

## Payload Staging

Payloads are hosted using an S3 bucket.

Typical use cases:

* binary staging
* payload delivery
* script hosting

Example:

```
<PRESIGNED_URL_TO_payload.exe>
```

---

# Deployment

The infrastructure is deployed using Terraform. Deploy `CORE` first, then deploy `LAB01` and/or `LAB02`.

### Initialize Terraform

```
terraform init
```

### Validate configuration

```
terraform validate
```

### Review planned infrastructure

```
terraform plan
```

### Deploy infrastructure

```
terraform apply
```

After deployment Terraform will output:

* redirector IP
* payload bucket URL
* lab public IPs (Linux and/or Windows)

Important configuration notes:

* LAB01 target SSH is intentionally limited to `ssh_cidr_blocks` (operator) plus the VPC CIDR (for linux01 → linux02 lateral movement).
* Restrict management access by setting `ssh_cidr_blocks` to your operator public IP (e.g. `["190.18.171.24/32"]`).
* Ensure `key_pair_name` matches an existing AWS EC2 key pair in your account/region.

---

# Repository Structure

```
CORE/   # persistent shared infra (VPC, redirector, bucket)
LAB01/  # Linux lab targets (linux01 + linux02)
LAB02/  # Windows lab targets (AD + workstations)
docs/   # architecture + security + notes
```

---

# Design Goals

This project was designed with the following goals:

* realistic adversary infrastructure simulation
* minimal operational cost
* clear separation between operator and cloud infrastructure
* reproducible infrastructure deployment

---

# Use Cases

This lab can be used for:

* red team training
* adversary simulation
* infrastructure experimentation
* offensive security research

---

# Documentation

Additional documentation:

* `docs/ARCHITECTURE.md` – detailed infrastructure design and deployment notes
* `docs/SECURITY.md` – responsible use policy
* `docs/user-guide/README.md` – lab user guide (operator workflow + exercises index)

---

# Disclaimer

This project is intended **strictly for defensive security research, red team training, and controlled laboratory environments**.

The authors are not responsible for misuse of this infrastructure outside authorized environments.

Users are responsible for complying with all applicable laws and regulations.

---

# License

MIT License
