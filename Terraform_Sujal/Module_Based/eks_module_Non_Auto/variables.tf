# Last Priority
# --------------------------------------------------------
# AWS Region (used in provider block)
# --------------------------------------------------------
# Last Priority
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_newbits" {
  description = "Number of new bits to add to VPC CIDR to generate subnets (e.g., 8 means /24 from /16)"
  type        = number
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

# --------------------------------------------------------
# Environment & Business Division Info
# --------------------------------------------------------

# Logical environment name (used in tags and resource names)
variable "environment_name" {
  description = "Environment name used in resource names and tags"
  type        = string
}

# Business unit or department (used in tags and naming)
variable "business_division" {
  description = "Business Division in the large organization this infrastructure belongs to"
  type        = string
}

# --------------------------------------------------------
# EKS Cluster Configuration
# --------------------------------------------------------

# Name of the EKS cluster (used in names, tags, and references)
variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources."
  type        = string
}

# Kubernetes version for the EKS control plane
variable "cluster_version" {
  description = "Kubernetes minor version to use for the EKS cluster (e.g. 1.28, 1.29)"
  type        = string
}

# Defines the range of private IP addresses from which Kubernetes assigns virtual IPs to its Services (e.g., ClusterIPs).
variable "cluster_service_ipv4_cidr" {
  description = "Service CIDR range for Kubernetes services. Optional — leave null to use AWS default."
  type        = string
}

# Enable access to the EKS API via private endpoint
variable "cluster_endpoint_private_access" {
  description = "Whether to enable private access to EKS control plane endpoint"
  type        = bool
}

# Enable access to the EKS API via public endpoint
variable "cluster_endpoint_public_access" {
  description = "Whether to enable public access to EKS control plane endpoint"
  type        = bool
}

# List of CIDRs allowed to reach the public EKS API endpoint
variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access public EKS endpoint"
  type        = list(string)
}

# --------------------------------------------------------
# Common Tags
# --------------------------------------------------------

# Tags applied to all resources created by this configuration
variable "tags" {
  description = "Tags to apply to EKS and related resources"
  type        = map(string)
}

# --------------------------------------------------------
# EKS Node Group Configuration
# --------------------------------------------------------

# EC2 instance types for worker nodes
variable "node_instance_types" {
  description = "List of EC2 instance types for the node group"
  type        = list(string)
}

# Capacity type for node group (ON_DEMAND or SPOT)
variable "node_capacity_type" {
  description = "Instance capacity type: ON_DEMAND or SPOT"
  type        = string
}

# Root volume size (GiB) for worker nodes
variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
}

variable "namespace" {
  type    = string
}

variable "service_account" {
  type    = string
}

variable "ebs_namespace" {
  type    = string
}

variable "ebs_service_account" {
  type    = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
}

variable "create_read_replica" {
  description = "Whether to create a read replica"
  type        = bool
}

variable "instance_class" {
  description = "DB instance size"
  type        = string
}

variable "max_allocated_storage" {
  description = "The upper limit to which RDS can automatically scale the storage (e.g., 100 GB)"
  type        = number
}

variable "deletion_protection" {
  description = "Enables deletion protection for the DynamoDB table"
  type        = bool
}

variable "table_name" {
  type        = string
  description = "The name of the DynamoDB table"
}

variable "hash_key" {
  type        = string
  description = "The Partition Key name"
}

variable "hash_key_type" {
  type    = string
}

variable "postgres_instance_class" {
  description = "Postgres instance size"
  type        = string
}

variable "db_secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
}

variable "redis_version" {
  description = "Redis engine version. MUST be 7.0 or higher for IAM Authentication"
  type        = string
}

variable "node_type" {
  description = "The instance class for the Redis nodes (e.g., cache.t3.medium)"
  type        = string
}

variable "num_cache_clusters" {
  description = "Total number of cache clusters (primary + replicas). Minimum 2 for Multi-AZ"
  type        = number
}

variable "parameter_group_name" {
  description = "The name of the parameter group to associate with this replication group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "The SSH key pair name to access the instance"
  type        = string
}

# SageMaker Specific Variables
variable "dr_region" {
  type    = string
}

variable "sagemaker_vpc_cidr" {
  type    = string
}

variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
}

variable "ecr_repo_name" {
  description = "ecr repo name"
}