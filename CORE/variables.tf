variable "aws_region" {
  default = "us-east-1"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH and other management ports."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  description = "CIDR blocks that can reach HTTP services."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR blocks that can reach HTTPS services."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "lab_domain" {
  description = "Primary domain used for the Nyxera lab redirector."
  type        = string
  default     = "lab.nyxera.cloud"
}

variable "wireguard_private_key" {
  description = "Private key material for the redirector WireGuard interface."
  type        = string
  default     = ""
  sensitive   = true
}

variable "wireguard_peer_public_key" {
  description = "Public key belonging to the operator WireGuard peer."
  type        = string
  default     = ""
  sensitive   = true
}

variable "wireguard_peer_endpoint" {
  description = "IP:port used to reach the operator WireGuard peer."
  type        = string
  default     = ""
}

variable "wireguard_listen_port" {
  description = "UDP port WireGuard listens on inside AWS."
  type        = number
  default     = 51820
}

variable "wireguard_peer_allowed_ips" {
  description = "Allowed IP ranges advertised to the operator over WireGuard."
  type        = list(string)
  default     = ["10.13.13.0/24"]
}

variable "cloudflare_tunnel_credentials_file" {
  description = "Path to the Cloudflare Tunnel credentials JSON file."
  type        = string
  default     = ""

  validation {
    condition     = var.cloudflare_tunnel_credentials_file == "" || can(regex("^/", var.cloudflare_tunnel_credentials_file))
    error_message = "cloudflare_tunnel_credentials_file must be an absolute path (Terraform does not expand '~')."
  }
}

variable "cloudflare_tunnel_name" {
  description = "Tunnel name (as configured inside Cloudflare) used when running the tunnel."
  type        = string
  default     = "nyxera-redteam"
}

variable "havoc_upstream" {
  description = "Optional additional upstream (host:port) exposed via the redirector at /cdn/api/v4."
  type        = string
  default     = "10.13.13.1:8444"
}

variable "key_pair_name" {
  description = "SSH key pair name to use for the redirector and target instances."
  type        = string
  default     = "redteam-lab-key"
}

variable "payload_bucket_name" {
  description = "Existing S3 bucket name used for payload staging."
  type        = string
  default     = "redteam-lab-payloads"
}

variable "existing_eip_allocation_id" {
  description = "Allocation ID for an existing Elastic IP (pre-provisioned and DNS-linked). Leave empty to let Terraform create one."
  type        = string
  default     = ""

  validation {
    condition     = var.existing_eip_allocation_id == "" || can(regex("^eipalloc-[0-9a-f]+$", var.existing_eip_allocation_id))
    error_message = "existing_eip_allocation_id must look like 'eipalloc-...' or be empty."
  }
}
