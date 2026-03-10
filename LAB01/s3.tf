resource "aws_s3_bucket" "payloads" {

  bucket = "redteam-lab-payloads"

  tags = {
    Name = "payload-storage"
  }

}
