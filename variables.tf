variable "aws_region" {
  default = "eu-north-1"
  type    = string
}

variable "project_name" {
  default = "wordpress-poc"
  type    = string
}

variable "ecr_repo_url" {
  description = "URL of the container image (e.g. public ECR)"
  type        = string
  default     = "public.ecr.aws/docker/library/wordpress:latest"
}

variable "alert_email" {
  description = "Email for CloudWatch alerts subscription"
  type        = string
}

variable "autoscale_min_capacity" {
  description = "Minimum number of instances in the Auto Scaling group"
  type        = number
  default     = 1

}

variable "autoscale_max_capacity" {
  description = "Maximum number of instances in the Auto Scaling group"
  type        = number
  default     = 3
}
