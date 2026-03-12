data "aws_eip" "existing" {
  count = var.existing_eip_allocation_id != "" ? 1 : 0

  filter {
    name   = "allocation-id"
    values = [var.existing_eip_allocation_id]
  }
}

resource "aws_eip" "redirector_eip" {
  count = var.existing_eip_allocation_id == "" ? 1 : 0

  domain = "vpc"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "redirector-elastic-ip"
  })
}

resource "aws_eip_association" "new_redirector" {
  count = var.existing_eip_allocation_id == "" ? 1 : 0

  instance_id   = aws_instance.redirector.id
  allocation_id = aws_eip.redirector_eip[0].allocation_id
}

resource "aws_eip_association" "existing_redirector" {
  count = var.existing_eip_allocation_id != "" ? 1 : 0

  instance_id   = aws_instance.redirector.id
  allocation_id = var.existing_eip_allocation_id
}

