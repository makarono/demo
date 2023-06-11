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

variable "DB_HOST" {
  description = "The hostname of the database"
  type        = string
  default     = "example-host"
}

variable "DB_PORT" {
  description = "The port of the database"
  type        = number
  default     = 3306
}

variable "DB_USER" {
  description = "The username for the database"
  type        = string
  default     = "example-user"
}

variable "DB_PASSWORD" {
  description = "The password for the database"
  type        = string
  default     = "example-password"
}

variable "security_group_id" {
  description = "The ID of the security group"
  type        = string
}

variable "subnet_ids" {
  description = "A list of private subnet IDs"
  type        = list(string)
}

variable "mysql_import_file" {
  description = "file with mysql dump statements"
  type        = string
  default     = ""
}
