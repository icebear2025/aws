# Get AMI
data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Key Pair
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "keypair" {
  key_name = "${var.project_name}-key-pair"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./temp/${var.project_name}-key-pair.pem"
}

resource "aws_security_group" "bastion_sg" {
  provider    = aws.ap-northeast-2
  name        = "${var.project_name}-i-bastion-sg"
  description = "${var.project_name}-i-bastion-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "${var.project_name}-i-bastion-sg"
  }
}

resource "aws_iam_role" "bastion" {
  name = "${var.project_name}-i-bastion-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project_name}-i-bastion-role"
  role = aws_iam_role.bastion.name
}

# Elastic IP
resource "aws_eip" "bastion_eip" {
  depends_on = [aws_instance.bastion]
}

# Bastion
resource "aws_instance" "bastion" {
  ami = data.aws_ssm_parameter.latest_ami.value
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.public_subnet_a.id
  associate_public_ip_address = true
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  key_name               = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  user_data = "${file("./src/userdata/userdata.sh")}"

  metadata_options {
    instance_metadata_tags = "enabled"
  }

  depends_on = [aws_key_pair.keypair, aws_s3_bucket.bucket]

  tags = {
    Name = "${var.project_name}-i-bastion"
  }
}

resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

output "bastion_details" {
  value = {
    ip_address        = aws_eip.bastion_eip.public_ip
    instance_id       = aws_instance.bastion.id
    availability_zone = aws_instance.bastion.availability_zone
  }
}