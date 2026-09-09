# Staging Environment Outputs
# These outputs provide useful information about the staging infrastructure

# Network Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids_list
}

output "app_subnet_ids" {
  description = "IDs of the application subnets"
  value       = module.network.app_subnet_ids_list
}

output "db_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.network.db_subnet_ids_list
}

output "availability_zones" {
  description = "Availability zones used"
  value       = module.network.availability_zones
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security.app_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.security.db_security_group_id
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.loadbalancer.alb_arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  value       = module.loadbalancer.alb_arn_suffix
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.loadbalancer.target_group_arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  value       = module.loadbalancer.target_group_arn_suffix
}

output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = module.loadbalancer.certificate_arn
}

# CDN Outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cloudfront_domain_name
}

output "route53_record_name" {
  description = "Route53 record name"
  value       = module.cdn.route53_record_name
}

# Compute Outputs
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.compute.launch_template_id
}

output "launch_template_version" {
  description = "Version of the launch template"
  value       = module.compute.launch_template_version
}

# Storage Outputs
output "storage_bucket_name" {
  description = "Name of the S3 bucket for application storage"
  value       = module.storage.s3_bucket_name
}

output "storage_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.storage.s3_bucket_arn
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = module.storage.efs_file_system_id
}

output "efs_file_system_arn" {
  description = "ARN of the EFS file system"
  value       = module.storage.efs_file_system_arn
}

output "efs_access_point_id" {
  description = "ID of the EFS access point"
  value       = module.storage.efs_access_point_id
}

output "efs_access_point_arn" {
  description = "ARN of the EFS access point"
  value       = module.storage.efs_access_point_arn
}

# Database Outputs
output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = module.database.db_instance_id
}

output "db_instance_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
}

output "db_instance_address" {
  description = "Address of the RDS instance"
  value       = module.database.db_instance_address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = module.database.db_instance_port
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.database.db_instance_arn
}

output "db_master_user_secret_arn" {
  description = "ARN of the RDS master user secret"
  value       = module.database.master_user_secret_arn
}

# IAM Outputs
output "app_role_arn" {
  description = "ARN of the application IAM role"
  value       = module.iam.role_arn
}

output "app_role_name" {
  description = "Name of the application IAM role"
  value       = module.iam.role_name
}

output "app_instance_profile_name" {
  description = "Name of the instance profile"
  value       = module.iam.instance_profile_name
}

# Secrets Manager Outputs
output "app_secret_arn" {
  description = "ARN of the application secrets"
  value       = module.secrets.secret_arn
}

output "app_secret_name" {
  description = "Name of the application secret"
  value       = module.secrets.secret_name
}

# Observability Outputs
output "alerts_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.observability.sns_topic_arn
}

output "alerts_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = module.observability.sns_topic_name
}

# Environment Information
output "environment" {
  description = "Current environment"
  value       = "staging"
}

output "app_full_name" {
  description = "Full application name with environment"
  value       = "${var.app_name}-staging"
}

# Useful URLs
output "application_url" {
  description = "URL of the application"
  value       = "https://${var.record_name}"
}

output "alb_url" {
  description = "URL of the ALB"
  value       = "http://${module.loadbalancer.alb_dns_name}"
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${module.cdn.cloudfront_domain_name}"
}

# Connection Information (for debugging)
output "bastion_connection" {
  description = "SSH command to connect to bastion (if applicable)"
  value       = "ssh -i your-key.pem ec2-user@bastion-ip"
}

# Monitoring Dashboards
output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.observability.cloudwatch_dashboard_name
}

# Summary
output "deployment_summary" {
  description = "Summary of the staging deployment"
  value = {
    environment      = "staging"
    vpc_id          = module.network.vpc_id
    alb_dns         = module.loadbalancer.alb_dns_name
    app_url         = "https://${var.record_name}"
    db_endpoint     = module.database.db_instance_endpoint
    s3_bucket       = module.storage.s3_bucket_name
    efs_id          = module.storage.efs_file_system_id
    asg_name        = module.compute.autoscaling_group_name
    sns_topic       = module.observability.sns_topic_arn
    cloudfront_id   = module.cdn.cloudfront_distribution_id
  }
}