variable "project_name" {
  description = "Project name for naming EFS"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of private subnet IDs for mount targets"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID that allows access to EFS"
  type        = string
}

variable "vpc_id" {}

variable "private_subnets" {
  type = list(string)
}

