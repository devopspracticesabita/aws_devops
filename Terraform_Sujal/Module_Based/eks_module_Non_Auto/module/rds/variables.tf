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

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "create_read_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = true
}

variable "instance_class" {
  description = "DB instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "max_allocated_storage" {
  description = "The upper limit to which RDS can automatically scale the storage (e.g., 100 GB)"
  type        = number
  default     = 100
}

variable "db_secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
  default     = "catalog-db-secret-3"
}

variable "mysql_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "skip_final_snapshot" {
  type = bool
}

variable "deletion_protection" {
  type = bool
}

variable "backup_retention_period" {
  type = number
  description = "Till how many days the backup will be kept"
}

variable "final_snapshot_identifier" {
  type    = string
}