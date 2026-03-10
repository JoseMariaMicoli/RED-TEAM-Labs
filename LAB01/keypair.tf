resource "aws_key_pair" "lab_key" {

  key_name = "redteam-lab-key"

  public_key = file("~/.ssh/redteam-labs/lab01.pub")

}
