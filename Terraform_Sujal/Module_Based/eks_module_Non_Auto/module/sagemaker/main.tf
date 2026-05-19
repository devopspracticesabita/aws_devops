# 1. IAM Role for SageMaker Studio to access AWS resources
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.environment_name}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.environment_name}-sagemaker-role" })
}

# 2. Attach the official AmazonSageMakerFullAccess policy
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# 3. Create a dedicated S3 Bucket for SageMaker Data and Models
resource "aws_s3_bucket" "sagemaker_bucket" {
  bucket = "${var.environment_name}-sagemaker-data-bucket-${var.sagemaker_region}"

  lifecycle {
    prevent_destroy = false
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-sagemaker-bucket" })
}

# 4. Attach precise S3 permissions to the SageMaker Role
resource "aws_iam_role_policy" "sagemaker_s3_policy" {
  name = "${var.environment_name}-sagemaker-s3-policy"
  role = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.sagemaker_bucket.arn,
          "${aws_s3_bucket.sagemaker_bucket.arn}/*"
        ]
      }
      # {
      #   Effect = "Deny"
      #   Action = "s3:CreateBucket"
      #   Resource = "*"
      # }
    ]
  })
}

# 5. Create a Security Group for the SageMaker Studio environment
resource "aws_security_group" "sagemaker_sg" {
  name        = "${var.environment_name}-sagemaker-sg"
  description = "Security group for SageMaker Studio"
  vpc_id      = var.vpc_id

  # Outbound access to securely fetch packages via the NAT Gateway
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-sagemaker-sg" })
}

# 6. Create the SageMaker Studio Domain
resource "aws_sagemaker_domain" "studio_domain" {
  domain_name = "${var.environment_name}-studio-domain"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.private_subnet_ids # Operates securely in private subnets

  default_user_settings {
    execution_role  = aws_iam_role.sagemaker_role.arn
    security_groups = [aws_security_group.sagemaker_sg.id]
  }

  retention_policy {
    home_efs_file_system = "Delete"
  }

  # Forces all web traffic to stay within your VPC boundaries
  app_network_access_type = "VpcOnly"

  tags = merge(var.tags, { Name = "${var.environment_name}-studio" })
}

# 7. Create a default User Profile inside the Studio Domain
resource "aws_sagemaker_user_profile" "default_user" {
  domain_id         = aws_sagemaker_domain.studio_domain.id
  user_profile_name = "default-data-scientist"

  tags = merge(var.tags, { Name = "${var.environment_name}-studio-user" })
}
