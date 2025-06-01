output "task_definition_arn" {
  description = "ARN of the ECS Task Definition for WordPress"
  value       = aws_ecs_task_definition.wordpress.arn
}
