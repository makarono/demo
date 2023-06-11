output "password" {
  value     = "AAAAA-password"
  sensitive = true
}

output "user" {
  value     = "74352USER"
  sensitive = true
}

output "mysql_endpoint" {
  value = "example-db.abc123xyz.us-west-2.rds.amazonaws.com"
}

output "mysql_host" {
  description = "RDS instance host"
  value       = "example-db.abc123xyz.us-west-2.rds.amazonaws.com"
  sensitive   = true
}

output "mysql_port" {
  description = "RDS instance port"
  value       = "3306"
  sensitive   = true
}