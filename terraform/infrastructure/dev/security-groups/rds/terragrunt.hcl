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
  attributes = ["mysql-${include.env.locals.env}"]
  create_before_destroy = true

  # Allow unlimited egress
  allow_all_egress = true
  vpc_id           = dependency.vpc.outputs.vpc_id
  tags             = include.env.locals.tags

  rule_matrix = [
    # Allow any of these security groups or the specified prefixes to access MySQL
    {
      source_security_group_ids = [dependency.ecs-svc-producer.outputs.id, dependency.ecs-svc-consumer-go.outputs.id, dependency.mysql-import-lambda.outputs.id]
      rules = [
        {
          key         = "mysql"
          type        = "ingress"
          from_port   = 3306
          to_port     = 3306
          protocol    = "tcp"
          description = "Allow MySQL access from trusted security groups"
        }
      ]
    }
  ]

}

dependency "vpc" {
  config_path = "../../vpc"
  mock_outputs = {
    vpc_id = "vpc-xxxxxxx"
  }
}

dependency "ecs-svc-producer" {
  config_path = "../ecs-svc-producer"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}

dependency "ecs-svc-consumer-go" {
  config_path = "../ecs-svc-consumer-go"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}

dependency "mysql-import-lambda" {
  config_path = "../mysql-import-lambda"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}