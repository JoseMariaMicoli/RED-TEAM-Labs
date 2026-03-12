data "terraform_remote_state" "core" {
  backend = "local"

  config = {
    path = "../CORE/terraform.tfstate"
  }
}

data "aws_vpc" "lab" {
  id = data.terraform_remote_state.core.outputs.vpc_id
}
