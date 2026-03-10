output "instance_ip" {
  value = aws_instance.linux_target.public_ip
}

output "target_public_ip" {

  value = aws_instance.linux_target.public_ip

}
