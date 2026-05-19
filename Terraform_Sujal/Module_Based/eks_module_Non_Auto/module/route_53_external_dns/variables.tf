variable "vpc_id" {
  type = string
}

variable "environment_name" {
  description = "Name of the environment (e.g., dev, staging, prod)"
  type        = string
}

variable "rds_address" {
  type        = string
  description = "The address of the RDS instance passed from the RDS module"
}

variable "clusters" {
  type        = list(string)
  description = "List of EKS cluster names for the association"
}

variable "public_domain_name" {
  type        = string
  description = "Name of the domain name"
  default     = "catalogservicesuj.com"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-2"
}

