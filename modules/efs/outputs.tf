output "file_system_id" {
  description = "The ID of the created EFS file system"
  value       = aws_efs_file_system.wordpress.id
}
