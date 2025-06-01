variable "project_name" {
  description = "Project name for naming RDS resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS and its SG should be created"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of private subnet IDs (same VPC) for RDS"
  type        = list(string)
}