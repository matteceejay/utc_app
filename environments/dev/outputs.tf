output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids_list
}

output "app_subnet_ids" {
  value = module.network.app_subnet_ids_list
}

output "db_subnet_ids" {
  value = module.network.db_subnet_ids_list
}

output "alb_security_group_id" {
  value = module.security.alb_security_group_id
}

output "app_security_group_id" {
  value = module.security.app_security_group_id
}

output "db_security_group_id" {
  value = module.security.db_security_group_id
}


output "alb_dns_name" {
  value = module.loadbalancer.alb_dns_name
}

output "target_group_arn" {
  value = module.loadbalancer.target_group_arn
}


# Auto Scaling Group (ASG) name is needed to attach the ASG to the target group.
output "asg_name" {
  value = module.compute.autoscaling_group_name
}





# Storage Outputs
# The S3 bucket name is needed to attach the bucket to the application for file uploads.
output "storage_bucket_name" {
  value = module.storage.s3_bucket_name
}

output "efs_file_system_id" {
  value = module.storage.efs_file_system_id
}

output "efs_access_point_id" {
  value = module.storage.efs_access_point_id
}




# efs file system arn and access point arn are needed to attach the EFS to the EC2 instances in the ASG.




## IAM Outputs
## The IAM role and instance profile are needed to attach the role to the EC2 instances in the ASG.
output "app_role_arn" {
  value = module.iam.role_arn
}

output "app_instance_profile_name" {
  value = module.iam.instance_profile_name
}

## Outputs for secrets
output "app_secret_arn" {
  value = module.secrets.secret_arn
}

output "alerts_topic_arn" {
  value = module.observability.sns_topic_arn
}

# Outputs for CI/CD
# The deploy role ARN is needed to allow GitHub Actions to assume the role and deploy the application.
output "github_deploy_role_arn" {
  value = module.cicd.deploy_role_arn
}