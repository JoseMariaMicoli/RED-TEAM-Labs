resource "aws_instance" "linux02" {
  ami           = data.aws_ami.ubuntu_latest.id
  instance_type = "t3.micro"
  subnet_id     = data.terraform_remote_state.core.outputs.subnet_id
  private_ip    = var.linux02_private_ip

  vpc_security_group_ids = [
    aws_security_group.target_lab.id
  ]

  key_name = data.aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/linux02_bootstrap.sh.tpl", {
    devops_password   = var.devops_password
    nfs_export_cidr   = data.aws_vpc.lab.cidr_block
    nfs_export_path   = "/srv/ops-share"
    nfs_mount_address = var.linux02_private_ip
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "nyxera-rt-lateral-target-ubuntu-02"
    Role = "lateral-target"
  })
}
