resource "aws_instance" "dc" {
  ami           = var.dc_ami_id != "" ? var.dc_ami_id : data.aws_ami.windows_server_2022_core.id
  instance_type = var.dc_instance_type
  subnet_id     = data.terraform_remote_state.core.outputs.subnet_id
  private_ip    = var.dc_private_ip

  vpc_security_group_ids = [
    aws_security_group.windows_lab.id
  ]

  key_name = data.aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/dc_user_data.ps1.tpl", {
    hostname               = "nyxera-rt-lumenworks-dc-win2022-01"
    ad_domain_name         = var.ad_domain_name
    ad_safe_mode_password  = var.ad_safe_mode_password
    dc_ip                  = var.dc_private_ip
    windows_admin_password = var.windows_admin_password
    win10_01_user          = var.win10_01_user
    win10_01_user_password = var.win10_01_user_password
  })

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "nyxera-rt-lumenworks-dc-win2022-01"
    Role = "dc"
  })
}

resource "aws_instance" "win10_01" {
  ami           = var.client_ami_id != "" ? var.client_ami_id : data.aws_ami.windows_server_2022_core.id
  instance_type = var.client_instance_type
  subnet_id     = data.terraform_remote_state.core.outputs.subnet_id
  private_ip    = var.win10_01_private_ip != "" ? var.win10_01_private_ip : null

  vpc_security_group_ids = [
    aws_security_group.windows_lab.id
  ]

  key_name = data.aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/client_user_data.ps1.tpl", {
    hostname               = "nyxera-rt-lumenworks-it-win2022-01"
    ad_domain_name         = var.ad_domain_name
    dc_ip                  = var.dc_private_ip
    windows_admin_password = var.windows_admin_password
    admin_over_peer        = false
    peer_admin_user        = var.win10_01_user
  })

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "nyxera-rt-lumenworks-it-win2022-01"
    Role = "workstation"
  })
}

resource "aws_instance" "win10_02" {
  ami           = var.client_ami_id != "" ? var.client_ami_id : data.aws_ami.windows_server_2022_core.id
  instance_type = var.client_instance_type
  subnet_id     = data.terraform_remote_state.core.outputs.subnet_id
  private_ip    = var.win10_02_private_ip != "" ? var.win10_02_private_ip : null

  vpc_security_group_ids = [
    aws_security_group.windows_lab.id
  ]

  key_name = data.aws_key_pair.lab_key.key_name

  user_data = templatefile("${path.module}/userdata/client_user_data.ps1.tpl", {
    hostname               = "nyxera-rt-lumenworks-fin-win2022-02"
    ad_domain_name         = var.ad_domain_name
    dc_ip                  = var.dc_private_ip
    windows_admin_password = var.windows_admin_password
    admin_over_peer        = true
    peer_admin_user        = var.win10_01_user
  })

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "nyxera-rt-lumenworks-fin-win2022-02"
    Role = "workstation"
  })
}
