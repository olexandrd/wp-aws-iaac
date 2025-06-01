output "alb_arn" {
  description = "ARN of the created Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the created ALB"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN of the WordPress target group"
  value       = aws_lb_target_group.wordpress.arn
}
