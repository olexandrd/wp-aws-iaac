resource "aws_sns_topic" "alerts" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = var.metric_namespace # "AWS/EC2" or "AWS/ECS"
  period              = var.period
  statistic           = "Average"
  threshold           = var.threshold
  alarm_description   = var.alarm_description

  # Для EC2: InstanceId = <EC2 instance id>
  # Для ECS: ClusterName + ServiceName
  dimensions = var.alarm_dimensions

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
