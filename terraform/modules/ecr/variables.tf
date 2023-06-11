variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "list of resources common tags"
  type = map(string)
}

variable "force_delete" {
  description = "force delete repo eaven it contains docker images"
  type        = bool
  default     = false
}
