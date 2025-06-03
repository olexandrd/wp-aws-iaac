variable "project_name" {
  description = "Project name"
  type        = string
}

variable "ecr_repo_url" {
  description = "Docker image URL"
  type        = string
}

variable "db_address" {
  description = "RDS endpoint"
  type        = string
}

variable "ssm_password_name" {
  description = "SSM Parameter Name, for ECS task to get the password"
  type        = string
}

variable "aws_ssm_parameter_arn" {
  description = "ARN SSM Parameter, for ECS task to get the password"
  type        = string
}

variable "efs_file_system_id" {
  description = "ID EFS for WordPress data storage"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security Group ID для ECS"
  type        = string
}

variable "aws_ecs_init_task_definition_arn" {
  description = "ARN ECS Task Definition for initialization tasks"
  type        = string
}


variable "cluster_name" {
  description = "ECS Cluster Name"
  type        = string

}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "aws_ecs_task_definition_arn" {
  description = "ARN ECS Task Definition for WordPress"
  type        = string
}

variable "autoscale_max_capacity" {
  type    = number
  default = 5
}

variable "autoscale_min_capacity" {
  type    = number
  default = 1
}
