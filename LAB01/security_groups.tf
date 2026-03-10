resource "aws_security_group" "lab_sg" {

  name = "lab-sg"

  vpc_id = aws_vpc.redteam_vpc.id

  ingress {

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["190.18.171.24/32"]

  }

  egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "lab-security-group"
  }

}
