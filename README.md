# TechEazy DevOps Assignment 2 - S3 Integration

This repository contains a Spring Boot MVC application with comprehensive AWS infrastructure automation using Terraform, including S3 bucket management and IAM role integration.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Assignment Requirements](#assignment-requirements)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Verification](#verification)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)

## 🚀 Project Overview

This project extends a simple Spring Boot application with AWS cloud infrastructure that includes:
- **Web Application**: Spring Boot with `/hello` and `/parcel` endpoints
- **EC2 Infrastructure**: Automated instance deployment with security groups
- **S3 Integration**: Private bucket with lifecycle policies for log storage
- **IAM Management**: Two distinct roles for different S3 access patterns
- **Automated Log Upload**: EC2 and application logs automatically uploaded to S3

## 📝 Assignment Requirements

### ✅ Completed Features:

1. **Two IAM Roles Created**:
   - **Role 1.a**: S3ReadOnlyRole - Read-only access to S3 bucket
   - **Role 1.b**: S3UploadOnlyRole - Upload access only (no read/download)

2. **EC2 Instance Profile**: Role 1.a attached via IamInstanceProfile

3. **Private S3 Bucket**: Configurable name with error handling if name exists

4. **EC2 Log Upload**: `/var/log/cloud-init.log`, `/var/log/user-data.log` uploaded after instance shutdown

5. **Application Log Upload**: Spring Boot application logs uploaded to `/app-logs` folder

6. **S3 Lifecycle Rule**: Automatically deletes logs after 7 days

7. **Access Verification**: Role 1.a can successfully list files in S3 bucket

## 📦 Prerequisites

### Required Tools:
- **AWS Account** with appropriate permissions
- **Terraform 1.0+** installed locally
- **AWS CLI** configured with credentials
- **Git** for cloning the repository

### AWS Permissions Needed:
- EC2: Launch instances, create security groups
- S3: Create buckets, manage lifecycle policies
- IAM: Create roles, policies, and instance profiles

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git
cd test-repo-for-devops/terraform
```

### 2. Configure Variables
```bash
# Create terraform.tfvars file
cat > terraform.tfvars << EOF
aws_region = "us-east-1"
s3_bucket_name = "techeazy-devops-logs-$(whoami)-$(date +%s)"
instance_type = "t2.micro"
app_port = 8080
EOF
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 4. Access Your Application
After deployment, use the output URLs:
```bash
# Get outputs
terraform output
# Access application at: http://YOUR_PUBLIC_IP:8080/hello
```

## 🔧 Detailed Setup

### Step 1: AWS Configuration

Ensure your AWS credentials are configured:
```bash
aws configure
# OR set environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Customize Deployment

Create `terraform/terraform.tfvars`:
```hcl
# Required: Unique S3 bucket name
s3_bucket_name = "your-unique-bucket-name-123"

# Optional: AWS region
aws_region = "us-east-1"

# Optional: EC2 instance type
instance_type = "t2.micro"

# Optional: SSH access (uncomment if needed)
# key_pair_name = "your-existing-key-pair"

# Optional: Custom VPC (leave empty for default)
# vpc_id = "vpc-xxxxxxxxx"
```

### Step 3: Deploy Resources

```bash
cd terraform

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### Step 4: Verify Deployment

After successful deployment, Terraform will output:
```
application_url = "http://54.123.456.789:8080"
s3_bucket_name = "your-bucket-name"
ssh_connection = "ssh -i ~/.ssh/key.pem ubuntu@54.123.456.789"
verification_commands = "..."
```

## ✅ Verification

### Automated Verification Script

SSH into your instance and run the verification script:
```bash
# SSH into the instance (use output command)
ssh -i ~/.ssh/your-key.pem ubuntu@YOUR_PUBLIC_IP

# Download and run verification script
wget -O verify.sh https://raw.githubusercontent.com/your-repo/verification-test.sh
chmod +x verify.sh
./verify.sh your-bucket-name
```

### Manual Verification Steps

1. **Test Application Endpoints**:
   ```bash
   curl http://YOUR_PUBLIC_IP:8080/hello
   curl http://YOUR_PUBLIC_IP:8080/parcel
   ```

2. **Verify S3 Access (from EC2 instance)**:
   ```bash
   # Test S3 list access (should work with read-only role)
   aws s3 ls s3://your-bucket-name/

   # Check uploaded logs
   aws s3 ls s3://your-bucket-name/ec2-logs/
   aws s3 ls s3://your-bucket-name/app-logs/
   ```

3. **Verify IAM Roles**:
   ```bash
   # Check attached IAM role
   curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
   ```

4. **Test Log Upload**:
   ```bash
   # Upload a test file
   echo "Test log $(date)" > /tmp/test.log
   aws s3 cp /tmp/test.log s3://your-bucket-name/test-logs/
   ```

## 🏗️ Architecture

### Infrastructure Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   EC2 Instance  │    │   S3 Bucket      │    │   IAM Roles     │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │Spring Boot  │ │    │ │  /ec2-logs/  │ │    │ │ReadOnlyRole │ │
│ │Application  │ │    │ │  /app-logs/  │ │    │ │             │ │
│ └─────────────┘ │    │ │ /system-logs/│ │    │ └─────────────┘ │
│                 │────┤ └──────────────┘ │    │                 │
│ ┌─────────────┐ │    │                  │    │ ┌─────────────┐ │
│ │   Logs      │ │    │ Lifecycle: 7 days│    │ │UploadRole   │ │
│ └─────────────┘ │    └──────────────────┘    │ │             │ │
└─────────────────┘                            │ └─────────────┘ │
                                               └─────────────────┘
```

### Security Configuration

- **VPC**: Uses default VPC or specified custom VPC
- **Security Group**: Allows SSH (22) and application port (8080)
- **S3 Bucket**: Private with blocked public access
- **IAM Roles**: Least privilege access patterns

### Logging Strategy

- **EC2 Logs**: System logs uploaded during instance setup
- **Application Logs**: Spring Boot logs with separate error streams
- **Automated Upload**: Periodic log uploads via systemd service
- **Lifecycle Management**: 7-day retention policy

## 🛠️ Troubleshooting

### Common Issues

#### 1. S3 Bucket Name Already Exists
```bash
# Error: BucketAlreadyExists
# Solution: Change bucket name in terraform.tfvars
s3_bucket_name = "techeazy-logs-unique-$(date +%s)"
```

#### 2. IAM Permission Issues
```bash
# Check current IAM role on EC2
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Test S3 access
aws s3 ls s3://your-bucket-name/
```

#### 3. Application Not Starting
```bash
# SSH into instance and check service
sudo systemctl status techeazy-app.service
sudo journalctl -u techeazy-app.service -f

# Check application logs
tail -f /opt/techeazy-app/logs/application.log
```

#### 4. Log Upload Failures
```bash
# Check AWS CLI configuration
aws sts get-caller-identity

# Manually test upload
aws s3 cp /var/log/user-data.log s3://your-bucket-name/test/
```

#### 5. Terraform State Issues
```bash
# Reset Terraform state (careful!)
terraform refresh
terraform plan

# Force unlock if needed
terraform force-unlock LOCK_ID
```

## 📁 Project Structure

```
├── src/
│   └── main/
│       ├── java/com/example/hellomvc/
│       │   ├── HelloMvcApplication.java      # Main Spring Boot app
│       │   └── controller/
│       │       ├── HelloController.java      # /hello endpoint
│       │       └── ParcelController.java     # /parcel endpoint
│       └── resources/
│           ├── application.properties        # Port: 80 (changed to 8080 in deployment)
│           └── templates/
│               └── hello.html                # Thymeleaf template
├── terraform/
│   ├── main.tf                               # Main Terraform configuration
│   ├── variables.tf                          # Variable definitions
│   ├── outputs.tf                            # Output values
│   └── terraform.tfvars                      # User configuration
├── scripts/
│   ├── user_data.sh                          # EC2 initialization script
│   └── verification-test.sh                  # Verification script
├── pom.xml                                   # Maven configuration
└── README.md                                 # README.md file
```

## 🔧 Configuration Reference

### Terraform Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for deployment | `us-east-1` | No |
| `s3_bucket_name` | Unique S3 bucket name | `""` (auto-generated) | No |
| `instance_type` | EC2 instance type | `t2.micro` | No |
| `app_port` | Application port | `8080` | No |
| `key_pair_name` | SSH key pair name | `""` (no SSH) | No |
| `vpc_id` | VPC ID | `""` (default VPC) | No |

### Environment Variables

```bash
# AWS Configuration
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Optional: Terraform variables
export TF_VAR_s3_bucket_name="my-unique-bucket"
export TF_VAR_instance_type="t3.micro"
```

## 🧪 Testing

### Unit Tests (Local)
```bash
# Run Spring Boot tests
mvn test

# Build application
mvn clean package
```

### Integration Tests (AWS)
```bash
# Deploy and test
terraform apply
./scripts/verify-deployment.sh

# Load test endpoints
ab -n 100 -c 10 http://YOUR_IP:8080/hello
```

### Cleanup
```bash
# Destroy all AWS resources
terraform destroy

# Verify cleanup
aws s3 ls | grep your-bucket-name
aws ec2 describe-instances --filters "Name=tag:Project,Values=DevOps-Assignment-2"
```

## 📚 Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS S3 Lifecycle Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## 📄 License

This project is part of the TechEazy DevOps training program.

---

**🚨 Important Notes:**
- Always use unique S3 bucket names
- Review AWS costs before deployment
- Clean up resources after testing
- Never commit AWS credentials to version control

**📞 Need Help?**
- Check the [Troubleshooting](#troubleshooting) section
- Review Terraform plan before applying
- Use AWS CloudWatch for monitoring
- Check application logs for runtime issues