# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ECS Security Group
resource "aws_security_group" "ecs" {
  name   = "${var.project_name}-ecs-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.external_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = "0"
    to_port     = "0"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

# IAM Roles for ECS
resource "aws_iam_role" "ecs_role" {
  name = "${var.project_name}-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_role_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_role_policy_cloudwatch" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "product_td" {
  family                   = "${var.project_name}-product-td"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.ecs_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"  
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "product"
      image     = "${aws_ecr_repository.product.repository_url}:v1.0.0"
      cpu       = 256  
      memory    = 1024
      memoryReservation = 512
      essential = true
      user      = "0"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group   = "true"
          awslogs-group          = "/gbsw/ecs/product"
          awslogs-region         = var.aws_region
          awslogs-stream-prefix  = "product"
        }
      }
    },
  ])
}

# ECS Service
resource "aws_ecs_service" "product_service" {
  name            = "${var.project_name}-product-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.product_td.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_c.id]
    security_groups = [
      aws_security_group.ecs.id
    ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.product_app_tg.arn
    container_name   = "product"
    container_port   = 8080
  }

  availability_zone_rebalancing = "ENABLED"

  depends_on = [aws_lb_listener.alb]

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      platform_version
    ]
  }

  tags = {
    Name = "${var.project_name}-product-svc"
  }
}