variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_subnet_ids" {
  description = "Private app subnet IDs to launch instances into"
  type        = list(string)
}

variable "app_security_group_id" {
  type = string
}

variable "target_group_arn" {
  description = "ALB target group ARN to register instances with"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB arn_suffix, used for the request-count scaling metric"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group arn_suffix, used for the request-count scaling metric"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (optional - omit if using SSM Session Manager only)"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name (from IAM-001). Leave null until that's built."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Raw (non-base64) user data script. Defaults to a minimal placeholder."
  type        = string
  default     = null
}

variable "root_volume_size" {
  type    = number
  default = 20
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "target_requests_per_target" {
  description = "Target ALB requests per instance before scaling out"
  type        = number
  default     = 1000
}

variable "health_check_grace_period" {
  type    = number
  default = 300
}

variable "tags" {
  type    = map(string)
  default = {}
}




variable "efs_file_system_id" {
  description = "EFS filesystem ID from STO-001, mounted via the access point"
  type        = string
}

variable "efs_access_point_id" {
  description = "EFS access point ID from STO-001"
  type        = string
}

variable "efs_mount_path" {
  description = "Local path where the EFS access point is mounted on each instance"
  type        = string
  default     = "/mnt/uploads"
}


variable "app_secret_arn" {
  description = "ARN of the app secret from SEC-002"
  type        = string
  default     = null
}

variable "db_secret_arn" {
  description = "ARN of the RDS master secret from DB-001"
  type        = string
  default     = null
}



variable "deploy_bucket" {
  description = "S3 bucket GitHub Actions uploads deploy artifacts to"
  type        = string
}

variable "deploy_prefix" {
  type    = string
  default = "deploy/"
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}


variable "aws_region" {
  description = "AWS region instances run in - needed by boto3 for Secrets Manager calls"
  type        = string
}