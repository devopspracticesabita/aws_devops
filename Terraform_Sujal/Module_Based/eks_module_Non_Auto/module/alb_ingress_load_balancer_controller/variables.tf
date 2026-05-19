variable "role_name" {
  type        = string
  description = "Name of the IAM Role"
}

variable "lbc_policy_json" {
  type        = string
  description = "The JSON content of the AWS Load Balancer Controller IAM policy"
}

variable "clusters" {
  type        = list(string)
  description = "List of EKS cluster names for the association"
}

variable "alb_ingress_namespace" {
  type    = string
  default = "kube-system"
}

variable "alb_ingress_service_account" {
  type    = string
  default = "aws-load-balancer-controller"
}