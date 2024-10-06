terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.68.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.0"
    }
  }

  backend "s3" {
    bucket         = "sushma2bucket" # replace with your S3 bucket name
    key            = "terraform/statefile.tfstate"
    region         = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Create VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MainVPC"
  }
}

# Create Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1b"
  tags = {
    Name = "MainSubnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MainIGW"
  }
}

# Create Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "MainRouteTable"
  }
}

# Create Route to IGW
resource "aws_route" "main_route" {
  route_table_id         = aws_route_table.main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "main_assoc" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

# Generate Key Pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "example" {
  key_name   = "my_key_pair" # Name for your key pair
  public_key = tls_private_key.example.public_key_openssh
}

# Create EC2 Instance
resource "aws_instance" "my_server" {
  ami           = "ami-097c5c21a18dc59ea" # Example AMI (Amazon Linux 2)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.main_subnet.id
  key_name      = aws_key_pair.example.key_name

  tags = {
    Name = "MyServer"
  }
}

# Local File Resource to Indicate Switching of State
resource "local_file" "state_file" {
  filename = "${path.module}/terraform.tfstate"
  content  = "State file will be switched to local"
}
