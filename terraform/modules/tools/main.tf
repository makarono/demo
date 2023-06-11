resource "random_string" "default" {
  length  = 14
  special = false
  upper   = false
  lower   = true
  numeric  = true
}