
data "aws_db_instance" "mysql" {
  db_instance_identifier = aws_db_instance.mysql.identifier
}

output "password" {
  value = aws_db_instance.mysql.password
  sensitive   = true
}

output "user" {
  value = aws_db_instance.mysql.username
  sensitive   = true
}

output "mysql_endpoint" {
  value = data.aws_db_instance.mysql.address
}

output "mysql_host" {
  description = "RDS instance host"
  value       = local.host
  sensitive   = true
}

output "mysql_port" {
  description = "RDS instance port"
  value       = local.port
}
