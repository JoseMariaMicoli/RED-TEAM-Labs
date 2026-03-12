resource "random_password" "lab02_flag_seed" {
  length  = 48
  special = false
}

locals {
  lab02_flag_ids = [
    "APT28-LAB02-1",
    "APT29-LAB02-1",
    "APT29-LAB02-2",
    "LAZARUS-LAB02-1",
  ]

  lab02_flags = {
    for id in local.lab02_flag_ids :
    id => format("NYXERA{%s:%s}", id, substr(sha256("${random_password.lab02_flag_seed.result}:${id}"), 0, 32))
  }
}

output "lab02_flag_seed" {
  description = "Secret seed used to validate rotating LAB02 flags (lab-only)."
  value       = random_password.lab02_flag_seed.result
  sensitive   = true
}
