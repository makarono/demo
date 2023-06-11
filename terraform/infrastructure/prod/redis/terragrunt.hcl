include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/redis")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_id                     = dependency.vpc.outputs.vpc_id
  subnet_ids                 = dependency.vpc.outputs.private_subnets
  current_ip_address_cidr    = dependency.tools.outputs.current_ip_address_cidr
  security_group_id          = dependency.redis-sg.outputs.id
  component                  = include.env.locals.component
  env                        = include.env.locals.env
  tags                       = include.env.locals.tags
  instance_type              = "cache.t4g.medium"
  snapshot_retention_limit   = 30
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false #TODO change application in ecs to work with tls
  automatic_failover_enabled = true
  enable_autoscaling         = true
  multi_az_enabled           = true
  min_capacity               = 1
  max_capacity               = 10
  target_value               = 75.0
  scale_in_cooldown          = 90
  scale_out_cooldown         = 90
  apply_immediately          = false
  port                       = "6379"
  maintenance_window         = "sun:04:00-sun:05:00"
  snapshot_window            = "06:00-07:00"
  cluster_mode_enabled       = true
  cluster_mode_num_node_groups            = 2
  cluster_mode_replicas_per_node_group    = 1
}

dependency "tools" {
  config_path = "../tools"
  mock_outputs = {
    current_ip_address_cidr = "1.1.1.1/32"
  }
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id          = "vpc-xxxxxxx"
    private_subnets = ["subnet-11111", "subnet-2222"]
  }
}

dependency "redis-sg" {
  config_path = "../security-groups/redis"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}
