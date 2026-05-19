# 1. Create RDS Security Group in the EKS VPC
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment_name}-rds-sg"
  description = "Security group for RDS allowing access from EKS"
  vpc_id      = var.vpc_id

  # Inbound: MySQL/Aurora (3306) from EKS Cluster SG
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_sg_id] # Source is EKS SG ID
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-rds-sg" })
}

# 2. Fetch the secret metadata
data "aws_secretsmanager_secret" "db_secret" {
  name = var.db_secret_name
}

# 3. Fetch the actual secret value (JSON string)
data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

# 4. Decode the JSON to extract key/value pairs
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)
}

# 2. Create DB Subnet Group using all Private Subnets
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.environment_name}-db-subnet-group" })
}

# 3. RDS Instance (Example MySQL)
resource "aws_db_instance" "main" {
  identifier              = "${var.environment_name}-mysql-db"
  engine                  = "mysql"
  engine_version          = var.mysql_version
  instance_class          = var.instance_class
  allocated_storage       = 20
  max_allocated_storage   = var.max_allocated_storage
  multi_az                = var.multi_az
  backup_retention_period = 1
  apply_immediately       = true
  db_name                 = local.db_creds["db_name"]        # Fetches 'db_name' key from JSON
  username                = local.db_creds["MYSQL_USER"]     # Fetches 'username' key from JSON
  password                = local.db_creds["MYSQL_PASSWORD"] # Fetches 'password' key from JSON
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  tags                    = var.tags
}

# Read Replica (Conditional)
resource "aws_db_instance" "replica" {
  count      = var.create_read_replica ? 1 : 0
  identifier = "${var.environment_name}-mysql-replica"

  # Replicas reference the primary instance
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.instance_class

  # Inherits security group and subnet group from primary implicitly
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  parameter_group_name   = "default.mysql8.0"

  tags = merge(var.tags, { Role = "Replica" })
}