include "env" {
  path = find_in_parent_folders("env.hcl")
  expose = true
  merge_strategy = "no_merge"
}

terraform {
  source = "${find_in_parent_folders("modules/tools")}///"
}

include "root" {
  path = find_in_parent_folders()
}