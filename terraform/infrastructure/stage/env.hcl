locals {
  env = "stage"
  component = "demo"
  tags = { env = local.env, component = local.component }
}