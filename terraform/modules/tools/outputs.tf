output "random_name" {
  value = random_string.default.result
  description = "returns random string"
}