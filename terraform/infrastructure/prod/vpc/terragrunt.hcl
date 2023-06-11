include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/vpc")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_cidr        = "172.16.0.0/24"
  public_subnets  = ["172.16.0.0/26", "172.16.0.64/26"]
  private_subnets = ["172.16.0.128/26", "172.16.0.192/26"]
  component       = include.env.locals.component
  env             = include.env.locals.env
  tags            = include.env.locals.tags
}