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
  instance_type              = "cache.t2.micro"
  snapshot_retention_limit   = 0
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false
  automatic_failover_enabled = false
  num_cache_clusters         = 1
  enable_autoscaling         = false
  multi_az_enabled           = false
  apply_immediately          = true
  port                       = "6379"
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
