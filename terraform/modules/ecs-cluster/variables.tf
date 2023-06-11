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

variable "capacity_providers" {
  description = "cluster capacity providers"
  type = list(string)
  default = [ "FARGATE" ]
}