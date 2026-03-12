resource "aws_security_group" "windows_lab" {
  name        = "lab02-windows-sg"
  description = "Ingress control for LAB02 Windows hosts"
  vpc_id      = data.aws_vpc.lab.id

  ingress {
    description = "RDP from operator"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.rdp_cidr_blocks
  }

  ingress {
    description = "LAB internal (VPC) access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.lab.cidr_block]
  }

  ingress {
    description = "Windows-to-Windows within SG"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "nyxera-rt-windows-lab02-sg"
  })
}

