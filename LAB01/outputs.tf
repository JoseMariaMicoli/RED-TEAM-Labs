output "c2_public_ip" {

  value = aws_instance.c2_server.public_ip

}

output "target_public_ip" {

  value = aws_instance.linux_target.public_ip

}

output "c2_public_dns" {
  value = aws_instance.c2_server.public_dns
}

output "certbot_domains" {
  value = var.certbot_domains
}
