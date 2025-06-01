# IAM Role for ECS Task Execution
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_exec" {
  name               = "${var.project_name}-ecs-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

# Attach the standard ECS Task Execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Policy to allow ECS task to read the RDS password from SSM
data "aws_iam_policy_document" "ecs_ssm_access" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_password_name}"
    ]
  }
}

resource "aws_iam_policy" "ecs_ssm_access" {
  name   = "${var.project_name}-ecs-ssm-access"
  policy = data.aws_iam_policy_document.ecs_ssm_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_ssm_attach" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = aws_iam_policy.ecs_ssm_access.arn
}

# ECS Task Definition for WordPress
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project_name}-wordpress"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn
  task_role_arn            = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = var.ecr_repo_url
      essential = true
      portMappings = [{
        containerPort = 80
        protocol      = "tcp"
      }]
      mountPoints = [{
        sourceVolume  = "wordpress-data"
        containerPath = "/var/www/html"
      }]
      environment = [
        { name = "WORDPRESS_DB_HOST", value = var.db_address },
        { name = "WORDPRESS_DB_USER", value = "admin" },
        { name = "WORDPRESS_DB_NAME", value = "wordpress" },
        { name = "WORDPRESS_DB_PASSWORD", value = "/${var.project_name}/rds-password" }
      ]
    }
  ])

  volume {
    name = "wordpress-data"
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }
}
