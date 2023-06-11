#Password
resource "random_password" "defult" {
  length           = 24
  special          = true
  override_special = "_!%^"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

resource "aws_secretsmanager_secret" "password" {
  name = format("%s-%s-redis-password-%s", var.component, var.env, random_string.suffix.result)
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = random_password.defult.result
}


resource "aws_elasticache_subnet_group" "default" {
  name       = format("%s-%s", var.component, var.env)
  subnet_ids = var.subnet_ids

  tags        = var.tags
  description = "Subnet group for the Redis instance"
}

resource "aws_security_group" "default" {
  count       = var.security_group_id == "" ? 1 : 0
  name        = format("%s-%s-redis-sg", var.component, var.env)
  description = "Security group for the Redis instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "redis access from internet"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = var.port
    protocol    = "tcp"
    to_port     = var.port
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


resource "aws_elasticache_replication_group" "default" {
  replication_group_id       = format("%s-%s", var.component, var.env)
  description                = format("Redis instance for %s %s", var.component, var.env)
  automatic_failover_enabled = var.cluster_mode_enabled ? true : var.automatic_failover_enabled
  num_cache_clusters         = var.cluster_mode_enabled ? null : var.num_cache_clusters
  multi_az_enabled           = var.multi_az_enabled
  node_type                  = var.instance_type
  engine_version             = var.engine_version
  subnet_group_name          = aws_elasticache_subnet_group.default.name
  security_group_ids         = var.security_group_id != "" ? [var.security_group_id] : [aws_security_group.default[0].id]
  maintenance_window         = var.maintenance_window
  snapshot_window            = var.snapshot_window
  snapshot_retention_limit   = var.snapshot_retention_limit
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  apply_immediately          = var.apply_immediately
  parameter_group_name       = var.cluster_mode_enabled ? format("%s.cluster.on", var.parameter_group_name) : var.parameter_group_name
  num_node_groups            = var.cluster_mode_enabled ? var.cluster_mode_num_node_groups : null
  replicas_per_node_group    = var.cluster_mode_enabled ? var.cluster_mode_replicas_per_node_group : null
  tags                       = var.tags
}

#data "aws_caller_identity" "current" {}
#
#resource "aws_appautoscaling_target" "default" {
#  count = var.enable_autoscaling ? 1 : 0
#
#  service_namespace  = "elasticache"
#  scalable_dimension = "elasticache:replication-group:Replicas"
#  resource_id        = "replication-group/${aws_elasticache_replication_group.default.id}"
#  min_capacity       = var.min_capacity
#  max_capacity       = var.max_capacity
#  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
#}

#resource "aws_appautoscaling_policy" "default" {
#  count = var.enable_autoscaling ? 1 : 0
#
#  name               = format("%s-%s-redis-auto-scaling-policy", var.component, var.env)
#  service_namespace  = "elasticache"
#  scalable_dimension = "elasticache:replication-group:Replicas"
#  resource_id        = "replication-group/${aws_elasticache_replication_group.default.id}"
#  policy_type        = "TargetTrackingScaling"
#
#  target_tracking_scaling_policy_configuration {
#    predefined_metric_specification {
#      predefined_metric_type = "RedisReplicationGroupAvailableMemory"
#    }
#    target_value       = var.target_value
#    scale_in_cooldown  = var.scale_in_cooldown
#    scale_out_cooldown = var.scale_out_cooldown
#  }
#}
