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
  version               = "v2.1.0"
  attributes            = ["ecs-service-producer-${include.env.locals.env}"]
  create_before_destroy = true

  # Allow unlimited egress
  allow_all_egress = true
  vpc_id           = dependency.vpc.outputs.vpc_id
  tags             = include.env.locals.tags
  rules = [
    {
      source_security_group_id = dependency.alb-sg.outputs.id
      key                      = "HTTP"
      type                     = "ingress"
      from_port                = "80"
      to_port                  = "80"
      protocol                 = "tcp"
      self                     = false
      description              = "Allow access from ALB to services"
    },
  ]

}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    vpc_id = "vpc-xxxxxxx"
  }
}

dependency "alb-sg" {
  config_path = "../alb"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}
