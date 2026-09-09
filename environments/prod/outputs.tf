# Production Environment Outputs
# These outputs provide comprehensive information about the production infrastructure
# with security considerations for sensitive information

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

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.network.nat_gateway_ids
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

output "alb_security_policy" {
  description = "Security policy used by the ALB"
  value       = module.loadbalancer.security_policy
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

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = module.cdn.cloudfront_hosted_zone_id
}

output "route53_record_name" {
  description = "Route53 record name"
  value       = module.cdn.route53_record_name
}

output "route53_record_fqdn" {
  description = "Fully qualified domain name of the Route53 record"
  value       = module.cdn.route53_record_fqdn
}

# Compute Outputs
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.compute.launch_template_id
}

output "launch_template_version" {
  description = "Latest version of the launch template"
  value       = module.compute.launch_template_version
}

output "launch_template_name" {
  description = "Name of the launch template"
  value       = module.compute.launch_template_name
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

output "storage_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = module.storage.s3_bucket_domain_name
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

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = module.storage.efs_dns_name
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

output "db_master_user_secret_name" {
  description = "Name of the RDS master user secret"
  value       = module.database.master_user_secret_name
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

output "app_policy_arn" {
  description = "ARN of the application IAM policy"
  value       = module.iam.policy_arn
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

output "app_secret_version" {
  description = "Version of the application secret"
  value       = module.secrets.secret_version
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

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.observability.cloudwatch_dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.observability.cloudwatch_dashboard_name}"
}

# Environment Information
output "environment" {
  description = "Current environment"
  value       = "production"
}

output "app_full_name" {
  description = "Full application name with environment"
  value       = "${var.app_name}-production"
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# Useful URLs
output "application_url" {
  description = "URL of the application"
  value       = "https://${var.record_name}"
}

output "alb_url" {
  description = "URL of the ALB"
  value       = "https://${module.loadbalancer.alb_dns_name}"
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${module.cdn.cloudfront_domain_name}"
}

# Health Check URLs
output "health_check_endpoint" {
  description = "Health check endpoint"
  value       = "https://${var.record_name}/health"
}

# Security Information (for audits)
output "security_config_summary" {
  description = "Security configuration summary"
  value = {
    alb_security_policy    = module.loadbalancer.security_policy
    ssl_certificate       = var.certificate_domain
    deletion_protection   = var.db_deletion_protection
    backup_retention      = var.db_backup_retention_period
    multi_az              = var.db_multi_az
    nat_gateway_count     = var.nat_gateway_count
    min_asg_size          = var.min_size
    max_asg_size          = var.max_size
  }
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of the production deployment"
  value = {
    environment        = "production"
    vpc_id            = module.network.vpc_id
    alb_dns           = module.loadbalancer.alb_dns_name
    app_url           = "https://${var.record_name}"
    db_endpoint       = module.database.db_instance_endpoint
    db_multi_az       = var.db_multi_az
    s3_bucket         = module.storage.s3_bucket_name
    efs_id            = module.storage.efs_file_system_id
    asg_name          = module.compute.autoscaling_group_name
    asg_min           = var.min_size
    asg_max           = var.max_size
    asg_desired       = var.desired_capacity
    instance_type     = var.instance_type
    sns_topic         = module.observability.sns_topic_arn
    cloudfront_id     = module.cdn.cloudfront_distribution_id
    cloudwatch_dashboard = module.observability.cloudwatch_dashboard_name
    secret_recovery_window = var.secret_recovery_window_days
  }
}

# Sensitive outputs that should be marked as sensitive
output "db_connection_string" {
  description = "Database connection string (sensitive)"
  value       = "postgresql://${var.db_username}:<password>@${module.database.db_instance_address}:${module.database.db_instance_port}/${var.db_name}"
  sensitive   = true
}

output "app_secret_arn_sensitive" {
  description = "ARN of the application secret (sensitive)"
  value       = module.secrets.secret_arn
  sensitive   = true
}

# Cost Optimization Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for production environment (USD)"
  value = {
    ec2_instances  = "${var.min_size} x ${var.instance_type}"
    rds            = "${var.db_instance_class} (${var.db_multi_az ? "Multi-AZ" : "Single-AZ"})"
    nat_gateways   = var.nat_gateway_count
    storage        = "${var.db_allocated_storage}GB RDS + EFS"
  }
}

# DR Information
output "disaster_recovery_summary" {
  description = "Disaster recovery configuration summary"
  value = {
    multi_az_db           = var.db_multi_az
    backup_retention      = var.db_backup_retention_period
    final_snapshot        = !var.db_skip_final_snapshot
    deletion_protection   = var.db_deletion_protection
    auto_scaling          = true
    min_instances        = var.min_size
    max_instances        = var.max_size
  }
}