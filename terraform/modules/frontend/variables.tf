variable "bucket_name" {
  description = "The name of the S3 bucket for the static website"
  type        = string
}

variable "index_document" {
  description = "The index document for the static website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The error document for the static website"
  type        = string
  default     = "error.html"
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