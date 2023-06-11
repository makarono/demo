locals {
  host_and_port = split(":", aws_db_instance.mysql.endpoint)
  host          = local.host_and_port[0]
  port          = local.host_and_port[1]
}

#Password
resource "random_password" "password" {
  length           = 24
  special          = true
  override_special = "_!%^"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}


resource "aws_secretsmanager_secret" "password" {
  name = format("%s-%s-mysql-password-%s", var.component, var.env, random_string.suffix.result)
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = random_password.password.result
}


## Username
resource "random_string" "username" {
  length  = 14
  special = false
  upper   = false
  lower   = true
  numeric = false
}

resource "aws_secretsmanager_secret" "username" {
  name = format("%s-%s-mysql-username-%s", var.component, var.env, random_string.suffix.result)
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "username" {
  secret_id     = aws_secretsmanager_secret.username.id
  secret_string = random_string.username.result
}

resource "aws_security_group" "default" {
  count       = var.security_group_id == "" ? 1 : 0
  name        = format("%s-%s-rds-mysql-sg", var.component, var.env)
  description = "Allow mysql inbound traffic"
  vpc_id      = var.vpc_id

  #if publicly_accessible is true allow only from my current ip
  dynamic "ingress" {
    for_each = var.publicly_accessible ? [1] : []
    content {
      description = "mysql access from current external ip address"
      cidr_blocks = [var.current_ip_address_cidr]
      from_port   = var.port
      protocol    = "tcp"
      to_port     = var.port
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}


## Instance

resource "aws_db_instance" "mysql" {
  identifier = format("%s-%s-mysql", var.component, var.env)
  username   = aws_secretsmanager_secret_version.username.secret_string
  password   = aws_secretsmanager_secret_version.password.secret_string
  # Enable Multi-AZ deployment for high availability
  multi_az = var.multi_az_enabled

  # Enable storage autoscaling with a maximum allocated storage of 40 GB
  allocated_storage     = 20 # Initial storage size
  max_allocated_storage = var.max_allocated_storage

  # Set Enhanced Monitoring interval
  monitoring_interval = var.monitoring_interval > 0 ? var.monitoring_interval : 0
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.monitoring.arn : null


  backup_window               = var.backup_window
  engine                      = var.engine
  engine_version              = var.engine_version
  maintenance_window          = var.maintenance_window
  parameter_group_name        = var.parameter_group_name
  storage_type                = var.storage_type
  backup_retention_period     = var.backup_retention_period
  db_subnet_group_name        = aws_db_subnet_group.default.name
  instance_class              = var.instance_class
  vpc_security_group_ids      = var.security_group_id != "" ? [var.security_group_id] : [aws_security_group.default[0].id]
  allow_major_version_upgrade = var.allow_major_version_upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = var.skip_final_snapshot ? null : format("%s-%s", var.final_snapshot_identifier, random_string.suffix.result)
  publicly_accessible         = var.publicly_accessible
  tags                        = var.tags

  # Print the RDS instance endpoint
  #provisioner "local-exec" {
  #  command = "echo ${aws_db_instance.mysql.endpoint} ${aws_db_instance.mysql.username} ${aws_db_instance.mysql.password} ${aws_db_instance.mysql.port} > ${var.terraform_tmp}/rds_endpoint.txt"
  #}
  depends_on = [aws_secretsmanager_secret_version.username, aws_secretsmanager_secret_version.password]
}

resource "aws_db_subnet_group" "default" {
  name       = format("%s-%s-private-subnet-group", var.component, var.env)
  subnet_ids = var.subnet_ids
}

#load mysql dump from local file if database is publicly accessible
resource "null_resource" "mysql_import" {
  count = var.publicly_accessible ? 1 : 0
  triggers = {
    # Add triggers to re-run the provisioner when the dump file or other dependencies change
    rds_instance_id = aws_db_instance.mysql.id
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/../../../../../../../app/mysql/"
    command     = "mysql -h ${local.host} -P ${local.port} -u ${aws_db_instance.mysql.username} --password=${aws_db_instance.mysql.password} < ./dump.sql"
  }
}

resource "aws_iam_policy" "monitoring" {
  name        = format("%s-%s-rds-enhanced-monitoring", var.component, var.env)
  description = "Policy for RDS Enhanced Monitoring"
  tags        = var.tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "monitoring" {
  name = format("%s-%s-rds-enhanced-monitoring", var.component, var.env)
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  policy_arn = aws_iam_policy.monitoring.arn
  role       = aws_iam_role.monitoring.name
}
