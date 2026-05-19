variable "environment_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_sg_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "postgres_instance_class" {
  description = "Postgres instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "create_read_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = false
}

variable "db_secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
  default     = "catalog-db-secret-3"
}