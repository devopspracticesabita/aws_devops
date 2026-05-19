output "lbc_iam_role_arn" {
  description = "The ARN of the IAM role for the LBC"
  value       = aws_iam_role.lbc.arn
}

output "lbc_iam_role_name" {
  description = "The name of the IAM role for the LBC"
  value       = aws_iam_role.lbc.name
}