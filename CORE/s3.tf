resource "aws_s3_bucket" "payloads" {
  bucket = var.payload_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "payload-storage"
  }
}
