output "redirector_ip" {

  description = "Elastic IP assigned to the AWS redirector"
  value       = local.redirector_ip
}

output "payload_bucket_url" {

  description = "S3 bucket endpoint used for payload hosting"
  value       = local.payload_bucket_domain_name
}

output "lab_domain" {

  description = "Fronting domain used by the Nyxera lab"
  value       = var.lab_domain
}

output "target_lab_ip" {
  description = "Live public IP for the vulnerable target lab instance"
  value       = aws_instance.target_lab.public_ip
}
