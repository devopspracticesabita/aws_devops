variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnet_id" {
  description = "The public subnet ID to launch the instance in"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "environment_name" {
  description = "Environment name used for tagging"
  type        = string
}

variable "key_name" {
  description = "The SSH key pair name to access the instance"
  type        = string
  default     = "sujal_ubuntu"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}