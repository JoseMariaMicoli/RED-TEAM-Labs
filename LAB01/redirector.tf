locals {
  cloudflare_tunnel_credentials_b64 = (
    var.cloudflare_tunnel_credentials_file != "" && fileexists(var.cloudflare_tunnel_credentials_file)
  ) ? base64encode(file(var.cloudflare_tunnel_credentials_file)) : ""
}

resource "aws_security_group" "redirector" {
  name        = "redirector-sg"
  description = "Ingress control for the AWS redirector"
  vpc_id      = aws_vpc.redteam_vpc.id

  ingress {
    description = "SSH from operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  ingress {
    description = "HTTP for stealth redirector"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.http_cidr_blocks
  }

  ingress {
    description = "HTTPS for stealth redirector"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.https_cidr_blocks
  }

  ingress {
    description = "WireGuard tunnel for operator"
    from_port   = var.wireguard_listen_port
    to_port     = var.wireguard_listen_port
    protocol    = "udp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Purpose = "aws-redirector-sg"
  })
}

resource "aws_instance" "redirector" {
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.lab_subnet.id

  vpc_security_group_ids = [
    aws_security_group.redirector.id
  ]

  key_name = data.aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/redirector_user_data.tpl", {
    lab_domain                        = var.lab_domain
    proxy_upstream                    = "10.13.13.1:8443"
    wireguard_private_key             = var.wireguard_private_key
    wireguard_peer_public_key         = var.wireguard_peer_public_key
    wireguard_peer_endpoint           = var.wireguard_peer_endpoint
    wireguard_peer_allowed_ips        = join(",", var.wireguard_peer_allowed_ips)
    wireguard_listen_port             = tostring(var.wireguard_listen_port)
    cloudflare_tunnel_credentials_b64 = local.cloudflare_tunnel_credentials_b64
    cloudflare_tunnel_name            = var.cloudflare_tunnel_name
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "aws-redirector"
  })
}
