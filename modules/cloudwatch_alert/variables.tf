variable "email" {
  description = "Email for subscribing to SNS topic"
  type        = string
}

variable "topic_name" {
  description = "SNS topic name"
  type        = string
  default     = "wordpress-alerts"
}

variable "alarm_name" {
  description = "CloudWatch Alarm name"
  type        = string
  default     = "wordpress-high-cpu"
}

variable "alarm_description" {
  description = "ОAlerm description"
  type        = string
  default     = "CPU utilization exceeds threshold"
}

variable "metric_namespace" {
  description = "CloudWatch metric namespace"
  type        = string
  default     = "AWS/ECS"
}

variable "alarm_dimensions" {
  description = "Map for dimensions (EC2 або ECS)"
  type        = map(string)
}

variable "evaluation_periods" {
  type    = number
  default = 2
}

variable "period" {
  type    = number
  default = 300
}

variable "threshold" {
  type    = number
  default = 60
}
