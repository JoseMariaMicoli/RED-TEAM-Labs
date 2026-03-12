resource "aws_s3_bucket" "payloads" {
  bucket = var.payload_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "payload-storage"
  }
}

# Hardening: keep the bucket private-by-default and suitable for presigned URL staging.
# This does not delete or replace the bucket.
resource "aws_s3_bucket_public_access_block" "payloads" {
  bucket = aws_s3_bucket.payloads.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "payloads" {
  bucket = aws_s3_bucket.payloads.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "payloads" {
  bucket = aws_s3_bucket.payloads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "payloads" {
  bucket = aws_s3_bucket.payloads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
