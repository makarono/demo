locals {
  env = "test"
  component = "demo"
  tags = { env = local.env, component = local.component }
}