data "aws_ami" "ubuntu_latest" {

  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

data "aws_ami" "windows_server" {

  most_recent = true

  owners = ["801119661308"] # Amazon Windows

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

}
