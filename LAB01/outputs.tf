output "target_ubuntu_01_public_ip" {
  description = "Public IP for nyxera-rt-target-ubuntu-01"
  value       = aws_instance.target_lab.public_ip
}

output "lateral_target_ubuntu_02_public_ip" {
  description = "Public IP for nyxera-rt-lateral-target-ubuntu-02"
  value       = aws_instance.linux02.public_ip
}
