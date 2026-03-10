resource "aws_instance" "linux_target" {

  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.lab_subnet.id

  vpc_security_group_ids = [
    aws_security_group.lab_sg.id
  ]

  key_name = aws_key_pair.lab_key.key_name

  tags = {
    Name = "linux-target"
  }

}
