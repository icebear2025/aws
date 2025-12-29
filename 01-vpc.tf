# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# VPC Subnet
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet-c"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-private-subnet-c"
  }
}

resource "aws_subnet" "protected_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-protected-subnet-a"
  }
}

resource "aws_subnet" "protected_subnet_c" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project_name}-protected-subnet-c"
  }
}

# VPC IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP
resource "aws_eip" "eip_a" {
}

resource "aws_eip" "eip_c" {
}

# NAT Gateway
resource "aws_nat_gateway" "nat_a" {
  depends_on = [aws_internet_gateway.igw]

  allocation_id = aws_eip.eip_a.id
  subnet_id = aws_subnet.public_subnet_a.id

  tags = {
    Name = "${var.project_name}-nat-a"
  }
}

resource "aws_nat_gateway" "nat_c" {
  depends_on = [aws_internet_gateway.igw]

  allocation_id = aws_eip.eip_c.id
  subnet_id = aws_subnet.public_subnet_c.id

  tags = {
    Name = "${var.project_name}-nat-c"
  }
}

# VPC Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private_route_table_a" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = {
    Name = "${var.project_name}-private-rt-a"
  }
}

resource "aws_route_table" "private_route_table_c" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }
  tags = {
    Name = "${var.project_name}-private-rt-c"
  }
}

resource "aws_route_table" "protected_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "${var.project_name}-protected-rt"
  }
}

# Subnet Association
resource "aws_route_table_association" "public_subnet_a_assoc" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_c_assoc" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_a_assoc" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table_a.id
}

resource "aws_route_table_association" "private_subnet_c_assoc" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.private_route_table_c.id
}

resource "aws_route_table_association" "protected_subnet_a_assoc" {
  subnet_id      = aws_subnet.protected_subnet_a.id
  route_table_id = aws_route_table.protected_route_table.id
}

resource "aws_route_table_association" "protected_subnet_c_assoc" {
  subnet_id      = aws_subnet.protected_subnet_c.id
  route_table_id = aws_route_table.protected_route_table.id
}