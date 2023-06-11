locals {
  env = "prod"
  component = "super"
  tags = { env = local.env, component = local.component }
}