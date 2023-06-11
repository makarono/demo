include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/rds")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_id                  = dependency.vpc.outputs.vpc_id
  subnet_ids              = dependency.vpc.outputs.private_subnets
  current_ip_address_cidr = dependency.tools.outputs.current_ip_address_cidr
  security_group_id       = dependency.rds-sg.outputs.id
  component               = include.env.locals.component
  env                     = include.env.locals.env
  tags                    = include.env.locals.tags
  instance_class          = "db.t2.micro"
  backup_retention_period = 1
  multi_az_enabled        = false
  monitoring_interval     = 0
  storage_autoscaling     = false
  max_allocated_storage   = 20
  publicly_accessible     = false
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

dependency "rds-sg" {
  config_path = "../security-groups/rds"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}
