output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "cloudwatch_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_utilization.arn
}
