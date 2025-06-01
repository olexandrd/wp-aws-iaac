output "db_instance_address" {
  description = "Endpoint address of the RDS instance"
  value       = module.db.db_instance_address
}

output "ssm_password_name" {
  description = "Name of the SSM parameter holding the RDS password"
  value       = aws_ssm_parameter.rds_password.name
}
