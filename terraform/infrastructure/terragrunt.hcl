locals {
aws_region = get_env("AWS_DEFAULT_REGION")
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}

terraform {
  required_version = ">= 1.4.6"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5"
    }
  }
}
EOF
}

#remote_state {
#  backend = "local"
#  config = {
#    path = "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/terraform.tfstate"
#  }
#
#  generate = {
#    path = "backend.tf"
#    if_exists = "overwrite"
#  }
#}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "tfstate-filesx-${get_aws_account_id()}-${local.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${local.aws_region}"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dynamo-${local.aws_region}"
  }
}