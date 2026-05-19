variable "role_name" {
  type        = string
  description = "Name of the IAM Role"
}

variable "clusters" {
  type        = list(string)
  description = "List of EKS cluster names for the association"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "efs_namespace" {
  type    = string
  default = "kube-system"
}

variable "service_account" {
  type    = string
  default = "aws-cli-sa"
}

variable "efs_service_account" {
  type    = string
  default = "efs-csi-controller-sa"
}

variable "kubernetes_version" {
  type        = string
  description = "The K8s version from the EKS cluster"
}

variable "csi_driver_status" {
  description = "The status of the CSI Secrets Store Helm release"
  type        = string
}

#variable "dynamodb_table_arn" {
# description = "The ARN of the DynamoDB table created in the other module"
# type        = string
#}

variable "dynamodb_service_account" {
  type    = string
  default = "carts"
}