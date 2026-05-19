# Output the bucket name (ID)
output "s3_bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.my_bucket.id
}

# Output the bucket ARN (Amazon Resource Name)
output "s3_bucket_arn" {
  description = "The ARN of the bucket. Format: arn:aws:s3:::bucketname"
  value       = aws_s3_bucket.my_bucket.arn
}

# Output the bucket regional domain name (useful for CloudFront origins)
output "s3_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name."
  value       = aws_s3_bucket.my_bucket.bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "The bucket's region."
  value       = aws_s3_bucket.my_bucket.region
}

