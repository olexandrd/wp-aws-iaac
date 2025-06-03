


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

resource "null_resource" "efs_init" {
  provisioner "local-exec" {
    command = <<EOT
      sleep 30 && aws ecs run-task --cluster ${var.cluster_name} \
        --task-definition ${var.aws_ecs_init_task_definition_arn} \
        --launch-type FARGATE \
        --network-configuration '{
          "awsvpcConfiguration": {
            "subnets": ${jsonencode(var.vpc_private_subnets)},
            "securityGroups": ["${var.ecs_sg_id}"],
            "assignPublicIp": "DISABLED"
          }
        }'
    EOT
  }
}

# ECS Task Definition for WordPress
resource "aws_ecs_task_definition" "wordpress" {
  depends_on               = [null_resource.efs_init]
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
      ],
      secrets = [
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = var.aws_ssm_parameter_arn
        }
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
resource "aws_ecs_capacity_provider" "ecs_asg_cp" {
  name = "${var.project_name}-ecs-cp"
  auto_scaling_group_provider {
    auto_scaling_group_arn = var.aws_ecs_task_definition_arn
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
    }

  }

  tags = {
    Name = "${var.project_name}-ecs-cp"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster_providers" {
  cluster_name = var.cluster_name

  capacity_providers = [
    aws_ecs_capacity_provider.ecs_asg_cp.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_cp.name
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_service" "wordpress_service" {
  name    = "${var.project_name}-wordpress-svc"
  cluster = var.cluster_name

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_cp.name
    weight            = 1
    base              = 1
  }

  # task_definition = module.ecs_task.task_definition_arn
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1

  network_configuration {
    subnets          = var.vpc_private_subnets
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "wordpress"
    container_port   = 80
  }
}
