# 1. Security Group for Postgres (Port 5432)
resource "aws_security_group" "pg_sg" {
  name        = "${var.environment_name}-postgres-sg"
  description = "Allow Postgres access from EKS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.environment_name}-postgres-sg" })
}

# 2. Secrets Manager Data Fetching
data "aws_secretsmanager_secret" "db_secret" {
  name = var.db_secret_name
}

data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)
}

# 3. DB Subnet Group
resource "aws_db_subnet_group" "pg_subnet_group" {
  name       = "${var.environment_name}-pg-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = merge(var.tags, { Name = "${var.environment_name}-pg-subnet-group" })
}

# 4. Primary PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier            = "${var.environment_name}-postgres-db"
  engine                = "postgres"
  engine_version        = var.postgres_version
  instance_class        = var.postgres_instance_class
  allocated_storage     = 20
  max_allocated_storage = var.max_allocated_storage
  multi_az              = var.multi_az

  # Credentials from JSON
  db_name  = local.db_creds["postgres_db_name"]
  username = local.db_creds["POSTGRES_USER"]     # Ensure these keys exist in your secret
  password = local.db_creds["POSTGRES_PASSWORD"] # Ensure these keys exist in your secret

  db_subnet_group_name   = aws_db_subnet_group.pg_subnet_group.name
  vpc_security_group_ids = [aws_security_group.pg_sg.id]

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false # Set to true for Production

  tags = var.tags
}

# 5. Postgres Read Replica
resource "aws_db_instance" "pg_replica" {
  count               = var.create_read_replica ? 1 : 0
  identifier          = "${var.environment_name}-postgres-replica"
  replicate_source_db = aws_db_instance.postgres.identifier
  instance_class      = var.postgres_instance_class

  vpc_security_group_ids = [aws_security_group.pg_sg.id]
  skip_final_snapshot    = true

  # Parameter group family must match Postgres version (e.g., postgres15)
  parameter_group_name = "default.postgres${split(".", var.postgres_version)[0]}"

  tags = merge(var.tags, { Role = "Replica" })
}