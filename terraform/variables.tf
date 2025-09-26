variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the security group into (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "key_pair_name" {
  description = "The name of the SSH key pair (leave empty if no SSH access needed)"
  type        = string
  default     = ""
}

variable "app_port" {
  description = "The port the application will run on"
  type        = number
  default     = 8080
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket to store logs (leave empty for auto-generated name)"
  type        = string
  default     = ""
  
  validation {
    condition     = var.s3_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_bucket_name))
    error_message = "S3 bucket name must be lowercase, start and end with alphanumeric characters, and can contain hyphens."
  }
}