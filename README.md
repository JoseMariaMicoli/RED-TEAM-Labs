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
Cloudflare Edge
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

The real command-and-control servers **never run in cloud infrastructure**.

---

# Features

Key capabilities of the lab environment include:

* layered redirector architecture
* CDN masking via Cloudflare
* encrypted operator tunnels
* payload staging infrastructure
* vulnerable application targets
* infrastructure-as-code deployment

The design allows testing offensive tooling in a controlled environment without exposing real command infrastructure.

---

# Infrastructure Components

## Operator Environment

The operator laptop hosts the command-and-control framework and offensive tooling.

Typical components:

* Havoc C2
* Sliver C2
* WireGuard client
* exploitation tooling

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
https://redteam-lab-payloads.s3.amazonaws.com/payload.exe
```

---

# Deployment

The infrastructure is deployed using Terraform.

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
* target lab IP

---

# Repository Structure

```
LAB01/
│
├ terraform configuration
├ userdata/
│   ├ redirector bootstrap
│   └ target lab bootstrap
│
└ scripts/
    operational helpers
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

* ARCHITECTURE.md – detailed infrastructure design
* SECURITY.md – responsible use policy

---

# Disclaimer

This project is intended **strictly for defensive security research, red team training, and controlled laboratory environments**.

The authors are not responsible for misuse of this infrastructure outside authorized environments.

Users are responsible for complying with all applicable laws and regulations.

---

# License

MIT License
