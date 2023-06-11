include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/ecs-cluster")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  capacity_providers = ["FARGATE"]
  component          = include.env.locals.component
  env                = include.env.locals.env
  tags               = include.env.locals.tags
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id          = "vpc-xxxxxxx"
    private_subnets = ["subnet-11111", "subnet-2222"]
  }
}
