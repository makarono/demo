variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where the Mysql instance will be deployed"
  default     = []
}

variable "port" {
  default = "3306"
}

variable "current_ip_address_cidr" {
  description = "The current IP address CIDR"
  type        = string
}

variable "backup_retention_period" {
  description = "The backup retention period"
  type        = number
  default     = 35
}

variable "instance_class" {
  description = "The RDS instance class"
  type        = string
}

variable "multi_az_enabled" {
  description = "Flag to enable multi-AZ deployment"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "The monitoring interval"
  type        = number
  default     = 60
}

variable "storage_autoscaling" {
  description = "Flag to enable storage autoscaling"
  type        = bool
  default     = true
}

variable "max_allocated_storage" {
  description = "The maximum allocated storage"
  type        = number
  default     = 40
}

variable "backup_window" {
  description = "The backup window"
  type        = string
  default     = "23:00-00:00"
}

variable "engine" {
  description = "The database engine"
  type        = string
  default     = "mysql"
}

variable "engine_version" {
  description = "The database engine version"
  type        = string
  default     = "8.0"
}

variable "maintenance_window" {
  description = "The maintenance window"
  type        = string
  default     = "Sat:00:00-Sat:03:00"
}

variable "parameter_group_name" {
  description = "The parameter group name"
  type        = string
  default     = "default.mysql8.0"
}

variable "storage_type" {
  description = "The storage type"
  type        = string
  default     = "gp2"
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrade"
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Auto minor version upgrade"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot"
  type        = bool
  default     = true
}

variable "publicly_accessible" {
  description = "Publicly accessible"
  type        = bool
  default     = false
}

variable "terraform_tmp" {
  type        = string
  default     = "/tmp/terraform"
  description = "directory created in shell script"
}

variable "component" {
  type        = string
  description = "componet identifier"
}

variable "env" {
  type        = string
  description = "environment identifier"
}

variable "tags" {
  description = "list of resources common tags"
  type        = map(string)
}

variable "security_group_id" {
  description = "optional default security group id"
  type        = string
  default     = ""
}

variable "final_snapshot_identifier" {
  type        = string
  description = "final snapshot dentifier"
  default = "FinalDbSnapshot"
}
