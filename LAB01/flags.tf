resource "random_password" "lab01_flag_seed" {
  length  = 48
  special = false
}

locals {
  lab01_flag_ids = [
    "APT28-LAB01-1",
    "APT29-LAB01-1",
    "APT29-LAB01-2",
    "LAZARUS-LAB01-1",
  ]

  lab01_flags = {
    for id in local.lab01_flag_ids :
    id => format("NYXERA{%s:%s}", id, substr(sha256("${random_password.lab01_flag_seed.result}:${id}"), 0, 32))
  }
}

output "lab01_flag_seed" {
  description = "Secret seed used to validate rotating LAB01 flags (lab-only)."
  value       = random_password.lab01_flag_seed.result
  sensitive   = true
}
