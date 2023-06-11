# Outputs
output "private_subnet_1_id" {
  description = "ID of Default Private Subnet 1"
  value       = aws_default_subnet.default_private_subnet_1.id
}

output "private_subnet_2_id" {
  description = "ID of Default Private Subnet 2"
  value       = aws_default_subnet.default_private_subnet_2.id
}

output "vpc_id" {
  description = "ID of Default VPC"
  value       = aws_default_vpc.vpc.id
}

output "private_subnet_1_cidr" {
  description = "CIDR block of Default Private Subnet 1"
  value       = aws_default_subnet.default_private_subnet_1.cidr_block
}

output "private_subnet_2_cidr" {
  description = "CIDR block of Default Private Subnet 2"
  value       = aws_default_subnet.default_private_subnet_2.cidr_block
}

#FAKE used only for testing
output "public_subnet_1_id" {
  description = "ID of Default Pubrlic Subnet 1"
  value       = aws_default_subnet.default_private_subnet_1.id
}

output "public_subnet_2_id" {
  description = "ID of Default Pubrlic Subnet 2"
  value       = aws_default_subnet.default_private_subnet_2.id
}

output "public_subnet_1_cidr" {
  description = "CIDR block of Default Public Subnet 1"
  value       = aws_default_subnet.default_private_subnet_1.cidr_block
}

output "public_subnet_2_cidr" {
  description = "CIDR block of Default Public Subnet 2"
  value       = aws_default_subnet.default_private_subnet_2.cidr_block
}

output "public_subnets" {
  description = "Private subnets list"
  value       = [aws_default_subnet.default_private_subnet_1.id, aws_default_subnet.default_private_subnet_2.id]
}

output "private_subnets" {
  description = "Private subnets list"
  value       = [aws_default_subnet.default_private_subnet_1.id, aws_default_subnet.default_private_subnet_2.id]
}

output "public_subnets_cidr" {
  description = "Private subnets cidr list"
  value       = [aws_default_subnet.default_private_subnet_1.cidr_block, aws_default_subnet.default_private_subnet_2.cidr_block]
}

output "private_subnets_cidr" {
  description = "Private subnets cidr list"
  value       = [aws_default_subnet.default_private_subnet_1.cidr_block, aws_default_subnet.default_private_subnet_2.cidr_block]
}