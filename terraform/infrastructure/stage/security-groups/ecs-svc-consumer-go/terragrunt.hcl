include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

include "root" {
  path = find_in_parent_folders()
}

include {
  path = "../module.hcl"
}


inputs = {
  version    = "v2.1.0"
  attributes = ["ecs-service-consumer-go-${include.env.locals.env}"]
  create_before_destroy = true

  # Allow unlimited egress
  allow_all_egress = true
  vpc_id           = dependency.vpc.outputs.vpc_id
  tags             = include.env.locals.tags
}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    vpc_id          = "vpc-xxxxxxx"
  }
}