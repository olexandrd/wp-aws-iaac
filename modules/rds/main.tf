# 0) Create a dedicated Security Group for RDS in the same VPC
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS in VPC ${var.vpc_id}"
  vpc_id      = var.vpc_id

  # Example ingress: allow MySQL port 3306 from anywhere in that VPC’s CIDR
  # Якщо потрібен доступ тільки з ECS SG, можна передавати ecs_sg_id як змінну і ставити в 'source_security_group_id'
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group for RDS in VPC ${var.vpc_id}"
  subnet_ids  = var.vpc_private_subnets

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# 1) Generate a random password for RDS
resource "random_password" "rds" {
  length  = 16
  special = true
}


# 2) Store the generated password in SSM Parameter Store
resource "aws_ssm_parameter" "rds_password" {
  name  = "/${var.project_name}/rds-password"
  type  = "SecureString"
  value = random_password.rds.result

  tags = {
    Name = "${var.project_name}-rds-password"
  }
}

# 3) Invoke the official Terraform AWS RDS module
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.3.0"

  identifier             = "${var.project_name}-db"
  engine                 = "mysql"
  major_engine_version   = "8.0"
  family                 = "mysql8.0"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = "wordpress"
  username               = "admin"
  password               = aws_ssm_parameter.rds_password.value
  skip_final_snapshot    = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  subnet_ids             = var.vpc_private_subnets
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "${var.project_name}-db"
  }
}
