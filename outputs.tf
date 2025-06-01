output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "rds_endpoint" {
  description = "RDS endpoint address"
  value       = module.rds.db_instance_address
}
