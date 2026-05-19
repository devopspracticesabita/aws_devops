# In the root outputs.tf (outside the module folder)
output "final_role_arn" {
  value = module.pod_identity_secret_manager_ebs_csi_driver.iam_role_arn
}

output "final_lbc_iam_role_arn" {
  description = "The ARN of the IAM role for the LBC"
  value       = module.alb_ingress_load_balancer_controller.lbc_iam_role_arn
}

output "final_lbc_iam_role_name" {
  description = "The name of the IAM role for the LBC"
  value       = module.alb_ingress_load_balancer_controller.lbc_iam_role_name
}

output "lbc_helm_release_name" {
  description = "The name of the Helm release for the LBC"
  value       = helm_release.aws_lbc.name
}

output "lbc_helm_release_status" {
  description = "The status of the Helm release"
  value       = helm_release.aws_lbc.status
}

output "lbc_helm_metadata" {
  description = "Metadata for the deployed LBC chart"
  value       = helm_release.aws_lbc.metadata
}

output "cart_dynamodb_table_arn" {
  description = "The ARN of the Cart DynamoDB table"
  value       = module.app_db.table_arn
}

output "cart_dynamodb_table_id" {
  description = "The name (ID) of the Cart DynamoDB table"
  value       = module.app_db.table_id
}

output "cart_dynamodb_table_stream_arn" {
  description = "The ARN of the Cart Table Stream (if enabled)"
  value       = module.app_db.table_stream_arn
}

output "aws_region" {
  value = var.aws_region
}

output "dynamodb_table_name" {
  value = module.app_db.table_name
}

# output "ecr_repository_url" {
#   description = "The URL of the ECR repository"
#   value       = module.my_ecr_repo.repository_url
# }

# output "ecr_repository_arn" {
#   description = "The ARN of the ECR repository"
#   value       = module.my_ecr_repo.repository_arn
# }
