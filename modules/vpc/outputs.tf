# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.eks_vpc.id
}

# public subnet IDs
output "public_subnet_ids" {
  description = "public subnet IDs"
  value       = aws_subnet.public[*].id
}

# private subnet IDs
output "private_subnet_ids" {
  description = "private subnet IDs"
  value       = aws_subnet.private[*].id
}