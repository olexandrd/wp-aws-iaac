# ----------------------------------------------------
# 1) Create VPC + public & private subnets (no NAT Gateway)
# ----------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name            = var.project_name
  cidr            = "10.0.0.0/16"
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  single_nat_gateway = false

  enable_dns_hostnames = true

  tags = {
    Name = var.project_name
  }
}

# ----------------------------------------------------
# 2) Security Group for ECS tasks (як раніше)
# ----------------------------------------------------
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# ----------------------------------------------------
# 3) NAT Instance: EC2 t4g.nano у публічній підмережі
# ----------------------------------------------------

# 3.1) Знайти останній Amazon Linux 2 ARM64 AMI
data "aws_ami" "nat_amzn2_arm64" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

# 3.2) Security Group для NAT Instance
resource "aws_security_group" "nat_sg" {
  name        = "${var.project_name}-nat-sg"
  description = "Security group for NAT instance"
  vpc_id      = module.vpc.vpc_id

  # Дозволяємо весь вихідний трафік з NAT
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Дозволяємо весь трафік із приватних підмереж до NAT
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = {
    Name = "${var.project_name}-nat-sg"
  }
}

# 3.3) Сам NAT Instance (t4g.nano) у першому публічному сабнеті
resource "aws_instance" "nat_instance" {
  ami                         = data.aws_ami.nat_amzn2_arm64.id
  instance_type               = "t4g.nano"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]

  # Налаштовуємо IP forwarding та маскараду
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y iptables-services
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/00-ip-forwarding.conf
    sysctl -p /etc/sysctl.d/00-ip-forwarding.conf
    iptables -t nat -A POSTROUTING -s ${module.vpc.vpc_cidr_block} -j MASQUERADE
    iptables -P FORWARD ACCEPT
    service iptables save
    systemctl enable iptables.service
    systemctl restart iptables.service
    EOF

  tags = {
    Name = "${var.project_name}-nat-instance"
  }
}

# ----------------------------------------------------
# 4) Route Table updates: прокладення приватних сабнетів
#    через NAT Instance (через instance_id)
# ----------------------------------------------------

locals {
  nat_eni_id = aws_instance.nat_instance.primary_network_interface_id
}

resource "aws_route" "private_to_nat" {
  count                  = length(module.vpc.private_route_table_ids)
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"

  network_interface_id = local.nat_eni_id
}
