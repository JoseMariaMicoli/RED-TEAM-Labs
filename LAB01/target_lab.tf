resource "aws_security_group" "target_lab" {
  name        = "target-lab-sg"
  description = "Traffic for the vulnerable target lab applications"
  vpc_id      = data.terraform_remote_state.core.outputs.vpc_id

  ingress {
    description = "Juice Shop HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "crAPI HTTP"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "VAmPI API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  ingress {
    description = "SSH lateral movement (VPC internal)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.lab.cidr_block]
  }

  ingress {
    description = "NFSv4 (VPC internal)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.lab.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Purpose = "target-lab-sg"
  })
}

resource "aws_instance" "target_lab" {
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.target_instance_type
  subnet_id     = data.terraform_remote_state.core.outputs.subnet_id

  vpc_security_group_ids = [
    aws_security_group.target_lab.id
  ]

  key_name = data.aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/target_lab_bootstrap.sh.tpl", {
    devops_password     = var.devops_password
    nfs_server_ip       = var.linux02_private_ip
    nfs_mount_path      = "/mnt/ops-share"
    nfs_export_path     = "/srv/ops-share"
    enable_password_ssh = true
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "nyxera-rt-target-ubuntu-01"
  })
}
