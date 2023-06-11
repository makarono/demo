locals {
  env = "dev"
  component = "demo"
  tags = { env = local.env, component = local.component }
}