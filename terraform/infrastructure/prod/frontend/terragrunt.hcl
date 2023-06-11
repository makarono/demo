
include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

locals {
  aws_region = get_env("AWS_DEFAULT_REGION")
  #find local frontend env file for correct environment
  frontend_env_file = find_in_parent_folders("app/frontend/.env.${include.env.locals.env}")
}

terraform {
  source = "${find_in_parent_folders("modules/frontend")}///"

  after_hook "bucket_name" {
    commands     = ["apply", "plan"]
    execute      = ["sh", "-c", "echo frontendx-${get_aws_account_id()}-${local.aws_region}-${include.env.locals.env}"]
    run_on_error = false
  }

  after_hook "write_api_endpoint" {
    commands     = ["apply", "plan"]
    execute      = ["sh", "-c", "echo \"REACT_APP_BACKEND_ENDPOINT='${dependency.alb.outputs.lb_endpoint}/count'\" > ${local.frontend_env_file} && cat ${local.frontend_env_file}"]
    run_on_error = false
  }

}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  bucket_name = "frontendx-${get_aws_account_id()}-${local.aws_region}-${include.env.locals.env}"
  component   = include.env.locals.component
  env         = include.env.locals.env
  tags        = include.env.locals.tags
}


dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    lb_endpoint = "http://test.com"
  }
}


