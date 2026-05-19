variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the SageMaker domain"
  type        = list(string)
}

variable "environment_name" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-south-2"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sagemaker_region" {
  type    = string
  default = "ap-south-1"
}