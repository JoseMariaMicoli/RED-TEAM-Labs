resource "aws_instance" "c2_server" {

  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.lab_subnet.id

  vpc_security_group_ids = [
    aws_security_group.lab_sg.id
  ]

  key_name = aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/c2_user_data.tpl", {
    certbot_domains = var.certbot_domains
    certbot_email   = var.certbot_email
    bootstrap       = file("${path.module}/userdata/c2_bootstrap.sh")
  })

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "sliver-c2"
  })

}

resource "aws_instance" "linux_target" {

  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.lab_subnet.id

  vpc_security_group_ids = [
    aws_security_group.lab_sg.id
  ]

  key_name = aws_key_pair.lab_key.key_name

  user_data = file("${path.module}/userdata/target_bootstrap.sh")

  tags = merge(local.common_tags, {
    Name = "vulnerable-target"
  })

}
