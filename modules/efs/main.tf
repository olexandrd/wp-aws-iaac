# Create an EFS file system for WordPress data
resource "aws_efs_file_system" "wordpress" {
  creation_token = "${var.project_name}-efs"
  tags = {
    Name = "${var.project_name}-efs"
  }
}

# Create mount targets in each private subnet
resource "aws_efs_mount_target" "efs_mount_target" {
  count           = length(var.vpc_private_subnets)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = var.vpc_private_subnets[count.index]
  security_groups = [var.ecs_sg_id]
}
