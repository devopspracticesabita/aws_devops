output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the created VPC"
}

output "public_subnet_ids" {
  #value = values(aws_subnet.public_subnet)[*].id
  #value       = [for s in aws_subnet.public_subnet : s.id]
  value       = { for az, subnet in aws_subnet.public_subnet : az => subnet.id }
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  #value = values(aws_subnet.private_subnet)[*].id
  value = [for s in aws_subnet.private_subnet : s.id]
  #value = { for az, subnet in aws_subnet.private_subnet : az => subnet.id }
  description = "List of public subnet IDs"
}

output "public_subnets_map" {
  value       = { for az, subnet in aws_subnet.public_subnet : az => subnet.id }
  description = "Map of AZ to Public Subnet IDs"
}

output "private_subnets_map" {
  description = "Map of AZ names to private subnet IDs"
  value       = { for az, subnet in aws_subnet.private_subnet : az => subnet.id }
}

output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}