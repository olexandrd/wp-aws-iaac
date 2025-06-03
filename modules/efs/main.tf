resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow NFS from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id]
    description     = "Allow NFS from ECS only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-efs-sg"
  }
}

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
  security_groups = [aws_security_group.efs.id]
}
