# Security Policy

<!-- This documentation lives under docs/. -->

## Responsible Use

Nyxera Adversary Simulation Lab is designed for **offensive security research, red team training, and controlled laboratory environments**.

The project must only be used in environments where the user has **explicit authorization to perform security testing**.

Unauthorized use of offensive security tools or infrastructure may violate local, national, or international laws.

Users are responsible for ensuring that they operate within the legal and ethical boundaries applicable to their jurisdiction.

---

# Supported Versions

This project is provided as a research and training environment.

Security updates may be applied to the main branch as improvements are made to the infrastructure.

Users are encouraged to keep their deployment environments updated with the latest changes.

---

# Reporting Security Issues

If you discover a security issue within this repository, please report it responsibly.

Do not disclose vulnerabilities publicly before they have been reviewed.

Reports may include:

* infrastructure misconfiguration
* exposed secrets
* dependency vulnerabilities
* insecure default settings

Please include:

* a clear description of the issue
* steps to reproduce
* potential impact
* suggested remediation if available

---

# Infrastructure Security Model

The architecture intentionally isolates sensitive components.

Key protections include:

* command and control servers run locally
* cloud infrastructure only acts as redirectors
* encrypted tunnels between infrastructure layers
* CDN masking of origin infrastructure
* restricted administrative access

These controls are designed to minimize exposure of sensitive infrastructure components.

---

# Ethical Use Policy

This repository is provided for:

* security education
* defensive research
* authorized penetration testing
* adversary simulation exercises

The project must **not be used for unauthorized intrusion or malicious activities**.

---

# Third-Party Components

The lab includes intentionally vulnerable applications used for testing purposes.

These applications are deployed only inside controlled environments and should never be exposed to production networks.

Examples include:

* OWASP Juice Shop
* OWASP crAPI
* VAmPI

Users should deploy these applications only within isolated testing environments.

---

# Acknowledgements

This project builds upon the work of the open source security community and the OWASP ecosystem.

The authors acknowledge the importance of responsible security research and ethical disclosure practices.
