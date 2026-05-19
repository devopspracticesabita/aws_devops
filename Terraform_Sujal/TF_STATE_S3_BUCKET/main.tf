#resource "random_string" "suffix" {
#  length  = 6
#  upper   = false
#  special = false
#}

resource "aws_s3_bucket" "tftstate_bucket" {
  #bucket = "tfstate-${var.environment_name}-${var.aws_region}-${random_string.suffix.result}"
  bucket = "tfstate-bucket-sujal-mitra"
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    #Name        = "tfstate-${var.environment_name}-${var.aws_region}"
    Name        = "TFSTATEBUCKET"
    Environment = "All"
  }
}

resource "aws_s3_bucket_public_access_block" "tftstate_bucket_publicaccess" {
  bucket = aws_s3_bucket.tftstate_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tftstate_bucket_versioning" {
  bucket = aws_s3_bucket.tftstate_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tftstate_bucket_encryption" {
  bucket = aws_s3_bucket.tftstate_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}