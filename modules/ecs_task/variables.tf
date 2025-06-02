variable "project_name" {
  description = "Ім’я проєкту"
  type        = string
}

variable "ecr_repo_url" {
  description = "URL репозиторію ECR (для образу WordPress)"
  type        = string
}

variable "db_address" {
  description = "Адреса RDS для коннекту з WordPress"
  type        = string
}

variable "ssm_password_name" {
  description = "SSM Parameter Name, звідки ECS-таска дістає пароль"
  type        = string
}

variable "aws_ssm_parameter_arn" {
  description = "ARN SSM Parameter, звідки ECS-таска дістає пароль"
  type        = string
}

variable "efs_file_system_id" {
  description = "ID EFS для монтування"
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
  description = "ARN ECS Task Definition для ініціалізації WordPress"
  type        = string
}


variable "cluster_name" {
  description = "Назва ECS кластеру, до якого буде додана таска"
  type        = string

}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "aws_ecs_task_definition_arn" {
  description = "ARN ECS Task Definition для WordPress"
  type        = string
}
