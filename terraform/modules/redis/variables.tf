variable "vpc_id" {
  description = "vpc id"
  type        = string
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

variable "current_ip_address_cidr" {
  description = "The current IP address CIDR"
  type        = string
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where the Redis instance will be deployed"
}

variable "engine_version" {
  description = "The Redis engine version"
  type        = string
  default     = "6.0"
}

variable "parameter_group_name" {
  description = "The Redis parameter group name"
  type        = string
  default     = "default.redis6.x"
}

variable "maintenance_window" {
  description = "The maintenance window for the Redis cluster"
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "snapshot_window" {
  description = "The snapshot window for the Redis cluster"
  type        = string
  default     = "06:00-07:00"
}

variable "instance_type" {
  description = "The instance type for the Redis cluster"
  type        = string
  default     = "cache.t2.micro"
}

variable "snapshot_retention_limit" {
  description = "The snapshot retention limit for the Redis cluster"
  type        = number
  default     = 0
}

variable "at_rest_encryption_enabled" {
  description = "Flag to enable at-rest encryption for the Redis cluster"
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Flag to enable transit encryption for the Redis cluster"
  type        = bool
  default     = true
}

variable "automatic_failover_enabled" {
  description = "Flag to enable automatic failover for the Redis cluster"
  type        = bool
  default     = true
}

variable "num_cache_clusters" {
  description = "The number of Redis cache clusters"
  type        = number
  default     = 2
}

variable "cluster_mode_enabled" {
  type        = bool
  description = "Switch to enable/disable creation of a native redis cluster"
  default     = false
}

variable "cluster_mode_replicas_per_node_group" {
  type        = number
  description = "Number of replica nodes for every node group"
  default     = 0
}

variable "cluster_mode_num_node_groups" {
  type        = number
  description = "Number of node shards for this redis replication group"
  default     = 0
}

variable "enable_autoscaling" {
  description = "Flag to enable autoscaling for the Redis cluster"
  type        = bool
  default     = true
}

variable "multi_az_enabled" {
  description = "Flag to enable multi-AZ deployment for the Redis cluster"
  type        = bool
  default     = true
}

variable "port" {
  description = "The port for the Redis cluster"
  type        = string
  default     = "6379"
}

variable "apply_immediately" {
  description = "Apply redis changes immediately"
  type        = bool
  default     = false
}

variable "security_group_id" {
  description = "optional default security group id"
  type        = string
  default     = ""
}

variable "min_capacity" {
  type        = number
  default     = 1
  description = "The minimum capacity for the App Autoscaling target"
}

variable "max_capacity" {
  type        = number
  default     = 5
  description = "The maximum capacity for the App Autoscaling target"
}

variable "target_value" {
  type        = number
  default     = 70.0
  description = "The target value for the App Autoscaling policy"
}

variable "scale_in_cooldown" {
  type        = number
  default     = 60
  description = "The amount of time, in seconds, after a scale in activity completes before another scale in activity can start"
}

variable "scale_out_cooldown" {
  type        = number
  default     = 60
  description = "The amount of time, in seconds, after a scale out activity completes before another scale out activity can start"
}

