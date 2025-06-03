variable "project_name" {
  description = "Project name for ECS cluster and resources"
  type        = string
}

variable "vpc_public_subnets" {
  description = "List of public subnet IDs for ASG"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID to attach to EC2 instances"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}
