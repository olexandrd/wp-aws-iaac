output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "launch_template_id" {
  description = "Launch Template ID for ECS worker nodes"
  value       = aws_launch_template.ecs_lt.id
}

output "asg_arn" {
  description = "ARN of the ECS Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.arn
}
