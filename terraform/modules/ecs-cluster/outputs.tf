output "cluster_arn" {
  value = aws_ecs_cluster.default.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.default.name
}

output "cluster_id" {
  value = aws_ecs_cluster.default.id
}

output "dns_namespace" {
  value = aws_service_discovery_private_dns_namespace.default.name
}

output "dns_namespace_id" {
  value = aws_service_discovery_private_dns_namespace.default.id
}

output "dns_arn" {
  value = aws_service_discovery_private_dns_namespace.default.arn
}



