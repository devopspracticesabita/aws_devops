variable "tags" {
  description = "Tags to apply to EKS and related resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}

variable "environment_name" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

# Business unit or department (used in tags and naming)
variable "business_division" {
  description = "Business Division in the large organization this infrastructure belongs to"
  type        = string
  default     = "retail"
}

variable "private_subnets_map" {
  type        = map(string)
  description = "Map of AZ names to private subnet IDs"
}

variable "vpc_id" {
  type = string
  description = "The target VPC ID where EFS targets will mount"
}

variable "karpenter_node_sg_id" {
  type        = string
  description = "Security Group ID of the Karpenter worker nodes to allow NFS ingress traffic"
}