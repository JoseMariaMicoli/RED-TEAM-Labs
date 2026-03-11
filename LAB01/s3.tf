data "aws_s3_bucket" "payloads" {
  count  = var.manage_payload_bucket ? 0 : 1
  bucket = var.payload_bucket_name
}

resource "aws_s3_bucket" "payloads" {
  count  = var.manage_payload_bucket ? 1 : 0
  bucket = var.payload_bucket_name

  tags = merge(local.common_tags, {
    Name = "payload-storage"
  })
}
