include "env" {
  path = find_in_parent_folders("env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/ecr")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  repository_names = ["producer", "consumer-go"]
  force_delete = false
  component = include.env.locals.component
  env = include.env.locals.env
  tags = include.env.locals.tags
}
