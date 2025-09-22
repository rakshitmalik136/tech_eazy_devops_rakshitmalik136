provider "aws" {
  region = var.aws_region
}

# Look up the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's owner ID
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Get default VPC if no VPC ID is provided
data "aws_vpc" "default" {
  count   = var.vpc_id == "" ? 1 : 0
  default = true
}

# Use provided VPC ID or default VPC
locals {
  vpc_id = var.vpc_id != "" ? var.vpc_id : data.aws_vpc.default[0].id
}

# Security group to allow traffic on specific ports (SSH and app port)
resource "aws_security_group" "app_security_group" {
  name_prefix = "app-sg-"
  description = "Allows SSH and application traffic"
  vpc_id      = local.vpc_id

  # Ingress rule for SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For production, restrict this to your IP
  }

  # Ingress rule for the application port
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TechEazy-App-SG"
  }
}

# Launch the EC2 instance
resource "aws_instance" "app_instance" {
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  user_data              = file("${path.module}/../scripts/user_data.sh")
  
  # Associate public IP automatically
  associate_public_ip_address = true

  tags = {
    Name    = "TechEazy-App-Server"
    Project = "DevOps-Assignment"
  }
}
