variable "vpc_id" {
  type = string
  description = "vpc id"
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

variable "application" {
  type        = string
  description = "application name"
}

variable "current_ip_address_cidr" {
  description = "The current IP address CIDR"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where the instance will be deployed"
}

variable "port" {
  description = "The port for the container"
  type        = string
  default     = "80"
}

variable "ingress_rules" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
  }))
  default = {
    http  = {
      description = "http access from external ip address"
      from_port   = 80
      to_port     = 80
    }
    https = {
      description = "https access from external ip address"
      from_port   = 443
      to_port     = 443
    }
  }
}

variable "security_group_id" {
  description = "optional default security group id"
  type        = string
  default     = ""
}