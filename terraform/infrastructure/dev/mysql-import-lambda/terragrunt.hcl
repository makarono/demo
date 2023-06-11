include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

#find local mysql dump file
locals {
  mysql_import_file = file(find_in_parent_folders("app/mysql/dump.sql"))
}

terraform {
  source = "${find_in_parent_folders("modules/mysql-import-lambda")}///"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  subnet_ids        = dependency.vpc.outputs.private_subnets
  security_group_id = dependency.mysql-import-lambda.outputs.id
  mysql_import_file = local.mysql_import_file
  component         = include.env.locals.component
  env               = include.env.locals.env
  tags              = include.env.locals.tags
  DB_HOST           = dependency.rds.outputs.mysql_host
  DB_PORT           = dependency.rds.outputs.mysql_port
  DB_USER           = dependency.rds.outputs.user
  DB_PASSWORD       = dependency.rds.outputs.password
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnets = ["subnet-11111", "subnet-2222"]
  }
}

dependency "rds" {
  config_path = "../rds"
  mock_outputs = {
    mysql_host = "example-db.abc123xyz.us-west-2.rds.amazonaws.com"
    mysql_port = "3306"
    password   = "jksda"
    user       = "sad"
  }
}

dependency "mysql-import-lambda" {
  config_path = "../security-groups/mysql-import-lambda"
  mock_outputs = {
    id = "sg-xxxxxxx"
  }
}
