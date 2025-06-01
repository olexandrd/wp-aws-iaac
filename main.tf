


# 1) Network (VPC + Security Group)
module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  aws_region   = var.aws_region
}

# 3) EFS (file system + mount targets)
module "efs" {
  source              = "./modules/efs"
  project_name        = var.project_name
  vpc_private_subnets = module.network.private_subnets
  ecs_sg_id           = module.network.ecs_sg_id
}

# 4) RDS (password in SSM + RDS instance)
module "rds" {
  source              = "./modules/rds"
  project_name        = var.project_name
  vpc_id              = module.network.vpc_id
  vpc_private_subnets = module.network.private_subnets
}

# 5) ECS Task Definition (container + IAM role)
module "ecs_task" {
  source             = "./modules/ecs_task"
  project_name       = var.project_name
  ecr_repo_url       = var.ecr_repo_url
  db_address         = module.rds.db_instance_address
  ssm_password_name  = module.rds.ssm_password_name
  efs_file_system_id = module.efs.file_system_id
}

# 6) ECS (cluster + EC2 workers + IAM for instances)
module "ecs" {
  source             = "./modules/ecs"
  project_name       = var.project_name
  vpc_public_subnets = module.network.public_subnets
  ecs_sg_id          = module.network.ecs_sg_id
  depends_on = [
    module.network.nat_instance_id,
  ]
}

# 7) ALB (load balancer + target group + listener)
module "alb" {
  source                = "./modules/alb"
  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  public_subnets        = module.network.public_subnets
  ecs_sg_id             = module.network.ecs_sg_id
  target_group_port     = 80
  target_group_protocol = "HTTP"
}

# -----------------------------------------
# 8) ECS Service (запускає Task Definition)
# -----------------------------------------

#########################################################
# 8) Capacity Provider для ASG, що запускає ECS-агенти
#########################################################

resource "aws_ecs_capacity_provider" "ecs_asg_cp" {
  name = "${var.project_name}-ecs-cp"


  auto_scaling_group_provider {
    auto_scaling_group_arn = module.ecs.asg_arn

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
  cluster_name = module.ecs.cluster_name

  capacity_providers = [
    aws_ecs_capacity_provider.ecs_asg_cp.name
  ]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_cp.name
    weight            = 1
    base              = 1
  }
}

####################################################
# 9. Оновлений ECS Service (тепер використовує CP)
####################################################

resource "aws_ecs_service" "wordpress_service" {
  name    = "${var.project_name}-wordpress-svc"
  cluster = module.ecs.cluster_name

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_cp.name
    weight            = 1
    base              = 1
  }

  task_definition = module.ecs_task.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets          = module.network.private_subnets
    security_groups  = [module.network.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_group_arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [
    module.alb

  ]
}
