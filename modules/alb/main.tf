# Create an Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.ecs_sg_id]
  subnets            = var.public_subnets

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Create a Target Group for WordPress tasks
resource "aws_lb_target_group" "wordpress" {
  name                 = "${var.project_name}-tg-wp"
  port                 = var.target_group_port
  protocol             = var.target_group_protocol
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    path                = "/"
    protocol            = var.target_group_protocol
    matcher             = "200-399"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg-wp"
  }
}

# Create an HTTP listener on port 80 forwarding to the WordPress target group
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}
