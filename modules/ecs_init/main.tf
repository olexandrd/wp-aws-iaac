data "aws_iam_policy_document" "ecs_init_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_init_role" {
  name               = "${var.project_name}-ecs-init-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_init_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_init_attach" {
  role       = aws_iam_role.ecs_init_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "init" {
  family                   = "${var.project_name}-wordpress-init"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_init_role.arn
  task_role_arn            = aws_iam_role.ecs_init_role.arn

  container_definitions = jsonencode([
    {
      name      = "copy-wordpress"
      image     = var.ecr_repo_url
      essential = true
      user      = "33"

      entryPoint = ["sh", "-c"]
      command    = ["cp -r /usr/src/wordpress/* /tmp/efs/"]

      mountPoints = [
        {
          sourceVolume  = "wordpress-data"
          containerPath = "/tmp/efs/"
          readOnly      = false
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
