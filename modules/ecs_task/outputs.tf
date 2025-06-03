output "task_definition_arn" {
  description = "ARN of the ECS Task Definition for WordPress"
  value       = aws_ecs_task_definition.wordpress.arn
}

output "service_name" {
  description = "Name of the ECS service for WordPress"
  value       = aws_ecs_service.wordpress_service.name
}
