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

# Create IAM Role for S3 Read-Only Access
resource "aws_iam_role" "s3_readonly_role" {
  name = "S3ReadOnlyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "S3ReadOnlyRole"
    Project = "DevOps-Assignment-2"
  }
}

# Policy for S3 Read-Only Access
resource "aws_iam_policy" "s3_readonly_policy" {
  name        = "S3ReadOnlyPolicy"
  description = "Policy for read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.log_bucket.arn,
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach policy to read-only role
resource "aws_iam_role_policy_attachment" "s3_readonly_attachment" {
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
  role       = aws_iam_role.s3_readonly_role.name
}

# Create IAM Role for S3 Upload (no read/download)
resource "aws_iam_role" "s3_upload_role" {
  name = "S3UploadOnlyRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "S3UploadOnlyRole"
    Project = "DevOps-Assignment-2"
  }
}

# Policy for S3 Upload Only (no read/download)
resource "aws_iam_policy" "s3_upload_policy" {
  name        = "S3UploadOnlyPolicy"
  description = "Policy for upload-only access to S3 (no read or download)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.log_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.log_bucket.arn
        ]
      }
    ]
  })
}

# Attach policy to upload-only role
resource "aws_iam_role_policy_attachment" "s3_upload_attachment" {
  policy_arn = aws_iam_policy.s3_upload_policy.arn
  role       = aws_iam_role.s3_upload_role.name
}

# Instance Profile for EC2 (attach role 1.a - read-only role)
resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "EC2S3Profile"
  role = aws_iam_role.s3_readonly_role.name
}

# Create Private S3 Bucket with configurable name
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.s3_bucket_name != "" ? var.s3_bucket_name : null

  tags = {
    Name = "TechEazy-Log-Bucket"
    Project = "DevOps-Assignment-2"
  }
}

# Configure bucket versioning
resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "log_bucket_pab" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add S3 Lifecycle Rule to delete logs after 7 days
resource "aws_s3_bucket_lifecycle_configuration" "log_bucket_lifecycle" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "delete_logs_after_7_days"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
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
