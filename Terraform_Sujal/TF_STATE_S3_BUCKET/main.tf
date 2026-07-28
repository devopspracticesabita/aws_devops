data "aws_iam_policy_document" "kms_policy" {

  statement {
    sid    = "EnableManagementAccountAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::048408301799:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowDevAccountUsage"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::802589443968:root"]
    }

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:ReEncrypt*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowProdTerraformRoleUsage"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::133089468258:role/TerraformDeploymentRole"
      ]
    }

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
      "kms:ReEncrypt*"
    ]

    resources = ["*"]
  }
}

###################################################
# KMS KEY
###################################################

resource "aws_kms_key" "terraform_state" {
  description             = "KMS Key for Terraform State Bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = data.aws_iam_policy_document.kms_policy.json

  tags = {
    Name        = "terraform-state-kms"
    Environment = "management"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

###################################################
# S3 STATE BUCKET
###################################################

resource "aws_s3_bucket" "tftstate_bucket" {
  #bucket = "tfstate-${var.environment_name}-${var.aws_region}-${random_string.suffix.result}"
  bucket = "tfstate-bucket-sujal-mitra"
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    #Name        = "tfstate-${var.environment_name}-${var.aws_region}"
    Name        = "TFSTATEBUCKET"
    Environment = "All"
  }
}

###################################################
# OWNERSHIP CONTROLS
###################################################

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  bucket = aws_s3_bucket.tftstate_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

###################################################
# PUBLIC ACCESS BLOCK
###################################################

resource "aws_s3_bucket_public_access_block" "tftstate_bucket_publicaccess" {
  bucket = aws_s3_bucket.tftstate_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###################################################
# VERSIONING
###################################################

resource "aws_s3_bucket_versioning" "tftstate_bucket_versioning" {
  bucket = aws_s3_bucket.tftstate_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "tftstate_bucket_encryption" {
#   bucket = aws_s3_bucket.tftstate_bucket.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

###################################################
# SERVER SIDE ENCRYPTION
###################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "tftstate_bucket_encryption" {
  bucket = aws_s3_bucket.tftstate_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

###################################################
# LIFECYCLE CONFIGURATION
###################################################

resource "aws_s3_bucket_lifecycle_configuration" "tfstate_lifecycle" {
  bucket = aws_s3_bucket.tftstate_bucket.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}