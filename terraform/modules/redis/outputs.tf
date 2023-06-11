output "subnet_group_name" {
  value = aws_elasticache_subnet_group.default.name
}

output "replication_group_id" {
  value = aws_elasticache_replication_group.default.id
}

output "primary_endpoint_address" {
  value       = var.cluster_mode_enabled ? join("", aws_elasticache_replication_group.default[*].configuration_endpoint_address) : join("", aws_elasticache_replication_group.default[*].primary_endpoint_address)
  description = "Redis primary or configuration endpoint depending on cluster mode"
}