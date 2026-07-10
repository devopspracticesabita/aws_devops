variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the repository"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  default = "ap-south-2"
}

variable "github_org" {
  type = string
  default = "devopspracticesabita"
}

variable "github_repo" {
  type = string
  default = "aws_devops"
}

variable "ecr_repo_name" {
  default = "retail-store/ui"
}