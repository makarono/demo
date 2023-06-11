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
  vpc_cidr        = "10.10.10.0/24"
  public_subnets  = ["10.10.10.0/26", "10.10.10.64/26"]
  private_subnets = ["10.10.10.128/26", "10.10.10.192/26"]
  component       = include.env.locals.component
  env             = include.env.locals.env
  tags            = include.env.locals.tags
}