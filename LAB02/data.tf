data "aws_vpc" "lab" {
  id = data.terraform_remote_state.core.outputs.vpc_id
}

data "aws_key_pair" "lab_key" {
  key_name = var.key_pair_name
}

data "aws_ami" "windows_server_2022_core" {
  most_recent = true

  owners = ["801119661308"] # Amazon Windows

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-Base-*"]
  }
}

data "aws_ami" "windows_server_2022_full" {
  most_recent = true

  owners = ["801119661308"] # Amazon Windows

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}
