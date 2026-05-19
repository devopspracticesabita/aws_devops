# 1. Define a Redis User with IAM Authentication
resource "aws_elasticache_user" "iam_user" {
  user_id       = "${var.environment_name}-iam-user"
  user_name     = "${var.environment_name}-iam-user" # This is the username your app will use to login
  engine        = "redis"
  access_string = "on ~* +@all" # Full access to all keys (Adjust for least privilege)

  authentication_mode {
    type = "iam"
  }
}

# 2. Create a User Group and add the IAM User to it
resource "aws_elasticache_user_group" "iam_user_group" {
  engine        = "redis"
  user_group_id = "${var.environment_name}-user-group"
  user_ids      = [aws_elasticache_user.iam_user.user_id, "default"] # 'default' user is required
}

# 3. Redis Security Group (Network Layer)
resource "aws_security_group" "redis_sg" {
  name        = "${var.environment_name}-redis-sg"
  description = "Security group for Redis allowing access from EKS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-redis-sg" })
}

# 4. Redis Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "${var.environment_name}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

# 5. Redis Replication Group with IAM Auth
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.environment_name}-redis"
  description          = "Redis cluster with IAM Authentication for ${var.environment_name}"

  engine               = "redis"
  engine_version       = var.redis_version # MUST be 7.0+ for IAM Auth
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = var.parameter_group_name

  # High Availability Configuration
  automatic_failover_enabled = var.multi_az
  multi_az_enabled           = var.multi_az
  num_cache_clusters         = var.num_cache_clusters

  subnet_group_name  = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids = [aws_security_group.redis_sg.id]

  # Security Settings
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true # REQUIRED for IAM Auth

  # Link the User Group (This enables IAM Auth)
  user_group_ids = [aws_elasticache_user_group.iam_user_group.user_group_id]

  tags = var.tags
}