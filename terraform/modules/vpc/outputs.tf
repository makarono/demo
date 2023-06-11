output "vpc_id" {
  description = "The ID of the VPC that this stack is deployed in"
  value       = aws_vpc.default.id
}

output "public_subnets" {
  description = "Public subnets list"
  value = aws_subnet.public.*.id
}

output "private_subnets" {
  description = "Private subnets list"
  value = aws_subnet.private.*.id
}

output "public_subnets_cidr" {
  description = "Private subnets cidr list"
  value       = aws_subnet.public.*.cidr_block
}

output "private_subnets_cidr" {
  description = "Private subnets cidr list"
  value       = aws_subnet.private.*.cidr_block
}


