locals {
  aws_region = get_env("AWS_DEFAULT_REGION")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/ecs-service")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_id              = dependency.vpc.outputs.vpc_id
  subnet_ids          = dependency.vpc.outputs.private_subnets
  public_subnets_cidr = dependency.vpc.outputs.public_subnets_cidr
  security_group_id   = dependency.ecs-svc-consumer-go-sg.outputs.id
  ecs_cluster_id      = dependency.ecs_cluster.outputs.cluster_name
  dns_namespace_id    = dependency.ecs_cluster.outputs.dns_namespace_id
  aws_region          = "${local.aws_region}"
  family              = "consumer-task-family"
  task_cpu            = "512"
  task_memory         = "1024"
  image_tag           = "latest"
  image_name          = "${get_aws_account_id()}.dkr.ecr.${local.aws_region}.amazonaws.com/consumer-go"
  application         = "consumer-go"
  desired_count       = 2
  deployment_minimum_healthy_percent = 25
  enable_autoscaling = false
#deployment_minimum_healthy_percent = 25
#deployment_maximum_percent = 200
#security_group_id = ""
#enable_autoscaling = false
#autoscaling_max_capacity = 10
#autoscaling_min_capacity = 1
#auto_scaling_memory_target_value = 80
#auto_scaling_cpu_target_value = 60
  component           = include.env.locals.component
  env                 = include.env.locals.env
  tags                = include.env.locals.tags
  container_environment = {
    REDIS_HOST  = dependency.redis.outputs.primary_endpoint_address
    REDIS_PORT  = "6379"
    REDIS_QUEUE = "demo_queue"
    DB_HOST     = dependency.rds.outputs.mysql_host
    DB_PORT     = dependency.rds.outputs.mysql_port
    DB_USER     = dependency.rds.outputs.user
    DB_PASSWORD = dependency.rds.outputs.password
    DB_NAME     = "count"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id              = "vpc-xxxxxxx"
    private_subnets     = ["subnet-11111", "subnet-2222"]
    public_subnets_cidr = ["1.1.1.1/32", "1.1.1.1/32"]
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    alb_target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-target-group/abcdefg12345678"
  }
}

dependency "ecs_cluster" {
  config_path = "../ecs-cluster"
  mock_outputs = {
    cluster_id       = "xxxxxxxxxx"
    cluster_name     = "xxxxxxxxxx"
    dns_namespace_id = "ns-1111hhhhhh"
  }
}

dependency "rds" {
  config_path = "../rds"
  mock_outputs = {
    mysql_host = "example-db.abc123xyz.us-west-2.rds.amazonaws.com"
    mysql_port = "3306"
    password   = "jksda"
    user       = "sad"
  }
}

dependency "redis" {
  config_path = "../redis"
  mock_outputs = {
    primary_endpoint_address = "example-cluster.abc123.0001.usw2.cache.amazonaws.com"
  }
}

dependency "ecs-svc-consumer-go-sg" {
  config_path = "../security-groups/ecs-svc-consumer-go"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}
