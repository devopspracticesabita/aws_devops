variable "environment_name" {
  description = "Name of the environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where Redis will be deployed"
  type        = string
}

variable "eks_sg_id" {
  description = "The Security Group ID of the EKS cluster/nodes to allow access"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the Redis subnet group"
  type        = list(string)
}

variable "node_type" {
  description = "The instance class for the Redis nodes (e.g., cache.t3.medium)"
  type        = string
  default     = "cache.t3.medium"
}

variable "redis_version" {
  description = "Redis engine version. MUST be 7.0 or higher for IAM Authentication"
  type        = string
  default     = "7.0"
}

variable "parameter_group_name" {
  description = "The name of the parameter group to associate with this replication group"
  type        = string
  default     = "default.redis7"
}

variable "num_cache_clusters" {
  description = "Total number of cache clusters (primary + replicas). Minimum 2 for Multi-AZ"
  type        = number
  default     = 1
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ and automatic failover"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
