variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "ecr_repo_url" {
  description = "URL образу WordPress (ECR або Public)"
  type        = string
}

variable "efs_file_system_id" {
  description = "ID EFS, куди копіювати файли"
  type        = string
}

