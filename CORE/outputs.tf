output "vpc_id" {
  description = "VPC ID for the shared red team lab network"
  value       = aws_vpc.redteam_vpc.id
}

output "subnet_id" {
  description = "Subnet ID for the shared red team lab network"
  value       = aws_subnet.lab_subnet.id
}

output "internal_subnet_id" {
  description = "Subnet ID for the internal (private) lab subnet"
  value       = aws_subnet.internal_subnet.id
}

output "internal_subnet_cidr" {
  description = "CIDR for the internal (private) lab subnet"
  value       = aws_subnet.internal_subnet.cidr_block
}

output "payloads_bucket_url" {
  description = "S3 virtual-hosted bucket endpoint (use presigned URLs for object access)"
  value       = "https://${aws_s3_bucket.payloads.bucket}.s3.amazonaws.com"
}

output "payloads_bucket_name" {
  description = "S3 bucket name used for payload staging"
  value       = aws_s3_bucket.payloads.bucket
}

output "payloads_bucket_s3_uri" {
  description = "S3 URI for payload staging"
  value       = "s3://${aws_s3_bucket.payloads.bucket}"
}

output "redirector_public_ip" {
  description = "Public IP (Elastic IP) for nyxera-rt-redirector-ubuntu-01"
  value = (
    var.existing_eip_allocation_id == ""
  ) ? aws_eip.redirector_eip[0].public_ip : data.aws_eip.existing[0].public_ip
}
