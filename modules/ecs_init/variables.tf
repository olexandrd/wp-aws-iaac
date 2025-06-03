variable "project_name" {
  description = "Project name for naming resources"
  type        = string
}

variable "ecr_repo_url" {
  description = "Docker image URL for the ECS task"
  type        = string
}

variable "efs_file_system_id" {
  description = "EFS File System ID for WordPress data storage"
  type        = string
}

