variable "instance_type" {
  default = "t3.micro"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH and other management ports."
  type        = list(string)
  default     = ["190.18.171.24/32"]
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

variable "certbot_domains" {
  description = "Comma-separated list of domains used when requesting Let's Encrypt certificates."
  type        = string
  default     = ""
}

variable "certbot_email" {
  description = "Email address for Let's Encrypt notifications."
  type        = string
  default     = ""
}
