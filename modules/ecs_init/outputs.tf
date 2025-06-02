output "aws_ecs_init_task_definition_arn" {
  description = "ARN of the ECS Task Definition for WordPress"
  value       = aws_ecs_task_definition.init.arn
}
