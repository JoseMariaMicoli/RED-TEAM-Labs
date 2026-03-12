variable "aws_region" {
  default = "us-east-1"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH and other management ports."
  type        = list(string)
  default     = ["190.18.171.24/32"]
}

variable "devops_password" {
  description = "Lab-only password used for the shared devops account (intentionally reused to simulate lateral movement)."
  type        = string
  default     = "ChangeMe-DevOps-01"
  sensitive   = true
}

variable "linux02_private_ip" {
  description = "Static private IP for the lateral target (kept stable for NFS + internal connectivity)."
  type        = string
  default     = "10.0.1.222"
}

variable "target_instance_type" {
  description = "Instance type used for the vulnerable target lab EC2 host."
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "SSH key pair name to use for the redirector and target instances."
  type        = string
  default     = "redteam-lab-key"
}
