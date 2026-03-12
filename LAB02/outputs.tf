output "dc_win2022_01_public_ip" {
  description = "Public IP for nyxera-rt-lumenworks-dc-win2022-01"
  value       = aws_instance.dc.public_ip
}

output "it_win2022_01_public_ip" {
  description = "Public IP for nyxera-rt-lumenworks-it-win2022-01"
  value       = aws_instance.win10_01.public_ip
}

output "fin_win2022_02_public_ip" {
  description = "Public IP for nyxera-rt-lumenworks-fin-win2022-02"
  value       = aws_instance.win10_02.public_ip
}
