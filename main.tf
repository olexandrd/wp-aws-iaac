# 1) Network (VPC + Security Group)
module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  aws_region   = var.aws_region
}

# 2) EFS (file system + mount targets)
module "efs" {
  source              = "./modules/efs"
  project_name        = var.project_name
  vpc_private_subnets = module.network.private_subnets
  ecs_sg_id           = module.network.ecs_sg_id
  vpc_id              = module.network.vpc_id
  depends_on = [
    module.network.nat_instance_id,
  ]
}

# 3) RDS (password in SSM + RDS instance)
module "rds" {
  source              = "./modules/rds"
  project_name        = var.project_name
  vpc_id              = module.network.vpc_id
  vpc_private_subnets = module.network.private_subnets
  depends_on = [
    module.network.nat_instance_id,
  ]
}

# 4) ECS Task Definitions

module "ecs_init" {
  source             = "./modules/ecs_init"
  project_name       = var.project_name
  ecr_repo_url       = var.ecr_repo_url
  efs_file_system_id = module.efs.file_system_id
  depends_on = [
    module.efs,
    module.ecs
  ]
}

module "ecs_task" {
  source                           = "./modules/ecs_task"
  project_name                     = var.project_name
  ecr_repo_url                     = var.ecr_repo_url
  db_address                       = module.rds.db_instance_address
  ssm_password_name                = module.rds.ssm_password_name
  aws_ssm_parameter_arn            = module.rds.aws_ssm_parameter_arn
  efs_file_system_id               = module.efs.file_system_id
  vpc_private_subnets              = module.network.private_subnets
  ecs_sg_id                        = module.network.ecs_sg_id
  aws_ecs_init_task_definition_arn = module.ecs_init.aws_ecs_init_task_definition_arn
  cluster_name                     = module.ecs.cluster_name
  target_group_arn                 = module.alb.target_group_arn
  aws_ecs_task_definition_arn      = module.ecs.asg_arn
  depends_on = [
    module.ecs_init
  ]
}

# 5) ECS (cluster + EC2 workers + IAM for instances)
module "ecs" {
  source              = "./modules/ecs"
  project_name        = var.project_name
  vpc_public_subnets  = module.network.public_subnets
  ecs_sg_id           = module.network.ecs_sg_id
  vpc_private_subnets = module.network.private_subnets
  depends_on = [
    module.network.nat_instance_id,
    module.alb
  ]
}

# 6) ALB (load balancer + target group + listener)
module "alb" {
  source                = "./modules/alb"
  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  public_subnets        = module.network.public_subnets
  ecs_sg_id             = module.network.ecs_sg_id
  target_group_port     = 80
  target_group_protocol = "HTTP"
  depends_on = [
    module.network.nat_instance_id,
  ]
}

# 7) CloudWatch 

module "cloudwatch_alert" {
  source           = "./modules/cloudwatch_alert"
  email            = var.alert_email
  metric_namespace = "AWS/ECS"
  alarm_dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs_task.service_name
  }
}
