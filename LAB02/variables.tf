variable "aws_region" {
  default = "us-east-1"
}

variable "key_pair_name" {
  description = "SSH key pair name used to decrypt Windows Administrator password."
  type        = string
  default     = "redteam-lab-key"
}

variable "rdp_cidr_blocks" {
  description = "CIDR blocks allowed to reach RDP (3389)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "dc_instance_type" {
  description = "Instance type for the Windows DC/DNS host."
  type        = string
  default     = "t3.micro"
}

variable "client_instance_type" {
  description = "Instance type for Windows 10 clients."
  type        = string
  default     = "t3.micro"
}

variable "dc_ami_id" {
  description = "Optional AMI ID override for the Windows DC/DNS host."
  type        = string
  default     = ""
}

variable "client_ami_id" {
  description = "Optional AMI ID override for the workstation hosts. Default uses Windows Server 2022 Core."
  type        = string
  default     = ""
}

variable "ad_domain_name" {
  description = "AD domain name to create when promoting the DC (optional)."
  type        = string
  default     = "lumenworks.internal"
}

variable "windows_admin_password" {
  description = "Password to set for the local Administrator account on all LAB02 Windows hosts (also used for domain join)."
  type        = string
  sensitive   = true
}

variable "ad_safe_mode_password" {
  description = "DSRM (Safe Mode) password used for AD promotion. Leave empty to skip auto-promotion."
  type        = string
  default     = ""
  sensitive   = true
}

variable "dc_private_ip" {
  description = "Static private IP to assign to the DC/DNS host (must be inside the shared subnet)."
  type        = string
  default     = "10.0.1.10"
}

variable "win10_01_private_ip" {
  description = "Optional static private IP for Windows 10 client 01. Leave empty to use DHCP."
  type        = string
  default     = ""
}

variable "win10_02_private_ip" {
  description = "Optional static private IP for Windows 10 client 02. Leave empty to use DHCP."
  type        = string
  default     = ""
}

variable "win10_01_user" {
  description = "Domain username representing the primary user of client 01."
  type        = string
  default     = "it.support"
}

variable "win10_01_user_password" {
  description = "Password for the domain user representing the primary user of client 01."
  type        = string
  sensitive   = true
}
