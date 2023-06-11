variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to merge with resource tags"
  type        = map(string)
}

variable "component" {
  type = string
  description = "componet identifier"
}
variable "env" {
  type = string
  description = "environment identifier"
}
