# Use account ID and region if provided, or fetch dynamically if empty
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id          = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.current.account_id
  aws_region          = var.aws_region != "" ? var.aws_region : data.aws_region.current.name
  docker_image_prefix = format("%s.dkr.ecr.%s.amazonaws.com", local.account_id, local.aws_region)
  public_subnets_cidr = var.current_ip_address_cidr != "" ? flatten([var.current_ip_address_cidr, [var.public_subnets_cidr]]) : var.public_subnets_cidr
}

resource "aws_security_group" "default" {
  count  = var.security_group_id == "" ? 1 : 0
  name   = format("%s-%s-%s-ecs-task", var.component, var.env, var.application)
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.port
    to_port     = var.port
    cidr_blocks = local.public_subnets_cidr
    description = "access from load balancer"
  }

  ingress {
    description = "Ingress from other containers in the same security group"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    self        = true
  }


  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_cloudwatch_log_group" "default" {
  name              = format("ecs/%s-%s-%s", var.component, var.env, var.application)
  retention_in_days = 1
  tags              = var.tags
}


resource "aws_ecs_task_definition" "default" {
  network_mode             = "awsvpc"
  family                   = var.family
  requires_compatibilities = var.requires_compatibilities
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  container_definitions = jsonencode([{
    name      = format("%s-%s-%s", var.component, var.env, var.application)
    image     = var.image_name
    image_tag = var.image_tag
    essential = true
    environment = [
      for key, value in var.container_environment : {
        name  = key
        value = tostring(value)
      }
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.port
      hostPort      = var.port
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.default.name
        awslogs-region        = local.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
  lifecycle {
    ignore_changes = [
      cpu,
      memory,
      tags,
      execution_role_arn,
      container_definitions,
      requires_compatibilities,
    ]
  }
  tags = var.tags
}

output "image_name" {
  value = aws_ecs_task_definition.default.container_definitions
}



resource "aws_iam_role" "task_role" {
  name = format("%s-%s-%s-ecs-task-role", var.component, var.env, var.application)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["ecs-tasks.amazonaws.com"] }
      Action    = ["sts:AssumeRole"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "task_policy" {
  name = format("%s-%s-%s-ecs-task-policy", var.component, var.env, var.application)
  tags = var.tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "servicediscovery:DiscoverInstances",
        ]
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.default.arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role" "execution_role" {
  name = format("%s-%s-%s-ecs-task-execution-role", var.component, var.env, var.application)

  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "ecs-tasks.amazonaws.com"
    },
    "Effect": "Allow"
  }
]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_service" "default" {
  name                               = format("%s-%s-%s", var.component, var.env, var.application)
  cluster                            = var.ecs_cluster_id
  task_definition                    = aws_ecs_task_definition.default.arn
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  network_configuration {
    security_groups  = var.security_group_id != "" ? [var.security_group_id] : [aws_security_group.default[0].id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  #if alb_target_group_arn has value connect it to load balancer
  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = format("%s-%s-%s", var.component, var.env, var.application)
      container_port   = var.port
    }
  }

  service_registries {
    registry_arn = aws_service_discovery_service.default.arn
    port         = var.port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  tags       = var.tags
  depends_on = [aws_service_discovery_service.default]
}

resource "aws_service_discovery_service" "default" {
  name        = var.application
  description = format("Discovery Service for ECSService: %s-%s-%s", var.component, var.env, var.application)
  dns_config {
    namespace_id   = var.dns_namespace_id
    routing_policy = "WEIGHTED"
    dns_records {
      ttl  = 60
      type = "A"
    }
    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 2
  }
  tags = var.tags
}

resource "aws_appautoscaling_target" "default" {
  count              = var.enable_autoscaling ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_id}/${aws_ecs_service.default.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
}

resource "aws_appautoscaling_policy" "memory" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = format("%s-%s-%s-memory-autoscaling", var.component, var.env, var.application)
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.default[0].service_namespace
  resource_id        = aws_appautoscaling_target.default[0].resource_id
  scalable_dimension = aws_appautoscaling_target.default[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.auto_scaling_memory_target_value
  }
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = format("%s-%s-%s-cpu-autoscaling", var.component, var.env, var.application)
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.default[0].service_namespace
  resource_id        = aws_appautoscaling_target.default[0].resource_id
  scalable_dimension = aws_appautoscaling_target.default[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.auto_scaling_cpu_target_value
  }
}