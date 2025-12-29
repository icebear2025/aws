resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_name}-db-instance"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.small"
  db_name                 = "gbsw2025"
  port                    = 3306
  allocated_storage       = 900
  username                = "admin"
  password                = "gbsw2025"
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnets.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  storage_encrypted       = true
  apply_immediately       = true
  skip_final_snapshot     = true
}

resource "aws_db_subnet_group" "aurora_subnets" {
  name        = "${var.project_name}-subnets"
  subnet_ids  = [
    aws_subnet.protected_subnet_a.id,
    aws_subnet.protected_subnet_c.id
  ]
}

resource "aws_security_group" "rds" {
  name = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}