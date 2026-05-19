output "iam_role_arn" {
  description = "The ARN of the IAM role for the aws-cli pod"
  value       = aws_iam_role.this.arn
}