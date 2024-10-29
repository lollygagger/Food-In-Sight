# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

locals {
        aws_key = "" #CHANGE TO BE YOUR KEY
}

# 1. Create the VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# 2. Create Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.0/26"

  tags = {
    Name = "public_subnet_1"
    Tier = "Public"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.64/26"

  tags = {
    Name = "public_subnet_2"
    Tier = "Public"
  }
}

# 3. Create Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.128/26"

  tags = {
    Name = "private_subnet_1"
    Tier = "Private"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.0.192/26"

  tags = {
    Name = "private_subnet_2"
    Tier = "Private"
  }
}

# 4. Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# 5. Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_rt_route_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_route_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Allocate Elastic IP for NAT Gateway
resource "aws_elastic_ip" "nat_elastic_ip" {
  vpc = true
}

# 7. Create NAT Gateway in the first public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_elastic_ip.nat_elastic_ip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "main_nat_gateway"
  }
}

# 8. Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# Associate Private Route Table with Private Subnets
resource "aws_route_table_association" "private_rt_route_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_route_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# 9. Create a Security Group for the EC2 Instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ec2_security_group"
  }
}

# 10. Create an EC2 Instance in the Public Subnet
resource "aws_instance" "web_server" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (change as needed)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  security_groups = [aws_security_group.ec2_security_group.id]

  associate_public_ip_address = true

  tags = {
    Name = "Team Terraform Activity"
  }

  key_name = "${local.aws_key}"
}