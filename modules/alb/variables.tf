variable "project_name" {
  description = "Project name for naming ALB resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID for ALB"
  type        = string
}

variable "target_group_port" {
  description = "Port for the target group (e.g., 80)"
  type        = number
}

variable "target_group_protocol" {
  description = "Protocol for the target group (HTTP or HTTPS)"
  type        = string
}
