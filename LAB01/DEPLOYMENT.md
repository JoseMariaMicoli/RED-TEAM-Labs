# Deployment & Testing Guide

1. **Prerequisites**
   - AWS credentials configured in your shell (`AWS_PROFILE` / `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`).
   - A key pair named `redteam-lab-key` with the public key at `~/.ssh/redteam-labs/lab01.pub` (or adjust `keypair.tf` accordingly).
   - Terraform 1.5+ installed alongside the AWS provider (the repository pin is `~> 5.0`).

2. **Quick start**
   - `cd RED-TEAM-Labs/LAB01`
   - `terraform init`
   - `terraform plan -var="certbot_domains=your.domain.com" -var="certbot_email=ops@your.domain.com"`
   - `terraform apply -var="certbot_domains=your.domain.com" -var="certbot_email=ops@your.domain.com"`
   - After apply, note the outputs (`c2_public_ip`, `c2_public_dns`) and SSH into the C2 host using the `ubuntu` user.

3. **Let’s Encrypt + HTTPS**
   - The bootstrap script installs Certbot and templates an HTTP-only Nginx site that proxies to the C2 backend on port 8080.
   - Once the domain resolves to the instance, run `sudo certbot --nginx -d your.domain.com` or rerun `terraform apply` with valid `certbot_domains`; the script will detect the variable and attempt a renewal via `certbot --nginx`.
   - Logs from the bootstrap process are in `/var/log/c2-setup.log`.

4. **Re-running `user_data`**
   - `user_data` only executes on first boot. To trigger it again:
     1. Run `terraform taint aws_instance.c2_server` and `terraform apply`, or
     2. Destroy the instance (`terraform destroy -target=aws_instance.c2_server`) and re-run `terraform apply`.
   - Always run `terraform plan` before applying changes.

5. **Post-install verification**
   - `systemctl status nginx` to confirm the reverse proxy is up.
   - `docker ps` to verify Docker is running (Compose plugin is installed via `docker-compose-plugin` and future containers should be launched with `docker compose ...`).
   - `sliver`, `msfconsole`, and `/usr/local/bin/havoc-ts` are placed in `/usr/local/bin`; you can start them manually or via `systemd` wrappers you add later.
   - Swap is configured at `/swapfile` (4 GB).

6. **Cleanup**
   - Use `terraform destroy -auto-approve` when you no longer need the lab; this ensures every resource is deleted.

7. **Future work**
   - You can deploy additional tooling inside containers (GoPhish, more complex C2s) using Docker Compose now that the daemon and Compose plugin are installed.
   - Keep using the `certbot_domains` / `certbot_email` variables in `terraform.tfvars` to keep HTTPS configuration consistent.
