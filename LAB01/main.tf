terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  lab_name = "redteam-lab"

  common_tags = {
    Project     = "RED-TEAM-Labs"
    Environment = "red-team"
  }
}
