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

  redirector_ip = (
    var.existing_eip_allocation_id == ""
  ) ? aws_eip.redirector_eip[0].public_ip : data.aws_eip.existing[0].public_ip

  payload_bucket_domain_name = (
    var.manage_payload_bucket
  ) ? aws_s3_bucket.payloads[0].bucket_domain_name : data.aws_s3_bucket.payloads[0].bucket_domain_name
}
