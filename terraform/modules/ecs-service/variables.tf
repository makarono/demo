variable "vpc_id" {
  type        = string
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
  default     = ""
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where the instance will be deployed"
}

variable "port" {
  description = "The port for the container"
  type        = number
  default     = 80
}

variable "alb_target_group_arn" {
  description = "Alb target group arn"
  type        = string
  default     = ""
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "List of public subnets cidr"
}

variable "task_cpu" {
  description = "CPU units for the task"
  default     = 256
}

variable "task_memory" {
  description = "Memory in MiB for the task"
  default     = 512
}

variable "image_tag" {
  description = "Image tag for the container"
  default     = "latest"
}

variable "image_name" {
  description = "Image name"
  type        = string
  default     = ""
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "requires_compatibilities" {
  type        = list(string)
  description = "requires compatibilities"
  default     = ["FARGATE"]
}

variable "ecs_cluster_id" {
  type        = string
  description = "ecs cluster id"
}

variable "container_environment" {
  description = "container environment variables"
  type        = map(string)
  default = {
    "env" = "1"
  }
}

variable "family" {
  description = "ecs task falily"
  type        = string
  default     = "ecs-task-family"
}

variable "dns_namespace_id" {
  description = "dns namespace id"
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "The desired number of instances or tasks for the service."
  type        = number
  default     = 1
}

variable "deployment_minimum_healthy_percent" {
  description = "The minimum healthy percentage of tasks that should be maintained during a deployment."
  type        = number
  default     = 50
}

variable "deployment_maximum_percent" {
  description = "The maximum percent of tasks that can be running during a deployment."
  type        = number
  default     = 200
}

variable "security_group_id" {
  description = "optional default security group id"
  type        = string
  default     = ""
}


variable "enable_autoscaling" {
  description = "switch to enable autoscaling"
  type        = bool
  default     = false
}


variable "autoscaling_max_capacity" {
  description = "The maximum capacity for autoscaling"
  type        = number
  default     = 10
}

variable "autoscaling_min_capacity" {
  description = "The minimum capacity for autoscaling"
  type        = number
  default     = 1
}

variable "auto_scaling_memory_target_value" {
  description = "Target value for memory autoscaling"
  type = number
  default     = 80
}

variable "auto_scaling_cpu_target_value" {
  description = "Target value for CPU autoscaling"
  type = number
  default     = 60
}