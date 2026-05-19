resource "aws_dynamodb_table" "this" {
  name                        = "${var.environment_name}-${var.table_name}"
  billing_mode                = var.billing_mode
  read_capacity               = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity              = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key                    = var.hash_key
  range_key                   = var.range_key
  deletion_protection_enabled = var.deletion_protection

  # Define the Partition Key (and Sort Key if provided)
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  dynamic "attribute" {
    for_each = var.range_key != "" ? [1] : []
    content {
      name = var.range_key
      type = var.range_key_type
    }
  }

  # Enable Point-in-Time Recovery (Backup)
  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-${var.table_name}" })
}