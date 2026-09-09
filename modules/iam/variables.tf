variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "s3_bucket_arn" {
  description = "ARN of the storage bucket from STO-001"
  type        = string
}

variable "efs_file_system_arn" {
  description = "ARN of the EFS filesystem from STO-001"
  type        = string
}

variable "efs_access_point_arn" {
  description = "ARN of the EFS access point from STO-001"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the RDS-managed master secret from DB-001"
  type        = string
}

variable "enable_ssm" {
  description = "Attach AWS-managed SSM policy for Session Manager access"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}