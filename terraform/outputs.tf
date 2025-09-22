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
