output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  value = values(aws_subnet.public_subnet)[*].id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value = values(aws_subnet.private_subnet)[*].id
  description = "List of public subnet IDs"
}

output "public_subnet_map" {
  value       = { for az, subnet in aws_subnet.public_subnet : az => subnet.id }
  description = "Map of AZ to Public Subnet IDs"
}