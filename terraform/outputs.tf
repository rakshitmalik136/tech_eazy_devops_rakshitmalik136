output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.app_instance.public_ip
}

output "instance_public_dns" {
  description = "The public DNS name of the EC2 instance"
  value       = aws_instance.app_instance.public_dns
}

output "application_url" {
  description = "The public URL to access the application"
  value       = "http://${aws_instance.app_instance.public_ip}:${var.app_port}"
}

output "ssh_connection" {
  description = "SSH connection command (if key pair is configured)"
  value       = var.key_pair_name != "" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.app_instance.public_ip}" : "SSH not configured - no key pair specified"
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.app_instance.id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.app_security_group.id
}

output "s3_bucket_name" {
  description = "The name of the created S3 bucket"
  value       = aws_s3_bucket.log_bucket.id
}

output "s3_bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = aws_s3_bucket.log_bucket.arn
}

output "s3_readonly_role_arn" {
  description = "The ARN of the S3 read-only role"
  value       = aws_iam_role.s3_readonly_role.arn
}

output "s3_upload_role_arn" {
  description = "The ARN of the S3 upload-only role"
  value       = aws_iam_role.s3_upload_role.arn
}

output "verification_commands" {
  description = "Commands to verify the setup"
  value = <<-EOF
    # SSH into the instance:
    ${var.key_pair_name != "" ? "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.app_instance.public_ip}" : "SSH not configured"}
    
    # Test S3 access (run on EC2 instance):
    aws s3 ls s3://${aws_s3_bucket.log_bucket.id}
    
    # Upload logs to S3:
    aws s3 cp /var/log/user-data.log s3://${aws_s3_bucket.log_bucket.id}/ec2-logs/
    aws s3 cp /opt/techeazy-app/logs/ s3://${aws_s3_bucket.log_bucket.id}/app-logs/ --recursive
  EOF
}