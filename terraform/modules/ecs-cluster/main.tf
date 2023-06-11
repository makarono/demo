#cloudmap dns
resource "aws_service_discovery_private_dns_namespace" "default" {
  name = format("%s%s.ecs", var.component, var.env)
  vpc = var.vpc_id
  tags = var.tags
}

resource "aws_ecs_cluster" "default" {
  name = format("%s-%s", var.component, var.env)
  tags = var.tags

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.default.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags_all = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name = aws_ecs_cluster.default.name
  capacity_providers = var.capacity_providers

  #default_capacity_provider_strategy {
  #  base              = 1
  #  weight            = 100
  #  capacity_provider = var.capacity_providers[0]
  #}
}

resource "aws_iam_role" "default" {
  name = format("%s-%s-ecs-cluster-role", var.component, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["ecs.amazonaws.com"] }
      Action    = ["sts:AssumeRole"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "default" {
  name = format("%s-%s-ecs-cluster-policy", var.component, var.env)
  tags = var.tags
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:AttachNetworkInterface",
        "ec2:CreateNetworkInterface",
        "ec2:CreateNetworkInterfacePermission",
        "ec2:DeleteNetworkInterface",
        "ec2:DeleteNetworkInterfacePermission",
        "ec2:Describe*",
        "ec2:DetachNetworkInterface",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "default_policy_attachment" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}
