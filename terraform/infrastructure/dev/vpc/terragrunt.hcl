include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/vpc")}///"
  #source = "${find_in_parent_folders("modules/test-vpc")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  vpc_cidr        = "192.168.101.0/24"
  public_subnets  = ["192.168.101.0/28", "192.168.101.16/28"]
  private_subnets = ["192.168.101.32/28", "192.168.101.48/28"]
  component       = include.env.locals.component
  env             = include.env.locals.env
  tags            = include.env.locals.tags
}
