include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/alb")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_id                  = dependency.vpc.outputs.vpc_id
  subnet_ids              = dependency.vpc.outputs.public_subnets
  current_ip_address_cidr = dependency.tools.outputs.current_ip_address_cidr
  security_group_id       = dependency.alb-sg.outputs.id
  component               = include.env.locals.component
  env                     = include.env.locals.env
  tags                    = include.env.locals.tags
  application             = "pronova"
  port                    = 80

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
    vpc_id         = "vpc-xxxxxxx"
    public_subnets = ["subnet-11111", "subnet-2222"]
  }
}

dependency "alb-sg" {
  config_path = "../security-groups/alb"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}
