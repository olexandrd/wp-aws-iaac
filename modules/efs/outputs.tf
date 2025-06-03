output "file_system_id" {
  description = "The ID of the created EFS file system"
  value       = aws_efs_file_system.wordpress.id
}

output "efs_sg_id" {
  description = "Security Group ID for the EFS file system"
  value       = aws_security_group.efs.id
}
