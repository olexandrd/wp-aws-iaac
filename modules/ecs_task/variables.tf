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

variable "efs_file_system_id" {
  description = "ID EFS для монтування"
  type        = string
}
