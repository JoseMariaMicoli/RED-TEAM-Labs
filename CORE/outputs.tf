output "vpc_id" {
  description = "VPC ID for the shared red team lab network"
  value       = aws_vpc.redteam_vpc.id
}

output "subnet_id" {
  description = "Subnet ID for the shared red team lab network"
  value       = aws_subnet.lab_subnet.id
}

output "payloads_bucket_url" {
  description = "S3 bucket endpoint used for payload staging"
  value       = "https://redteam-lab-payloads.s3.amazonaws.com"
}

output "redirector_public_ip" {
  description = "Public IP (Elastic IP) for nyxera-rt-redirector-ubuntu-01"
  value = (
    var.existing_eip_allocation_id == ""
  ) ? aws_eip.redirector_eip[0].public_ip : data.aws_eip.existing[0].public_ip
}

