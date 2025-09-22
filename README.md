# TechEazy Spring Boot Application - Deployment Guide

This repository contains a simple Spring Boot MVC application with automated deployment scripts for AWS infrastructure using Terraform.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [AWS Deployment](#aws-deployment)
- [Manual Deployment](#manual-deployment)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

## 🚀 Project Overview

This is a simple Spring Boot application that provides:
- A "Hello World" endpoint at `/hello`
- A parcel endpoint at `/parcel`
- Thymeleaf templating engine for view rendering
- Runs on port 80 (configurable via `application.properties`)

## 📦 Prerequisites

### For Local Development:
- **Java 17** or higher
- **Maven 3.6+**
- **Git**

### For AWS Deployment:
- **AWS Account** with appropriate permissions
- **Terraform 1.0+** installed
- **AWS CLI** configured with credentials
- **SSH Key Pair** (optional, for server access)

## 🏠 Local Development

### Step 1: Clone the Repository
```bash
git clone https://github.com/Trainings-TechEazy/test-repo-for-devops.git
cd test-repo-for-devops
```

### Step 2: Build the Application
```bash
mvn clean package
```

### Step 3: Run Locally
```bash
java -jar target/hellomvc-0.0.1-SNAPSHOT.jar
```

### Step 4: Access the Application
- **Main Hello Page**: http://localhost:80/hello
- **Parcel Endpoint**: http://localhost:80/parcel

> **Note**: The application runs on port 80 by default. You may need to run with `sudo` on Linux/Mac or change the port in `application.properties`.

## ☁️ AWS Deployment

### Step 1: Configure AWS Credentials

Make sure your AWS CLI is configured:
```bash
aws configure
```

Or set environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Navigate to Terraform Directory
```bash
cd terraform
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Review and Customize Variables (Optional)

Create a `terraform.tfvars` file to customize deployment:
```hcl
# terraform.tfvars
aws_region      = "us-west-2"
instance_type   = "t3.small"
key_pair_name   = "my-key-pair"  # Your existing AWS key pair name
app_port        = 8080
```

### Step 5: Plan the Deployment
```bash
terraform plan
```

### Step 6: Deploy the Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### Step 7: Access Your Application

After deployment completes, Terraform will output:
- **Public IP**: The instance's public IP address
- **Application URL**: Direct link to access your app
- **SSH Command**: Command to connect to the server (if key pair configured)

Example output:
```
application_url = "http://54.123.456.789:8080"
instance_public_ip = "54.123.456.789"
ssh_connection = "ssh -i ~/.ssh/my-key.pem ubuntu@54.123.456.789"
```

### Step 8: Test Your Deployment
- **Hello Endpoint**: `http://YOUR_PUBLIC_IP:8080/hello`
- **Parcel Endpoint**: `http://YOUR_PUBLIC_IP:8080/parcel`

### Step 9: Clean Up Resources (When Done)
```bash
terraform destroy
```

## 🔧 Manual Deployment

If you prefer to deploy manually on an existing Ubuntu server:

### Step 1: Connect to Your Server
```bash
ssh ubuntu@your-server-ip
```

### Step 2: Run the Deployment Script
```bash
wget https://raw.githubusercontent.com/Trainings-TechEazy/test-repo-for-devops/main/scripts/user_data.sh
chmod +x user_data.sh
sudo ./user_data.sh
```

### Step 3: Verify Deployment
```bash
sudo systemctl status techeazy-app.service
```

## 🛠️ Troubleshooting

### Common Issues:

#### 1. Port 80 Permission Issues (Local)
```bash
# Change port in src/main/resources/application.properties
server.port=8080
```

#### 2. AWS Deployment Fails
- Check AWS credentials: `aws sts get-caller-identity`
- Verify Terraform installation: `terraform version`
- Check AWS service limits in your region

#### 3. Application Not Starting on EC2
```bash
# SSH into the instance and check logs
ssh -i your-key.pem ubuntu@instance-ip
sudo journalctl -u techeazy-app.service -f
```

#### 4. Security Group Issues
Ensure the security group allows traffic on:
- Port 22 (SSH)
- Port 8080 (Application) or your configured port

#### 5. Service Status Check
```bash
# On the EC2 instance
sudo systemctl status techeazy-app.service
sudo systemctl restart techeazy-app.service
```

## 📁 Project Structure

```
├── src/
│   └── main/
│       ├── java/com/example/hellomvc/
│       │   ├── HelloMvcApplication.java      
│       │   └── controller/
│       │       ├── HelloController.java      
│       │       └── ParcelController.java     
│       └── resources/
│           ├── application.properties        
│           └── templates/
│               └── hello.html                
├── terraform/
│   ├── main.tf                               
│   ├── variables.tf                          
│   └── outputs.tf                            
├── scripts/
│   └── user_data.sh                          
├── pom.xml                                   
└── README.md                                 
```

## 🔍 Configuration Details

### Application Configuration
- **Default Port**: 80 (configurable in `application.properties`)
- **Framework**: Spring Boot 3.2.4
- **Java Version**: 17
- **Templating**: Thymeleaf

### AWS Infrastructure
- **Instance Type**: t3.micro (default, configurable)
- **OS**: Ubuntu 22.04 LTS
- **Security**: Security group with SSH (22) and app port access
- **Service**: Systemd service for auto-start and management

### Terraform Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `vpc_id` | VPC ID (empty = default VPC) | `""` |
| `key_pair_name` | SSH key pair name | `""` |
| `app_port` | Application port | `8080` |

## 🚨 Security Considerations

⚠️ **Important**: The current configuration allows public access. For production:

1. **Restrict SSH access** to your IP range
2. **Use Application Load Balancer** with SSL/TLS
3. **Enable VPC flow logs** and monitoring
4. **Implement proper IAM roles** and policies
5. **Use AWS Systems Manager** instead of SSH keys

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## 📄 License

This project is part of the TechEazy DevOps training assignment.

---

**Need Help?** 
- Check the [Troubleshooting](#troubleshooting) section
- Review AWS CloudWatch logs for deployment issues
- Verify all prerequisites are installed and configured
