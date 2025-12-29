# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_c.id]
  security_groups    = [aws_security_group.external_alb.id]
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.bucket.id
    prefix  = "log"
    enabled = true
  }

  depends_on = [aws_s3_bucket_policy.alb_logs]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "product_app_tg" {
  name        = "${var.project_name}-product-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    port                = 8080
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-product-target-group"
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.product_app_tg.arn
  }
}

resource "aws_security_group" "external_alb" {
  name        = "${var.project_name}-alb-sg"
  description = "${var.project_name}-alb-sg"
  vpc_id      = aws_vpc.main_vpc.id

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
    Name = "${var.project_name}-alb-sg"
  }
}